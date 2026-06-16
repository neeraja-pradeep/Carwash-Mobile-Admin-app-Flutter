# API Integration Helper — DriveDeck Admin

Quick map of **screen → feature group → data hook** for the API-integration phase.

## How integration works (one pattern for all)

UI is currently fed by static data. Each feature already has:

```
domain/repositories/<feature>_repository.dart      ← contract (DO NOT change signatures)
infrastructure/data_sources/local/<feature>_local_ds.dart  ← SWAP THIS for the API
infrastructure/repositories/<feature>_repository_impl.dart ← wire remote + cache here
application/providers/<feature>_providers.dart     ← FutureProviders the UI reads
```

**To integrate a screen:** add a `<feature>_api.dart` (Dio) under `infrastructure/data_sources/remote/`, then update `<feature>_repository_impl.dart` to call it (with the L1/L2/L3 cache from `docs/HIVE implementation.md`). The provider names and all presentation code stay unchanged.

## Screen → Feature → Data hook

| Screen(s) | Feature group | Provider(s) the UI reads | Swap point (`*_local_ds.dart` + repo) | Suggested endpoint(s) |
|---|---|---|---|---|
| Login (Admin + Driver OTP) | `auth` | — (no repo yet) | add `auth` repo + remote DS | `POST /auth/login`, `POST /auth/otp/send`, `POST /auth/otp/verify` |
| Dashboard | `dashboard` | `dashboardSnapshotProvider`, `hiringSnapshotProvider`, `activityFeedProvider` | `dashboard` | `GET /dashboard/snapshot`, `GET /dashboard/activity` |
| Bookings list, Booking detail, New manual booking | `bookings` | `bookingsProvider`, `bookingByIdProvider` | `bookings` | `GET /bookings`, `GET /bookings/{id}`, `POST /bookings`, `PATCH /bookings/{id}/status` |
| Service-request detail, New driver-hire / inspection | `service_requests` | `serviceRequestsProvider`, `serviceRequestByIdProvider` | `service_requests` | `GET /service-requests`, `GET /{id}`, `POST /service-requests`, `PATCH /{id}/assign`, `PATCH /{id}/status` |
| Shops list, Shop detail (Info/Services/Settlement), Hours & Slots, Add/Edit shop, Service form | `shops` | `shopsProvider`, `shopByIdProvider`, `holidaysProvider` | `shops` | `GET /shops`, `GET /shops/{id}`, `POST/PUT /shops`, `POST/PUT /shops/{id}/services`, `GET /holidays` |
| Customers list, Customer detail (Info/Garage/History), Block | `customers` | `customersProvider` | `customers` | `GET /customers`, `GET /customers/{id}`, `PATCH /customers/{id}/block` |
| Reviews list + detail | `reviews` | `reviewsProvider` | `reviews` | `GET /reviews` |
| Refund log, Refund detail, New refund, Mark paid | `refunds` | `refundsProvider` | `refunds` | `GET /refunds`, `POST /refunds`, `PATCH /refunds/{id}/status` |
| Payout log, Payout detail, New payout, Override net | `payouts` | `payoutsProvider` | `payouts` | `GET /payouts`, `POST /payouts`, `PATCH /payouts/{id}` |
| Coupons list + form, Banners list + form | `offers` | `couponsProvider`, `bannersProvider` | `offers` | `GET/POST/PUT /coupons`, `GET/POST/PUT /banners` |
| Daily Summary + 5 reports | `reports` | `dailySummaryProvider` | `reports` | `GET /reports/{kind}?period=` |
| Settings, Service areas, Hiring rates | `settings` | `appSettingsProvider` | `settings` | `GET/PUT /settings`, `PUT /settings/service-areas`, `PUT /settings/rates` |
| Notifications list (Push = coming soon) | `notifications` | `notificationsProvider` | `notifications` | `GET /notifications`, `PATCH /notifications/{id}/read` |
| Drivers & Inspectors roster, Driver detail (live job + docs), Hire driver | `drivers` | `fieldDriversProvider`, `fieldDriverByIdProvider`, `inspectorsProvider`, `foundersProvider`, `assigneeByIdProvider` | `drivers` | `GET /drivers`, `GET /inspectors`, `POST /drivers`, `PATCH /drivers/{id}/status`, `PATCH /drivers/{id}/docs` |
| Driver app — Today / Schedule / Earnings / Profile, Job detail | `driver_app` | `driverJobsProvider`, `driverJobByIdProvider`, `driverEarningsProvider`, `signedInDriverProvider` | `driver_app` | `GET /driver/jobs`, `GET /driver/earnings`, `PATCH /driver/jobs/{id}/otp` |

## Notes

- **Auth token storage** → `flutter_secure_storage` (already a dependency); attach via a Dio interceptor.
- **Cross-feature reads** (e.g. booking detail resolves shop/driver via `shopByIdProvider` / `assigneeByIdProvider`) stay as-is — only the underlying `*_local_ds.dart` changes.
- **Caching/offline/304/retry** are specced in `docs/HIVE implementation.md`; wire them in each `*_repository_impl.dart`.
- Demo constants (`AppConstants.demoOtp`, `demoAdminPassword`, `sampleLoadDelay`) are removed/replaced when real auth + network land.
