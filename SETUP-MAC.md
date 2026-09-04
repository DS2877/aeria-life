# Mac setup — one time, ~30 minutes

You only do this once. After it's done, the day-to-day loop is just
`git pull` → press ▶ in Xcode.

Everything below is typed into the **Terminal** app on your Mac
(Applications → Utilities → Terminal), unless it says otherwise.

---

## 1. Install Xcode

1. Open the **App Store** on your Mac.
2. Search for **Xcode**, click **Get / Install**. It's large (~10 GB), give it
   time.
3. When it's installed, open Xcode once. Accept the license prompt. Let it
   "install additional components" if it asks.
4. Back in Terminal, run this so command-line tools point at Xcode:

   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

   It will ask for your Mac password (you won't see characters as you type —
   that's normal). Press Return.

5. Verify:

   ```bash
   xcodebuild -version
   ```

   You should see `Xcode 26.x`.

---

## 2. Install Homebrew (a package installer for Mac)

Paste this whole line:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow its prompts (it may ask for your password). When it finishes it prints
two lines starting with `eval` under **"Next steps"** — copy those, paste them,
and run them so `brew` works in your current Terminal.

Verify:

```bash
brew --version
```

---

## 3. Install XcodeGen

```bash
brew install xcodegen
```

Verify:

```bash
xcodegen --version
```

---

## 4. Get the code onto your Mac

```bash
mkdir -p ~/Developer
cd ~/Developer
git clone https://github.com/DS2877/aeria-life.git
cd aeria-life
```

> ⚠️ **Do not put the project inside iCloud Drive, OneDrive, or Dropbox.**
> Xcode and cloud-sync folders corrupt each other's files. `~/Developer` is a
> safe place.

Later, to get updates: `git pull` inside the `aeria-life` folder.

---

## 5. Generate the Xcode project and open it

Inside the `aeria-life` folder:

```bash
xcodegen generate
open AeriaLife.xcodeproj
```

Xcode opens.

---

## 6. Run it in the Simulator

1. At the top of the Xcode window, next to the ▶ button, there's a device
   selector. Click it and choose any **iPhone** simulator (e.g.
   "iPhone 17 Pro").
2. Press **▶** (or ⌘R).
3. First build takes a minute or two. The Simulator launches and the app
   appears.

**One thing won't work in the Simulator: scanning documents.** The Simulator
has no camera. Everything else (Today, Ask Aeria, Life Inbox, Calendar,
Reminders) works fine there — for Vault scanning, use a real iPhone (step 7).

---

## 7. Run it on your real iPhone (needed for document scanning)

1. Plug your iPhone into your Mac with a cable (or set up wireless
   debugging: **Window → Devices and Simulators** in Xcode, then check
   "Connect via network").
2. In Xcode, click the device selector at the top and choose your iPhone.
3. You'll need a free **Apple ID** signed into Xcode: **Xcode → Settings →
   Accounts → +**.
4. Click the project name (**AeriaLife**) in the left sidebar. Aeria has
   three targets now — **Aeria**, **AeriaWidgetsExtension**, and
   **AeriaWatch** — pick your name under **Team** on **Signing &
   Capabilities** for all three (Xcode usually offers to do this
   automatically the first time it hits a signing error; let it).
5. On your iPhone, trust your Mac if it asks. Press **▶** in Xcode.
6. First launch: on the iPhone, go to **Settings → General → VPN & Device
   Management** and trust your developer certificate.

> Installing on a real device with a *free* Apple ID works but the app
> expires after 7 days and must be re-installed. A paid **Apple Developer
> Program** membership ($99/year) removes that limit and is required for
> TestFlight and the App Store. You don't need it yet.

---

## 8. Try the Widget and the Watch app

**Widget**: on the iPhone Simulator (or a real iPhone), long-press the Home
Screen, tap **+** in the top corner, search **Aeria**, and add it. It reads
whatever Today last showed — open the app once first so it has something to
show.

**Watch app**: pick the **AeriaWatch** scheme at the top of Xcode (next to
the ▶ button, where you normally pick "Aeria"), choose a paired Watch
Simulator as the device, and press ▶. The watch app only shows something
once the phone app has run at least once and sent it data — a fresh watch
Simulator pairing starts empty, which is expected.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `xcodegen: command not found` | `brew install xcodegen` didn't finish, or `brew` isn't on PATH. Re-run step 2's `eval` lines. |
| Xcode: "No account for team" / signing errors | Add a free Apple ID in **Xcode → Settings → Accounts**, then in the project's **Signing & Capabilities** tab pick your name under Team. Only needed for real-device runs. |
| Build fails after a `git pull` | Run `xcodegen generate` again — new files were added to `project.yml`. |
| Camera scanning doesn't open anything | You're in the Simulator — it has no camera. Use a real iPhone. |
| A file under `Sources/Intelligence/FoundationModelsIntelligenceProvider.swift` fails to build | It's optional and not used by default — see the comment at the top of that file. Safe to delete it. |
| Signing errors mentioning `AeriaWidgetsExtension` or `AeriaWatch` | Same fix as the main app — pick your Team on that target's **Signing & Capabilities** tab. If it complains about an App Group (`group.com.aeria.life`), open **Aeria** target → **Signing & Capabilities** → **App Groups**, and let Xcode create it (or check the box next to it if it's already listed but unchecked). |
| Widget shows nothing / "Open Aeria on your iPhone to sync" forever | Open the main Aeria app at least once first — the widget/watch only ever show what the phone last published. |
| A background task never seems to fire | This is expected during normal testing — iOS decides when background refresh actually runs, and the Simulator rarely does it at all. See docs/ARCHITECTURE.md § Proactive notifications for the LLDB command that forces one. |
| `mic`/voice capture button does nothing | Check **Settings → Privacy & Security → Speech Recognition** and **Microphone** on the device — if you tapped "Don't Allow" once, you'll need to flip it there rather than being asked again. |

When you hit an error you don't understand, copy the **full red error text**
from Xcode's Issue Navigator (the ⚠️ icon in the left sidebar) and send it to
Claude.
