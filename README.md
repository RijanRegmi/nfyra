# Tramessage

> **Zero-Internet, Peer-to-Peer NFC Message & Link Sharing for Android**

Tramessage is a fully offline, privacy-first Android app that enables physical, tap-to-share messaging between devices using Near Field Communication (NFC) and Android Host Card Emulation (HCE). 

**Key Innovation:**
- **No receiver app required**: The sending phone emulates a standard NFC Forum Type 4 Tag. Any smartphone (Android with native Tag Viewer or iPhone with Safari URL reader) can receive and read the message without downloading or installing Tramessage.
- **Enhanced security if both devices have Tramessage**: Messages carry a hardware-backed Ed25519/ECDSA signature, anti-replay nonces, and 60-second expiration. Devices running Tramessage verify the sender's signature and log the message to local encrypted storage.

---

## Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────────┐
│                        TRAMESSAGE ARCHITECTURE                         │
│                                                                        │
│  ┌───────────────────────── SENDER PHONE ────────────────────────────┐ │
│  │  Flutter UI (FLAG_SECURE, Material 3)                             │ │
│  │  ┌──────────────────────────────────────────────────────────────┐ │ │
│  │  │  ComposeShareScreen: Text / HTTPS Link input                  │ │ │
│  │  │  Biometric Gate: Enforces local authentication               │ │ │
│  │  │  30-Second Armed Countdown: Memory-wiped on timeout          │ │ │
│  │  └──────────────────────────────────────────────────────────────┘ │ │
│  │                                  │                                  │ │
│  │                      Platform MethodChannel                         │ │
│  │                                  ↓                                  │ │
│  │  ┌──────────────────────────────────────────────────────────────┐ │ │
│  │  │  Android Native (Kotlin)                                      │ │ │
│  │  │  • KeystoreManager: Hardware-backed EC (P-256) keypair       │ │ │
│  │  │  • HceService: Emulates Type 4 Tag (AID: D2760000850101)    │ │ │
│  │  │  • Multi-Record NDEF Generation:                             │ │ │
│  │  │    [Record 1]: Standard Text (T) or URI (U) -> NO APP NEEDED │ │ │
│  │  │    [Record 2]: MIME application/vnd.tramessage.msg (Signed)  │ │ │
│  │  └──────────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                      │                                 │
│                            ~~~ NFC RF TOUCH ~~~                        │
│                                      │                                 │
│  ┌───────────────────────────────────┴───────────────────────────────┐ │
│  │                                                                   │ │
│  ▼                                                                   ▼ │
│  [DEVICE WITHOUT APP]                              [DEVICE WITH TRAMESSAGE]    │
│  • Android: Native Tag Viewer pops up              • Cold/Warm NDEF_DISCOVERED │
│    displaying plain text message.                  • ValidateNfcPayloadUsecase │
│  • iPhone: Background NFC tag notification           - Expiration check (<60s) │
│    opens HTTPS URL in Safari.                        - Nonce cache dedup check │
│  • No installation needed.                           - Signature verification  │
│                                                    • Local Encrypted History   │
│                                                    • Safe URL Prompt Dialog    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Offline Security & Threat Model

Tramessage is designed to be **unconditionally offline**:
- **Zero Internet Permissions**: `android.permission.INTERNET` is **strictly omitted** from `AndroidManifest.xml` and validated in CI. The app cannot transmit data over Wi-Fi, cellular, or Bluetooth.
- **No Telemetry / SDKs**: Zero analytics, crash loggers, or remote APIs.
- **FLAG_SECURE**: Sensitive screens block OS-level screenshots and screen recordings.
- **Hardware-Protected Keys**: Sender identity keys are generated in Android Keystore with StrongBox / TEE backing.
- **Link Sanitization**: Only `https://` URLs are accepted. Dangerous protocols (`javascript:`, `file:`, `data:`, `intent:`) and control characters are stripped. URLs never open automatically and require explicit user confirmation.
- **Anti-Replay Protection**: Nonces are recorded in an encrypted LRU cache. Replayed payloads are rejected.
- **Memory Wiping**: Armed HCE payloads are cleared and memory zeroed on read or timeout.
- **Encrypted Local Storage**: Local history is protected via Android Keystore-backed AES storage.

---

## Project Structure

```
Tramessage/
├── mobile/                      # Flutter Android App
│   ├── android/                 # Native Kotlin & HCE implementation
│   │   └── app/src/main/kotlin/com/tramessage/mobile/
│   │       ├── MainActivity.kt     # MethodChannels & NFC intent dispatch
│   │       ├── HceService.kt       # Host Card Emulation (Type 4 Tag)
│   │       ├── KeystoreManager.kt  # Android Keystore EC signing/verifying
│   │       └── NfcManager.kt       # Hardware & HCE capability detection
│   ├── lib/
│   │   ├── core/                # DI, Router, Security, Theme, Errors
│   │   └── features/
│   │       ├── nfc_gate/        # NFC availability blocking check
│   │       ├── compose_share/   # Message composition, countdown, arming
│   │       ├── receive/         # Cryptographic payload verification & inbox
│   │       ├── history/         # Local encrypted message store
│   │       └── settings/        # Key fingerprint & privacy controls
│   └── test/                    # Unit, security, and widget tests
├── .github/workflows/ci.yml     # CI pipeline (analyze, test, manifest audit)
└── README.md
```

---

## How to Test on Physical Android Devices

> **Note**: Android emulators **cannot emulate NFC RF touch**. Testing requires physical hardware.

### Prerequisites
1. Two physical Android devices with NFC enabled (e.g., Device A and Device B).
2. Developer options & USB Debugging enabled on both devices.

### Quick Run
Navigate into the `mobile` directory:
```bash
cd mobile
flutter run -d <DEVICE_ID>
```

### Scenario 1: Device A (Tramessage) → Device B (NO APP INSTALLED)
1. On **Device A**, open Tramessage, type a message or URL (e.g., `https://google.com`), and tap **Share via NFC**.
2. Authenticate with biometric/fingerprint if prompted.
3. The 30-second countdown will start.
4. Unlock **Device B** (make sure NFC is turned on in its settings).
5. Hold both devices back-to-back.
6. **Result**: Device B's native Android Tag Viewer or browser will automatically display the message or prompt the URL without any app installed!

### Scenario 2: Device A (Tramessage) → Device B (Tramessage)
1. Open Tramessage on **Device B** and navigate to **Share** or keep the app running.
2. Tap **Share via NFC** on **Device A**.
3. Hold both devices back-to-back.
4. **Result**: Device B immediately launches the **Incoming NFC Message** screen, verifies the Ed25519 signature, displays the green verified badge, shows the sender key fingerprint, and logs it to local history.
