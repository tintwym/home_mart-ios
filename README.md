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

## Backend notes

Endpoints the app expects include (among others): **`POST /mapi/login`**, **`POST /mapi/register`**, **`GET /mapi/user`**, **`GET /mapi/listings`**, **`GET /mapi/categories`**, and password update on **`/mapi/user/password`** (with Bearer token). Adjust the Laravel routes to match if your API differs.

## License

See the repository owner for licensing terms.
