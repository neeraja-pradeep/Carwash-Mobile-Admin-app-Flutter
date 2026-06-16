# DriveDeck Admin

The **operator / admin** mobile app for DriveDeck — a doorstep car-wash booking
platform operating in Alappuzha, Kerala. Founders use it to run daily
operations: receive and assign bookings, manage third-party shops & services,
hire drivers/inspectors, track refunds & shop settlements, view reviews, and
configure the business. A scoped **Driver app** (separate bottom nav) lets hired
drivers see only their assigned jobs and earnings.

> **Status:** Presentation layer (UI) complete. This phase is **UI-only** — all
> screens run on in-memory static sample data. API + Hive caching plug in behind
> the existing repository contracts in the next phase with no UI changes.

## Tech stack

- **Flutter** (Dart 3) · Material 3, light theme
- **Riverpod** (`flutter_riverpod`) — state management
- **flutter_screenutil** — responsive sizing (design baseline **380×800**)
- **go_router** — routing (admin + driver bottom-nav shells)
- **google_fonts** (Figtree) · **intl** — typography & formatting
- **hive** / **synchronized** / **connectivity_plus** — wired in the API phase

## Architecture — feature-first, 4 layers

```
lib/
├─ app/            bootstrap · config · router · theme
├─ core/           widgets (design system) · status · constants · cache · error · utils
└─ features/<f>/
   ├─ domain/          entities (immutable) · repositories (abstract)
   ├─ infrastructure/  data_sources/local (static data today) · repositories (impl)
   ├─ application/      states (immutable + copyWith) · providers (Riverpod)
   └─ presentation/     screens · components
```

Layer rules are strict: domain has zero upward deps; application depends on the
domain repository contract; presentation never touches infrastructure directly;
all data access flows entity → local data source → repository → provider, so the
data source is the single swap point for the API phase.

`lib/features/reviews/` is the canonical reference feature for the patterns.

## Running

```sh
flutter pub get
flutter run
```

Login screen defaults to the **Driver** toggle (OTP demo `1234`); switch to
**Admin** and sign in (password prefilled `drivedeck`) for the operator app.

## Notes

- The simulated device chrome and the Tweaks/QA-index tooling from the HTML
  prototype are intentionally omitted — the real OS provides the status bar and
  home indicator.
- Naming conventions follow the project's custom-lint spec
  (`docs/Linting & Analysis(implementation guide)-Flutter.md`); the sibling
  `naming_conventions_lint` package is a team-side dev tool, not bundled here.
