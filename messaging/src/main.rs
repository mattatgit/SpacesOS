mod account;
mod core;
mod service;
#[cfg(test)]
mod tests;

#[tokio::main]
async fn main() {
    let cmd = std::env::args().nth(1).unwrap_or_default();
    let result = async {
        let profile = account::Profile::open()?;
        match cmd.as_str() {
            "setup" => profile.setup().await,
            "serve" => service::serve(&profile).await,
            _ => anyhow::bail!("command"),
        }
    }
    .await;
    if let Err(e) = result {
        let message = service::reason(&e);
        if cmd == "serve" {
            println!(
                "{}",
                serde_json::json!({"type":"unavailable","message":message})
            )
        } else {
            eprintln!("{message}")
        }
        std::process::exit(1)
    }
}
