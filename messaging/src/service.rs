use crate::{account, core};
use anyhow::{Result, ensure};
use base64::{Engine, engine::general_purpose::STANDARD};
use matrix_sdk::{
    Client,
    config::SyncSettings,
    media::{MediaFormat, MediaThumbnailSettings},
    ruma::{OwnedEventId, OwnedRoomId, RoomId},
};
use serde::Deserialize;
use serde_json::{Value, json};
use std::{io::Cursor, time::Duration};
use tokio::io::{AsyncBufReadExt, BufReader};

#[derive(Deserialize)]
#[serde(tag = "op", rename_all = "snake_case")]
enum Request {
    History { before: Option<String> },
    Text { body: String, txn: String },
    Upload { url: String, txn: String },
    Save { event: OwnedEventId, url: String },
    Preview { event: OwnedEventId },
    Avatar,
}

fn thumbnail(bytes: &[u8], edge: u32) -> Result<String> {
    let mut reader = image::ImageReader::new(Cursor::new(bytes)).with_guessed_format()?;
    let mut limits = image::Limits::default();
    limits.max_image_width = Some(8192);
    limits.max_image_height = Some(8192);
    limits.max_alloc = Some(96 * 1024 * 1024);
    reader.limits(limits);
    let img = reader.decode()?.thumbnail(edge, edge).to_rgb8();
    let mut out = Cursor::new(Vec::new());
    img.write_to(&mut out, image::ImageFormat::Jpeg)?;
    Ok(format!(
        "data:image/jpeg;base64,{}",
        STANDARD.encode(out.into_inner())
    ))
}

pub fn reason(err: &anyhow::Error) -> &'static str {
    match err.to_string().as_str() {
        "setup" => "Close Chats and run scripts/chat setup in a terminal.",
        "room" => "This room must be encrypted, invite-only and contain only your account.",
        "keyring" => "Unlock the login keyring, then reopen Chats.",
        "busy" => "Messaging is open elsewhere. Close Chats before running setup.",
        "verify" | "keys" | "recovery" => {
            "Verify this device using the recovery key from Element. Close Chats and run scripts/chat setup."
        }
        "peer" => "Verify the Mac session in Element before sending.",
        "restore" | "login" | "account" => {
            "Sign-in failed. Check the account, server and login method."
        }
        "save" => "Choose a new filename in a writable folder.",
        "size" => "Attachments can be up to 25 MiB.",
        "text" => "Enter a message of up to 32 KB.",
        "file" => "Choose a local file.",
        _ => {
            "Request failed. Check the connection, file access and device verification, then retry."
        }
    }
}

fn emit(v: Value) {
    println!("{v}");
}

async fn handle(client: &Client, id: &RoomId, req: Request, serial: u64) -> Result<Value> {
    let progress = |current, total| {
        emit(json!({"type":"progress","serial":serial,"current":current,"total":total}))
    };
    match req {
        Request::History { before } => core::history(client, id, before.as_deref()).await,
        Request::Text { body, txn } => {
            core::send_with_id(client, id, &body, &txn).await?;
            Ok(Value::Null)
        }
        Request::Upload { url, txn } => {
            core::upload_with_id(client, id, &account::file_path(&url)?, &txn, progress).await?;
            Ok(Value::Null)
        }
        Request::Save { event, url } => {
            let data = core::download(client, id, &event, progress).await?;
            core::save(&data, &account::file_path(&url)?)?;
            Ok(Value::Null)
        }
        Request::Preview { event } => {
            let data = core::download(client, id, &event, progress).await?;
            Ok(json!(thumbnail(&data, 320)?))
        }
        Request::Avatar => {
            let room = core::room(client, id).await?;
            let member = room.get_member(client.user_id().unwrap()).await?;
            if let Some(m) = member
                && let Some(data) = m
                    .avatar(MediaFormat::Thumbnail(MediaThumbnailSettings::new(
                        72u32.into(),
                        72u32.into(),
                    )))
                    .await?
            {
                Ok(json!(thumbnail(&data, 72)?))
            } else {
                Ok(Value::Null)
            }
        }
    }
}

async fn observe(client: Client, room: OwnedRoomId) {
    let mut filter = matrix_sdk::ruma::api::client::filter::FilterDefinition::default();
    filter.room.rooms = Some(vec![room.clone()]);
    let mut since = None;
    let mut offline = true;
    loop {
        let mut settings = SyncSettings::default()
            .filter(filter.clone().into())
            .timeout(Duration::from_secs(15));
        if let Some(s) = since.clone() {
            settings = settings.token(s)
        }
        match client.sync_once(settings).await {
            Ok(update) => {
                if let Some(joined) = update.rooms.joined.get(&room) {
                    for raw in &joined.ephemeral {
                        if let Ok(matrix_sdk::ruma::events::AnySyncEphemeralRoomEvent::Typing(
                            event,
                        )) = raw.deserialize()
                        {
                            let active = event
                                .content
                                .user_ids
                                .iter()
                                .any(|id| Some(id.as_ref()) == client.user_id());
                            emit(json!({"type":"typing","active":active}));
                        }
                    }
                }
                let changed = offline
                    || update.rooms.iter_all_room_ids().any(|r| r == &room)
                    || !update.to_device.is_empty();
                since = Some(update.next_batch);
                offline = false;
                if changed {
                    emit(json!({"type":"changed"}))
                }
            }
            Err(e)
                if matches!(
                    e.client_api_error_kind(),
                    Some(matrix_sdk::ruma::api::error::ErrorKind::UnknownToken(_))
                ) =>
            {
                emit(
                    json!({"type":"unavailable","message":"Your Matrix session expired. Follow the sign-in recovery steps in docs/messaging.md."}),
                );
                return;
            }
            Err(_) => {
                emit(json!({"type":"offline"}));
                offline = true;
                tokio::time::sleep(Duration::from_secs(3)).await;
            }
        }
    }
}

pub async fn serve(profile: &account::Profile) -> Result<()> {
    let (client, id) = profile.connected().await?;
    let worker = tokio::spawn(observe(client.clone(), id.clone()));
    let mut lines = BufReader::new(tokio::io::stdin()).lines();
    while let Some(line) = lines.next_line().await? {
        ensure!(line.len() < 128 * 1024, "request");
        let Ok(v) = serde_json::from_str::<Value>(&line) else {
            continue;
        };
        let Some(serial) = v["serial"].as_u64() else {
            continue;
        };
        let reply = match serde_json::from_value::<Request>(v) {
            Ok(req) => handle(&client, &id, req, serial).await,
            Err(_) => Err(anyhow::anyhow!("request")),
        };
        match reply {
            Ok(data) => emit(json!({"type":"reply","serial":serial,"data":data})),
            Err(err) => emit(json!({"type":"reply","serial":serial,"error":reason(&err)})),
        }
    }
    worker.abort();
    Ok(())
}
