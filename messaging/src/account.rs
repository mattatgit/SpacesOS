use crate::core;
use anyhow::{Context, Result, ensure};
use matrix_sdk::{
    Client,
    authentication::matrix::MatrixSession,
    ruma::{OwnedRoomId, UserId},
};
use serde::{Deserialize, Serialize};
use std::{
    fs::{self, File},
    io::{self, Write},
    os::unix::fs::DirBuilderExt,
    path::PathBuf,
    process::{Command, Stdio},
};

#[derive(Serialize, Deserialize)]
pub struct Account {
    server: String,
    store_key: String,
    session: MatrixSession,
    pub room: Option<OwnedRoomId>,
}

pub struct Profile {
    root: PathBuf,
    _lock: File,
}

impl Profile {
    pub fn open() -> Result<Self> {
        let base = std::env::var_os("XDG_DATA_HOME")
            .map(PathBuf::from)
            .or_else(|| {
                std::env::var_os("HOME").map(|home| PathBuf::from(home).join(".local/share"))
            })
            .context("profile")?;
        let root = base.join("SpacesOS/matrix");
        fs::DirBuilder::new()
            .recursive(true)
            .mode(0o700)
            .create(&root)?;
        let lock = File::options()
            .create(true)
            .truncate(false)
            .write(true)
            .open(root.join("lock"))?;
        lock.try_lock().map_err(|_| anyhow::anyhow!("busy"))?;
        Ok(Self { root, _lock: lock })
    }

    fn identifier(&self) -> Result<String> {
        let id = fs::read_to_string(self.root.join("profile")).context("setup")?;
        ensure!(
            id.len() == 32 && id.bytes().all(|c| c.is_ascii_hexdigit()),
            "profile"
        );
        Ok(id)
    }

    fn load(&self, id: &str) -> Result<Account> {
        let output = Command::new("secret-tool")
            .args(["lookup", "application", "SpacesOS-Matrix", "profile", id])
            .stderr(Stdio::null())
            .output()
            .context("keyring")?;
        ensure!(output.status.success(), "keyring");
        serde_json::from_slice(&output.stdout).context("keyring")
    }

    fn store(&self, id: &str, account: &Account) -> Result<()> {
        let mut child = Command::new("secret-tool")
            .args([
                "store",
                "--label=Spaces OS messaging",
                "application",
                "SpacesOS-Matrix",
                "profile",
                id,
            ])
            .stdin(Stdio::piped())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()
            .context("keyring")?;
        serde_json::to_writer(child.stdin.take().context("keyring")?, account)?;
        ensure!(child.wait()?.success(), "keyring");
        Ok(())
    }

    async fn restore(&self, id: &str) -> Result<(Client, Account)> {
        let account = self.load(id)?;
        let client = core::client(&account.server, &self.root.join(id), &account.store_key).await?;
        client
            .restore_session(account.session.clone())
            .await
            .context("restore")?;
        Ok((client, account))
    }

    pub async fn connected(&self) -> Result<(Client, OwnedRoomId)> {
        let (client, a) = self.restore(&self.identifier()?).await?;
        Ok((client, a.room.context("setup")?))
    }

    pub async fn setup(&self) -> Result<()> {
        let (id, client, mut a) = if self.root.join("profile").try_exists()? {
            let id = self.identifier()?;
            let (client, a) = self.restore(&id).await?;
            (id, client, a)
        } else {
            let user = UserId::parse(prompt(
                "Matrix ID from Element (for example @name:example.org)",
            )?)?;
            let id = format!("{:032x}", rand::random::<u128>());
            let store_key = format!(
                "{:032x}{:032x}",
                rand::random::<u128>(),
                rand::random::<u128>()
            );
            let client = core::client(
                user.server_name().as_str(),
                &self.root.join(&id),
                &store_key,
            )
            .await?;
            ensure!(client.homeserver().scheme() == "https", "https");
            let browser = prompt("Sign in with browser SSO or password? [s/p]")?;
            let auth = client.matrix_auth();
            if browser == "s" {
                auth.login_sso(|url| async move {
                    let status = Command::new("xdg-open")
                        .arg(url)
                        .stdout(Stdio::null())
                        .stderr(Stdio::null())
                        .status()?;
                    if !status.success() {
                        return Err(io::Error::other("browser").into());
                    }
                    Ok(())
                })
                .initial_device_display_name("Spaces OS Framework")
                .await
                .context("login")?;
            } else {
                ensure!(browser == "p", "login");
                let password = rpassword::prompt_password("Matrix password (hidden): ")?;
                auth.login_username(&user, &password)
                    .initial_device_display_name("Spaces OS Framework")
                    .send()
                    .await
                    .context("login")?;
            }
            ensure!(client.user_id() == Some(&user), "account");
            let a = Account {
                server: client.homeserver().to_string(),
                store_key,
                session: auth.session().context("login")?,
                room: None,
            };
            self.store(&id, &a)?;
            core::save(id.as_bytes(), &self.root.join("profile"))?;
            (id, client, a)
        };
        core::sync(&client, None, 0).await?;
        if core::verified(&client, false).await.is_err() {
            eprintln!(
                "Use the Matrix recovery key from your verified Element session. This imports existing keys and verifies this device."
            );
            let key = rpassword::prompt_password("Recovery key (hidden): ")?;
            client
                .encryption()
                .recovery()
                .recover(key.trim())
                .await
                .context("recovery")?;
            core::sync(&client, None, 0).await?;
            core::verified(&client, false).await?;
        }
        if a.room.is_none() {
            let choice = prompt(
                "Paste the ID of your encrypted invite-only room containing only you, or type create to make My Devices",
            )?;
            let room_id = if choice == "create" {
                core::create_private(&client).await?.room_id().to_owned()
            } else {
                choice.try_into()?
            };
            core::sync(&client, None, 0).await?;
            core::room(&client, &room_id).await?;
            a.room = Some(room_id);
            self.store(&id, &a)?;
        }
        eprintln!(
            "My Devices is connected. Open Home → Chats on the Framework and the same room in Element."
        );
        Ok(())
    }
}

fn prompt(label: &str) -> Result<String> {
    eprint!("{label}: ");
    io::stderr().flush()?;
    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    Ok(input.trim().into())
}

pub fn file_path(url: &str) -> Result<PathBuf> {
    url::Url::parse(url)?
        .to_file_path()
        .map_err(|_| anyhow::anyhow!("file"))
}
