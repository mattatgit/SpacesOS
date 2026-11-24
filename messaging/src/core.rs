use anyhow::{Context, Result, ensure};
use matrix_sdk::{
    Client, Room, RoomMemberships, RoomState, TransmissionProgress,
    attachment::{AttachmentConfig, AttachmentInfo, BaseFileInfo, BaseImageInfo},
    config::{RequestConfig, SyncSettings},
    encryption::{BackupDownloadStrategy, EncryptionSettings},
    reqwest,
    room::MessagesOptions,
    ruma::{
        EventId, RoomId, UserId,
        api::client::room::create_room::v3::{Request, RoomPreset},
        events::room::{EncryptedFile, join_rules::JoinRule, message::RoomMessageEventContent},
    },
};
use matrix_sdk_crypto::{CollectStrategy, DecryptionSettings, TrustRequirement};
use serde_json::{Value, json};
use std::{
    io::{Read, Write},
    os::unix::fs::OpenOptionsExt,
    path::Path,
    time::Duration,
};

pub const LIMIT: u64 = 25 * 1024 * 1024;

pub async fn client(server: &str, path: &Path, key: &str) -> Result<Client> {
    let builder = if server.contains("://") {
        // This is the previously discovered endpoint. Restoring should also work offline.
        Client::builder().homeserver_url(server)
    } else {
        Client::builder().server_name_or_homeserver_url(server)
    };
    let builder = builder
        .sqlite_store(path, Some(key))
        .request_config(RequestConfig::short_retry().timeout(Duration::from_secs(25)))
        .with_room_key_recipient_strategy(CollectStrategy::OnlyTrustedDevices)
        .with_decryption_settings(DecryptionSettings {
            sender_device_trust_requirement: TrustRequirement::CrossSigned,
        })
        .with_encryption_settings(EncryptionSettings {
            backup_download_strategy: BackupDownloadStrategy::AfterDecryptionFailure,
            ..Default::default()
        });
    Ok(builder.build().await?)
}

pub async fn sync(client: &Client, token: Option<String>, seconds: u64) -> Result<String> {
    let mut filter = matrix_sdk::ruma::api::client::filter::FilterDefinition::default();
    filter.room.timeline.limit = Some(0u32.into());
    let mut settings = SyncSettings::default()
        .filter(filter.into())
        .timeout(Duration::from_secs(seconds));
    if let Some(token) = token {
        settings = settings.token(token);
    }
    Ok(client.sync_once(settings).await?.next_batch)
}

pub async fn create_private(client: &Client) -> Result<Room> {
    let mut req = Request::new();
    req.name = Some("My Devices".into());
    req.preset = Some(RoomPreset::PrivateChat);
    req.initial_state = serde_json::from_value(json!([
        {"type":"m.room.encryption","state_key":"","content":{"algorithm":"m.megolm.v1.aes-sha2"}},
        {"type":"m.room.history_visibility","state_key":"","content":{"history_visibility":"joined"}}
    ]))?;
    Ok(client.create_room(req).await?)
}

pub async fn room(client: &Client, id: &RoomId) -> Result<Room> {
    let room = client.get_room(id).context("sync")?;
    ensure!(
        room.state() == RoomState::Joined
            && matches!(room.join_rule(), Some(JoinRule::Invite))
            && !room.is_space()
            && room.latest_encryption_state().await?.is_encrypted(),
        "room"
    );
    let members = room.members(RoomMemberships::ACTIVE).await?;
    ensure!(
        members.len() == 1 && Some(members[0].user_id()) == client.user_id(),
        "room"
    );
    Ok(room)
}

pub async fn verified(client: &Client, require_peer: bool) -> Result<()> {
    let crypto = client.encryption();
    ensure!(
        crypto
            .get_own_device()
            .await?
            .is_some_and(|d| d.is_verified_with_cross_signing()),
        "verify"
    );
    if require_peer {
        let devices = crypto
            .get_user_devices(client.user_id().context("login")?)
            .await?;
        ensure!(
            devices
                .devices()
                .any(|d| Some(d.device_id()) != client.device_id()
                    && d.is_verified_with_cross_signing()),
            "peer"
        );
    }
    Ok(())
}

