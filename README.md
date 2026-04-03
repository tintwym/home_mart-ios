# Home Mart (iOS)

Native SwiftUI client for Home Mart. It talks to a Laravel-style JSON API under the **`/mapi`** prefix.

## Requirements

- **Xcode** (recent release recommended)
- **iOS 17.0** or later (simulator or device)

## Open and run

1. Open **`home_mart.xcodeproj`** in Xcode.
2. Select the **`home_mart`** scheme and an iPhone simulator (or your device).
3. **Run** (⌘R).

## API base URL

The app resolves the server in this order (first match wins):

1. **Environment variable** `HOME_MART_BASE_URL` — useful for CI or a custom Xcode scheme (e.g. local Laravel).
2. **Info.plist** `HOME_MART_BASE_URL` — injected at build time from **`Config/APIBase.xcconfig`**.
3. **Default:** `https://homemart-mm.vercel.app` if nothing else is set.

Edit **`Config/APIBase.xcconfig`** to change the default production/staging host. Do not put a trailing slash on the URL.

### Command-line build

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -scheme home_mart -project home_mart.xcodeproj \
  -destination 'generic/platform=iOS Simulator' build
```

### Tests

```bash
xcodebuild test -scheme home_mart -project home_mart.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:home_martTests
```

Use a simulator name or device ID that exists on your Mac (`xcrun simctl list`).

## Project layout

| Path | Purpose |
|------|---------|
| `home_mart/` | App sources (features, services, models, assets) |
| `home_mart/Services/` | `AuthStore`, API config, listings, categories, etc. |
| `home_mart/Features/` | SwiftUI screens (auth, dashboard, profile, listings) |
| `Config/` | Shared **`APIBase.xcconfig`** for default API host |
| `home_martTests/` | Unit tests (Swift Testing) |

## Simulator console noise (keyboard / haptics)

While typing in the **Simulator**, Xcode’s console may show messages such as:

- **`TUIKeyboardCandidateMultiplexer` / “Could not find cached accumulator”** — internal Text Input UI / autocorrection pipeline.
- **`Unable to simultaneously satisfy constraints`** involving **`_UIRemoteKeyboardPlaceholderView`** and **`_UIKBCompatInputView`** — layout inside **Apple’s keyboard**, not your views.
- **`CHHapticPattern` / `hapticpatternlibrary.plist`** — the Simulator has **no Mac haptic tuning files**; keyboard haptics fall back and log errors.

These are **known system / Simulator issues** and are **not** caused by broken Auto Layout in the app. They often **do not appear on a physical device**, or are reduced on newer OS/Xcode builds. You can filter the console or ignore them during development.

Auth screens use **`scrollDismissesKeyboard(.never)`** to avoid extra keyboard transition churn that can make that logging more frequent.

## Backend notes

Endpoints the app expects include (among others): **`POST /mapi/login`**, **`POST /mapi/register`**, **`GET /mapi/user`**, **`GET /mapi/listings`**, **`GET /mapi/categories`**.

**Password change:** the app tries, in order, **`mapi/user/password`**, **`api/user/password`**, and **`mapi/password`** (each with `PUT`, then `POST`, then `PATCH`), JSON body `current_password`, `password`, `password_confirmation`, and **`Authorization: Bearer`**. If you see *“The route … could not be found”*, that message is from **Laravel** — register one of those routes (or align the client list in `APIConfiguration.passwordUpdateCandidateURLs`) on your backend.

## License

See the repository owner for licensing terms.
