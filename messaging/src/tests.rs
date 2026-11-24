use super::core::*;
use anyhow::{Result, ensure};
use matrix_sdk::{
    Client,
    config::SyncSettings,
    ruma::{
        api::client::room::create_room::v3::Request, events::room::message::RoomMessageEventContent,
    },
};
use tempfile::tempdir;

#[test]
fn attachment_is_private_and_never_overwrites() -> Result<()> {
    use std::os::unix::fs::PermissionsExt;
    let tmp = tempdir()?;
    let file = tmp.path().join("sample");
    save(b"first", &file)?;
    ensure!(save(b"second", &file).is_err());
    ensure!(read_attachment(&file)? == b"first");
    ensure!(file.metadata()?.permissions().mode() & 0o077 == 0);
    ensure!(read_attachment(tmp.path()).is_err());
    std::fs::OpenOptions::new()
        .write(true)
        .open(&file)?
        .set_len(LIMIT + 1)?;
    ensure!(read_attachment(&file).is_err());
    Ok(())
}

async fn tick(client: &Client) -> Result<()> {
    client
        .sync_once(SyncSettings::default().timeout(std::time::Duration::ZERO))
        .await?;
    Ok(())
}

#[tokio::test]
#[ignore = "run scripts/test-messaging for a disposable isolated homeserver"]
async fn two_devices() -> Result<()> {
    let url = std::env::var("SPIKE_SERVER")?;
    let password = std::env::var("SPIKE_PASSWORD")?;
    let parent = tempdir()?;
    let key = rand::random::<u128>().to_string();
    let open = |name: &str| {
        let path = parent.path().join(name);
        let key = key.clone();
        let url = url.clone();
        async move { client(&url, &path, &key).await }
    };
    let a = open("framework").await?;
    a.matrix_auth()
        .login_username("fixture", &password)
        .initial_device_display_name("Framework test device")
        .send()
        .await?;
    tick(&a).await?;
    a.encryption()
        .bootstrap_cross_signing_if_needed(None)
        .await?;
    let recovery = a.encryption().recovery().enable().await?;
    tick(&a).await?;
    let created = create_private(&a).await?;
    let id = created.room_id().to_owned();
    tick(&a).await?;
    ensure!(send_text(&a, &id, "with no verified peer").await.is_err());
    let b = open("peer").await?;
    b.matrix_auth()
        .login_username("fixture", &password)
        .initial_device_display_name("Peer test device")
        .send()
        .await?;
    tick(&b).await?;
    ensure!(verified(&b, false).await.is_err());
    b.encryption().recovery().recover(&recovery).await?;
    tick(&b).await?;
    tick(&a).await?;
    tick(&b).await?;
    verified(&a, true).await?;
    verified(&b, true).await?;
    let plain = a.create_room(Request::new()).await?;
    tick(&a).await?;
    ensure!(send_text(&a, plain.room_id(), "must fail").await.is_err());
    created
        .send(RoomMessageEventContent::text_plain("SDK fixture"))
        .await?;
    send_text(&a, &id, "Framework fixture").await?;
    tick(&b).await?;
    // Inject two wire events through the homeserver. The first lacks a room key.
    // The second is plaintext in an encrypted room and must never appear in Chats.
    use matrix_sdk::ruma::{
        TransactionId, api::client::message::send_message_event, events::MessageLikeEventType,
    };
    let raw = serde_json::json!({"algorithm":"m.megolm.v1.aes-sha2","ciphertext":"Ag","session_id":"absent","sender_key":"absent","device_id":"absent"});
    b.send(send_message_event::v3::Request::new_raw(
        id.clone(),
        TransactionId::new(),
        MessageLikeEventType::RoomEncrypted,
        serde_json::from_value(raw)?,
    ))
    .await?;
    b.send(send_message_event::v3::Request::new(
        id.clone(),
        TransactionId::new(),
        &RoomMessageEventContent::text_plain("Plaintext fixture"),
    )?)
    .await?;
    let media = [
        ("test.png", &include_bytes!("../tests/pixel.png")[..]),
        ("test.txt", &b"document fixture"[..]),
    ];
    for (name, bytes) in media {
        let path = parent.path().join(name);
        save(bytes, &path)?;
        upload(&b, &id, &path).await?;
    }
    tick(&a).await?;
    let rows = history(&a, &id, None).await?;
    let displayed = rows["items"].as_array().unwrap();
    ensure!(displayed.iter().any(|e| e["kind"] == "locked"));
    ensure!(displayed.iter().all(|e| e["body"] != "Plaintext fixture"));
    for (name, bytes) in media {
        let found = rows["items"]
            .as_array()
            .unwrap()
            .iter()
            .find(|e| e["body"] == name)
            .expect("encrypted attachment");
        ensure!(found["deviceName"] == "Peer test device");
        let data = download(
            &a,
            &id,
            found["id"].as_str().unwrap().try_into()?,
            |_, _| {},
        )
        .await?;
        ensure!(data == bytes);
    }
    let received = history(&b, &id, None).await?;
    ensure!(
        received["items"]
            .as_array()
            .unwrap()
            .iter()
            .any(|e| e["body"] == "Framework fixture")
    );
    let session = a.matrix_auth().session().unwrap();
    drop(created);
    drop(plain);
    drop(a);
    send_text(&b, &id, "while Framework offline").await?;
    let restored = open("framework").await?;
    restored.restore_session(session).await?;
    tick(&restored).await?;
    let rows = history(&restored, &id, None).await?;
    ensure!(
        rows["items"]
            .as_array()
            .unwrap()
            .iter()
            .any(|e| e["body"] == "while Framework offline")
    );
    // Provision the separate test process through an isolated Secret Service.
    // The harness supplies a temporary data directory and a dedicated session bus.
    let root = std::path::PathBuf::from(std::env::var("SPIKE_PROFILE_ROOT")?);
    let profile = format!("{:032x}", rand::random::<u128>());
    std::fs::create_dir_all(&root)?;
    let record = serde_json::json!({"server":url,"room":id,"session":restored.matrix_auth().session(),"store_key":key});
    drop(restored);
    std::fs::rename(parent.path().join("framework"), root.join(&profile))?;
    let mut store = std::process::Command::new("secret-tool")
        .args([
            "store",
            "--label=Ephemeral Spaces test",
            "application",
            "SpacesOS-Matrix",
            "profile",
            &profile,
        ])
        .stdin(std::process::Stdio::piped())
        .spawn()?;
    serde_json::to_writer(store.stdin.take().unwrap(), &record)?;
    ensure!(store.wait()?.success());
    save(profile.as_bytes(), &root.join("profile"))?;
    Ok(())
}