#[cfg(test)]
pub async fn send_text(client: &Client, id: &RoomId, text: &str) -> Result<()> {
    send_with_id(client, id, text, &rand::random::<u128>().to_string()).await
}

pub async fn send_with_id(client: &Client, id: &RoomId, text: &str, txn: &str) -> Result<()> {
    ensure!(!txn.is_empty() && txn.len() <= 128, "request");
    ensure!(!text.trim().is_empty() && text.len() <= 32000, "text");
    let room = room(client, id).await?;
    verified(client, true).await?;
    room.send(RoomMessageEventContent::text_plain(text))
        .with_transaction_id(txn.into())
        .await?;
    Ok(())
}

pub fn read_attachment(path: &Path) -> Result<Vec<u8>> {
    let f = std::fs::OpenOptions::new()
        .read(true)
        .custom_flags(libc::O_NONBLOCK)
        .open(path)?;
    let meta = f.metadata()?;
    ensure!(meta.is_file() && meta.len() <= LIMIT, "size");
    let mut data = Vec::new();
    f.take(LIMIT + 1).read_to_end(&mut data)?;
    ensure!(data.len() as u64 <= LIMIT, "size");
    Ok(data)
}

#[cfg(test)]
pub async fn upload(client: &Client, id: &RoomId, path: &Path) -> Result<()> {
    upload_with_id(
        client,
        id,
        path,
        &rand::random::<u128>().to_string(),
        |_, _| {},
    )
    .await
}

pub async fn upload_with_id(
    client: &Client,
    id: &RoomId,
    path: &Path,
    txn: &str,
    progress: impl Fn(u64, u64),
) -> Result<()> {
    ensure!(!txn.is_empty() && txn.len() <= 128, "request");
    let room = room(client, id).await?;
    verified(client, true).await?;
    let data = read_attachment(path)?;
    let name = path.file_name().and_then(|s| s.to_str()).context("file")?;
    let mime = mime_guess::from_path(path).first_or_octet_stream();
    let size = Some((data.len() as u32).into());
    let info = if mime.type_().as_str() == "image" {
        AttachmentInfo::Image(BaseImageInfo {
            size,
            ..Default::default()
        })
    } else {
        AttachmentInfo::File(BaseFileInfo { size })
    };
    let observable = eyeball::SharedObservable::<TransmissionProgress>::default();
    let mut changes = observable.subscribe();
    let upload = room
        .send_attachment(
            name,
            &mime,
            data,
            AttachmentConfig::new().txn_id(txn.into()).info(info),
        )
        .with_send_progress_observable(observable)
        .into_future();
    tokio::pin!(upload);
    loop {
        tokio::select! {
            result=&mut upload=>{ result?;break; }
            Some(p)=changes.next()=>progress(p.current as u64,p.total as u64)
        }
    }
    Ok(())
}

pub async fn history(client: &Client, id: &RoomId, from: Option<&str>) -> Result<Value> {
    let room = room(client, id).await?;
    verified(client, false).await?;
    let member = room
        .get_member(client.user_id().context("login")?)
        .await?
        .context("room")?;
    let mut options = MessagesOptions::backward();
    options.limit = 50u32.into();
    options.from = from.map(str::to_owned);
    let page = room.messages(options).await?;
    let devices = client.devices().await.ok();
    let mut rows = Vec::new();
    for event in page.chunk.iter().rev() {
        let raw: Value = serde_json::from_str(event.raw().json().get())?;
        if raw["sender"].as_str() != client.user_id().map(UserId::as_str) {
            continue;
        }
        let c = &raw["content"];
        let kind = match (raw["type"].as_str(), event.encryption_info().is_some()) {
            (Some("m.room.encrypted"), _) => "locked",
            (Some("m.room.message"), true) => match c["msgtype"].as_str() {
                Some("m.text") => "text",
                Some("m.file") if c["file"].is_object() => "file",
                Some("m.image") if c["file"].is_object() => "image",
                _ => continue,
            },
            _ => continue,
        };
        let origin = event
            .encryption_info()
            .filter(|info| {
                info.verification_state
                    == matrix_sdk::deserialized_responses::VerificationState::Verified
            })
            .and_then(|info| info.sender_device.as_deref());
        let device_name = origin.and_then(|id| {
            devices
                .as_ref()?
                .devices
                .iter()
                .find(|device| device.device_id == id)
                .and_then(|device| device.display_name.as_deref())
        });
        let body = match kind {
            "locked" => "Missing key or unverified sending device",
            "image" | "file" => c["filename"]
                .as_str()
                .or_else(|| c["body"].as_str())
                .unwrap_or("Attachment"),
            _ => c["body"].as_str().unwrap_or(""),
        };
        rows.push(
            json!({"id":raw["event_id"], "name":member.name(), "sender":raw["sender"],
            "time":raw["origin_server_ts"], "kind":kind, "body":body,
            "size":c["info"]["size"].as_u64(), "mime":c["info"]["mimetype"].as_str(),
            "deviceName":device_name}),
        );
    }
    Ok(json!({"items":rows,"previous":page.end}))
}

