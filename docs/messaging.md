# My Devices

Home’s Chats sidebar opens an encrypted Matrix conversation for exchanging text, images and documents with your own devices. Use Element on the Mac and the Spaces OS login on the Framework.

## Run on the Framework

In the real Spaces OS login, run this command in Console. The GNOME test desktop has its own profile and bus.

```sh
spaces-chat setup
```

Enter the Matrix ID shown in Element and follow the local sign-in and verification prompts. Create **My Devices** or select an existing private encrypted room containing only your account. The first build downloads the pinned Rust dependencies and can take several minutes.

In Home, use the upper-right Sidebar toggle to open My Devices. On the Mac, select the same room in Element. After a restart, reopen Chats to return to the conversation. After changing the Rust service, run `scripts/chat build`, then close and reopen Chats.

## Try a round trip

1. Send text from the Framework and check it arrives in Element.
2. Send a screenshot and a document from the Mac. Preview the image in Home and use **Save…** to keep each file under a new name. Use **Open file** for a saved PDF, text file or supported image.
3. Drag a file onto the conversation or choose **Add attachment**, then press **Send**. Check the reply on the Mac.
4. Reopen the Spaces session on the Framework and open the conversation. Disconnect the Framework, send another message from Element, reconnect and check it arrives.

A transfer can contain up to 25 MiB. The sidebar previews PNG, JPEG and WebP. Earlier history is available using **Earlier messages**. Verification notices appear below the header. Failed sends remain visible with a retry action while Chats is open. If the sidebar closed during a transfer, check the history before sending again. Personal attachments stay in the conversation when switching Spaces.

## Implementation and tests

A Rust executable handles Matrix operations. The native QML sidebar renders its conversation, attachment progress and delivery results. The two components communicate through the shell’s child process. The existing dock and Space navigation also work without provisioning an account.

```sh
scripts/test-messaging
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software scripts/dock test
```

The integration test creates a temporary local homeserver and two test devices. It checks encrypted text and media, session restoration, safe saving, verification, retries and reconnection. The physical Mac round trip above is a separate acceptance check.

## Design review

Home, current-Space and participant-chat references are `2515:68984`, `2515:69078` and `2515:69311`. Spaces Architect approved direct entry while My Devices is the only conversation. A message can show its originating device’s display name beside the timestamp when the SDK establishes its identity. Transfer progress stays with the composer. Element’s typing notice appears without a device name.

For a native image to compare with Figma at 100% logical scale, use `scripts/dock capture /path/to/capture.png` on a disposable conversation. Captures include visible message contents.
