# Changelog

All notable changes to the DriveDeck Admin app are documented here.

## [Unreleased] — Presentation layer (UI-only)

Pixel-perfect Flutter port of the "DriveDeck Admin" design prototype. No backend
integration in this phase — every screen runs on in-memory static sample data
structured so the API + Hive cache layer plugs in behind the existing repository
contracts without UI changes.

### Added

- **Foundation**: Material 3 light theme (DriveTo yellow brand), Figtree
  typography, responsive sizing via `flutter_screenutil` (380×800 baseline), and
  a shared design-system widget library mirroring the prototype (status badges,
  cards, buttons, top bar, bottom nav, search, chips, sheets, dialogs, toast,
  skeleton/empty/error states, list controls, FAB).
- **Routing**: `go_router` with admin (Dashboard · Bookings · Drivers ·
  Customers) and driver (Today · Schedule · Earnings · Profile) bottom-nav
  shells, plus all module/detail routes.
- **Features** (each as a 4-layer feature-first module): auth (Admin/Driver
  login toggle), dashboard, bookings (carwash list/detail/manual booking),
  service requests (driver-hire & inspection), shops (list/detail/hours/forms),
  customers (directory/detail/block), reviews, refunds, payouts, offers
  (coupons & banners), reports (6 reports), settings (+ service areas),
  notifications (+ push coming-soon), drivers & inspectors, and the scoped
  driver app (jobs/earnings/OTP job flow).
- **API-phase scaffolding** (not yet wired): `CacheConfig`, `CacheEntry`
  (+ hand-written Hive adapter), `RetryPolicy`, `RequestPool`, `HiveProvider`
  (lock-guarded singleton) per `docs/HIVE implementation.md`; `Failure` model and
  unified logger.

### Security

- `android:allowBackup="false"` set in the Android manifest (no auth/PII backup).
- No secrets, tokens, or credentials committed; demo login values are clearly
  marked placeholders for the prototype only.
