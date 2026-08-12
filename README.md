# Fund Nexus

Flutter client for Fund Nexus.

## Runtime configuration

The network layer reads environment values from `dart-define`:

- `APP_ENV`: `development`, `staging`, or `production`.
- `API_BASE_URL`: absolute API URL. Production only accepts HTTPS.
- `WEB_BASE_URL`: absolute H5 URL. Production only accepts HTTPS.
- `API_SIGNING_SECRET`: server-provided HMAC-SHA256 signing secret.
- `API_AES_KEY`: AES key used by encrypted report endpoints.
- `API_AES_IV`: 16-byte AES-CBC initialization vector.
- `CAPTURE_PROXY_HOST`: optional local proxy host for explicit debug capture.
- `CAPTURE_PROXY_PORT`: optional local proxy port.
- `CAPTURE_ALLOW_BAD_CERTIFICATES`: must remain `false` in production; set only
  for controlled HTTPS interception during local debugging.

On iOS, an explicit `CAPTURE_PROXY_HOST`/`CAPTURE_PROXY_PORT` pair takes
priority. Without it, the app uses the current system HTTP proxy when one is
enabled in the device Wi-Fi settings. HTTPS interception should use a capture
certificate trusted by the device; invalid certificates are never accepted in
production.

Example:

```shell
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://staging-api.example.com/api \
  --dart-define=WEB_BASE_URL=https://staging.example.com \
  --dart-define=API_SIGNING_SECRET=server-provided-secret \
  --dart-define=API_AES_KEY=server-provided-aes-key \
  --dart-define=API_AES_IV=server-provided-aes-iv \
  --dart-define=CAPTURE_PROXY_HOST=192.168.1.10 \
  --dart-define=CAPTURE_PROXY_PORT=8888 \
  --dart-define=CAPTURE_ALLOW_BAD_CERTIFICATES=true
```

The signing and AES values have no source-controlled defaults. Every build
must provide them through the build environment; do not commit real values.

Every request reloads the installed app version, iOS model code, and system
version. The first available IDFV is persisted in the device-only Keychain and
then reused for both `cockatoos` and `reformer`. A best-effort startup request
to `/viler/resite` resolves the model code to the server device name used by
`nutlike`; the local model code remains the fallback.

The Fund Nexus response envelope uses `fasciitis`, `bravo`, and `foresight`.
Code `0` is success and `-2` means the session has expired. Public request
parameters are URL encoded and signed using the documented HMAC-SHA256 scheme.

Encrypted payloads use AES-CBC with PKCS7 padding and Base64 output. Crypto
configuration must never be written to logs or error reporting metadata.

Session IDs are stored with platform secure storage. The remembered phone
number is stored separately and can be retained when signing out.
