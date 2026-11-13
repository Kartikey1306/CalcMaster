# AGENTS.md — CalcMaster

**What:** a sheet calculator. Each line of a ruled sheet works out as you type —
arithmetic, `#n`/`prev` references, percentages, unit conversions, and currency
conversions at the European Central Bank reference rate, optionally for a named
date ("Rate on the day"). Sheets are saved on the device, searchable, and
shareable as text or CSV with every rate, its date and its source. Thirty tools
(tip, tax, loan, units, dates, maths, engineering, BMI) live in a Tools drawer;
every tool except BMI can add its result to the sheet. 12 locales, 11 regions.
No account, nothing for sale.

## Run commands
```bash
FLUTTER=/Users/spatchava/agl/.flutter-sdk/bin/flutter   # pinned SDK
$FLUTTER pub get
$FLUTTER analyze
$FLUTTER test                     # unit + widget tests
$FLUTTER test --run-skipped --update-goldens --tags design   # review PNGs
$FLUTTER gen-l10n                 # regenerate lib/l10n/generated from ARB
dart run tools/gen_icon.dart      # regenerate the "=" icon and splash marks
```

## Architecture
Single Flutter client (iOS/Android/Web). Provider (ChangeNotifier) state +
go_router (one stack, no tab bar). The sheet grammar, export and rate client are
pure Dart and run offline. The only network call is Frankfurter
(`api.frankfurter.dev`, keyless ECB rates).

## File map
| Path | Responsibility |
| --- | --- |
| `lib/main.dart` | Entry: crash reporting, loads the last sheet, `CalcMasterApp` (providers, Ledger / Night ledger themes) |
| `lib/app_router.dart` | `/` sheet (home) · `/sheets` · `/tools` drawer + `/tools/<tool>` · `/settings` `/help` `/privacy` `/about` |
| `lib/sheet/sheet_engine.dart` | Pure-Dart line grammar, totals, rate captions (no Flutter import) |
| `lib/sheet/sheet_model.dart` | `Sheet`, `SheetLine`, `RatePin` (JSON under `sheets_v1`) |
| `lib/sheet/sheet_store.dart` | SharedPreferences persistence, dated-rate cache (`ecb_rates_v1`), one-time Notes → sheets migration (`notes_migrated_v1`; the old `notes` key is left untouched) |
| `lib/sheet/sheets_controller.dart` | Editing, autosave (~500 ms + on pause), list ops (search/rename/duplicate/delete+undo), fetching needed rates, Re-price |
| `lib/sheet/sheet_export.dart` | Share-as-text and CSV (`line,label,input,result,unit_or_currency,ecb_rate,ecb_date`) |
| `lib/sheet/sheet_share.dart` | share_plus hand-off, export preview, clipboard fallback |
| `lib/sheet/add_to_sheet.dart` | "Add to sheet" from any tool |
| `lib/lib_currency.dart` | Regions, the 30 ECB codes, latest table, `RateClient.fetchRateOn` (typed failures, permanent dated cache) |
| `lib/lib_units.dart` | Units + conversion factors (pure Dart) and the sheet's unit aliases |
| `lib/lib_calc.dart` | Shunting-yard evaluator used by every line |
| `lib/lib_tax.dart`, `lib/lib_payroll.dart` | Income-tax and paycheck tables (`taxTableYear` = 2025, shown on screen) |
| `lib/theme/tokens.dart` | `LedgerColors` (Ledger / Night ledger), `Fonts` (Golos Text UI, Reddit Mono figures), `Radii` (4/8/0), `Spacing` |
| `lib/screens/sheet/` | Sheet editor (ruled paper, key row, footer total), Sheets list / pane |
| `lib/screens/tools/tools_drawer.dart` | The grouped Tools drawer |
| `lib/screens/{finance,calculate,tools}/`, `convert_detail.dart` | The tools themselves |
| `lib/state/region_provider.dart` | Region, latest ECB table (also the sheet's `LatestRatesSource`) |
| `lib/state/appearance_provider.dart` | System / Ledger / Night ledger |
| `lib/monetization/` | AdMob banner (Sheets list and Tools only — never the editor), ATT, UMP consent, analytics/notification seams |
| `assets/fonts/` | Golos Text and Reddit Mono static instances + OFL licences |

## Rules that matter
- **Real rates only.** ECB reference rates via Frankfurter; 30 currencies; never estimate a rate, never add a second source (no scraping). A dated rate shows the ECB date actually used. The latest table is re-fetched every 30 min and on resume; with Settings → "Keep sheets at the latest rate" (on by default) undated lines move to each new publication, with it off they stay pinned until Re-price.
- **No account, no paywall.** The Supabase sign-in, demo session and Pro paywall were removed; do not reintroduce them.
- **5.6:** one build for everyone — no remote switches, reviewer detection, hidden gestures or demo logins.

## Gotchas
- **Pinned Flutter SDK** at `/Users/spatchava/agl/.flutter-sdk/bin/flutter`.
- **`archive` pinned to ^3.6.1** via `dependency_overrides` (icon/splash tooling).
- **CocoaPods forced** (`enable-swift-package-manager: false`) — google_mobile_ads vs SPM.
- **RegionId enum values are UPPERCASE** and persisted by `.name` — do not rename.
- **Bundle/app id** is `com.americangroupllc.calcmaster` — leave it.
- **Wide windows** (≥ 840 dp) show the Sheets list as a left pane beside the sheet.
- Generated l10n (`lib/l10n/generated/`) is committed but regenerable — edit ARB, not the generated files.
