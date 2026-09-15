# Environments

CalcMaster builds for three environments. Configuration is supplied at build time
with `--dart-define-from-file`; nothing is read from the filesystem at runtime,
so a shipped binary contains exactly the values it was built with.

| | dev | staging | prod |
|---|---|---|---|
| `APP_ENV` | `dev` | `staging` | `prod` |
| applicationId | `com.americangroup.calcmaster.dev` | `com.americangroup.calcmaster.staging` | `com.americangroup.calcmaster` |
| Launcher name | CalcMaster Dev | CalcMaster Staging | CalcMaster |
| versionName suffix | `-dev` | `-staging` | *(none)* |

All three install side by side, so a tester can hold every build at once and a
staging install can never overwrite production.

## Files

| File | Committed? | Contents |
|---|---|---|
| `env/dev.json` · `env/staging.json` · `env/prod.json` | yes | Non-secret configuration |
| `env/secrets.example.json` | yes | Template for secrets |
| `env/secrets.json` | **no** — gitignored | Real secrets, internal builds only |

## Configuration keys (committed)

| Key | Role |
|---|---|
| `APP_ENV` | Selects the environment. Defaults to `prod` when the flag is omitted, so a forgotten flag fails closed. |
| `API_BASE_URL` | configuration |
| `GOOGLE_IOS_CLIENT_ID` | configuration |
| `GOOGLE_SERVER_CLIENT_ID` | configuration |
| `RECEIPT_VERIFICATION_URL` | HTTPS endpoint that validates a store receipt with Apple/Google and answers `{"entitled": true\|false}`. Empty means no backend check, so `PremiumProvider` trusts the store callback — set it before taking real money. |
| `SUPABASE_ANON_KEY` | configuration |
| `SUPABASE_URL` | configuration |

## Secrets (never committed)

These live only in the gitignored `env/secrets.json`. Absent by default, which
makes the paths that depend on them inert.

| Key |
|---|
| `ADMIN_EMAIL` |
| `ADMIN_PASSWORD` |
| `DEV_EMAIL` |
| `DEV_PASSWORD` |
| `QA_EMAIL` |
| `QA_PASSWORD` |

## Commands

```bash
flutter run --flavor dev     --dart-define-from-file=env/dev.json
flutter run --flavor staging --dart-define-from-file=env/staging.json
flutter run --flavor prod    --dart-define-from-file=env/prod.json
```

Internal build that needs the secrets — never for production:

```bash
flutter run --flavor dev \
  --dart-define-from-file=env/dev.json \
  --dart-define-from-file=env/secrets.json
```

Release artifacts:

```bash
flutter build apk       --release --flavor staging --dart-define-from-file=env/staging.json
flutter build appbundle --release --flavor prod    --dart-define-from-file=env/prod.json
```

A production App Bundle additionally needs `android/key.properties`. Without it
the build falls back to the debug keystore and the Play Console rejects the
artifact.

## Guards against shipping the wrong configuration

1. **Fails closed.** `APP_ENV` defaults to `prod`, so a build that forgets the
   flag does not silently become a dev build pointed at dev infrastructure.
2. **Startup check.** `AppEnv.validate()` reports empty or non-https URLs, and
   test credentials present in a production release. It throws in debug/profile
   so a developer hits it immediately; in release it only logs, because
   crashing a user's launch is worse than the misconfiguration itself.
3. **Build-time check.** `test/app_env_test.dart` is the real gate: it
   validates every committed `env/*.json`, asserts no committed file carries a
   secret, and fails if the code reads a `fromEnvironment` key that is not
   documented here. It runs in CI.

## Known limitation

`SUPABASE_URL` currently points at the **same** Supabase project in all three
environments. The build-time separation above is real, but true backend
isolation needs separate Supabase projects (and separate keys) per environment
— that is an infrastructure task, not a code change.
