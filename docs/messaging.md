# My Devices on the Framework and Mac

My Devices is a private, encrypted Matrix room for two devices signed in to the same account. The Framework uses Home’s native Chats sidebar. The Mac can use Element. Both devices use the homeserver of the existing account.

## Connect once

1. On the Mac, open Element and find your full Matrix ID in account settings. Confirm that the Mac session is verified and that you have the account’s Matrix recovery key. Element’s security settings can enable recovery if the account has never set it up. Keep the verified Mac signed in throughout setup.
2. In a terminal on the Framework, run `scripts/chat setup` from the repository. Close Chats while running setup. The launcher uses the pinned Nix shell and Cargo.lock. The first build downloads the Rust dependencies and can take several minutes. `scripts/chat build` builds without signing in.
3. Enter the full Matrix ID, then choose password or browser SSO according to the homeserver’s supported sign-in methods. Enter the recovery key in the hidden terminal prompt. The SDK imports the existing cross-signing and backup keys and checks that the Framework is a verified device. The browser method requires the server’s Matrix SSO compatibility flow.
4. Type `create` to make an encrypted, invite-only room called **My Devices** with joined-member history. Alternatively, paste the internal room ID of an existing encrypted, invite-only room containing only your account. The service binds the profile to the room ID. A second room with the same name is a different conversation.
5. Run `scripts/dock start` or `scripts/dock reload` and select **Home → Chats**. Open the same room on the Mac. Single-person rooms may be under **Rooms** in Element.

Use the same commands after a restart. Normal launches restore the device identity from the login keyring and its encrypted SDK database. Run `scripts/chat build` after changing the service. Close and reopen Chats to load the new executable.

## Make a round trip

Send a short line from Home and check it appears on the Mac. Send a screenshot and a document back from Element. Choose **Preview** on the image, then **Save…** on each attachment and select a new filename. **Show file** opens the destination folder. Drag a file onto the conversation or select **Add attachment**, then press **Send**. Transfers are limited to 25 MiB per file. In-app previews support PNG, JPEG and WebP.

Restart the preview, reopen Chats and check the conversation. Take the Framework offline, send a message on the Mac, reconnect and check that it arrives. Failed sends keep the composer contents while the sidebar is open. Retrying an unchanged send uses the same Matrix transaction ID. After closing the sidebar during an upload or send, check the timeline before resending. **Earlier messages** retrieves the previous page.

## Verification and recovery

- **Verification required** means the SDK cannot establish trust in the local device. Close Chats and run setup with the recovery key from the same account. If the Mac is unverified, verify it in Element. Sending requires another cross-signed device on the account.
- **Missing key or unverified sending device** marks a message the SDK could not decrypt under the configured trust policy. Verify the originating device and ensure Element’s encrypted history backup is current. Reopen Chats to fetch the timeline again. History without a recoverable key can remain unreadable.
- **Offline** retains the visible conversation and reconnects. Loading earlier history and starting transfers need a connection. A sent indicator acknowledges homeserver acceptance. It does not establish that another device has read the message.
- **Expired session** means the homeserver revoked the login. With Chats and setup closed, move the local Matrix data directory aside, run setup again, recover the account and select the original room ID. Keep the old data directory and keyring item until recovery is confirmed.
- **Unlock the login keyring** means Secret Service could not retrieve the session. Unlock the existing GNOME keyring. Keep credentials, recovery keys, downloaded files and personal captures outside the checkout.

## Service boundary

`messaging/` is a Rust executable with an interactive provisioning command and a private standard-input/output interface. Quickshell starts it while the personal sidebar is open. JSON lines carry requests and replies for history, send, upload, preview and save, plus connection and transfer notifications. Credentials remain inside the service. It has no listening socket or background daemon.

The SDK handles device identity, Olm/Megolm, synchronization, pagination and encrypted uploads. Downloads stream ciphertext from the authenticated Matrix media endpoint with a size limit, then use the SDK’s attachment decryptor and integrity check before saving. The service writes completed downloads into new files with owner-only permissions. Live transfers and drafts are in memory. The homeserver stores conversation history as encrypted room events.

GNOME Secret Service holds the session and a generated SQLite store passphrase. The local profile and SDK databases live under `$XDG_DATA_HOME/SpacesOS/matrix` (normally `~/.local/share/SpacesOS/matrix`). The shell renders plain text and previews decoded images in memory. It never routes personal events to the shared Files shelf. Switching away from Home destroys the chat view and its process. Setup discovers room metadata. The running service filters room synchronization to the bound room.

The pinned Rust compiler is 1.95. SDK 0.18 supports it and includes cross-signing, backup recovery, encrypted SQLite stores and encrypted media. SDK 0.19 requires Rust 1.96. The dedicated development shell keeps Rust compilation out of a normal dock launch. See the [SDK repository](https://github.com/matrix-org/matrix-rust-sdk).

## Checks and design review

Run `scripts/test-messaging` to start a loopback-only disposable Synapse, a private D-Bus session and a temporary keyring. It generates a test account, authenticates two devices, verifies cross-signing and recovery, compares received file bytes, restores the service, and checks the same IPC used by Quickshell. All fixture data is temporary. Use `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software scripts/dock test` for the dock regression suite.

The design references are Home `2515:68984`, current Space chat `2515:69078` and participant chat `2515:69311`. Inspect at 100% logical scale. `scripts/dock capture /path/to/capture.png` captures visible messages too. Use a disposable conversation for screenshots intended for review.

Questions for Spaces Architect concern the single-room entry in Home, device labels beside timestamps, and the placement of attachment actions, errors and verification guidance. When Element publishes a typing notice, the composer shows “Typing on another device”. Matrix identifies the account in this event, so the label omits the device name. This first client only receives typing notices. Shared-Space conversations and Apple Messages remain later milestones.