pub async fn download(
    client: &Client,
    id: &RoomId,
    event_id: &EventId,
    progress: impl Fn(u64, u64),
) -> Result<Vec<u8>> {
    let room = room(client, id).await?;
    verified(client, false).await?;
    let event = room.event(event_id, None).await?;
    let raw: Value = serde_json::from_str(event.raw().json().get())?;
    ensure!(
        event.encryption_info().is_some()
            && raw["sender"].as_str() == client.user_id().map(UserId::as_str)
            && raw["type"] == "m.room.message",
        "keys"
    );
    let c = &raw["content"];
    ensure!(
        matches!(c["msgtype"].as_str(), Some("m.image" | "m.file")) && c["file"].is_object(),
        "file"
    );
    ensure!(
        c["info"]["size"].as_u64().is_none_or(|n| n <= LIMIT),
        "size"
    );
    let file: EncryptedFile = serde_json::from_value(c["file"].clone())?;
    let (server, media_id) = file.url.parts()?;
    let mut url = client.homeserver();
    url.path_segments_mut()
        .map_err(|_| anyhow::anyhow!("file"))?
        .pop_if_empty()
        .extend([
            "_matrix",
            "client",
            "v1",
            "media",
            "download",
            server.as_str(),
            media_id,
        ]);
    // Keep the bearer token on the authenticated homeserver. Stream ciphertext
    // so the size limit also applies to missing or inaccurate event metadata.
    let transport = reqwest::Client::builder()
        .redirect(reqwest::redirect::Policy::none())
        .timeout(Duration::from_secs(180))
        .build()?;
    let mut response = transport
        .get(url)
        .bearer_auth(client.access_token().context("login")?)
        .send()
        .await?;
    ensure!(response.status().is_success(), "download");
    let total = response
        .content_length()
        .or_else(|| c["info"]["size"].as_u64())
        .unwrap_or(0);
    ensure!(total <= LIMIT, "size");
    let mut ciphertext = Vec::new();
    let mut last = 0;
    while let Some(chunk) = response.chunk().await? {
        ensure!(ciphertext.len() + chunk.len() <= LIMIT as usize, "size");
        ciphertext.extend_from_slice(&chunk);
        if ciphertext.len() - last >= 65536 || ciphertext.len() as u64 == total {
            progress(ciphertext.len() as u64, total);
            last = ciphertext.len();
        }
    }
    let mut bytes = Vec::with_capacity(ciphertext.len());
    matrix_sdk_crypto::AttachmentDecryptor::new(
        &mut std::io::Cursor::new(ciphertext),
        file.into(),
    )?
    .read_to_end(&mut bytes)?;
    Ok(bytes)
}

pub fn save(bytes: &[u8], destination: &Path) -> Result<()> {
    let mut tmp = tempfile::NamedTempFile::new_in(destination.parent().context("file")?)?;
    tmp.write_all(bytes)?;
    tmp.as_file().sync_all()?;
    tmp.persist_noclobber(destination)
        .map_err(|_| anyhow::anyhow!("save"))?;
    Ok(())
}
