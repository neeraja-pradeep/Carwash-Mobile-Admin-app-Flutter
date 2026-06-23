# DriveDeck Admin — Dashboard & Recent Activity API

API reference for the **operator console**, scoped to the two Home screens:
the **Dashboard** (KPIs + header + notifications bell) and the **Recent Activity**
feed. All requests/responses are JSON.

Auth is **session-based** (Django sessions, cookie auth) — clients persist the
`sessionid` cookie returned on login (see [§0 · Sign In](#0--sign-in-auth)). There
are no JWT/Bearer tokens.

The dashboard endpoints require the logged-in user to be an **`admin`** (shop
owner) or **`superadmin`**. An `admin` sees carwash data scoped to the shops they
own; a `superadmin` sees data across all shops. `user`/`driver` accounts get `403`.

Base hosts:
- `accounts` app → `/api/accounts/v1/...`
- `booking` app → `/api/booking/v1/...`

### Conventions (apply to every endpoint unless noted)

**Headers**

| Header | When | Value |
|---|---|---|
| `Cookie: sessionid=…` | every request after login | the session cookie; this is the auth. |
| `Content-Type: application/json` | on `POST` with a JSON body | login/logout. |
| `Accept: application/json` | optional | responses are JSON regardless. |

> The endpoints in this doc are all `GET` (reads) except login/logout, which are
> CSRF-exempt — so no `X-CSRFToken` header is needed for anything here.

**Auth & roles.** Authenticated session required (`401` if missing/expired).
The dashboard reads are role-gated: `admin` is scoped to shops they own,
`superadmin` is global; a `user`/`driver` hitting them gets `403`.

**Common error responses**:

| Code | When | Body |
|---|---|---|
| `401` | no/expired session | `{"detail": "Authentication credentials were not provided."}` |
| `403` | authenticated but wrong role | `{"detail": "You do not have permission to perform this action."}` |
| `429` | throttled (login: 5/hour) | `{"detail": "Request was throttled. Expected available in N seconds."}` |

**Pagination.** Only the "View all" activity list paginates
([car_wash/pagination.py](../car_wash/pagination.py)): `page_size = 10`, override
with `?page_size=` (max `100`), page with `?page=N`. Envelope:
```json
{ "count": 42, "next": "https://…?page=2", "previous": null, "results": [ /* … */ ] }
```
The dashboard snapshot and the top-5 feed are **not** paginated.

---

## 0 · Sign In (Auth)

The operator console's **Sign In** screen authenticates against a single
password-login call. The screen has a **Driver / Admin** segmented control —
the **Admin** tab is documented here; admins/superadmins sign in with their
**username + password**. (The Driver tab uses the OTP flow in the partner app
and is out of scope for this doc.)

Auth is **session-based**: a successful login sets the `sessionid` cookie, which
the client persists and sends on every subsequent request (see
[Conventions](#conventions-apply-to-every-endpoint-unless-noted)). There are no
JWT/Bearer tokens.

Mapping the screen → endpoints:

| Screen element | Endpoint | Notes |
|---|---|---|
| Username field | — | Sent as `username` in the login body. |
| Password field (Show toggle) | — | Sent as `password`. |
| **Sign In** button | `POST /api/accounts/v1/login/` | Sets `sessionid`; returns the user. |
| (after sign-out) | `POST /api/accounts/v1/logout/` | Clears the session. |

> The login screen accepts the operator's **username** (not the phone number,
> despite the phone-style placeholder in older mockups). It maps directly to the
> `username` field below. "Forgot password?" has **no backend endpoint** yet —
> password resets are handled out-of-band (a superadmin re-sets it).

---

**1. Sign in — `POST /api/accounts/v1/login/`**

Authenticates username + password and opens a session. Implemented by
`LoginUser` ([accounts/views/login.py](../accounts/views/login.py)).

- Permissions: `AllowAny` (this is the unauthenticated entry point).
- **CSRF-exempt** (uses `CsrfExemptSessionAuthentication`) — no `X-CSRFToken`
  needed on this call.
- Throttle: `AuthThrottle` — **5 requests/hour** per client.
- Request body:
```json
{ "username": "operator_anand", "password": "drive2026" }
```
- Response (200) — the full `UserSerializer`; the `Set-Cookie: sessionid=…`
  header carries the session. Persist that cookie.
```json
{
  "id": 4,
  "username": "operator_anand",
  "email": "anand@driveto.in",
  "phone": "+919847022119",
  "first_name": "Anand",
  "last_name": "",
  "role": "admin",
  "profile_picture": null,
  "language": "en"
}
```
- Response (401) — bad credentials:
```json
{ "error": "Invalid credentials" }
```

Notes:
- **Role gating is not enforced at login** — any role (`user`/`driver`/etc.) can
  authenticate here. After login, read `role` from the response: it should be
  `admin` or `superadmin` for the operator console. If it's anything else, the
  app should refuse and sign back out — every admin endpoint will otherwise just
  return `403`. (`admin` → own shops; `superadmin` → all shops.)
- On `429`, surface the "too many attempts, try later" state (5/hour limit).

---

**2. Sign out — `POST /api/accounts/v1/logout/`**

Ends the session. Implemented by `LogoutView`
([accounts/views/logout.py](../accounts/views/logout.py)).

- Permissions: `IsAuthenticated`.
- Empty body. Response (200): `{ "message": "Logged out" }`.
- The client should then drop the `sessionid` cookie and return to Sign In.

---

## 1 · Dashboard

The Home screen is the operational dashboard — a header (greeting, avatar,
notifications bell), two KPI groups (**Driver Hiring & Inspection** and
**Carwash · Today**), and a top-5 **Recent Activity** feed (with a "View all"
link to the full list).

It's backed by **four calls** on open: the profile (header), the unread-count
(bell badge), the KPI snapshot, and the top-5 activity feed.

Mapping the screen → endpoints:

| Screen element | Endpoint | Fields actually used by the UI |
|---|---|---|
| Header — "Good afternoon, Anand", avatar | `GET /api/accounts/v1/profile/` | `first_name`, `profile_picture`. |
| Header — notifications bell badge (`3`) | `GET /api/accounts/v1/notifications/unread-count/` | `unread`. |
| Driver Hiring & Inspection — Drivers online (`3/4`, "2 on a job now") | `GET /api/booking/v1/admin/dashboard/` | `driver_inspector.drivers_online.{online,total,on_job}`. |
| Driver Hiring & Inspection — Hire requests (`3`, "1 needs assignee") | `GET /api/booking/v1/admin/dashboard/` | `driver_inspector.hire_requests.{count,needs_assignee}`. |
| Driver Hiring & Inspection — Inspections (`2`, "1 open") | `GET /api/booking/v1/admin/dashboard/` | `driver_inspector.inspections.{count,open}`. |
| Driver Hiring & Inspection — On a job now (`2`, "live driver jobs") | `GET /api/booking/v1/admin/dashboard/` | `driver_inspector.on_job_now`. |
| Carwash · Today — Overdue (`2`, "needs action now") | `GET /api/booking/v1/admin/dashboard/` | `overdue`. |
| Carwash · Today — Bookings today (`9`, "1 waiting · 4 active · 3 done") | `GET /api/booking/v1/admin/dashboard/` | `bookings_today.{total,waiting,active,done}`. |
| Carwash · Today — Active now (`4`, "in progress right now") | `GET /api/booking/v1/admin/dashboard/` | `active_now`. |
| Carwash · Today — Pending refunds (`2`, "₹1,450 pending") | `GET /api/booking/v1/admin/dashboard/` | `pending_refunds.{count,amount}`. |
| Recent Activity feed (top 5) | `GET /api/booking/v1/admin/recent-activity/` | `[].{verb,title,subtitle,reference,booking,di_booking,created_at}`. |
| Recent Activity — "View all" | `GET /api/booking/v1/activities/` | paginated full list (same row shape). |

> The **driver/inspector block is platform-level** (driver-hire and inspection
> requests are not shop-scoped), so it shows the same global numbers for a shop
> admin and a superadmin. The carwash KPIs remain shop-scoped (admin → own
> shops, superadmin → all).

> **When to refresh:**
> 1. **On screen open** — call `profile`, `notifications/unread-count`, `admin/dashboard/`, `admin/recent-activity/` in parallel.
> 2. **Pull-to-refresh** — re-call `admin/dashboard/` + `admin/recent-activity/` + `notifications/unread-count` (skip `profile`, it rarely changes).
> 3. **After a wash-status change / driver assignment / refund** — re-call `admin/dashboard/` (counts move) and `admin/recent-activity/` (new event).
> The server bumps the per-admin cache version on these events, so a re-call returns fresh data immediately.

---

**1. Header — `GET /api/accounts/v1/profile/`**

Standard `UserSerializer`. For the dashboard header you only need:

```json
{
  "first_name": "Anand",
  "profile_picture": "https://cdn.bunnycdn.com/admin1.jpg",
  "role": "admin"
}
```
Greeting label: `Good afternoon, ${first_name || "there"}` (pick the salutation by local time-of-day client-side).

---

**2. Notifications bell badge — `GET /api/accounts/v1/notifications/unread-count/`**

The unread count drawn on the bell (the red `3`). Implemented by
`NotificationViewSet.unread_count`
([accounts/views/notification_viewset.py](../accounts/views/notification_viewset.py)).

- Permissions: `IsAuthenticated` (scoped to the current user's notifications).
- Response (200):
```json
{ "unread": 3 }
```
- Hide the badge when `unread == 0`. Tapping the bell opens the **Notifications**
  screen — see [§2 · Notifications](#2--notifications).

---

**3. KPI snapshot — `GET /api/booking/v1/admin/dashboard/`**

A single call returning every KPI card on the dashboard. Implemented by
`AdminDashboardView` ([booking/views/admin_dashboard_view.py](../booking/views/admin_dashboard_view.py)).

- Permissions: `IsAdmin` (admin or superadmin).
- Scope: admin → own shops only; superadmin → all shops (carwash block). The
  `driver_inspector` block is global either way.
- Response (200):
```json
{
  "admin_name": "Anand",
  "overdue": 2,
  "bookings_today": { "total": 9, "waiting": 1, "active": 4, "done": 3 },
  "active_now": 4,
  "pending_refunds": { "count": 2, "amount": "1450.00" },
  "unassigned": { "count": 1, "oldest_minutes": 18 },
  "unassigned_alert_minutes": 15,
  "driver_inspector": {
    "drivers_online": { "online": 3, "total": 4, "on_job": 2 },
    "hire_requests": { "count": 3, "needs_assignee": 1 },
    "inspections": { "count": 2, "open": 1 },
    "on_job_now": 2
  }
}
```

**Carwash · Today block:**

| Field | Type | Meaning |
|---|---|---|
| `admin_name` | string \| null | `first_name`, falling back to `username`, else `null`. |
| `overdue` | int | Confirmed, not-completed bookings whose slot start passed beyond `overdue_grace_minutes`. Drives "Overdue · needs action now". |
| `bookings_today.total` | int | All bookings with `appointment_date == today`. |
| `bookings_today.waiting` | int | Today: `status=confirmed` AND `washing_status=confirmed` (booked, not started). |
| `bookings_today.active` | int | Today: `status=confirmed`, `washing_status` in the active set. |
| `bookings_today.done` | int | Today: `washing_status=completed` OR `status=completed`. |
| `active_now` | int | Active washes across **all** dates (not just today). Drives "Active now · in progress right now". |
| `pending_refunds.count` | int | Bookings with `status=refund_requested` for these shops. |
| `pending_refunds.amount` | string | Sum of those bookings' admin-set `refund_amount` (decimal string; `"0.00"` if unset). Render as "₹1,450 pending". |
| `unassigned.count` | int | Confirmed bookings today-or-later with no driver assigned. |
| `unassigned.oldest_minutes` | int \| null | Age (minutes) of the oldest unassigned booking; `null` if none. |
| `unassigned_alert_minutes` | int | Threshold from `OrgInfo.unassigned_alert_minutes` (default 15). |

> The **active set** (for `bookings_today.active` / `active_now`) =
> `crew_en_route`, `picked_up`, `dropped_at_shop`, `in_progress`, `wash_done`,
> `picked_up_from_shop`, `returning` (everything except `confirmed` and
> `completed`).

**Driver Hiring & Inspection block** (`driver_inspector`) — platform-level
(driver-hire/inspection are not shop-scoped, so these are global). All counts are
for **today's** (`appointment_date == today`) requests unless noted.

| Field | Type | Meaning |
|---|---|---|
| `drivers_online.online` | int | Numerator of the `3/4` card — drivers on the roster (not `inactive`). |
| `drivers_online.total` | int | Denominator — total non-deactivated `Drivers`. |
| `drivers_online.on_job` | int | Distinct drivers currently on a live DI job (`arrived`/`in_progress`); same value as `on_job_now`. Drives the "N on a job now" subline. |
| `hire_requests.count` | int | Open driver-hire requests today (status not `completed`/`cancelled`). |
| `hire_requests.needs_assignee` | int | Subset still unassigned (status `new`/`contacted`). Drives "N needs assignee". |
| `inspections.count` | int | Open inspection requests today (status not `completed`/`cancelled`). |
| `inspections.open` | int | Subset not yet completed (status `new`/`contacted`/`assigned`/`arrived`). Drives "N open". |
| `on_job_now` | int | Live driver jobs right now — distinct drivers assigned to a DI booking in `arrived`/`in_progress`. |

> **"Online" is derived, not real-time presence.** There is no heartbeat/last-seen
> field; `drivers_online.online` counts every non-deactivated driver, and
> `on_job`/`on_job_now` come from current assignment + DI job status.

---

**4. Recent Activity feed (top 5) — `GET /api/booking/v1/admin/recent-activity/`**

Read-only, **unpaginated** feed of the 5 newest events — a mixed list of carwash
and driver/inspection lifecycle events. This is what the dashboard renders.
Implemented by `RecentActivityView` ([booking/views/recent_activity_view.py](../booking/views/recent_activity_view.py)).

- Permissions: `IsAdmin` (admin or superadmin).
- Scope: shop admin → own shop's carwash events only. Superadmin → all shops'
  carwash events **plus** platform-level driver/inspection events. (DI events
  carry no shop, so a shop admin never sees them.)
- Returns a plain array of at most 5 items, newest-first.
- Response (200):
```json
[
  {
    "id": 412,
    "verb": "booking_created",
    "title": "New booking from Priya Menon",
    "subtitle": "AquaShine",
    "booking": 558,
    "booking_reference": "CW-20260618-003",
    "di_booking": null,
    "di_booking_reference": null,
    "reference": "CW-20260618-003",
    "created_at": "2026-06-18T09:38:00Z"
  },
  {
    "id": 410,
    "verb": "di_completed",
    "title": "Driver hire completed — Sajan Varghese",
    "subtitle": "SR-DR-20260618-002",
    "booking": null,
    "booking_reference": null,
    "di_booking": 77,
    "di_booking_reference": "SR-DR-20260618-002",
    "reference": "SR-DR-20260618-002",
    "created_at": "2026-06-18T08:46:00Z"
  }
]
```

`verb` values (drives the feed-row icon):

| `verb` | Label | Points at |
|---|---|---|
| `booking_created` | New booking | `booking` |
| `wash_done` | Wash done | `booking` |
| `returning` | Returning to customer | `booking` |
| `refund_issued` | Refund issued | `booking` |
| `review_created` | New review | `booking` |
| `driver_assigned` | Driver assigned | `booking` |
| `booking_cancelled` | Booking cancelled | `booking` |
| `damage_reported` | Damage reported | `booking` |
| `payout_created` | Payout created | `booking` |
| `di_request_created` | New driver/inspection request | `di_booking` |
| `di_assigned` | Worker assigned (driver/inspection) | `di_booking` |
| `di_completed` | Driver/inspection job completed | `di_booking` |

Row rendering:
- `title` is the headline (e.g. "New booking from Priya Menon"); `subtitle` is the
  shop or reference. Show `created_at` as a relative time ("3 min ago").
- A row carries **either** `booking` or `di_booking` (never both). On tap, open the
  matching detail screen for whichever id is non-null. `reference` is the
  human-readable label (resolves to whichever side is set).

---

**5. Recent Activity — "View all" — `GET /api/booking/v1/activities/`**

The full, paginated feed behind the "View all" link. Implemented by
`ActivityLogViewSet` ([booking/views/activity_log_view_set.py](../booking/views/activity_log_view_set.py)).

- Permissions: `IsAdmin` (admin or superadmin).
- Scope: **shop-only** for admins; superadmin → all shops. (Unlike the top-5 feed,
  this paginated list does **not** include the platform-level DI events.)
- Pagination: `PAGE_SIZE = 20`; page with `?page=N`. Same row shape as above,
  wrapped in the standard `{count, next, previous, results}` envelope.

---

## 2 · Notifications

Opened from the dashboard bell. A paginated, per-recipient list with a header
unread count, a **Filter** sheet (read-state + type chips), a per-row unread dot,
and a header ✓ to mark everything read. All backed by `NotificationViewSet`
([accounts/views/notification_viewset.py](../accounts/views/notification_viewset.py)).
Notifications are **per-user** (`IsAuthenticated`, scoped to the caller) — not
shop-scoped like the activity feed.

Mapping the screen → endpoints:

| Screen element | Endpoint | Notes |
|---|---|---|
| Header "N unread" | `GET /api/accounts/v1/notifications/unread-count/` | `unread`. Same call as the bell badge. |
| "7 notifications" count + the list | `GET /api/accounts/v1/notifications/` | paginated; `count` is the total. |
| **Filter** → Unread only | `GET …/notifications/?is_read=false` | read-state filter. |
| **Filter** → type chips | `GET …/notifications/?kind=booking,refund` | comma-separated `kind`s. |
| Unread dot (yellow) per row | (list field) | `is_read == false`. |
| Row tap → deep link | (list field) | `ref_booking` / `ref_di_booking`. |
| ✓ (mark all read) | `POST …/notifications/read-all/` | clears all unread. |
| Swipe / tap a single row read | `POST …/notifications/{id}/read/` | marks one read. |

---

**1. List — `GET /api/accounts/v1/notifications/`**

- Permissions: `IsAuthenticated` (only the caller's own notifications).
- **Query params (the Filter sheet):**

  | Param | Type | Purpose |
  |---|---|---|
  | `is_read` | bool | `false` → "Unread only"; `true` → read; omit → all. |
  | `kind` | string | One or more kinds, comma-separated (e.g. `booking,refund`). Unknown values are ignored. |
  | `page`, `page_size` | int | Standard pagination (`page_size` default 10, max 100). |

- Response (200) — standard paginated envelope (`count` powers the "7 notifications" label):
```json
{
  "count": 7,
  "next": "https://…/notifications/?page=2",
  "previous": null,
  "results": [
    {
      "id": 5012,
      "kind": "booking",
      "title": "New booking received",
      "body": "Priya Menon · AquaShine Thathampally · 4:15 PM pickup",
      "ref_booking": 558,
      "ref_di_booking": null,
      "is_read": false,
      "created_at": "2026-06-18T09:38:00Z"
    },
    {
      "id": 5008,
      "kind": "payout",
      "title": "Payout marked paid",
      "body": "AquaShine Thathampally · ₹3,920 · UTR logged",
      "ref_booking": null,
      "ref_di_booking": null,
      "is_read": true,
      "created_at": "2026-06-17T16:20:00Z"
    }
  ]
}
```

Field reference:

| Field | Type | Meaning |
|---|---|---|
| `id` | int | Notification id (used by the `read` action). |
| `kind` | enum | Drives the row icon. One of `booking`, `refund`, `review`, `payout`, `attention`, `promo`, `system`. |
| `title` | string | Bold headline (e.g. "New booking received"). |
| `body` | string \| null | Secondary line (customer · shop · detail). |
| `ref_booking` | int \| null | Carwash booking to open on tap. |
| `ref_di_booking` | int \| null | Driver/inspection request to open on tap (mutually exclusive with `ref_booking`). |
| `is_read` | bool | `false` → show the unread dot. |
| `created_at` | datetime | Render relative ("3 min ago", "Yesterday"). |

> **`kind` → icon mapping** (the rows in the mock): `booking` (inbox),
> `attention` (warning triangle — e.g. "Booking unassigned"), `refund` (receipt),
> `review` (star), `payout` (card), `system` (calendar — e.g. "Holiday reminder").
> `promo` is for marketing pushes.

> **Caching:** the list is cached per-user for 300s with version bumping; the
> `read` / `read-all` actions bump the caller's version so the next read is fresh.
> Different `is_read` / `kind` / `page` values cache independently (keyed by query
> string), so filters never return stale results.

---

**2. Unread count — `GET /api/accounts/v1/notifications/unread-count/`**

Powers both the bell badge and the screen's "N unread" header.

- Response (200): `{ "unread": 3 }`.

---

**3. Mark one read — `POST /api/accounts/v1/notifications/{id}/read/`**

- Marks a single notification read (no-op if already read). `404` if the id isn't
  the caller's.
- Response (200): `{ "success": true }`.

---

**4. Mark all read — `POST /api/accounts/v1/notifications/read-all/`**

The header ✓ action.

- Response (200): `{ "success": true, "updated": 3 }` (`updated` = how many flipped).
- After this, `unread-count` returns `0` and the dots clear.

---

## 3 · Shops

The **Shops** screen is a searchable, filterable, sortable list of shop cards.
One endpoint backs it. Served by `ShopViewSet.list` with `ShopListSerializer`
([shop/views/shop.py](../shop/views/shop.py), [shop/serializers/shop_list.py](../shop/serializers/shop_list.py)).

- **Scope:** `superadmin` → all shops; `admin` → only their own shop. (The filter
  and sort below still apply, but an admin only ever has one shop.)
- **Permissions:** `ShopRolePermission`. Pagination: `page_size` default 10, max 100.

Mapping the screen → the list call:

| Screen element | Source |
|---|---|
| Search bar ("Search shop name or area") | `?search=` (matches name-prefix, address, state). |
| "5 shops" count | `count` in the paginated envelope. |
| **Filter** → STATUS chips | `?status=active,inactive` |
| **Filter** → VEHICLE TYPES chips | `?vehicle_type=hatchback,sedan,…` |
| **Filter** → RATING chips | `?min_rating=4.5` (omit for "Any rating") |
| **Sort** sheet | `?sort=name\|rating\|busiest\|capacity` |
| Card — name | `name` |
| Card — area line ("Thathampally Beach Rd") | `area` (the shop's `address`) |
| Card — "Open" / closed | `is_open_now` (computed from weekly business hours + today's override) |
| Card — Active/Inactive badge | `status` |
| Card — rating "4.3 (74)" | `rating` + `rating_count` |
| Card — TODAY | `today_bookings` |
| Card — CAPACITY "16/18" | `capacity.used` / `capacity.total` |
| Card — COMMISSION "₹40/boo…" / "12%" / "15% · min ₹…" | `commission_label` |
| Card — SERVICES | `services_count` |

---

**1. Add Shop — `POST /api/shop/v1/shops/`**

The **Add Shop** form (SHOP / CONTACTS / OPERATIONAL CONFIG / COMMISSION /
BANK · UPI sections). Served by `ShopViewSet.create` → `perform_create`
([shop/views/shop.py](../shop/views/shop.py)) with `ShopSerializer`
([shop/serializers/shop.py](../shop/serializers/shop.py)).

- **Permissions:** `ShopRolePermission` — `admin` or `superadmin` only. An
  `admin` can create exactly **one** shop (their own) and is always its owner; a
  `superadmin` can create a shop for any owner. A second create attempt by an
  admin is rejected `400` ("You already have a shop. Each admin can only create
  one shop.").

Mapping the form → request body (all are writable `ShopSerializer` fields):

| Form section / field | Body field | Notes |
|---|---|---|
| SHOP — Name | `name` | **Required, unique.** |
| SHOP — Address | `address` | |
| SHOP — Pincode / City / State | `pincode`, `city`, `state` | |
| CONTACTS — Shop phone | `phone` | The "Shop phone" drivers see. |
| CONTACTS — Owner name | `owner_name` | Free-text; with `owner_phone`, the API **get-or-creates** an admin `User` and links it as owner. |
| CONTACTS — Owner phone | `owner_phone` | An existing number is **reused** (must be `admin`/`superadmin`, else `400`); a new number creates a `role=admin` User. |
| CONTACTS — (pick existing owner) | `user_id` | An existing admin `User` id. **Takes precedence** over `owner_name`/`owner_phone`. |
| OPERATIONAL CONFIG — Daily booking cap | `daily_booking_cap` | int (e.g. `20`). |
| OPERATIONAL CONFIG — Vehicle types | `supported_vehicle_types` | Array of canonical types; **empty `[]` = all types**. |
| COMMISSION — Type | `commission_type` | `percentage` \| `flat` \| `percent_floor`. |
| COMMISSION — Value | `commission_percentage` / `commission_amount` / `commission_floor` | `commission_percentage` for `percentage` & `percent_floor`; `commission_amount` for `flat`; `commission_floor` for `percent_floor`. |
| BANK · UPI (all optional) | `bank_account_name`, `bank_account_number`, `bank_ifsc`, `upi_id`, `gstin`, `pan` | |
| (Map — optional, not on the form) | `latitude`, `longitude` | **Not required** — `location` is nullable; set later when configuring the shop. |

- **Owner resolution (superadmin), in priority order:** ① `user_id` (existing
  admin) → ② `owner_name` + `owner_phone` (get-or-create admin) → ③ fall back to
  the superadmin themselves. For an `admin`, the owner is always themselves.

- **Request example:**
```json
POST /api/shop/v1/shops/
{
  "name": "AquaShine Thathampally",
  "address": "Beach Rd, Thathampally, Alappuzha",
  "pincode": "688013",
  "city": "Alappuzha",
  "state": "Kerala",
  "phone": "+914772243390",
  "owner_name": "Suresh Kumar",
  "owner_phone": "+919946122087",
  "daily_booking_cap": 20,
  "supported_vehicle_types": ["hatchback", "sedan"],
  "commission_type": "percent_floor",
  "commission_percentage": "12.00",
  "commission_floor": "30.00",
  "bank_account_name": "AquaShine Services",
  "bank_account_number": "338911004521",
  "bank_ifsc": "SBIN0011223",
  "upi_id": "aquashine@oksbi",
  "gstin": null,
  "pan": "DKLPS9087H"
}
```

- **Behavior:**
  - The shop is **always created with `status = "inactive"`** regardless of any
    `status` sent in the body — `status` on create is **ignored**. (Banner: "Shop
    is created Inactive. Add at least one active service before you can activate
    it.")
  - Onboarding audit (`onboarded_by`, `onboarded_at`, `last_edited_by`) is stamped
    automatically.

- **Response (201):** the created shop, in `ShopSerializer` shape (same field set
  as the detail GET above, with `status: "inactive"` and `latitude`/`longitude`
  `null` until coordinates are set).

- **Activation:** to activate later, `PATCH /api/shop/v1/shops/{id}/` with
  `{"status": "active"}`. This is **rejected `400`** ("Add at least one active
  service before activating this shop.") unless the shop has **≥1 active
  ShopService** — add one first (see [§3.1 · Services tab](#31--services-tab)).
  See also the **"Shop active" toggle — write via `status`** note in the detail
  section above.

- **Validation:** `supported_vehicle_types` is validated against the canonical
  enum (`hatchback`, `sedan`, `suv`, `convertible`, `bike`); non-canonical values
  are rejected `400`.

> **🔴 Vehicle-type enum mismatch (same flag as the list / detail):** the form
> chips "Compact SUV" and "Premium SUV" are **not** in the canonical enum — the
> API rejects `compact_suv` / `premium_suv`. The app must map its chips to
> `hatchback` / `sedan` / `suv` / `convertible` / `bike` (or the enum must be
> extended first).

> **🟡 No location on the Add Shop form.** The form has no map; `location` is now
> nullable, so creation succeeds without coordinates. The shop won't appear in
> distance-sorted / nearby results until `latitude` + `longitude` are set later
> (via a subsequent `PATCH`).

---

**2. List — `GET /api/shop/v1/shops/`**

- **Query params:**

  | Param | Type | Purpose |
  |---|---|---|
  | `search` | string | Name (prefix), address, or state. |
  | `status` | string | STATUS chips — comma-separated. One or more of `active`, `inactive`, `pending`, `suspended`. |
  | `vehicle_type` | string | VEHICLE TYPES chips — comma-separated `hatchback`,`sedan`,`suv`,`convertible`,`bike`. A shop matches if it supports **any** listed type; a shop with no restriction (`supported_vehicle_types == []`) matches all. |
  | `min_rating` | float | RATING chips — minimum average rating (e.g. `4.5`/`4.0`/`3.5`). Unrated shops (`rating == null`) are excluded when set. Omit for "Any rating". |
  | `sort` | enum | Sort sheet — see below. Default is name A–Z when omitted. |
  | `category`, `service_name` | int / string | (Pre-existing) filter by a service category id / service-name substring. |
  | `page`, `page_size` | int | Standard pagination. |

  **Sort options (`sort`):**

  | Value | Sort sheet label | Order |
  |---|---|---|
  | `name` | Name A–Z | `name` ascending (the default). |
  | `rating` | Rating: high → low | `rating` descending, **nulls last**, then name. |
  | `busiest` | Busiest today | Most bookings with `appointment_date == today` first. |
  | `capacity` | Capacity used | Highest `today_bookings / today_capacity` ratio first (then absolute bookings, then name). |

- **Response (200)** — standard paginated envelope; each result is a card:
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "AquaShine Thathampally",
      "tagline": "Premium hand wash",
      "area": "Thathampally Beach Rd",
      "city": "Alappuzha",
      "status": "active",
      "rating": 4.3,
      "rating_count": 74,
      "cover_image_url": "https://cdn.bunnycdn.com/aquashine.jpg",
      "is_open_now": true,
      "distance": null,
      "today_bookings": 16,
      "capacity": { "used": 16, "total": 18 },
      "commission_label": "₹40/booking",
      "services_count": 2
    }
  ]
}
```

Field reference:

| Field | Type | Meaning |
|---|---|---|
| `name` | string | Shop name. |
| `area` | string | Locality line on the card (the shop's `address`). |
| `city` | string | City. |
| `status` | enum | `active` / `inactive` / `pending` / `suspended` — drives the badge. |
| `rating` | float \| null | Average rating; `null` if unrated. |
| `rating_count` | int | Number of reviews (the "(74)"). |
| `is_open_now` | bool | Whether the shop is currently within business hours (today's override → weekly schedule). Drives the green "Open". |
| `today_bookings` | int | Bookings with `appointment_date == today`. The "TODAY" stat. |
| `capacity` | object | `{ "used", "total" }` for "16/18". `total` = today's bookable slots (per-shop capacity, else the global default); `used` = `today_bookings`. |
| `commission_label` | string \| null | Short commission summary: `₹N/booking` (flat), `N%` (percentage), or `N% · min ₹M` (percent + floor). `null` if unset. |
| `services_count` | int | Number of active services offered. |
| `cover_image_url` | string \| null | Card image. |
| `distance` | float \| null | Metres from the caller (only when the caller has a saved location; `null` for superadmin without one). |

> **Serializer coverage:** every card field on the screen is already present in
> `ShopListSerializer` — no field gaps. The work here was adding the **filter**
> (`status`, `vehicle_type`, `min_rating`) and **sort** (`name`, `rating`,
> `busiest`, `capacity`) query params, which the list endpoint did not support
> before.

> **Vehicle-type naming mismatch (flag for design):** the Filter mockup shows
> chips "Hatchback / Sedan / Compact SUV / SUV / Premium SUV", but the backend's
> canonical vehicle types are `hatchback`, `sedan`, `suv`, `convertible`, `bike`
> ([car_wash/vehicle_types.py](../car_wash/vehicle_types.py)). There is no
> `compact_suv` / `premium_suv` in the system. The `?vehicle_type=` filter accepts
> only the canonical values (unknown values are ignored). Either the chips should
> map to the canonical set, or the vehicle-type enum needs new values added first.

> **Caching:** the list is cached per-user with version bumping; each distinct
> `search`/`status`/`vehicle_type`/`min_rating`/`sort`/`page` combination caches
> independently (keyed by query string), so filtering/sorting never returns stale
> results. Shop edits bump the version.

---

**3. Detail — Info tab — `GET /api/shop/v1/shops/{id}/`**

The shop **detail** screen (Info / Services / Settlement tabs). This documents the
**Info** tab. Served by `ShopViewSet.retrieve` with `ShopDetailSerializer`
([shop/serializers/shop_detail.py](../shop/serializers/shop_detail.py)).

- **Scope / gating:** `superadmin` → any shop; `admin` → only their own shop.
  The **`settlement` block (commission + bank/UPI) is omitted entirely** for
  anyone who isn't the owning admin or a superadmin (not `null` — the key is
  dropped).

Mapping the Info tab → fields:

| Screen element | Field |
|---|---|
| Header — TODAY | `today_bookings` |
| Header — CAP USED ("16/18") | `capacity.used` / `capacity.total` |
| Header — AVG TIME ("32m") | `avg_service_minutes` |
| Header — STATUS ("Open") | `is_open_now` |
| Cover + gallery + Add | `cover_image_url`, `normal_image1_url`…`normal_image4_url` |
| Shop Identity — Owner | `owner_name` |
| Shop Identity — Owner phone | `owner_phone` |
| Shop Identity — Shop phone | `phone` |
| Shop Identity — Address | `address` (+ `city`, `state`, `pincode`) |
| Map / View location | `latitude`, `longitude` |
| Operating Hours (per weekday) | `operating_hours[]` |
| "Daily cap N · hourly slots" | `operational_config.daily_booking_cap` |
| Next holiday | `next_holiday` |
| Operational Config — Daily booking cap | `operational_config.daily_booking_cap` |
| Operational Config — Vehicle types (chips) | `operational_config.vehicle_types[]` |
| Operational Config — Shop active toggle | **read:** `operational_config.is_active` (derived from `status == "active"`) · **write:** `PATCH status` (see note below) |
| Commission card | `settlement.commission` |
| Bank / UPI card | `settlement.bank` |
| Footer — "Onboarded … by …" / "Last edited …" | `onboarded_at`, `onboarded_by_name`, `last_edited_by_name`, `updated_at` |

- **Response (200):**
```json
{
  "id": 1,
  "name": "AquaShine Thathampally",
  "tagline": "Premium hand wash",
  "status": "active",
  "address": "Beach Rd, Thathampally, Alappuzha 688013",
  "city": "Alappuzha",
  "state": "Kerala",
  "pincode": "688013",
  "latitude": 9.49,
  "longitude": 76.33,
  "distance": null,
  "phone": "+914772243390",
  "cover_image_url": "https://cdn…/cover.jpg",
  "normal_image1_url": "https://cdn…/1.jpg",
  "normal_image2_url": null,
  "normal_image3_url": null,
  "normal_image4_url": null,
  "rating": 4.3,
  "rating_count": 74,
  "is_open_now": true,
  "owner_name": "Suresh Kumar",
  "owner_phone": "+919946122087",
  "today_bookings": 16,
  "capacity": { "used": 16, "total": 18 },
  "avg_service_minutes": 32,
  "operating_hours": [
    { "weekday": 0, "label": "Mon", "is_open": false, "opening_time": null, "closing_time": null, "display": "Off day" },
    { "weekday": 1, "label": "Tue", "is_open": true,  "opening_time": "9:00 AM", "closing_time": "8:00 PM", "display": "9:00 AM – 8:00 PM" }
  ],
  "next_holiday": { "date": "2026-06-07", "label": "Sun 07 Jun" },
  "operational_config": {
    "daily_booking_cap": 18,
    "vehicle_types": [
      { "value": "hatchback", "label": "Hatchback", "supported": true },
      { "value": "sedan", "label": "Sedan", "supported": true },
      { "value": "suv", "label": "SUV", "supported": false },
      { "value": "convertible", "label": "Convertible", "supported": false },
      { "value": "bike", "label": "Bike", "supported": false }
    ],
    "is_active": true
  },
  "settlement": {
    "commission": { "type": "flat", "percentage": null, "amount": "40.00", "floor": null, "label": "₹40/booking" },
    "bank": {
      "account_name": "AquaShine Services", "account_number": "3389 1100 4521",
      "ifsc": "SBIN0011223", "upi_id": "aquashine@oksbi", "gstin": null, "pan": "DKLPS9087H"
    }
  },
  "onboarded_at": "2026-02-02",
  "onboarded_by_name": "Vishnu",
  "last_edited_by_name": "Anand",
  "updated_at": "2026-05-18T10:22:00Z"
}
```

Field notes:

| Field | Type | Meaning |
|---|---|---|
| `avg_service_minutes` | int \| null | Average wash duration in minutes — mean gap between the `in_progress` (Wash Started) and `wash_done` (Wash Done) timeline events over this shop's bookings in the **last 30 days**. `null` when there's no completed-wash data. Render as "{n}m". |
| `capacity` | object | `{used, total}`; `used` = today's bookings, `total` = today's bookable slots (per-shop capacity → global default). |
| `is_open_now` | bool | Within business hours right now (today's override → weekly schedule). |
| `operating_hours[]` | array | One row per weekday (0=Mon…6=Sun): `is_open`, `opening_time`/`closing_time` (12-hour), and a ready-made `display` ("9:00 AM – 8:00 PM" or "Off day"). |
| `next_holiday` | object \| null | The next upcoming `is_closed` business-hours override: `{date, label}`. `null` if none scheduled. |
| `operational_config.vehicle_types[]` | array | Every selectable type with a `supported` flag, so the UI renders selected (highlighted) vs available (greyed) chips. An empty `supported_vehicle_types` on the shop means it serves all types → every chip `supported: true`. |
| `operational_config.daily_booking_cap` | int | The shop's explicit `daily_booking_cap`, else the computed slot-capacity total. |
| `operational_config.is_active` | bool | **Read-only, derived** from `status == "active"`. To flip the "Shop active" toggle you must `PATCH` the **`status`** field — there is no writable `is_active`. See the toggle note below. |
| `settlement` | object | **Present only** for the owning admin / superadmin. `commission.type` is one of `flat` / `percentage` / `percent_floor` (drives the segmented control); `commission.label` is the pre-formatted summary. `bank` fields may be `null` when unset. |
| `onboarded_by_name` / `last_edited_by_name` | string \| null | Full names for the audit footer. |

> **Vehicle-type chips (same flag as the list):** `operational_config.vehicle_types`
> enumerates the canonical types `hatchback`, `sedan`, `suv`, `convertible`, `bike`
> — there is no `compact_suv` / `premium_suv`. The mockup's "Compact SUV / Premium
> SUV" chips don't correspond to backend values; the chip set must map to the
> canonical types (or the enum needs extending first).

> **`service_started_at` / `service_completed_at` are not used.** Those Booking
> columns exist but are never written, so AVG TIME is derived from the
> `BookingStatusEvent` timeline instead.

> **⚠️ "Shop active" toggle — write via `status`, not `is_active`.** The Shop model
> has no `is_active` column; activeness is the `status` enum
> (`active` / `inactive` / `pending` / `suspended`). The detail response exposes a
> convenience **read-only** `operational_config.is_active`, but `PATCH`ing
> `is_active` is **silently ignored** (DRF drops unknown keys and returns `200`
> with no change — this is the "toggle does nothing" symptom). Toggle the shop by
> PATCHing `status`:
>
> ```
> PATCH /api/shop/v1/shops/{id}/
> { "status": "inactive" }   // toggle OFF  (→ is_active:false in the next GET)
> { "status": "active" }     // toggle ON   (→ is_active:true)
> ```
>
> Served by `ShopViewSet.partial_update` (`ShopSerializer`, where `status` is
> writable). Same scope gating as the detail GET: `superadmin` → any shop,
> `admin` → only their own.

---

### 3.1 · Services tab

The detail screen's **Services** tab: a list of the shop's services, an **Add
Service** form, and two bulk actions. Served by `ShopServiceViewSet`
([shop/views/shop_service.py](../shop/views/shop_service.py)) with
`ShopServiceSerializer` ([shop/serializers/shop_service.py](../shop/serializers/shop_service.py)).

- **Scope:** `admin` → own shop's services only; `superadmin` → all (and must name
  the shop on writes); `user` → read-only.

Mapping the screen → endpoints:

| Screen element | Endpoint |
|---|---|
| Service list (cards) | `GET /api/shop/v1/shop-services/?shop={id}` (or nested `GET /api/shop/v1/shops/{id}/services/`) |
| **Add Service** form | `POST /api/shop/v1/shop-services/` |
| Edit a service (pencil) | `PATCH /api/shop/v1/shop-services/{id}/` |
| Per-service active toggle | `PATCH /api/shop/v1/shop-services/{id}/` with `{ "active": false }` |
| **Copy services from another shop** | `POST /api/shop/v1/shop-services/copy-from/` |
| **Apply % price change to all** | `POST /api/shop/v1/shop-services/apply-price-change/` |

---

**1. List — `GET /api/shop/v1/shop-services/?shop={id}`**

- Filter by `?shop={id}`. Each item is a card:
```json
{
  "id": 12,
  "shop": 1,
  "name": "Exterior Wash",
  "category_id": 3,
  "inclusions": ["Foam wash", "Dry"],
  "uniform_pricing": false,
  "price": 0,
  "duration_in_slots": 1,
  "estimated_minutes": 30,
  "variants": [
    { "id": 40, "vehicle_type": "hatchback", "label": "Hatchback", "price": 230, "duration_in_slots": 1, "estimated_minutes": 30, "active": true },
    { "id": 41, "vehicle_type": "sedan", "label": "Sedan", "price": 260, "duration_in_slots": 1, "estimated_minutes": 30, "active": true },
    { "id": 42, "vehicle_type": "suv", "label": "SUV", "price": 300, "duration_in_slots": 1, "estimated_minutes": 30, "active": true }
  ],
  "from_price": 230,
  "summary": "3 vehicle types · from ₹230",
  "active": true
}
```

| Card element | Field |
|---|---|
| Service name | `name` |
| Description ("Foam wash + dry") | `inclusions` (bullet list — join for display) |
| **FLAT** badge | shown when `uniform_pricing == true` |
| Price summary | `summary` — pre-built: `"₹150 · 20 min · all types"` (uniform) or `"3 vehicle types · from ₹230"` (per-type) |
| Per-service active toggle | `active` |

> `estimated_minutes` = `duration_in_slots × 30` (a slot is 30 min). `from_price`
> is the cheapest price across the service.

---

**2. Add Service — `POST /api/shop/v1/shop-services/`** (edit: `PATCH …/{id}/`)

The Add Service form. Body:
```json
{
  "name": "Exterior Wash",
  "inclusions": ["Foam wash", "Dry"],
  "category_id": 3,
  "uniform_pricing": false,
  "active": true,
  "variants": [
    { "vehicle_type": "hatchback", "price": 230, "duration_in_slots": 1, "active": true },
    { "vehicle_type": "sedan", "price": 260, "duration_in_slots": 1, "active": true }
  ]
}
```

Form field → payload:

| Form field | Payload | Notes |
|---|---|---|
| Service name | `name` | Required. |
| Description ("What's included…") | `inclusions` | **The textarea maps to `inclusions`** — split the text by newline into a list of bullet strings (there is no separate free-text `description` field). |
| "Same price for all vehicle types" toggle | `uniform_pricing` | `true` → send top-level `price` + `duration_in_slots`, omit `variants`. `false` → send `variants`, omit top-level price. |
| Per-type grid: PRICE ₹ | `variants[].price` | One entry per enabled (ON) vehicle type. |
| Per-type grid: MINS | `variants[].duration_in_slots` | **Stored as 30-min slots, not minutes.** The client converts the MINS input → slots (round to nearest 30 ÷ 30; e.g. 20 min → 1 slot, 45 min → 2). `estimated_minutes` in responses is `slots × 30` for display. |
| Per-type grid: ON toggle | `variants[].active` | Only send rows the operator enabled; omitted types aren't offered. |
| Master "Service active" toggle | `active` | Per-service on/off. |

- **Uniform mode** (`uniform_pricing: true`): `price` and `duration_in_slots` are
  **required**; `variants` are ignored (cleared on update).
- **Per-type mode** (`uniform_pricing: false`): at least one variant is required.
  On `PATCH`, sending `variants` **replaces** the set (vehicle types absent from
  the payload are deleted; present ones upsert by `vehicle_type`).
- Response: the created/updated service in the list shape above (with computed
  `summary` / `from_price` / `estimated_minutes`).

> **Vehicle-type chips (same flag as Info):** the grid in the mockup lists
> "Hatchback / Sedan / Compact SUV / SUV / Premium SUV", but `variants.vehicle_type`
> accepts only the canonical `hatchback`, `sedan`, `suv`, `convertible`, `bike`
> ([car_wash/vehicle_types.py](../car_wash/vehicle_types.py)). `compact_suv` /
> `premium_suv` don't exist — the chip set must map to the canonical values, or
> the enum needs extending first (a shared change with `accounts.Cars`).

---

**3. Copy services from another shop — `POST /api/shop/v1/shop-services/copy-from/`**

Copies every **active** service (with its variants) from a source shop into the
target shop. Name collisions are **skipped** (append, never overwrite).

- Body: `{ "source_shop": 7, "target_shop": 1 }` — `target_shop` is required for
  superadmin, ignored for admin (always their own shop).
- Response (200): `{ "copied": 4, "skipped": 1 }`.
- Errors: `400` if `source_shop` missing / equals target / not found; `403` if an
  admin targets a shop they don't own.

---

**4. Apply % price change to all — `POST /api/shop/v1/shop-services/apply-price-change/`**

Bumps every price for one shop by a percentage (uniform `price` **and** all
variant prices), rounded to the nearest rupee.

- Body: `{ "shop": 1, "percent": 10 }` — `percent` e.g. `10` (+10%) or `-5` (−5%),
  must be `> -100`. `shop` required for superadmin, ignored for admin.
- Response (200): `{ "services_updated": 2, "variants_updated": 3 }`.
- Errors: `400` for a non-numeric or `≤ -100` percent; `403` for the wrong shop/role.

> **Caching:** the service list is cached with version bumping; create / update /
> delete and both bulk actions bump `shop_service`, so the next read is fresh.

---

### 3.2 · Settlement tab + New Payout

The detail screen's **Settlement** tab (per shop) and the **New Payout** flow.
All settlement endpoints are **superadmin-only** (`IsSuperAdmin`). Commission is
deducted per booking using the shop's commission rule; "net payable" is gross −
commission.

> **Settleable** = a carwash booking that is `status=confirmed`,
> `washing_status=completed`, and not already in a payout. Commission per booking
> follows `commission_type`: `flat` (₹N), `percentage` (N%), or `percent_floor`
> (max of N% and a floor) — see [shop/models/shop.py](../shop/models/shop.py)
> `commission_for` / `payout_for`.

Mapping the screens → endpoints:

| Screen element | Endpoint |
|---|---|
| **Settlement tab** — header + pending list + net | `GET /api/booking/v1/admin/settlements/{shop_id}/pending/` |
| **Settlement tab** — "Create Payout for This Shop" | `POST /api/booking/v1/admin/settlements/{shop_id}/payout/` |
| **Settlement tab** — Payout history | `GET /api/booking/v1/admin/settlements/{shop_id}/history/` |
| **New Payout** — shop picker (all shops + net) | `GET /api/booking/v1/admin/settlements/` |
| **New Payout** — auto-calculated net + "Create Payout" | `GET …/{shop_id}/pending/` then `POST …/{shop_id}/payout/` |

---

**1. Pending + stats — `GET /api/booking/v1/admin/settlements/{shop_id}/pending/`**

Backs the whole Settlement-tab body. Response (200):
```json
{
  "shop_id": 1,
  "count": 2,
  "net_payable": "420.00",
  "pending_total": "420.00",
  "last_settled": "2026-05-20T10:00:00Z",
  "lifetime_paid": "41200.00",
  "items": [
    { "booking_id": 552, "reference": "…0527-0022", "appointment_date": "2026-05-27", "gross": "250.00", "commission": "40.00", "net": "210.00" },
    { "booking_id": 559, "reference": "…0529-0041", "appointment_date": "2026-05-29", "gross": "250.00", "commission": "40.00", "net": "210.00" }
  ]
}
```

| Screen element | Field |
|---|---|
| Header — PENDING ₹420 | `pending_total` (= `net_payable`) |
| Header — LAST SETTLED | `last_settled` (most recent payout's `created_at`; `null` if none) |
| Header — LIFETIME PAID | `lifetime_paid` (sum of paid payouts) |
| PENDING SETTLEMENTS rows | `items[]` — `reference`, `appointment_date`, `gross`, `commission`, `net` |
| Net payable | `net_payable` |

---

**2. Create payout — `POST /api/booking/v1/admin/settlements/{shop_id}/payout/`**

Settles **all currently-pending bookings** for the shop into one `paid` payout
batch — this is the "oldest pending → today" behaviour both screens describe. The
period is auto-derived (`period_start` = earliest, `period_end` = latest booking
date).

- Body (both optional): `{ "utr": "SBIN5520119003", "notes": "…" }`.
- Response (201): the created payout —
```json
{
  "id": 88, "shop": 1,
  "gross_amount": "500.00", "commission_amount": "80.00", "total_amount": "420.00",
  "booking_count": 2, "status": "paid",
  "utr": "SBIN5520119003", "notes": null,
  "period_start": "2026-05-27", "period_end": "2026-05-29",
  "created_by": 3, "created_by_name": "Anand", "created_at": "2026-06-18T…Z",
  "items": [ { "id": 1, "booking": 552, "reference": "…0527-0022", "appointment_date": "2026-05-27", "gross": "250.00", "commission": "40.00", "net": "210.00" } ]
}
```
- `400` if nothing is pending; `409` if a concurrent payout already settled some
  of the bookings (retry). Row-locks the candidates and re-checks settleability
  inside a transaction, so a booking is settled at most once.

> **Booking selection / per-booking adjustment is not supported** — a payout
> always takes *all* currently-pending bookings. The mockup's "Review bookings and
> adjust on the next screen after saving" implies a future per-item adjust step;
> there is no endpoint for it yet. Flagged as a follow-up.

---

**3. Payout history — `GET /api/booking/v1/admin/settlements/{shop_id}/history/`**

Response (200): `{ "count", "results": [ <payout> ] }`, newest first. Each row has
the same shape as the create response.

| History row element | Field |
|---|---|
| Date range ("10–20 May 2026") | `period_start` – `period_end` |
| Amount ("₹3,920") | `total_amount` |
| UTR ("SBIN5520119003") | `utr` |
| Status badge ("Paid") | `status` |

---

**4. Shop picker (overview) — `GET /api/booking/v1/admin/settlements/`**

Powers the New Payout **shop picker** — every shop with its current net payable,
so the picker can list all shops and pre-fill the selected shop's amount. Net is
computed per booking with each shop's commission rule (so it matches what a payout
would settle). Implemented by `ShopSettlementsOverviewView`
([booking/views/shop_settlements_overview_view.py](../booking/views/shop_settlements_overview_view.py)).

- Response (200):
```json
{
  "count": 5,
  "items": [
    {
      "shop_id": 1, "name": "AquaShine Thathampally",
      "pending_total": "4496.00", "booking_count": 18,
      "period": { "start": "2026-05-21", "end": "2026-06-18" },
      "last_paid": { "date": "2026-05-20T10:00:00Z", "amount": "3920.00" }
    }
  ]
}
```

| Picker element | Field |
|---|---|
| Radio row per shop | `items[]` — `shop_id`, `name` |
| Pre-filled "Net payable ₹4,496" for the selected shop | `pending_total` |
| "oldest pending → today" period banner | `period.start` → `period.end` (`null` when nothing pending) |

Notes:
- **All shops are returned**, including those with nothing pending
  (`pending_total: "0"`, `booking_count: 0`, `period: null`), so the picker can
  list every shop. Sorted by highest pending first, then name.
- After picking a shop, the client uses `…/{shop_id}/pending/` for the detailed
  breakdown and `…/{shop_id}/payout/` to create the payout — there's no separate
  "create from overview" call.
- Parallel to the worker version, `GET /api/booking/v1/admin/worker-settlements/`.

---

### 3.3 · Payout Log + Payout detail

A global, cross-shop **Payout Log** (last 90 days) and the **Payout detail**
screen. Superadmin-only.

> **Net payable formula.** Each payout stores its parts:
> `net = gross − commission − refunds_total − other_adjustments`, **unless**
> `net_override` is set (the detail screen's pencil), which then wins.
> `total_amount` always holds the resolved net. `refunds_total` is captured at
> create time — the sum of non-failed `BookingRefund`s issued against the shop's
> bookings during the payout period.

Mapping the screens → endpoints:

| Screen element | Endpoint |
|---|---|
| **Payout Log** list (all shops, 90d) | `GET /api/booking/v1/admin/payouts/` |
| Search "shop or UTR" | `?search=` (shop name / UTR / PO reference) |
| Filter — STATUS / SHOP | `?status=pending,paid` / `?shop=1,2` |
| Sort sheet | `?sort=recent\|net_desc\|net_asc\|shop` |
| **Payout detail** — every field | (same `PayoutSerializer` row from the log/history) |

---

**1. Payout Log — `GET /api/booking/v1/admin/payouts/`**

- Default window: **last 90 days** (override with `?days=`).
- Query params:

  | Param | Type | Purpose |
  |---|---|---|
  | `search` | string | Shop name, UTR, or PO reference (case-insensitive). |
  | `status` | string | `pending` / `paid`, comma-separated. |
  | `shop` | string | Shop id(s), comma-separated. |
  | `sort` | enum | `recent` (default) / `net_desc` (Net high→low) / `net_asc` / `shop` (A–Z). |
  | `days` | int | Window size (default 90). |
  | `page`, `page_size` | int | Standard pagination. |

- Response (200): standard paginated envelope; each result is a full payout (same
  shape as the detail screen):
```json
{
  "id": 91,
  "reference": "PO-20260529-007",
  "shop": 4,
  "shop_name": "SparkleWash Mullackal",
  "gross_amount": "2320.00",
  "commission_amount": "349.00",
  "refunds_total": "150.00",
  "other_adjustments": "0.00",
  "net_override": null,
  "total_amount": "1821.00",
  "booking_count": 9,
  "status": "paid",
  "utr": "SBIN5520119003",
  "notes": null,
  "period_start": "2026-05-01",
  "period_end": "2026-05-29",
  "created_by": 3,
  "created_by_name": "Anand",
  "created_at": "2026-05-29T12:00:00Z",
  "items": [
    { "id": 1, "booking": 552, "reference": "…0527-0022", "appointment_date": "2026-05-27", "gross": "250.00", "commission": "40.00", "net": "210.00" }
  ]
}
```

| Log card / detail element | Field |
|---|---|
| Shop name | `shop_name` |
| Status badge (Pending / Paid) | `status` |
| Period ("1 May – 29 May 2026") | `period_start` – `period_end` |
| Gross / Comm / Refunds | `gross_amount` / `commission_amount` / `refunds_total` |
| Net ("₹1,821") | `total_amount` |
| "Created 29 May, 5:30 PM" | `created_at` |
| PO reference ("PO-20260529-007") | `reference` |
| Detail calc — Other adjustments | `other_adjustments` |
| Detail calc — edited net (pencil) | `net_override` (when set) |
| Per-booking lines | `items[]` |

> **Detail screen** uses the same row — there is no separate detail endpoint; the
> client already has the full payout from the log (or from a shop's
> `…/{shop_id}/history/`). Expand the calc rows from `gross_amount`,
> `commission_amount`, `refunds_total`, `other_adjustments`, and the resolved
> `total_amount`.

---

**2. Create with adjustments — `POST /api/booking/v1/admin/settlements/{shop_id}/payout/`**

The existing create endpoint (see §3.2) now also accepts, in its body:

| Field | Type | Effect |
|---|---|---|
| `other_adjustments` | number | Manual correction (deduction positive). Default 0. |
| `net_override` | number | Explicit net payable; overrides the formula. |

`refunds_total` and `reference` (PO number) are computed/assigned server-side. The
response is the enriched payout above.

> **Lifecycle gap (flagged).** These mockups show a **Pending → Mark Paid** flow
> with payment proof, an editable net on an already-created payout, and a `Pending`
> filter. The backend currently creates payouts as **`paid` immediately** — there
> is **no Mark-Paid transition, no payment-proof upload, and no post-create edit**.
> So the `Pending` status filter returns nothing today, and the detail screen's
> "Mark Paid" / pencil-after-save / "Payment proof" controls have no endpoint yet.
> The net-calc fields (`refunds_total`, `other_adjustments`, `net_override`) and
> the PO `reference` **are** implemented and set at create time. Building the full
> pending lifecycle is a separate, larger change (new `Payout` status workflow +
> proof storage + a `mark-paid` endpoint).

---

### 3.4 · Manage Hours & Slots

Reached from the shop detail screen's **⋮ → "Manage hours & slots"**. This screen
configures **when** a shop is open and bookable:

- a **weekly schedule** — per-weekday open/close times, with off days;
- **auto-generated hourly slots** with per-slot **break** toggles (turn an hourly
  slot OFF for a recurring break);
- a **slot-level capacity** switch (whether per-slot capacity or the shop's daily
  cap governs how many bookings fit);
- a **copy-one-day-to-all** shortcut; and
- a list of **upcoming holidays** that close the shop on specific dates.

**Permissions.**
- Weekly schedule + slot breaks: `ShopRolePermission` — `admin` → only their **own**
  shop (auto-linked; the `shop` field is filled in for them), `superadmin` → any
  shop (must pass `shop` explicitly on writes). `user` is read-only.
- Holidays: `IsAdmin` — `admin` or `superadmin`. An `admin` only sees/edits
  holidays that include one of their shops (see scoping note below).

> **How the slot grid works.** The banner *"slots are auto-generated hourly from
> opening hours; turn off individual slots for breaks"* describes a **static
> reference grid**: the `Slot` model is a fixed set of times (`id`, `start_time`)
> shared by all shops — fetch it once from `GET /api/shop/v1/slots/`. The per-day
> slot list shown on this screen is **derived client-side** by walking the `Slot`
> times between the day's `opening_slot` and `closing_slot`. The only things
> stored **server-side** for a day are (a) the weekly open/close row and (b) which
> slots are broken. So "9:00 AM – 8:00 PM · 11 slots" is computed from
> opening → closing, not returned as a field.

The screen is backed by four endpoint groups plus the shared `slots/` reference list.

Mapping the screen → endpoints:

| Screen element | Endpoint |
|---|---|
| Reference slot grid (all hourly times) | `GET /api/shop/v1/slots/` |
| Weekly schedule (per-day open/close, off days) | `GET/POST /api/shop/v1/shop-weekly-businesses/` (+ `PATCH`/`DELETE /{id}/`) |
| "Copy Tue to all" | `POST /api/shop/v1/shop-weekly-businesses/{id}/copy-to-all/` |
| Per-slot break toggles | `GET/POST /api/shop/v1/shop-slot-breaks/` (+ `DELETE /{id}/`) |
| "tap slots then Save" (bulk per day) | `POST /api/shop/v1/shop-slot-breaks/set-day/` |
| "Slot-level capacity" switch | `PATCH /api/shop/v1/shops/{id}/` `{"use_slot_level_capacity": …}` |
| UPCOMING HOLIDAYS card | `GET/POST /api/shop/v1/holidays/` (+ `DELETE /{id}/`) |

---

**1. Weekly schedule — `GET/POST /api/shop/v1/shop-weekly-businesses/`**

(`PATCH`/`DELETE /api/shop/v1/shop-weekly-businesses/{id}/`)

One row per `(shop, weekday)` — `unique_together`. Served by
`ShopWeeklyBusinessViewSet` ([shop/views/shop_weekly_business.py](../shop/views/shop_weekly_business.py))
with `ShopWeeklyBusinessSerializer`.

| Field | Type | Notes |
|---|---|---|
| `shop` | int (FK) | Optional for `admin` (auto-linked to their shop); **required** for `superadmin`. |
| `weekday` | int | `0`=Mon, `1`=Tue, … `6`=Sun. |
| `opening_slot` | int (FK → `Slot`) | The day's first bookable slot. Resolves to a `start_time`. |
| `closing_slot` | int (FK → `Slot`) | The day's last bookable slot. Resolves to a `start_time`. |
| `id`, `created_at`, `updated_at` | — | Read-only. |

- **Off days.** A weekday with **no row** is an **OFF day** — there's no separate
  "closed" flag in this model. To make an open day an off day, **`DELETE` its row**.
- **`?shop=` filter** lists one shop's rows (admins are already scoped to their own).
- The detail screen's "9:00 AM – 8:00 PM · 11 slots" line is **derived** from
  `opening_slot.start_time` → `closing_slot.start_time` (count of `Slot` grid times
  in that window).

- **Request / Response (one row):**
```json
POST /api/shop/v1/shop-weekly-businesses/
{ "shop": 1, "weekday": 1, "opening_slot": 19, "closing_slot": 41 }
```
```json
{
  "id": 7,
  "shop": 1,
  "weekday": 1,
  "opening_slot": 19,
  "closing_slot": 41,
  "created_at": "2026-06-21T08:00:00Z",
  "updated_at": "2026-06-21T08:00:00Z"
}
```

> Posting a second row for the same `(shop, weekday)` is rejected `400`
> ("…with this shop and weekday already exists."). To change a day's hours,
> `PATCH` the existing row instead.

---

**2. Copy one day to all — `POST /api/shop/v1/shop-weekly-businesses/{id}/copy-to-all/`**

Backs **"Copy Tue to all"**. Copies the row's `opening_slot` / `closing_slot` to
**all other 6 weekdays** of the same shop (create-or-update per weekday). The
source day's own row is left untouched. **Empty body.**

- Returns the **full 7-day** weekly list for the shop (ordered by `weekday`):
```json
POST /api/shop/v1/shop-weekly-businesses/7/copy-to-all/
{}
```
```json
[
  { "id": 5,  "shop": 1, "weekday": 0, "opening_slot": 19, "closing_slot": 41, "created_at": "…", "updated_at": "…" },
  { "id": 7,  "shop": 1, "weekday": 1, "opening_slot": 19, "closing_slot": 41, "created_at": "…", "updated_at": "…" },
  { "id": 8,  "shop": 1, "weekday": 2, "opening_slot": 19, "closing_slot": 41, "created_at": "…", "updated_at": "…" },
  { "id": 9,  "shop": 1, "weekday": 3, "opening_slot": 19, "closing_slot": 41, "created_at": "…", "updated_at": "…" },
  { "id": 10, "shop": 1, "weekday": 4, "opening_slot": 19, "closing_slot": 41, "created_at": "…", "updated_at": "…" },
  { "id": 11, "shop": 1, "weekday": 5, "opening_slot": 19, "closing_slot": 41, "created_at": "…", "updated_at": "…" },
  { "id": 12, "shop": 1, "weekday": 6, "opening_slot": 19, "closing_slot": 41, "created_at": "…", "updated_at": "…" }
]
```

> "Copy to all" overwrites every other day's hours — including days that were
> previously **off** (they get a row and become open). To keep a day off after a
> copy, `DELETE` that day's row afterwards.

---

**3. Slot breaks — `GET/POST /api/shop/v1/shop-slot-breaks/`**

(`DELETE /api/shop/v1/shop-slot-breaks/{id}/`)

A **break** = one hourly slot turned **OFF** on a weekday, **recurring weekly**.
Served by `ShopSlotBreakViewSet` ([shop/views/shop_slot_break.py](../shop/views/shop_slot_break.py))
with `ShopSlotBreakSerializer`. One row per `(shop, weekday, slot)` (`unique_together`).

| Field | Type | Notes |
|---|---|---|
| `shop` | int (FK) | Optional for `admin`; **required** for `superadmin`. |
| `weekday` | int | `0`=Mon … `6`=Sun. |
| `slot` | int (FK → `Slot`) | The hourly slot turned off. |
| `id`, `created_at` | — | Read-only. |

- **DELETE** the row to turn the slot back **on**.
- Filters: `?shop=` and `?weekday=`.

> **Availability vs capacity.** A slot is bookable only if it's **within the day's
> opening hours AND not in a break** — this is *availability*, distinct from
> *capacity* (how many bookings fit, handled by `ShopCapacity` / the daily cap in
> §4 below). Booking a broken slot is rejected by `Booking.validate_business_hours`
> ([booking/models/booking.py](../booking/models/booking.py)) with "…unavailable
> (break) on this weekday".

```json
POST /api/shop/v1/shop-slot-breaks/
{ "shop": 1, "weekday": 1, "slot": 27 }
```
```json
{ "id": 14, "shop": 1, "weekday": 1, "slot": 27, "created_at": "2026-06-21T08:05:00Z" }
```

**Bulk setter — `POST /api/shop/v1/shop-slot-breaks/set-day/`**

Backs the **"tap slots then Save"** flow. **Replaces ALL** breaks for one
`(shop, weekday)` with the given `slot_ids` in a single call.

- Body: `{ "shop"?, "weekday", "slot_ids": [...] }` — `shop` optional for `admin`,
  required for `superadmin`; `weekday` required (int 0–6); `slot_ids` a list.
- `slot_ids: []` **clears** the day's breaks (turns every slot back on).
- Returns the resulting break list for that `(shop, weekday)`:
```json
POST /api/shop/v1/shop-slot-breaks/set-day/
{ "shop": 1, "weekday": 1, "slot_ids": [27, 28] }
```
```json
[
  { "id": 15, "shop": 1, "weekday": 1, "slot": 27, "created_at": "2026-06-21T08:06:00Z" },
  { "id": 16, "shop": 1, "weekday": 1, "slot": 28, "created_at": "2026-06-21T08:06:00Z" }
]
```

---

**4. Slot-level capacity toggle — `PATCH /api/shop/v1/shops/{id}/`**

The **"Slot-level capacity"** switch is backed by the boolean
`Shop.use_slot_level_capacity` ([shop/models/shop.py](../shop/models/shop.py)).
There is no dedicated endpoint — toggle it on the shop itself:

```json
PATCH /api/shop/v1/shops/1/
{ "use_slot_level_capacity": true }
```

It's also surfaced **read-only** in the shop detail's `operational_config` block
(see the Info tab above): `operational_config.use_slot_level_capacity`.

> **What the toggle changes.** When **OFF (default)**, the shop's
> `daily_booking_cap` governs how many bookings fit per day ("daily cap of 18
> applies"). When **ON**, **per-slot capacity** (`ShopCapacity` rows) governs
> instead — capacity is summed per slot. (See `_daily_capacity` in
> [shop/serializers/_helpers.py](../shop/serializers/_helpers.py).) This is
> *capacity*, independent of the *availability* breaks in group 3.

---

**5. Upcoming holidays — `GET/POST /api/shop/v1/holidays/`**

(`DELETE /api/shop/v1/holidays/{id}/`)

A **global, labeled** holiday across one or more shops — the card's
"Local festival · 4 shops". Served by `HolidayViewSet`
([shop/views/holiday.py](../shop/views/holiday.py)) with `HolidaySerializer`.
**Permission: `IsAdmin`.**

| Field | Type | Notes |
|---|---|---|
| `date` | date | The closed date. |
| `label` | string | e.g. "Local festival". |
| `shops` | list[int] (FK) | Shop ids closed on this date. |
| `shop_count` | int | **Read-only** — `len(shops)` (the "N shops"). |
| `created_by` | int | **Read-only** — stamped from the requester. |
| `id`, `created_at` | — | Read-only. |

- Filters: `?upcoming=true` → only holidays with `date ≥ today` (the **UPCOMING
  HOLIDAYS** list); `?shop=<id>` → holidays including that shop.
- **DELETE** removes a holiday (the **×** on the card).
- Marking a holiday **closes each linked shop** on that date: booking is rejected
  by `Booking.validate_business_hours` via `Holiday.closes_shop_on`
  ([shop/models/holiday.py](../shop/models/holiday.py)) with "Shop is closed for a
  holiday on …".

> **Scoping.** An `admin` can only attach their **own** shop(s) — **omitting**
> `shops` defaults the holiday to the admin's shop(s); passing a **foreign** shop
> id → `400` ("You can only attach your own shop(s)…"). A `superadmin` can attach
> **any** shops. An admin's list/detail is filtered to holidays that include one
> of their shops.

```json
POST /api/shop/v1/holidays/
{ "date": "2026-08-15", "label": "Independence Day", "shops": [1, 2, 4, 7] }
```
```json
{
  "id": 22,
  "date": "2026-08-15",
  "label": "Independence Day",
  "shops": [1, 2, 4, 7],
  "shop_count": 4,
  "created_by": 3,
  "created_at": "2026-06-21T08:10:00Z"
}
```

> **Two ways to close a shop on a date.** A **global `Holiday`** (this endpoint,
> shared label across shops) closes *every* linked shop. Separately, a **per-shop
> date override** (`ShopWeeklyBusinessOverride` —
> `GET/POST /api/shop/v1/shop-weekly-business-overrides/`) can close a *single*
> shop on a date **or** give it custom one-off hours; the shop detail's
> `next_holiday` field reflects the next such per-shop closure. Both mechanisms are
> honored by `validate_business_hours` (holiday is checked first, then the
> per-shop override). Use a `Holiday` for a shared closure across shops; use an
> override for a one-shop closure or custom hours.
>
> **⚠️ Break enforcement edge case.** Recurring `ShopSlotBreak`s are only enforced
> on days that fall through to the **weekly** schedule. If a date has a
> `ShopWeeklyBusinessOverride` with custom (non-closed) hours, that branch checks
> the override window but **does not** re-apply slot breaks — so a slot "turned
> off for a break" can still be booked on an overridden date.

---

## 4 · Bookings

The **Bookings** tab has a **Driver & Inspection** / **Carwash** segmented control.
This section documents the **Driver & Inspection** segment (the carwash segment is
the separate `bookings/` list). Served by `DriverInspectionBookingViewSet.list`
with `DriverInspectionListSerializer`
([booking/views/driver_inspection_booking_view_set.py](../booking/views/driver_inspection_booking_view_set.py)).

- **Scope:** `admin`/`superadmin` → all requests; `driver`/`inspector` → only the
  requests assigned to them; `user` → their own. (`IsAuthenticated`.)

Mapping the screen → the list call:

| Screen element | Source |
|---|---|
| Search ("Search ID, name, or phone") | `?search=` (reference, customer first/last name, phone) |
| "6 requests" count | `count` in the paginated envelope |
| **Filter** → SERVICE TYPE | `?request_type=driver\|inspection` |
| **Filter** → STATUS | `?status=new\|contacted\|assigned\|in_progress\|completed\|cancelled` |
| **Sort** sheet | `?sort=recent\|upcoming\|status` |
| Card — service chip (INSPECTION/DRIVER) | `request_type` |
| Card — status pill (Contacted, In Progress…) | `status` |
| Card — customer name | `customer_name` |
| Card — vehicle ("Honda City (2019, used)") | `vehicle` |
| Card — date + time | `appointment_date` + `start_time` |
| Card — duration ("~1 hr") | `duration_label` |
| Card — location | `address_text` |
| Card — fee ("₹800") | `amount` |
| Card — "Needs assignee" vs assignee name | `needs_assignee` (bool) / `assignee_name` |

---

**1. List — `GET /api/booking/v1/driver-inspection-requests/`**

- **Query params:**

  | Param | Type | Purpose |
  |---|---|---|
  | `search` | string | Reference (ID), customer name, or phone. |
  | `request_type` | enum | `driver` / `inspection` (the SERVICE TYPE chips). |
  | `status` | enum | `new` / `contacted` / `assigned` / `arrived` / `in_progress` / `completed` / `cancelled` (the STATUS chips). |
  | `sort` | enum | `recent` (default) / `upcoming` / `status` — see below. |
  | `date_range` | enum | `today` / `yesterday` / `last_7_days` / `this_month`, or `date_after` / `date_before`. |
  | `page`, `page_size` | int | Standard pagination. |

  **Sort options (`sort`):**

  | Value | Sort sheet label | Order |
  |---|---|---|
  | `recent` | Most recent | Newest created first (default). |
  | `upcoming` | Upcoming first | Future-or-today appointments first, ascending by date+time; past requests sink to the bottom. |
  | `status` | By status | Workflow order: `new` → `contacted` → `assigned` → `arrived` → `in_progress` → `completed` → `cancelled`, then newest within each. |

  > **No default date scoping.** The list returns all requests (subject to role);
  > the "Today · 29 May 2026" header is a client label. Use `?date_range=today`
  > to scope to today.

- **Response (200)** — standard paginated envelope; each result is a card:
```json
{
  "id": 77,
  "reference": "SR-IN-20260530-002",
  "request_type": "inspection",
  "trip_type": null,
  "inspection_type": "pre_purchase",
  "title": "Vehicle Inspection",
  "vehicle": "Honda City (2019, used)",
  "appointment_date": "2026-05-30",
  "start_time": "11:00:00",
  "duration_label": "~1 hr",
  "address_text": "Thathampally, near Beach Rd, Alappuzha",
  "drop_address_text": null,
  "amount": "800.00",
  "is_paid": false,
  "status": "contacted",
  "assignee_name": null,
  "needs_assignee": true,
  "customer_name": "Meera Jacob",
  "customer_phone": "+919812340002"
}
```

Field notes:

| Field | Type | Meaning |
|---|---|---|
| `request_type` | enum | `driver` / `inspection` — the chip. |
| `status` | enum | The status pill. |
| `vehicle` | string \| null | `brand_model · registration` from the linked car, else the free-text `vehicle_text`. |
| `duration_label` | string \| null | "~1 hr" (inspection), "Full day (8 hrs)" / "{n} hrs" (driver). |
| `amount` | string \| null | `quoted_fee` if set, else `estimated_fee` (`null` if neither). |
| `assignee_name` | string \| null | Full name of the assigned driver/inspector, or `null` if unassigned. |
| `needs_assignee` | bool | `true` when the request is awaiting a worker — no active assignment **and** status is `new`/`contacted`. Drives the amber "Needs assignee" warning. When `false` and assigned, show `assignee_name` instead. |
| `customer_name` / `customer_phone` | string | The requester. |

> **`needs_assignee` was added for this screen** — previously the client had to
> infer it from `assignee_name == null` plus the status. It's computed the same way
> the dashboard counts `hire_requests.needs_assignee` (status in `new`/`contacted`,
> no active `BookingAssignment`), so the card and the dashboard KPI agree.

---

### 4.1 · D&I request detail + lifecycle

The request **detail** screen and its full lifecycle (assign → arrive → start →
end). Same flow for **driver** and **inspection** requests — the only difference
is which worker pool is assigned and the final-bill math (drivers can have overage;
inspectors are fixed-fee). Served by `DriverInspectionBookingViewSet`
([booking/views/driver_inspection_booking_view_set.py](../booking/views/driver_inspection_booking_view_set.py))
with `DriverAndInspectionBookingSerializer`.

Mapping the screens → endpoints:

| Screen element | Endpoint |
|---|---|
| Detail (header, request card, note, worker card, timeline) | `GET /api/booking/v1/driver-inspection-requests/{id}/` |
| Assign sheet — candidate workers + availability | `GET …/{id}/assignable-workers/` |
| Assign / Change | `POST …/{id}/assign/` |
| Set status (e.g. → Contacted) | `POST …/{id}/status/` |
| Mark arrived | `POST …/{id}/arrive/` |
| Start Job (start OTP) | `POST …/{id}/verify-start-otp/` |
| End Job (end OTP) | `POST …/{id}/verify-end-otp/` |
| Cancel | `POST …/{id}/cancel/` |

---

**1. Detail — `GET …/{id}/`**

Returns the full `DriverAndInspectionBookingSerializer`. Field → screen:

| Screen element | Field |
|---|---|
| Title / reference | `request_type` (→ "Inspection Request") / `reference` |
| Call action | `customer_phone` |
| Status pill | `status` |
| Vehicle ("Honda City (2019, used) · Sedan") | `car_label` (else `vehicle_text`) |
| When ("30 May, 11:00 AM · ~1 hr") | `appointment_date` + `start_time` + `duration_label` |
| Location + navigate | `address_text`, `latitude`, `longitude` |
| Quoted fee | `quoted_fee` (else `estimated_fee`) |
| Customer note | `customer_note` |
| Assigned worker card | `worker` — `{ name, title, role, phone, masked_phone, rating }` or `null` |
| Status timeline | `timeline[]` — see below |
| Bottom action (Assign first / Start Job / End Job / completed) | derive from `status` (+ `worker`) |

The OTPs (`start_otp` / `end_otp`) are returned **only in the customer's own**
detail response (the "Demo · OTP is 7390" the admin reads out comes from the
customer's app); admins and workers get `null`.

**Timeline entries** (`timeline[]`):
```json
{ "id": 5, "status": "completed", "actor_name": "Salim K", "source": "system",
  "note": null, "latitude": 9.49, "longitude": 76.33,
  "location_text": "Thathampally, near Beach Rd, Alappuzha",
  "created_at": "2026-05-29T11:28:00Z" }
```
`status`, `created_at`, and `actor_name`/`source` ("Customer app" / "Anand") drive
each row; `latitude`/`longitude`/`location_text` (set on start/end) power the
location line under In Progress / Completed.

---

**2. Assignable workers — `GET …/{id}/assignable-workers/`**

Powers the **Assign** sheet. Returns workers of the request's role
(inspectors for inspection, drivers for driver requests), each flagged available
for this request's date + slot span — computed with the **same slot-conflict
logic `assign` enforces**, so the sheet can't show "Available" for someone assign
would then reject.

- `IsAdmin`. Optional `?slot_id=` anchors availability (defaults to the request's
  `start_slot`).
- Response (200):
```json
{
  "count": 2,
  "items": [
    { "id": 8, "name": "Salim K", "role": "inspector", "title": "Inspector", "phone": "+919074533890", "masked_phone": null, "rating": 4.7, "available": true },
    { "id": 5, "name": "Ravi Menon", "role": "inspector", "title": "Inspector", "phone": "…", "masked_phone": null, "rating": 4.5, "available": false }
  ]
}
```
- Deactivated workers are excluded. Available workers sort first, then by name.
  The card's "On a job · unavailable" = `available: false`.

> **This endpoint is new** — previously there was no way to list candidates with
> server-authoritative availability; the sheet would have had to guess.

---

**3. Assign / Change — `POST …/{id}/assign/`**

- `IsAdmin`. Body: `{ "inspector_id": 8, "slot_id": 42 }` (or `driver_id`).
- Sets `status=assigned`, blocks the worker for the whole estimated span, and
  **generates fresh start/end OTPs**. Calling it again **reassigns** (the "Change"
  button) — the prior assignment is cancelled first.
- `409` if the worker is already busy for that span; `400` for a bad slot/worker.

---

**4. Set status — `POST …/{id}/status/`**

- `IsAdmin`. Body: `{ "status": "contacted", "note": "…", "quoted_fee": 800 }`.
- Generic transition + a timeline entry. This is how **Contacted** is set, and how
  `quoted_fee` is recorded ("to be set on call"). `assign` sets `assigned`
  automatically; start/end OTP set `in_progress`/`completed`.

---

**5. Mark arrived — `POST …/{id}/arrive/`**

- `IsAssignedWorkerOrAdmin`. Requires `status=assigned` **and** the advance paid
  (`is_paid`). Sets `status=arrived`.

> **Flow note:** the backend requires `arrived` before Start Job (this step also
> enforces advance-paid). The Assigned-screen "Start Job" button must therefore
> call `arrive` first (or surface an Arrived step). This is intentional —
> `verify-start-otp` rejects a non-`arrived` request with `409`.

---

**6. Start Job — `POST …/{id}/verify-start-otp/`**

- `IsAssignedWorkerOrAdmin`. Requires `status=arrived`.
- Body: `{ "otp": "7390" }` plus **optional** `latitude` / `longitude` /
  `location_text`. On a correct OTP → `status=in_progress`, stamps
  `start_otp_verified_at`, and logs a timeline event. The event's location uses
  the worker's GPS if sent, **else the booking's pickup** `latitude`/`longitude` +
  `address_text`.
- `400` on a wrong OTP; `409` if not `arrived`.

---

**7. End Job — `POST …/{id}/verify-end-otp/`**

- `IsAssignedWorkerOrAdmin`. Requires `status=in_progress`.
- Body: same as start (`otp` + optional location). On a correct OTP →
  `status=completed`, stamps `end_otp_verified_at`, logs the timeline event
  (location → worker GPS, else booking **drop** coords, else pickup), and computes
  the final bill:
  - **Driver:** `actual_hours = ceil(elapsed start→end)`, `additional_charges`
    (overage via the rate card), `final_total = advance + additional_charges`,
    `balance_due`.
  - **Inspector:** fixed — `additional_charges = 0`, `final_total = advance`,
    `balance_due = 0`, `balance_paid = true`.
  - Releases the worker back to `active` and credits their earnings ledger.

> **`final-bill`** — `GET …/{id}/final-bill/` returns the itemised breakdown once
> completed.

---

### 4.2 · New Request (admin phone-in)

The admin logs a driver-hire / inspection request **on a customer's behalf** — for
an existing customer or a brand-new one created on the spot. Fee, timing and
assignment are confirmed on a follow-up call, so the create captures basics only
(no estimate, no payment), landing at `status="new"`.

Mapping the screens → endpoints:

| Screen element | Endpoint |
|---|---|
| Customer sheet — "Search existing" | `GET /api/accounts/v1/superadmin/customers/?search=` |
| Customer sheet — "Add new" (with / without OTP) | `POST /api/accounts/v1/admin/customers/` |
| "Create Request" (Driver hire / Vehicle inspection) | `POST /api/booking/v1/admin/manual-di-booking/` |

---

**1. Search customers — `GET /api/accounts/v1/superadmin/customers/?search=`**

(Existing endpoint — the Customers tab list, reused by the picker.) `IsAdmin`-class
access; `?search=` matches phone / first / last / username. Returns
`CustomerListSerializer` cards (`id`, `full_name`, `initials`, `phone`, …). Pick a
row → use its `id` as `customer_id` below.

---

**2. Add new customer — `POST /api/accounts/v1/admin/customers/`**

Creates a `role=user` account by phone + name. Two paths, one endpoint:
- **"Send OTP to verify"** → include `otp_code`; it's verified before the account
  is created.
- **"Add without OTP (override)"** → omit `otp_code`; the account is created
  directly.

- Permissions: `IsAdmin`. Body:
```json
{ "phone": "+919447056789", "full_name": "Ramesh Kurup", "otp_code": "1234", "email": null }
```
- Response (201): the `CustomerListSerializer` card (use its `id` as `customer_id`).
- **`409`** if the phone already belongs to a customer — the body includes that
  `customer_id` so the UI can switch to "use existing":
```json
{ "phone": "A customer with this number already exists.", "customer_id": 7 }
```
- `400` for a missing phone/name or a bad `otp_code`.

> Phone is unique across all users. The OTP `otp_code` is verified via the same
> Twilio flow as customer self-signup; the override path is for numbers the admin
> already confirmed on the call.

---

**3. Create request — `POST /api/booking/v1/admin/manual-di-booking/`**

Logs the phone-in request for the chosen customer. `IsAdmin`. No estimate, no
Razorpay — created at `status="new"` with an optional `quoted_fee`.

- Body (most fields optional — capture what's known on the call):
```json
{
  "customer_id": 7,
  "request_type": "driver",
  "trip_type": "round_trip",
  "vehicle_text": "Maruti Ertiga · KL-04-1234",
  "appointment_date": "2026-05-30",
  "start_slot": 33,
  "address_text": "Pickup / inspection address",
  "quoted_fee": "800",
  "customer_note": "Seller available 11am–1pm"
}
```

| Form field | Payload |
|---|---|
| Customer (search/add) | `customer_id` (a `role=user` id) |
| Driver hire / Vehicle inspection | `request_type` = `driver` / `inspection` |
| Reason for hire chips | `trip_type` (`one_way` / `round_trip` / `hourly`; `hospital` also accepted) |
| Inspection type | `inspection_type` (`pre_purchase` / `pre_sale`) |
| Vehicle — make&model + plate | `vehicle_text` (free text) — or `car_id` to link a saved car |
| When | `appointment_date` + `start_slot` (slot's time is stored) or `start_time` |
| Duration | `hourly_package` / `requested_hours` |
| Location | `address_text` (+ optional `latitude`/`longitude`, drop fields) |
| Quoted fee · optional | `quoted_fee` (null = "to be set on call") |
| Note · optional | `customer_note` |

- Response (201): the full `DriverAndInspectionBookingSerializer` (status `new`,
  reference assigned, timeline seeded with a "Phone-in request" entry). From here
  the request flows through the normal lifecycle (§4.1): set Contacted → Assign →
  Start → End.
- Validation: `customer_id` must be a `role=user` account (`400` otherwise);
  `trip_type` required for a driver request; a linked `car_id` must belong to the
  customer.

> **Reason-for-hire / trip types:** the API accepts the values the system supports
> today — `one_way`, `round_trip`, `hourly` (+ `hospital`). The mockup's extra
> chips ("Outstation", "Event / Wedding", "Hospital Assistance") are UI labels; map
> them to a supported `trip_type` (or extend the `TripType` enum first) before
> sending.

> **Vehicle:** a phone-in typically uses free-text `vehicle_text` (make&model ·
> plate). Linking `car_id` is only for a customer's already-saved vehicle; this
> endpoint does not create `Cars` rows.

---

### 4.3 · Carwash segment (list + filter + sort)

The **Carwash** tab of Bookings. Fully backed by `BookingViewSet.list` with
`BookingListSerializer`
([booking/views/booking_view_set.py](../booking/views/booking_view_set.py),
[booking/serializers/booking_list_serializer.py](../booking/serializers/booking_list_serializer.py),
filters in [booking/filters.py](../booking/filters.py)). Everything below already
exists — no gaps.

- **Scope:** `admin` → own shops; `superadmin` → all. Not date-scoped by default
  (the "Today · 29 May 2026" header is a client label; pass `?date_range=today`).
- **Count:** "9 bookings" = the paginated `count`.

Mapping the screen → the list call (`GET /api/booking/v1/bookings/`):

| Screen element | Source |
|---|---|
| Search ("Search ID, name, or phone") | `?search=` (reference, customer name, phone) |
| **Filter** → Date range | `?date_range=today\|yesterday\|last_7_days\|this_month` or `?date_after=&date_before=` |
| **Filter** → Time of day | `?time_of_day=morning\|afternoon\|evening` |
| **Filter** → Status chips | `?status_chip=` (repeatable; see mapping) |
| **Filter** → Shop | `?shop=` (repeatable shop ids) |
| **Filter** → Assignment | `?assignment=me\|unassigned` |
| **Sort** sheet | `?sort=recent\|oldest\|amount_desc\|amount_asc\|customer_az` |

---

**1. List card fields** (`BookingListSerializer`):

| Card element | Field |
|---|---|
| Appointment time ("4:15 PM") | `start_slot_time` (+ `appointment_date`) |
| Reference ("#0048") | `reference` |
| Status pill ("New" / "Done") | derive from `status` + `washing_status` + `assignee_name` — see note |
| Customer name | `customer_name` |
| Vehicle ("Hyundai i20 · KL-04-AB-1234") | `vehicle_label` |
| PICKUP · CUSTOMER address | `pickup_address` |
| DROP · SHOP (name + address) | `shop_name` + `shop_area` |
| Amount ("₹250") | `amount` |
| Payment ("Paid") | `payment_status` / `is_paid` |
| "Assign →" vs assignee | `assignee_name` (`null` → unassigned → show "Assign →") |

> **Status pill:** the serializer's `display_status` is coarse
> (`UPCOMING`/`COMPLETED`/`CANCELLED`). The fine-grained pill the card shows
> ("New", "Going", "Washing", "Done"…) is derived client-side from `status` +
> `washing_status` + whether a driver is assigned — the **same mapping** the
> `status_chip` filter uses (below). All the inputs (`status`, `washing_status`,
> `assignee_name`) are on the card payload.

---

**2. Status chips — `?status_chip=` (repeatable, OR'd):**

| Chip | `status_chip` | Condition |
|---|---|---|
| New | `new` | confirmed, not started, **no** driver assigned |
| Assigned | `assigned` | confirmed, not started, driver assigned |
| Going | `going` | `washing_status=crew_en_route` |
| Picked | `picked` | `washing_status=picked_up` |
| At Shop | `at_shop` | `washing_status=dropped_at_shop` |
| Washing | `washing` | `washing_status=in_progress` |
| Done | `done` | `washing_status=wash_done` |
| Returning | `returning` | `washing_status=returning` |
| Completed | `completed` | `status=completed` or `washing_status=completed` |
| Cancelled | `cancelled` | `status=cancelled` |

Multi-select OR's the chips; in-flight chips exclude cancelled bookings.

---

**3. Assignment — `?assignment=`:**

| Chip | Value | Meaning |
|---|---|---|
| Assigned to me | `me` | Bookings with an active driver assignment to the caller. |
| Unassigned | `unassigned` | Bookings with no active driver assignment. |

> Only `me` and `unassigned` exist — matching the design. (A "co-founder" / team
> assignment chip has no data-model equivalent and is intentionally not exposed.)

---

**4. Sort — `?sort=`:**

| Sort sheet label | Value | Order |
|---|---|---|
| Most recent | `recent` | `-created_at` (default) |
| Oldest first | `oldest` | `created_at` |
| Amount: high → low | `amount_desc` | `-amount` |
| Amount: low → high | `amount_asc` | `amount` |
| Customer A–Z | `customer_az` | customer `first_name`, `last_name` |

All sorts carry a stable `-created_at` / `id` tiebreaker for deterministic
pagination.

---

### 4.4 · Carwash booking detail + lifecycle

The carwash booking **detail** screen and its actions (assign / reassign / assign-me,
washing-status steps, damage check at pickup + drop). Served by `BookingViewSet`
([booking/views/booking_view_set.py](../booking/views/booking_view_set.py)) with
`BookingSerializer` on retrieve.

Mapping the screens → endpoints:

| Screen element | Endpoint |
|---|---|
| Detail (header, customer, vehicle, journey, services, timeline, damage card) | `GET /api/booking/v1/bookings/{id}/` |
| Assign-driver sheet — candidate drivers | `GET …/{id}/assignable-drivers/` |
| Assign driver / Reassign | `POST …/{id}/assign-driver/` |
| "Assign Me" (step list) | `POST …/{id}/assign-me/` |
| Update Status steps | `PATCH …/{id}/` `{ "washing_status": … }` |
| Damage Check (pickup / drop) | `POST` / `GET …/{id}/damage-check/` |
| Cancel / Refund | (see §2 Bookings / Refunds) |

---

**1. Detail — `GET …/{id}/`**

Returns the full `BookingSerializer`. Field → screen:

| Screen element | Field |
|---|---|
| Status pill / reference / total / paid | `status` + `washing_status` · `reference` · `amount` · `is_paid`/`payment_status` |
| Customer (name, phone, call) | `customer_name`, `customer_phone` |
| Vehicle (make/model, type, plate) | `car` (FK → `brand_model`, `car_type`, `registration`) / `vehicle_label` |
| Journey — pickup time + address (+ navigate) | `start_slot_time`, `appointment_date`, `address_detail` (lat/lng) |
| Journey — shop (name, address, call, navigate) | `shop` (nested `ShopSerializer`: name, address, phone, lat/lng) |
| Journey — drop ("Same as pickup") | `drop_address` (null ⇒ same as pickup) |
| Services (name, est min, price, total) | `service_name`, `estimated_minutes`, `amount` |
| Assigned driver | `driver` (`{id, name, title, phone, masked_phone}` or null) |
| Update Status step timestamps | `timeline[]` (`{washing_status, actor, created_at}`) |
| **Damage & issues** card (per stage) | `damage` — see below |

**`damage`** (new, embedded so the card renders in one call):
```json
"damage": {
  "pickup": { "stage": "pickup", "checked": true, "issues_found": "issues",
              "damage_types": ["paint_chip"], "panels": ["rear_bumper"],
              "notes": "damaged", "voice_note_url": "https://cdn…", … },
  "drop": null
}
```
`null` for a stage = "Not checked yet". The full edit/record view still uses the
`damage-check` action.

---

**2. Assignable drivers — `GET …/{id}/assignable-drivers/`**

Powers the **Assign driver** sheet. `IsAdmin` (shop-scoped). Returns active drivers,
each flagged `available` for the booking's date + slot span (same conflict logic as
assign-driver); the role label ("founder" / "co-founder" / "Detailer") is the
driver's `title`.
```json
{ "count": 2, "items": [
  { "id": 5, "name": "Anand", "title": "founder", "phone": "+919847022119", "masked_phone": null, "rating": 4.8, "available": true }
] }
```
Available drivers sort first; deactivated drivers excluded.

> **New endpoint** — parallel to the DI `assignable-workers` (§4.1).

---

**3. Assign / Reassign — `POST …/{id}/assign-driver/`**

`IsAdmin`. Body `{ "driver_id": 5 }`. Replaces any existing active driver
assignment (so it doubles as **Reassign**), blocks the driver for the full service
span, logs a `driver_assigned` activity. `409` if the driver is busy for that span.

---

**4. Assign Me — `POST …/{id}/assign-me/`**

The step-list "Assign Me" button — the caller assigns **their own** driver profile.
The founder/co-founder operate as `role=driver` accounts (their `title` is
"founder" etc.), so they self-assign here.

- Allowed for a `driver` (their own profile), or an `admin`/`superadmin` who also
  has an active `Drivers` profile (shop-scoped for admins).
- No body. `400` if the caller has no active driver profile; `409` if they're
  already busy for the span.
- A driver can open + claim an **unassigned** booking in the queue (the booking
  list/detail now surfaces unassigned jobs to drivers for this reason); jobs taken
  by another driver stay hidden.

---

**5. Update washing status — `PATCH …/{id}/` `{ "washing_status": … }`**

Advances the step list. Allowed values (in order): `confirmed` → `crew_en_route`
(Going for Pickup) → `picked_up` (Car Picked Up) → `dropped_at_shop` → `in_progress`
(Wash Started) → `wash_done` → `picked_up_from_shop` → `returning` (Dropped to
Customer) → `completed`. Each transition writes a `BookingStatusEvent`, which is why
`timeline[]` carries the per-step timestamps. Permission: superadmin, the shop's
admin, or the assigned driver.

---

**6. Damage Check — `POST` / `GET …/{id}/damage-check/`**

Records (or fetches) the per-stage damage inspection. `GET` returns all reports;
`POST` upserts one stage (unique per `(booking, stage)`). Permission: superadmin,
shop admin, or the assigned driver.

- Body (JSON, or **multipart** when attaching a voice note):
```json
{ "stage": "pickup", "checked": true, "issues_found": "issues",
  "damage_types": ["paint_chip"], "panels": ["rear_bumper"], "notes": "damaged" }
```

| Form element | Field |
|---|---|
| "I have checked the vehicle…" | `checked` (bool) |
| Issues found? (No all clear / Yes issues) | `issues_found` = `clear` / `issues` |
| DAMAGE TYPE chips | `damage_types[]` — `minor_scratch`, `major_scratch`, `dent`, `glass_crack`, `paint_chip`, `interior_stain`, `other` |
| PANEL / LOCATION chips | `panels[]` — `front_bumper`, `rear_bumper`, `front_left_door`, `front_right_door`, `rear_left_door`, `rear_right_door`, `bonnet`, `boot`, `roof`, `windshield`, `interior`, `other` |
| Notes | `notes` |
| Add voice note (max 60s) | multipart file field `voice_note` → uploaded to BunnyCDN → `voice_note_url` |
| Pickup vs Drop | `stage` = `pickup` / `dropoff` |

- When `issues_found = clear`, `damage_types` / `panels` / `notes` are cleared
  server-side. An issues report at pickup emits a `damage_reported` activity.
- Voice-note upload is already wired to BunnyCDN (validated audio → public URL;
  the previous note is deleted on replace).

---

## 5 · Refunds (New Refund)

The **New Refund** screen — pre-filled from a booking, the admin picks a tier
(100% / 70% / 0% / Override), an amount, a reason, optional notes, and **Create
Refund initiates a Razorpay refund** against the original payment. Multiple partial
refunds are allowed, capped at the amount paid. Served by `CarwashRefundView`
([booking/views/refund_views.py](../booking/views/refund_views.py)) +
`issue_refund` ([booking/services/refunds.py](../booking/services/refunds.py)).
**Superadmin-only** (`IsSuperAdmin`).

> A parallel `DriverInspectionRefundView` at
> `/api/booking/v1/admin/refunds/driver-inspection/{di_booking_id}/` does the same
> for DI requests (with `payment_kind=advance|balance` to pick which payment).

Mapping the screen → endpoints:

| Screen element | Endpoint |
|---|---|
| Pre-fill (suggested tier, amount paid, prior refunds) | `GET /api/booking/v1/admin/refunds/carwash/{booking_id}/` |
| Booking reference (display) | from the booking the screen was opened on |
| Create Refund | `POST /api/booking/v1/admin/refunds/carwash/{booking_id}/` |

---

**1. Summary (pre-fill) — `GET …/refunds/carwash/{booking_id}/`**

```json
{
  "amount_paid": "250.00",
  "total_refunded": "0.00",
  "remaining": "250.00",
  "count": 0,
  "refunds": []
}
```
Use `amount_paid` for the tier math and `remaining` as the cap. `refunds[]` is the
prior ledger (each row has `amount`, `percent`, `reason`, `comment`, `status`,
`razorpay_refund_id`, `created_by_name`, `created_at`).

---

**2. Create refund — `POST …/refunds/carwash/{booking_id}/`**

- Body — provide **exactly one** of `amount` / `percent`:
```json
{ "percent": 100, "reason": "cancellation_by_customer", "comment": "per call" }
```

| Form element | Field | Notes |
|---|---|---|
| Tier (100% / 70% / 0%) | `percent` | Server resolves `amount = round(amount_paid × percent/100)`. |
| Override / Amount (₹) | `amount` | Send a rupee amount instead of `percent`. |
| Reason chip | `reason` | One of `cancellation_by_customer`, `founder_cancellation`, `service_quality_issue`, `damage_during_wash`, `duplicate_charge`, `other`. Optional. |
| Notes | `comment` | Free text. Optional. |
| (advanced) recorded-only | `mode: "manual"` | Skips the gateway (records a manual refund). |

- **Razorpay:** if the booking has an online payment
  (`UserPaymentMethod.razorpay_payment_id`), `issue_refund` calls
  `client.payment.refund(payment_id, {amount: paise})` and stores the returned
  `razorpay_refund_id`. Offline/cash bookings (or `mode=manual`) record a
  processed refund with no gateway call.
- **Cap:** `sum(non-failed refunds) ≤ amount_paid`, enforced under a row lock.
  Over-cap → `400` with the cap math.
- **Gateway failure:** records a `status=failed` row (excluded from the cap) and
  returns `502` so the admin can retry.
- **Side effects:** the carwash booking's `status` becomes `refunded` (first
  refund), and the customer + shop are notified.
- Response (201):
```json
{
  "refund": { "id": 9, "amount": "250.00", "percent": "100.00",
              "reason": "cancellation_by_customer", "comment": "per call",
              "status": "processed", "razorpay_refund_id": "rfnd_123", … },
  "summary": { "amount_paid": "250.00", "total_refunded": "250.00", "remaining": "0.00", "count": 1, "refunds": [ … ] }
}
```

> **Tier is client-side.** The backend has no tier logic — the UI maps the
> 100/70/0 buttons to a `percent` (and Override to a typed `amount`). The
> structured `reason` is new (added for these chips); it's distinct from the
> customer-facing cancellation reasons. A refund can be issued against any paid
> booking — it does **not** require the booking to be in `refund_requested` first.

---

## 6 · Cancel a booking

The booking detail's **Cancel** button → "Cancel this booking?" dialog. One
**role-aware** endpoint on `BookingViewSet`
([booking/views/booking_view_set.py](../booking/views/booking_view_set.py)):

**`POST /api/booking/v1/bookings/{id}/cancel/`**

- **Admin / superadmin** (this screen): cancels **outright** → `status="cancelled"`.
  The assigned driver is released, the customer is notified, and a
  `booking_cancelled` activity is logged. **No refund is issued** — "a refund may
  be required" → the admin uses the Refund screen (§5) separately if one is due.
  - Body (all optional): `{ "reason": "Customer no-show" }` (free text, stored on
    `cancellation_reason_other`). No reason is required for the "Yes, cancel" tap.
  - Scope: an admin may only cancel their own shop's booking (superadmin any).
  - Response (200): `{ "message": "Booking cancelled", "booking_id", "reference", "status": "cancelled" }`.

- **Customer** (their own app): the same endpoint is a *cancellation request* —
  it captures a structured `cancellation_reason` and moves the booking to
  `refund_requested` (the admin's pending-refunds queue), **not** `cancelled`. The
  admin then issues a refund (§5), which flips it to `refunded`.

- Only `pending` / `confirmed` bookings can be cancelled (else `400`); a booking
  the caller can't act on returns `404`/`403`.

> **Preview** — `GET …/{id}/cancellation-preview/` returns the policy-based refund
> quote (fee %, refund amount, free-window flag, ETA) shown to the customer before
> they confirm. The admin dialog doesn't need it (admin cancel is refund-agnostic).

---

## 7 · New Booking (manual carwash)

The admin **New Booking · Manual/phone-in** flow for **carwash** — book on a
customer's behalf, no online payment (confirmed offline). Served by
`ManualBookingView` ([booking/views/manual_booking_view.py](../booking/views/manual_booking_view.py))
+ `BookingCreateSerializer`. `IsAdmin`; admins are scoped to their own shop,
superadmins any. The DI version is §4.2.

**`POST /api/booking/v1/admin/manual-booking/`** — body maps to the 8 steps:

| # · Step | Field(s) | Notes |
|---|---|---|
| 1 · Customer | `customer_id` | A `role=user` account. Search via `/superadmin/customers/?search=`; add via `/admin/customers/` (§4.2). |
| 2 · Vehicle | `car` | A `Cars` id; must belong to the customer. "Add new vehicle" → create via `POST /api/accounts/v1/cars/` with `user_id` first, then pass `car`. |
| 3 · Shop | `shop_id` | Radio list. Admin → own shop only (else 403). |
| 4 · Services | `service_id` | **Single service** today — see the gap below. Amount is computed server-side from `service.price_for(vehicle_type)`. |
| — vehicle type for pricing | `vehicle_type` | Defaults to the car's type; "Prices shown for Sedan". |
| 5 · Pickup — address | `pickup_address_text` *or* `address` | **Free-text** `pickup_address_text` creates a doorstep `Address` for the customer on the fly; or pass a saved `address` id. |
| 5 · Pickup — time | `start_slot` + `appointment_date` | The typed time maps to a `Slot` id (use `slots-available` to resolve). Capacity + business hours enforced. |
| 6 · Drop | `same_as_pickup` (default `true`), `drop_address` | On → drop mirrors pickup; off → pass a separate `drop_address` id. |
| 7 · Coupon | `coupon_code` | Optional; validated + discount applied to `amount` server-side. |
| 8 · Payment | `payment_status` = `pending` / `paid` | Booking is created **confirmed**, `payment_mode=offline`. |

- **Amount is server-computed** (service + vehicle-type pricing − coupon); the
  client never sends `amount`. Slot capacity + shop business hours are enforced.
- Response (201): the full booking (`BookingSerializer`) — `status=confirmed`,
  `payment_mode=offline`, the resolved `amount`, `coupon_name`, addresses, etc.

> **🔴 Multi-service is a known gap (not yet built).** The screen lets the admin
> select **multiple** services (Exterior Wash ₹320 + Interior Vacuum ₹180 = ₹500),
> but `Booking` has a **single `service_id` FK** — so only one service can be sent
> today (`service_id`, and `amount` = that one service's price). Supporting
> multi-service is a dedicated cross-cutting change:
> 1. A `BookingService` line-item table (`booking`, `service`, `vehicle_type`,
>    `price`, `duration`) — or a Booking↔ShopService M2M with per-row price.
> 2. `amount` = sum of selected line items (− coupon); `duration_in_blocks` = sum.
> 3. Updates to the booking **detail** (services card lists all items), the
>    **settlement** math (gross per line), and any report keying off `service_id`.
> 4. The create payload becomes `service_ids: [...]` (or line items).
> Until then the client should send one `service_id`; the "add another service"
> multi-select isn't backed server-side.

> **Newly added for this screen:** free-text `pickup_address_text` (creates the
> Address), the `same_as_pickup` / `drop_address` handling, and the previously-null
> `coupon_name` / `discount_amount` / `original_amount` getters on
> `BookingCreateSerializer` (the customer create response).

---

## 8 · Team (Drivers & Inspectors)

The admin **Team** screens — two near-identical tabs (**Drivers** and
**Inspectors**) listing the shop's workers with a status filter, plus a **Hire
Driver / Add Driver** create form (and the inspector equivalent). Backed by the
`Drivers` and `Inspectors` models (shop app) and a shared `WorkerDocument` model.
`IsAdmin`; admins are scoped to their own shop, superadmins see all shops.

The two tabs are symmetric — everything below is written for **Drivers**; the
**Inspectors** endpoints are identical except: swap `drivers` → `inspectors` in
the path, there is **no `sub_role`**, `role_label` is always `"Inspector"`, and
the status field is `inspector_status` (the `?status=` param maps to it).

> **Inspectors are list-only.** The Inspectors tab has **no detail screen** — its
> cards show just initials/avatar, name, `"inspector · {phone}"`, and the status
> badge, all of which the list item already returns. The `GET /inspectors/{id}/`
> endpoint still exists and works (and returns the same rich blocks as the driver
> detail), but the app does not render an inspector detail page. The **detail
> screen below is the Drivers tab only.**

Mapping the screen → endpoints:

| Screen element | Endpoint |
|---|---|
| Drivers tab — worker cards | `GET /api/shop/v1/drivers/` |
| Inspectors tab — worker cards | `GET /api/shop/v1/inspectors/` |
| Driver **detail** screen (Drivers tab only — inspectors have no detail) | `GET /api/shop/v1/drivers/{id}/` |
| Status filter chips (Active / Invited / Suspended) | `?status=active\|invited\|suspended` |
| Hire Driver / Add Driver (create form) | `POST /api/shop/v1/drivers/hire/` |
| Add Inspector (create form) | `POST /api/shop/v1/inspectors/hire/` |
| **Edit profile** (name / email / role / license / status — one form) | `PATCH /api/shop/v1/drivers/{id}/` · `PATCH /api/shop/v1/inspectors/{id}/` |
| Documents section — upload a file | `POST /api/shop/v1/drivers/{id}/documents/` |
| Documents — verify (FRONT ✓ / BACK ✓) or remove a doc | `PATCH` / `DELETE /api/shop/v1/drivers/{id}/documents/{doc_id}/` · `PATCH` / `DELETE /api/shop/v1/inspectors/{id}/documents/{doc_id}/` |
| Suspend / edit / remove a worker | `PATCH` / `DELETE /api/shop/v1/drivers/{id}/` |

---

**1. List drivers — `GET /api/shop/v1/drivers/`**

Returns the shop's drivers as worker cards. `?status=` filters on `driver_status`
(`active`, `invited`, `suspended`; `assigned` / `inactive` also exist in the model
but aren't surfaced as filter chips). Omit `?status=` for all.

Each item:
```json
{
  "id": 12,
  "user": { "id": 88, "username": "ravi_k", "phone": "+9198••••3210", "email": "ravi@example.com" },
  "name": "Ravi Kumar",
  "profile_picture": "https://cdn.bunny.net/…/ravi.jpg",
  "driver_status": "active",
  "sub_role": "wash_hire",
  "role_label": "Wash + hire driver",
  "jobs_count": 47,
  "on_job": true,
  "license_number": "KA0120201234567",
  "license_expiry": "08-2027",
  "license_verified": true,
  "license_status": "verified",
  "vehicle_classes": ["hatchback", "sedan", "suv"],
  "rating": "4.8",
  "documents": [
    { "id": 3, "kind": "license", "name": "DL front", "file_url": "https://cdn.bunny.net/…/dl.jpg", "verified": true, "uploaded_at": "2026-05-01T09:12:00Z" }
  ],
  "documents_count": 1
}
```

| Field | Notes |
|---|---|
| `role_label` | Derived from `sub_role`: `wash` → "Wash driver", `wash_hire` → "Wash + hire driver", `hire` → "Hire driver". Inspectors are always "Inspector". |
| `jobs_count` | Count of **completed** `WorkerEarning` rows for this worker, **excluding incentives**. |
| `on_job` | `true` if the driver has a **live assigned `BookingAssignment` today**. **Decoupled from `driver_status`** — a driver can be `"active"` **and** `on_job: true` ("Active · On a job"). |
| `license_status` | `"verified"` when `license_verified` is true, else `"pending"`. |
| `vehicle_classes` | Canonical vehicle types only — `hatchback`, `sedan`, `suv`, `convertible`, `bike` (see [car_wash/vehicle_types.py](../car_wash/vehicle_types.py)). See 🔴 gap below. |
| `documents` / `documents_count` | The worker's `WorkerDocument` rows (license / aadhaar / police_verification / other). |

---

**1a. Driver / Inspector detail — `GET /api/shop/v1/drivers/{id}/`**

The **detail screen** for one worker (inspectors:
`GET /api/shop/v1/inspectors/{id}/`). Returns **everything the list item returns**
(see above) **plus** the detail-only blocks below. These blocks are `null` /
absent on the list endpoint and **populated only on retrieve**.

Detail-only fields:
```json
{
  "active_job": {
    "kind": "driver_hire",
    "booking_type": "driver_inspection",
    "booking_id": 412,
    "reference": "SR-DR-20260529-012",
    "stage": "On trip",
    "stage_code": "in_progress",
    "reason": "Hospital Assistance",
    "location": {
      "text": "NH66, near Kalarcode",
      "latitude": 9.51, "longitude": 76.34,
      "updated_at": "2026-06-21T09:40:00+05:30",
      "source": "last_status_event"
    }
  },
  "this_week": { "jobs": 6, "earnings": "4200.00" },
  "jobs_done": 47,
  "joined": "2025-11-02"
}
```

| Field | Notes |
|---|---|
| `active_job` | The **LIVE / ON A JOB** card, or `null` when idle. |
| `active_job.kind` | `driver_hire` \| `inspection` \| `carwash`. |
| `active_job.booking_type` | `driver_inspection` \| `carwash` — picks which booking the **Open booking** action links to. |
| `active_job.booking_id` · `reference` | The live booking's id and reference. |
| `active_job.stage` / `stage_code` | Human label + code of the booking's current status (e.g. "On trip" / `in_progress`). |
| `active_job.reason` | DI `reason_for_hire` or trip-type label; **`null` for carwash**. |
| `active_job.location` | **Last reported** position — the most recent status-event of the DI request (captured at OTP start / arrival). **`null` for carwash** (no status-event location feed). See 🟡 gap below. |
| `this_week` | `{ "jobs": <int>, "earnings": "<decimal string>" }` for the current week (**Monday → Sunday, IST**), counting **non-incentive** `WorkerEarning` rows. |
| `jobs_done` | **Lifetime** non-incentive `WorkerEarning` count (the Profile "Jobs done" line). |
| `joined` | Account `date_joined` date — the Profile **"Joined"** line. |

> **No live GPS.** `active_job.location` is the **last status-event position**, not a
> live feed — there is **no live GPS tracking**, so there is **no "MOVING" state** and
> the position can be **stale** (hence `updated_at` + `source: "last_status_event"`).

**Profile block → existing fields.** The detail "Profile" panel maps to:
`phone`, `email` (`user.email`), `license_number`, `license_expiry`,
`license_status` / `license_verified` (the **Verification ✓**), and `joined`.

**Documents section.** Uses each `WorkerDocument`'s `front_verified` /
`back_verified` for the **FRONT ✓** / **BACK ✓ / —** ticks (upload in **§8.3**,
verify / rename / delete in **§8.5**); `documents_count` is the number of
`WorkerDocument` rows.

**Assigned Role selector.** Maps to `sub_role` (drivers only) — **PATCHable**
`wash` \| `wash_hire` \| `hire` via `PATCH /api/shop/v1/drivers/{id}/` (see
**§8.4**). See 🟡 gap below re: the "Inspector" chip.

**Card actions.**
- **Reassign** → the **existing** assign endpoints, by `active_job.booking_type`:
  carwash → `POST /api/booking/v1/bookings/{id}/assign-driver/`; DI →
  `POST /api/booking/v1/driver-inspection-requests/{id}/assign/` (see §4).
- **Open booking** → the booking detail for `active_job.booking_type` +
  `booking_id` (carwash booking detail or DI request detail — see §4).

---

**2. Hire a driver — `POST /api/shop/v1/drivers/hire/`**

The **Hire Driver / Add Driver** form. Creates a `User(role=driver)` **and** the
`Drivers` record in one call, scoped to the admin's shop.

- Body:
```json
{
  "full_name": "Ravi Kumar",
  "phone": "+919812345678",
  "email": "ravi@example.com",
  "sub_role": "wash_hire",
  "vehicle_classes": ["hatchback", "sedan", "suv"],
  "license_number": "KA0120201234567",
  "license_expiry": "08-2027",
  "license_verified": true
}
```

| Form element | Field | Notes |
|---|---|---|
| Full name | `full_name` | Required. |
| Phone | `phone` | Required. `409` if a user with this phone already exists. |
| Email | `email` | Optional. |
| Role (Wash / Wash + hire / Hire) | `sub_role` | `wash` / `wash_hire` / `hire`. **Drivers only** — omit for inspectors. |
| Vehicle classes chips | `vehicle_classes` | Array of canonical types — see 🔴 gap below. |
| License number | `license_number` | |
| License expiry | `license_expiry` | Accepts `"MM-YYYY"` (e.g. `"08-2027"`). |
| License verified | `license_verified` | Bool. |

- **The driver is created with `driver_status="active"`.** Per the current product
  decision there is **no invite/SMS workflow** — the create path sets status to
  `active` and sends **no SMS** (see 🟡 gap below).
- `409` if the phone already belongs to a user.
- Response (201): the created worker, same shape as the list item above.

> The **inspector** equivalent is `POST /api/shop/v1/inspectors/hire/` — identical
> body **minus `sub_role`**, and the record is created with `inspector_status="active"`.

---

**3. Upload a worker document — `POST /api/shop/v1/drivers/{id}/documents/`**

The form's / detail screen's **Documents** section. **Multipart** upload of one
side of a `WorkerDocument` (file + kind + side) to BunnyCDN; the saved row is
attached to this driver (the inspector equivalent is
`POST /api/shop/v1/inspectors/{id}/documents/`). `WorkerDocument` is owned by
**exactly one** of driver/inspector (XOR).

- Body (`multipart/form-data`):

| Field | Notes |
|---|---|
| `file` | The document file → uploaded to BunnyCDN → `front_file_url` / `back_file_url`. |
| `kind` | One of `license`, `aadhaar`, `police_verification`, `other`. |
| `side` | `front` \| `back` (default `front`) — which side this file is. |
| `name` | Optional display label. |

- **Front / back behaviour.** Uploading the **missing side** of an existing
  same-`kind` document fills that side **in-place** — so a single `WorkerDocument`
  row accrues **both** front + back (e.g. upload `side=front` then `side=back` for
  `kind=license` → one row with both files). If no same-`kind` row is missing that
  side, a **new row** is created.
- Response (201): the `WorkerDocument`:
```json
{
  "id": 7, "kind": "license", "kind_label": "Driving Licence", "name": null,
  "front_file_url": "https://cdn…/front.jpg", "front_verified": true,
  "back_file_url": "https://cdn…/back.jpg",  "back_verified": false,
  "file_url": null, "verified": false,
  "uploaded_at": "…", "updated_at": "…"
}
```

| Field | Notes |
|---|---|
| `front_file_url` / `back_file_url` | The two uploaded sides (either may be `null` until uploaded). |
| `front_verified` / `back_verified` | Per-side verification → the detail screen's **FRONT ✓** / **BACK ✓ / —** ticks. |
| `file_url` / `verified` | **Deprecated** single-file fields, kept for **back-compat** only. |
| `kind_label` | Human label for `kind` (e.g. `license` → "Driving Licence"). |

---

**4. Edit profile / suspend / remove — `PATCH` / `DELETE /api/shop/v1/drivers/{id}/`**

The detail screen's **Edit profile** form patches **both** the `Drivers` row
**and** the linked `User` account in **one PATCH** (the inspector equivalent is
`PATCH /api/shop/v1/inspectors/{id}/`). All fields are **optional** — it's a
partial update, so send only the changed ones.

- Sample body (editing name + email + verification + role together):
```json
{
  "full_name": "Ravi Kumar",
  "email": "ravi.kumar@example.com",
  "license_verified": true,
  "sub_role": "wash_hire"
}
```
- Response (200): the updated worker — **same shape as the detail/list item**
  (nested `user`, computed `name`, etc.). See note on write-only inputs below.

Editable field set:

| Form element | Field | Lands on | Notes |
|---|---|---|---|
| Full name | `full_name` | **User** | Split on the first space → `first_name` / `last_name`. **Write-only.** |
| Email | `email` | **User** | Unique across accounts. **Write-only.** A duplicate email on another account → `400 {"email": "This email is already in use."}`. |
| Status (Active / Inactive / Suspended / Invited) | `driver_status` | Drivers | e.g. suspend with `{ "driver_status": "suspended" }`; re-activate with `active`. |
| Assigned Role (Wash / Wash + hire / Hire) | `sub_role` | Drivers | `wash` \| `wash_hire` \| `hire`. **Drivers only** (inspectors have no `sub_role`). |
| Vehicle classes chips | `vehicle_classes` | Drivers | Array — validated against the canonical enum (see 🔴 gap below). |
| License number | `license_number` | Drivers | |
| License expiry | `license_expiry` | Drivers | A `DateField` — PATCH expects an **ISO date `YYYY-MM-DD`** (the `hire` / create form additionally accepts `"MM-YYYY"`). |
| Verification ✓ | `license_verified` | Drivers | Bool — drives `license_status`. |
| Phone | `phone` | Drivers / Inspectors | Present on both worker models. |
| Title | `title` | Drivers / Inspectors | Present on both worker models. |
| Masked phone | `masked_phone` | Drivers / Inspectors | Present on both worker models. |

> **Write-only account inputs.** `full_name` and `email` are **write-only** —
> they are accepted on PATCH but **never echoed back**. The read response still
> returns the nested **`user`** object (with the saved `first_name` /
> `last_name` / `email`) and the computed **`name`** string.

- **Inspectors:** same field set **minus `sub_role`**, and the status field is
  **`inspector_status`** (e.g. `{ "inspector_status": "suspended" }`).
- **Remove** → `DELETE /api/shop/v1/drivers/{id}/`.

---

**5. Verify / rename / delete a document — `PATCH` / `DELETE /api/shop/v1/drivers/{id}/documents/{doc_id}/` (inspectors: `/api/shop/v1/inspectors/{id}/documents/{doc_id}/`)**

Backs the detail screen's per-document **FRONT ✓** / **BACK ✓** verification
toggles and the document **remove** action (inspectors:
`/api/shop/v1/inspectors/{id}/documents/{doc_id}/`). Complements the upload
endpoint in **§8.3** (which adds files) — this edits/removes an existing
`WorkerDocument`. `IsAdmin`.

- **PATCH** — send any of:

| Field | Notes |
|---|---|
| `front_verified` | Bool — the **FRONT ✓** tick. String values are accepted: `"1"` / `"true"` / `"yes"` → true (case-insensitive); any other string → false. |
| `back_verified` | Bool — the **BACK ✓** tick (same string-bool parsing). |
| `verified` | Bool — the deprecated single-file flag (same string-bool parsing). |
| `name` | New display label. |

  Returns **200** with the updated `WorkerDocument` (same shape as the §8.3
  upload response). An **empty body / no editable fields → 400**. A `doc_id`
  that doesn't belong to this worker → **404**.

- **DELETE** — removes the document row → **204 No Content**.

---

### Flagged gaps

> **🔴 Vehicle-class enum mismatch.** The mockup's **"Compact SUV"** and
> **"Premium SUV"** chips are **not** in the canonical vehicle-type enum — the only
> valid values are `hatchback`, `sedan`, `suv`, `convertible`, `bike`
> ([car_wash/vehicle_types.py](../car_wash/vehicle_types.py)). The API **rejects**
> `compact_suv` / `premium_suv`. Either the app maps those chips to canonical types
> (e.g. both → `suv`) **or** the enum is extended. **Flag for product** — until
> resolved, only send canonical values in `vehicle_classes`.

> **🟡 "Invited" status + "Send Invite" SMS workflow (not wired).** The data model
> keeps `invited` as a valid status and the form copy says **"Send Invite"**, but
> **no invite/OTP-SMS flow exists yet** (per the current product decision).
> Admin-created workers go **straight to `active`** with no SMS sent. The `invited`
> status chip and the "Send Invite" wording are **retained in the model/UI for the
> future** but are inert today — documented as a **planned follow-up**.

> **🟡 No live location.** `active_job.location` is the **last status-event
> position**, not live GPS. The mockup's **"MOVING · Updated just now"** implies
> real-time tracking, which is **not implemented** (would need a driver-location
> ping model/endpoint). Documented as a **follow-up**.

> **🟡 "Inspector" not selectable in a driver's role selector.** The mockup's
> **Assigned Role** chips show **Wash / Wash + hire / Hire / Inspector** together,
> but Drivers and Inspectors are **separate models**. On a driver only
> `sub_role` ∈ {`wash`, `wash_hire`, `hire`} is editable; switching a driver to an
> Inspector is a **model change, not a `sub_role` flip** — **out of scope** (no
> convert flow).

---

## 9 · Customers

The admin **Customers** screen — a searchable, filterable, sortable list of
customer cards (avatar + name, phone, Active/Blocked badge, and per-customer
booking/spend stats), with a **Filter** sheet, a **Sort** sheet, and a search
box. One list endpoint backs it. Served by `UserViewSet.list` with
`CustomerListSerializer`
([accounts/views/user_viewset.py](../accounts/views/user_viewset.py),
[accounts/serializers/customer_list.py](../accounts/serializers/customer_list.py));
the filter/sort/annotation helpers live in
[accounts/views/_customer_query.py](../accounts/views/_customer_query.py).

- **Scope / permissions:** `IsOwnerOrAdmin`. An `admin` / `superadmin` sees **all**
  customers (every `role` ∈ {`user`, `driver`} account); a regular `user`/`driver`
  hitting the endpoint sees **only themselves** (the queryset is narrowed to their
  own id). Pagination: standard `{count, next, previous, results}` envelope — the
  screen's "8 customers" label is `count`.

> The list path is the **canonical** `GET /api/accounts/v1/superadmin/customers/`.
> The older `…/superadmin/users/` route is kept registered as a
> **backwards-compatible alias** to the same viewset — prefer `customers/`.

Mapping the screen → the list call:

| Screen element | Source |
|---|---|
| Search bar ("Search name or phone") | `?search=` (phone, first name, last name, username) |
| "8 customers" count | `count` in the paginated envelope |
| Card — avatar initials | `initials` |
| Card — name | `full_name` |
| Card — phone | `phone` |
| Card — Active / Blocked badge | `is_active` (`true` = Active, `false` = Blocked) |
| Card — bookings stat | `bookings_count` |
| Card — "₹11,200 spent" | `total_spent` |
| Card — "Last 29-May-2026" | `last_booking_date` |
| **Filter** → STATUS chips | `?status=active\|blocked` |
| **Filter** → JOINED chips | `?joined=any\|30d\|90d\|year` |
| **Filter** → BOOKING COUNT chips | `?booking_count=any\|1-5\|6-20\|20plus` |
| **Sort** sheet | `?sort=name\|spend\|bookings\|recent` |
| Active/Blocked toggle (action) | `POST …/customers/{id}/block/` (with reason) · `…/unblock/` (see below) |
| + / "Add new customer" | `POST /api/accounts/v1/admin/customers/` (see [§4.2](#42--new-request-admin-phone-in)) |
| Card / row → open **customer detail** | `GET …/customers/{id}/` (Info / Garage / History tabs — see below) |
| Detail — **Info** tab (stat strip · saved addresses · founder notes) | `GET …/customers/{id}/` |
| Detail — **Garage** tab (saved vehicles) | `vehicles[]` from `GET …/customers/{id}/` |
| Detail — **History** tab (paginated booking history) | `GET …/customers/{id}/history/` (see below) |
| Detail — edit **Founder notes** | `PATCH …/customers/{id}/` `{ "founder_notes" }` |
| Detail — **Block** dialog (reason + notes) | `POST …/customers/{id}/block/` (see below) |

---

**1. List — `GET /api/accounts/v1/superadmin/customers/`**

Returns customers as cards. Implemented by `UserViewSet.list`.

- **Query params:**

  | Param | Type | Purpose |
  |---|---|---|
  | `search` | string | Matches `phone`, `first_name`, `last_name`, or `username`. |
  | `status` | enum | STATUS chip → maps to `is_active`: `active` → `is_active=true`; `blocked` → `is_active=false`. Omit for all. |
  | `joined` | enum | JOINED chip on `date_joined`: `30d` (last 30 days) / `90d` (last 90 days) / `year` (this calendar year). `any`/omit → no filter. |
  | `booking_count` | enum | BOOKING COUNT chip on the (non-cancelled) `bookings_count`: `1-5` / `6-20` / `20plus`. `any`/omit → no filter. |
  | `sort` | enum | Sort sheet — see below. Default is Name A–Z when omitted. |
  | `page`, `page_size` | int | Standard pagination. |

  **Sort options (`sort`):**

  | Value | Sort sheet label | Order |
  |---|---|---|
  | `name` | Name A–Z | `first_name`, `last_name` ascending (the default). |
  | `spend` | Top spenders | `total_spent` descending. |
  | `bookings` | Most bookings | `bookings_count` descending. |
  | `recent` | Recently active | latest activity date descending, **nulls last** (customers with no activity sort to the end). |

- **Request example** — Active customers who joined this year, with 6–20 bookings,
  sorted by spend:
```
GET /api/accounts/v1/superadmin/customers/?status=active&joined=year&booking_count=6-20&sort=spend
```

- **Response (200)** — standard paginated envelope; each result is a card:
```json
{
  "count": 8,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 7,
      "full_name": "Anjali Thomas",
      "initials": "AT",
      "phone": "+919847022119",
      "is_active": true,
      "bookings_count": 14,
      "total_spent": "11200.00",
      "last_booking_date": "2026-05-29"
    },
    {
      "id": 12,
      "full_name": "Ramesh Kurup",
      "initials": "RK",
      "phone": "+919447056789",
      "is_active": false,
      "bookings_count": 2,
      "total_spent": "0.00",
      "last_booking_date": null
    }
  ]
}
```

Field reference:

| Field | Type | Meaning |
|---|---|---|
| `id` | int | Customer (`User`) id — used by the block/unblock/history actions. |
| `full_name` | string | `first_name` + `last_name`; falls back to `username` when both are blank. |
| `initials` | string | Avatar initials (e.g. `"AT"`). |
| `phone` | string \| null | Customer phone (the "Search name or phone" box also matches this). |
| `is_active` | bool | The Active/Blocked badge — `true` = Active, `false` = Blocked. |
| `bookings_count` | int | **Non-cancelled** bookings across both types (carwash + driver/inspection), combined. |
| `total_spent` | string | Decimal string of **PAID** bookings only: carwash with a captured payment **plus** driver/inspection with `is_paid=true`. `"0.00"` when none. |
| `last_booking_date` | string \| null | ISO date — latest `appointment_date` across both booking types (the "Last 29-May-2026" line). `null` if the customer has no bookings. |

> **Stats are annotated in SQL.** `bookings_count`, `total_spent`, and the last-activity
> date are computed as correlated subqueries on the list queryset (carwash and
> driver/inspection aggregated separately, then summed, so the two relations never
> join-multiply). This keeps the list a **single query** (no N+1) and lets the
> `spend` / `bookings` / `recent` sorts and the `booking_count` filter run at the
> DB level. (The detail/picker paths fall back to a per-row Python helper.)

> **What counts.** "Spent" (`total_spent`) counts **only PAID** bookings — a
> carwash booking with a captured payment, or a DI request with `is_paid=true`.
> "Bookings" (`bookings_count`) counts everything **except cancelled**. The two
> metrics therefore don't have to match (an unpaid-but-active booking lifts the
> count, not the spend).

---

**2. Customer detail — `GET /api/accounts/v1/superadmin/customers/{id}/`**

Backs the **customer detail** screen — the header (avatar, name, phone, Active/Blocked
badge), the **BOOKINGS / SPENT / LAST / AGE** stat strip, the **Info** tab (saved
addresses + founder notes), and the **Garage** tab (saved vehicles). Served by
`UserViewSet.retrieve` with `CustomerDetailSerializer`
([accounts/views/user_viewset.py](../accounts/views/user_viewset.py),
[accounts/serializers/customer_detail.py](../accounts/serializers/customer_detail.py)).

- **Scope / permissions:** `IsOwnerOrAdmin`. An `admin` / `superadmin` may fetch **any**
  customer; a regular `user` / `driver` can only fetch **their own** id (the queryset is
  narrowed to themselves, so any other id `404`s).

- **Response (200):**
```json
{
  "id": 7,
  "full_name": "Anjali Thomas",
  "initials": "AT",
  "phone": "+919847022119",
  "email": "anjali@example.com",
  "is_active": true,
  "created_at": "2025-12-01T09:14:00Z",
  "founder_notes": "VIP — prefers weekend slots.",
  "stats": {
    "bookings_count": 14,
    "total_spent": "11200.00",
    "last_booking_date": "2026-05-29",
    "joined": "2025-12-01T09:14:00Z",
    "age": "6 months"
  },
  "addresses": [
    {
      "id": 31,
      "label": "Home",
      "address_line": "12 Marine Drive",
      "landmark": "Near jetty",
      "city": "Kochi",
      "state": "Kerala",
      "pincode": "682031",
      "latitude": "9.9784",
      "longitude": "76.2752",
      "is_default": true,
      "created_at": "2025-12-01T09:20:00Z",
      "updated_at": "2025-12-01T09:20:00Z"
    }
  ],
  "vehicles": [
    {
      "id": 18,
      "user": "anjali",
      "car_type": "SUV",
      "brand_model": "Hyundai Creta",
      "registration": "KL07AB1234",
      "image_url": "https://…/cars/creta.jpg",
      "is_favourite": false,
      "is_primary": true,
      "booking_count": 9,
      "created_at": "2025-12-01T09:25:00Z",
      "updated_at": "2026-02-10T11:00:00Z"
    }
  ],
  "block_reason": null,
  "block_notes": null,
  "blocked_at": null,
  "blocked_by_name": null
}
```

Field reference:

| Field | Type | Meaning |
|---|---|---|
| `id` | int | Customer (`User`) id. |
| `full_name` | string | `first_name` + `last_name`; falls back to `username`. |
| `initials` | string | Avatar initials. |
| `phone` | string \| null | Customer phone. |
| `email` | string \| null | Customer email — may be `null`. |
| `is_active` | bool | The Active / Blocked badge (`true` = Active). |
| `created_at` | ISO datetime | Account-record creation stamp. |
| `founder_notes` | string \| null | Admin-editable internal note (the Info tab "Founder notes" card). The **only** writable field here — see (3) below. |
| `stats` | object | Drives the **BOOKINGS / SPENT / LAST / AGE** stat strip (see below). |
| `addresses` | array | The customer's **saved addresses** (Info tab "Saved addresses" card). **Read-only** here — managed by the customer app. |
| `vehicles` | array | The customer's **saved vehicles** (Garage tab). **Read-only** here — managed by the customer app. |
| `block_reason` | enum \| null | Current block reason (set by the Block action). `null` when active. |
| `block_notes` | string \| null | Free-text note recorded with the current block. |
| `blocked_at` | ISO datetime \| null | When the customer was blocked. |
| `blocked_by_name` | string \| null | Name (or username) of the admin who blocked them. |

`stats` fields:

| Field | Type | Meaning |
|---|---|---|
| `bookings_count` | int | **Non-cancelled** bookings across carwash + driver/inspection (matches the list's `bookings_count`). |
| `total_spent` | string | Decimal string of **PAID** bookings only (carwash with a captured payment + DI with `is_paid=true`). |
| `last_booking_date` | ISO date \| null | Latest `appointment_date` across both booking types; `null` if none. |
| `joined` | ISO datetime | The account's `date_joined` — drives the "Joined" line. |
| `age` | string \| null | Smart tenure label derived from `date_joined`: e.g. `"Just joined"`, `"1 week"`, `"2 weeks"`, `"6 months"`, `"1 year"`, `"2 years"`. |

- **Saved addresses** (each item): `label`, `is_default` (DEFAULT marker), `address_line`,
  `city`, `state`, `pincode`, `landmark` (plus `id`, `latitude`/`longitude`, timestamps).
- **Vehicles** (each item): `brand_model`, `car_type`, `registration` (the plate),
  `is_primary` (DEFAULT badge), and `booking_count` — that vehicle's **non-cancelled**
  carwash + DI bookings (computed only on this admin detail path).

> **Read-only vs. editable.** On this screen only `founder_notes` is writable (via
> `PATCH`, below). `addresses` and `vehicles` are **managed by the customer app** and
> are read-only here; the block fields are set via the block/unblock actions.

> `joined` and `age` both derive from the account's **`date_joined`** (the project's
> `created_at` stamp matches it for customers). `age` is a humanized label, not a count.

---

**3. Edit founder notes — `PATCH /api/accounts/v1/superadmin/customers/{id}/`**

The Info tab's editable **Founder notes** card. `IsOwnerOrAdmin`. Served by
`UserViewSet.partial_update` with `CustomerDetailSerializer`.

- **Body:** `{ "founder_notes": "Called re: refund — resolved." }`
- **Response (200):** the full detail payload (as in (2) above) with the updated
  `founder_notes`.

> `founder_notes` is the **only** writable field on the detail serializer — everything
> else (`addresses`, `vehicles`, `stats`, block state, identity fields) is read-only.
> Addresses and vehicles **cannot** be edited through this endpoint; they are owned by
> the customer app.

---

**4. Block / Unblock — `POST …/customers/{id}/block/` · `…/customers/{id}/unblock/`**

These actions back the card's **Active/Blocked** toggle and the detail screen's **Block**
dialog — they flip the customer's `is_active` and record an audit trail. `IsAdmin`
(admin or superadmin).

- **`POST /api/accounts/v1/superadmin/customers/{id}/block/`** → `is_active=false`
  (Blocked). The detail screen's Block dialog sends a reason + optional note:

  - **Body:** `{ "reason": "<enum>", "notes": "<optional free text>" }`
  - `reason` is **optional**, but if given it must be one of:
    `frequent_no_shows`, `abusive_behavior`, `payment_issues`, `fake_bookings`,
    `other` — an invalid value returns **`400`** `{ "reason": "Invalid reason. Allowed: …" }`.
  - `notes` is optional free text.
  - Sets `is_active=false` and records `block_reason`, `block_notes`, `blocked_at`,
    and `blocked_by` on the user, and appends a `CustomerBlockEvent` audit row
    (`action="block"`).
  - **Response (200):**
```json
{
  "id": 7,
  "is_active": false,
  "block_reason": "frequent_no_shows",
  "block_notes": "Missed 3 confirmed slots.",
  "blocked_at": "2026-06-21T10:05:00Z"
}
```

- **`POST /api/accounts/v1/superadmin/customers/{id}/unblock/`** → `is_active=true`
  (Active). Clears `block_reason` / `block_notes` / `blocked_at` / `blocked_by`, and
  logs a `CustomerBlockEvent` (`action="unblock"`).
  - **Response (200):** `{ "id": 7, "is_active": true }`.

- After either, the next list/detail read returns the customer with the updated
  `is_active` badge and block fields (and the list's `?status=` filter reflects it).

> **In-flight vs. new bookings — enforced.** The Block dialog copy promises that a
> blocked customer "won't be able to make new bookings" while in-flight bookings
> continue. This is now **enforced** at the self-serve booking-create paths: a
> blocked customer (`is_active=false`) is rejected with **`403`** and the message
> *"This account is blocked and can't make new bookings…"* on
> ([booking/views/create_booking_and_initiate_payment_view.py](../booking/views/create_booking_and_initiate_payment_view.py)
> carwash booking create) and the D&I
> ([booking/views/driver_inspection_booking_view_set.py](../booking/views/driver_inspection_booking_view_set.py)`.create`)
> request-create **and** instant ("now") booking paths.
> - **In-flight bookings are unaffected** — already-placed bookings continue
>   through their lifecycle (assignment, washing, completion); only *new* creates
>   are blocked.
> - **Admin manual bookings on behalf of a customer are NOT blocked** — the
>   admin phone-in / manual flows (§4.2, §7) can still book for anyone, blocked or
>   not. The guard targets the customer's own self-serve create only.

---

**5. Add new customer — `POST /api/accounts/v1/admin/customers/`**

The **+ / "Add new customer"** flow. Same endpoint documented under the manual
phone-in request — see **[§4.2 · Add new customer](#42--new-request-admin-phone-in)**
(phone + name, optional OTP; returns a `CustomerListSerializer` card; `409` if the
phone already exists). Not duplicated here.

---

**6. Customer booking history — `GET …/customers/{id}/history/`**

Backs the customer detail **History** tab. `IsAdmin`. Returns the customer's
carwash **and** driver/inspection bookings merged and sorted newest-first by
`appointment_date`, each tagged with a `kind` (`carwash`, or the DI `request_type`),
then **paginated**.

- **Query params:**

  | Param | Type | Purpose |
  |---|---|---|
  | `page` | int | 1-based page number. Default `1`. |
  | `page_size` | int | Rows per page. Default `20`, **max `100`** (clamped). |

- **Response (200)** — a **custom** envelope (note the extra `page` / `page_size`
  keys; this differs from the standard DRF list envelope):
```json
{
  "count": 37,
  "page": 1,
  "page_size": 20,
  "next": "https://…/customers/7/history/?page=2&page_size=20",
  "previous": null,
  "results": [
    {
      "reference": "CW-2026-00412",
      "kind": "carwash",
      "appointment_date": "2026-05-29",
      "amount": "800.00",
      "status": "completed",
      "display_status": "Completed",
      "shop_name": "Sparkle Wash, Kochi"
    },
    {
      "reference": "DI-2026-00088",
      "kind": "driver",
      "appointment_date": "2026-05-21",
      "amount": "1500.00",
      "status": "completed",
      "display_status": "Completed"
    }
  ]
}
```

- **Envelope fields:** `count` (total merged rows across all pages), `page`,
  `page_size`, `next` / `previous` (absolute page URLs or `null`), and `results`
  (this page's rows). The History tab's "Showing N of M · 20 per page" maps to
  `results` length / `count` / `page_size`.

- **Row fields:** each result is a `BookingListSerializer` /
  `DriverInspectionListSerializer` card (see
  [§4.3](#43--carwash-segment-list--filter--sort) / [§4](#4--bookings)) plus a `kind`
  field — `"carwash"` for carwash rows, or the DI `request_type` (e.g. `"driver"`,
  `"inspection"`) for D&I rows. Common fields: `reference`, `appointment_date`,
  `amount`, `status` / `display_status`; `shop_name` is present on carwash rows only.

---

## 10 · Refund Log

The **Refund Log** screen — a **unified feed** of every refund across **carwash**
and **driver/inspection** bookings — plus a **refund detail** screen (with a
stepper and status-driven action buttons), the standalone **New Refund** create
form, and the **Approve / Mark Paid / Decline** lifecycle actions.
**Superadmin-only** (`IsSuperAdmin`).

This sits alongside the per-booking **New Refund** screen in §5: §5 refunds a
*known* booking (opened by id, with pre-fill); the Refund Log here is the
*cross-booking ledger* (search/filter/sort), the per-refund detail screen, and a
standalone create-by-reference form.

Refunds now follow a real **Requested → Approved → Paid** lifecycle (with
**Declined** as a terminal off-ramp). A customer-requested refund is *approved*
first (creating a refund row; no money moves) and *marked paid* later (money
moves). Admin-initiated standalone refunds (§10.5 and §5) still issue **directly
to Paid**, bypassing the approve step. See the status-model callout in §10.1.

Mapping the screen → endpoints:

| Screen element | Endpoint |
|---|---|
| List (the feed) | `GET /api/booking/v1/admin/refunds/` |
| Search · Filter (status / reason / days) | `GET …/admin/refunds/?search=&status=&reason=&days=` |
| Sort sheet | `GET …/admin/refunds/?sort=` |
| Refund **detail** screen | `GET /api/booking/v1/admin/refunds/detail/{id_or_reference}/` |
| **Approve** button (detail) | `POST /api/booking/v1/admin/refunds/approve/` |
| **Mark Paid** button (detail) | `POST /api/booking/v1/admin/refunds/mark-paid/` |
| **New Refund** (standalone form) | `POST /api/booking/v1/admin/refunds/create/` |
| **Decline** a refund request | `POST /api/booking/v1/admin/refunds/decline/` |

---

**1. Refund Log — `GET /api/booking/v1/admin/refunds/`**

A unified, paginated feed across carwash + driver/inspection refunds. The response
is a **custom** paginated envelope (note the extra `page` / `page_size` keys; this
differs from the standard DRF list envelope):

```json
{
  "count": 42,
  "page": 1,
  "page_size": 20,
  "next": "https://…/admin/refunds/?page=2&page_size=20",
  "previous": null,
  "results": [
    {
      "id": 9,
      "reference": "RF-20260620-009",
      "kind": "refund",
      "booking_type": "carwash",
      "booking_id": 412,
      "booking_reference": "DT-412-7a3c",
      "customer_name": "Anil Kumar",
      "customer_phone": "+919876543210",
      "amount": "250.00",
      "percent": "100.00",
      "tier_label": "100%",
      "reason": "cancellation_by_customer",
      "reason_label": "Cancellation by customer",
      "status": "paid",
      "raw_status": "processed",
      "comment": "per call",
      "created_at": "2026-06-20T11:05:00Z",
      "approved_at": "2026-06-20T11:00:00Z",
      "paid_at": "2026-06-20T11:05:00Z"
    },
    {
      "id": null,
      "reference": null,
      "kind": "request",
      "booking_type": "driver_inspection",
      "booking_id": 88,
      "booking_reference": "SR-DR-20260619-0007",
      "customer_name": "Maya R",
      "customer_phone": "+919812345678",
      "amount": "0.00",
      "percent": null,
      "tier_label": null,
      "reason": null,
      "reason_label": null,
      "status": "requested",
      "raw_status": null,
      "comment": null,
      "created_at": "2026-06-19T09:30:00Z",
      "approved_at": null,
      "paid_at": null
    }
  ]
}
```

- **Query params:**

  | Param | Type | Purpose |
  |---|---|---|
  | `search` | string | Booking reference / customer name / phone. |
  | `status` | enum (CSV) | Comma-separated badges: `requested`, `approved`, `paid`, `declined`. OR'd. |
  | `reason` | enum (CSV) | Comma-separated refund reasons: `cancellation_by_customer`, `founder_cancellation`, `service_quality_issue`, `damage_during_wash`, `duplicate_charge`, `other`. OR'd. |
  | `sort` | enum | `recent` (default) · `amount_desc` · `amount_asc` · `status`. |
  | `days` | int | `created_at` window in days. Default `30` (the "Last 30 days" header). `0` or `all` disables the window. |
  | `page` | int | 1-based page number. Default `1`. |
  | `page_size` | int | Rows per page. Default `20`, **max `100`** (clamped). |

- **Sort — `?sort=`:**

  | Sort sheet label | Value | Order |
  |---|---|---|
  | Most recent | `recent` | newest `created_at` first (default) |
  | Amount: high → low | `amount_desc` | `-amount` |
  | Amount: low → high | `amount_asc` | `amount` |
  | By status | `status` | grouped by badge |

- **Result item fields:**

  | Field | Type | Notes |
  |---|---|---|
  | `id` | int \| null | The `BookingRefund` row id; `null` for synthesized `request` items. |
  | `reference` | string \| null | The refund reference (e.g. `RF-20260620-009`); `null` for synthesized `request` items. |
  | `kind` | enum | `"refund"` = a real refund row · `"request"` = a synthesized entry for a booking awaiting a decision. |
  | `booking_type` | enum | `carwash` \| `driver_inspection`. |
  | `booking_id` | int | The underlying booking id. |
  | `booking_reference` | string | `DT-…` (carwash) or `SR-…` (DI) reference. |
  | `customer_name` | string | Booking customer. |
  | `customer_phone` | string | Booking customer phone. |
  | `amount` | string | Refund amount (decimal string; `"0.00"` for requests / declines). |
  | `percent` | string \| null | Tier percent, when set. |
  | `tier_label` | string \| null | Display tier — e.g. `"100%"`, `"70%"`, `"Override"`. |
  | `reason` | enum \| null | Structured refund reason (see the enum above). |
  | `reason_label` | string \| null | Human label for `reason`. |
  | `status` | enum | The **badge**: `requested` \| `approved` \| `paid` \| `declined`. |
  | `raw_status` | enum \| null | The underlying refund-row status (`pending` / `processed` / `declined` / `failed`); `null` for `request` items. |
  | `comment` | string \| null | Free-text note. |
  | `created_at` | ISO datetime | Refund row created (or, for requests, when the booking entered `refund_requested`). |
  | `approved_at` | ISO datetime \| null | When the refund row was approved (created). `null` for `request` items. |
  | `paid_at` | ISO datetime \| null | When the refund was marked paid (money moved). `null` until **Paid**. |

> **Status model (badge ↔ lifecycle).** The 4 badges map onto a real
> **Requested → Approved → Paid** lifecycle (with **Declined** as a terminal
> off-ramp). It spans **both** a booking's `refund_requested` state **and** the
> refund row's outcome:
> - **Requested** — a customer asked: a booking in `refund_requested` with **no**
>   refund row yet. This is a *synthesized* item (`kind="request"`, `id=null`,
>   `reference=null`, `raw_status=null`).
> - **Approved** — an admin approved the request (§10.3 Approve) → a `BookingRefund`
>   row at `raw_status="pending"`. **No money has moved yet** — only an obligation
>   has been recorded.
> - **Paid** — an admin marked it paid (§10.4 Mark Paid) → **money moves**
>   (Razorpay, or manual record-only) and the row reaches `raw_status="processed"`,
>   with `paid_at` set and payment proof captured.
> - **Declined** — an admin rejected the request → `raw_status="declined"` (a ₹0
>   audit row) **or** `raw_status="failed"` (gateway error). Terminal.
>
> Each refund row carries a `reference` (e.g. `RF-20260529-014`), `approved_at`
> (set on Approve), `paid_at` (set on Mark Paid), and payment-proof fields
> (captured at Mark Paid).
>
> **Two paths to Paid.** *Customer-requested* refunds flow
> **Requested → Approve → Mark Paid** (two admin steps; money moves only at the
> end). *Admin-initiated* refunds — the standalone create (§10.5) and the
> per-booking endpoints (§5) — **issue directly to Paid** (`processed`) and
> **bypass** the approve step, since there is no customer request to approve.

---

**2. Refund detail — `GET /api/booking/v1/admin/refunds/detail/{id_or_reference}/`**

The **refund detail** screen for a single refund row. `{id_or_reference}` accepts
the numeric refund **id** *or* its `RF-…` **reference**. Returns the detail payload
including a **stepper** (`steps`) and the status-driven **footer action**
(`next_action`).

```json
{
  "id": 14,
  "reference": "RF-20260529-014",
  "booking_type": "carwash",
  "booking_id": 531,
  "booking_reference": "DT-531-9b1f",
  "customer_name": "Anil Kumar",
  "customer_phone": "+919876543210",
  "amount": "175.00",
  "percent": "70.00",
  "tier_label": "70%",
  "reason": "service_quality_issue",
  "reason_label": "Service quality issue",
  "reason_subtitle": "Customer was unhappy with the wash quality",
  "status": "approved",
  "raw_status": "pending",
  "steps": [
    { "key": "requested", "label": "Requested", "done": true,  "at": "2026-05-29T08:10:00Z" },
    { "key": "approved",  "label": "Approved",  "done": true,  "at": "2026-05-29T09:00:00Z" },
    { "key": "paid",      "label": "Paid",      "done": false, "at": null }
  ],
  "next_action": "mark_paid",
  "payment_proof": {
    "reference": null,
    "screenshot_url": null,
    "on_file": false,
    "required_before_paid": true
  },
  "created_at": "2026-05-29T09:00:00Z",
  "approved_at": "2026-05-29T09:00:00Z",
  "paid_at": null,
  "created_by_name": "Admin User"
}
```

*(The example above is an **Approved** refund: the `requested` + `approved` steps
are `done`, `paid` is still pending, and `next_action` is `"mark_paid"`.)*

- **Fields:**

  | Field | Type | Notes |
  |---|---|---|
  | `id` | int | The `BookingRefund` row id. |
  | `reference` | string | The refund reference, e.g. `RF-20260529-014`. |
  | `booking_type` | enum | `carwash` \| `driver_inspection`. |
  | `booking_id` | int | The underlying booking id. |
  | `booking_reference` | string | `DT-…` (carwash) or `SR-…` (DI) reference. |
  | `customer_name` | string | Booking customer. |
  | `customer_phone` | string | Booking customer phone. |
  | `amount` | string | Refund amount (decimal string). |
  | `percent` | string \| null | Tier percent, when set. |
  | `tier_label` | string \| null | Display tier — `"100%"`, `"70%"`, `"Override"`. |
  | `reason` | enum \| null | Structured refund reason (see §10.1 enum). |
  | `reason_label` | string \| null | Human label for `reason`. |
  | `reason_subtitle` | string \| null | Longer human description / the customer's note. |
  | `status` | enum | The **badge**: `requested` \| `approved` \| `paid` \| `declined`. |
  | `raw_status` | enum | Underlying row status: `pending` / `processed` / `declined` / `failed`. |
  | `steps` | array | The **stepper**. Each item: `{ key: "requested"\|"approved"\|"paid", label, done (bool), at (ISO datetime \| null) }`. |
  | `next_action` | enum \| null | The footer button: `"approve"` · `"mark_paid"` · `null` (terminal). |
  | `payment_proof` | object | `{ reference, screenshot_url, on_file (bool), required_before_paid (true) }` — see §10.4. |
  | `created_at` | ISO datetime | Refund row created. |
  | `approved_at` | ISO datetime \| null | Set on Approve. |
  | `paid_at` | ISO datetime \| null | Set on Mark Paid (`null` until **Paid**). |
  | `created_by_name` | string \| null | Admin who created the refund row. |

> **Detail-screen footer (action by status).** `next_action` (and the buttons the
> screen renders) follow the lifecycle:
>
> | Current status | Footer buttons | `next_action` |
> |---|---|---|
> | **Requested** | Approve · Decline | `"approve"` |
> | **Approved** | Mark Paid · Decline | `"mark_paid"` |
> | **Paid** | *(none — "Refund settled")* | `null` |
> | **Declined** | *(none — "Refund declined")* | `null` |

---

**3. Approve a request — `POST /api/booking/v1/admin/refunds/approve/`**

The detail screen's **Approve** button. Approves a customer's refund **request** (a
booking sitting in `refund_requested`), creating the `BookingRefund` row at
`raw_status="pending"` (badge **Approved**). **No money moves here** — only the
obligation is recorded; settlement happens later via **Mark Paid** (§10.4). The
amount is **cap-checked** (cannot exceed the booking's remaining refundable amount).

- **Body:**

  | Form element | Field | Notes |
  |---|---|---|
  | Booking reference | `booking_reference` | **Required.** Must resolve to a booking in `refund_requested`, else `400`. `404` if the reference is unknown. |
  | Tier (100 / 70 / 0) | `percent` | Maps the tier buttons to a percent (`100` / `70` / `0`). Provide `percent` **or** `amount`. |
  | Override / Amount (₹) | `amount` | Override → a typed rupee amount. Provide `amount` **or** `percent`. Capped at the remaining refundable amount. |
  | Reason chip | `reason` | One of the refund-reason enum (see §10.1). An invalid value → `400`. |
  | Notes | `comment` | Free text. Optional. |

```json
{ "booking_reference": "DT-531-9b1f", "percent": 70,
  "reason": "service_quality_issue", "comment": "approved per call" }
```

- **Effect:** creates the refund row at `raw_status="pending"`, sets `approved_at`,
  assigns a `reference`. The booking leaves `refund_requested` into the approved
  state. **No gateway call.**
- **Response (201):** `{ "refund": { … } }` — the full **detail payload** (same shape
  as §10.2), now showing `status="approved"`, `requested`+`approved` steps done, and
  `next_action="mark_paid"`.

---

**4. Mark Paid — `POST /api/booking/v1/admin/refunds/mark-paid/`**
**(or `POST /api/booking/v1/admin/refunds/{id_or_reference}/mark-paid/`)**

The detail screen's **Mark Paid** button. **This is where money moves.** The refund
must currently be **Approved** (`raw_status="pending"`), else `400`. Fires the
Razorpay refund (unless `mode="manual"`), advances the row to
`raw_status="processed"`, sets `paid_at`, and saves the **payment proof**.

- **Body (JSON or `multipart/form-data`):**

  | Form element | Field | Notes |
  |---|---|---|
  | Which refund | `refund` | The refund **id** or `RF-…` **reference**. Omit when using the URL form `…/refunds/{id_or_reference}/mark-paid/`. |
  | Payment proof reference | `payment_proof_reference` | E.g. `"UPI/AXIS/552210034"` — the transaction/UTR reference. |
  | Screenshot | `screenshot` | Optional file upload (uploaded to **BunnyCDN**); the stored URL is returned as `payment_proof.screenshot_url`. |
  | (advanced) record-only | `mode: "manual"` | Record-only — **skips** the Razorpay gateway, just marks the row paid with the supplied proof. |

```json
{ "refund": "RF-20260529-014",
  "payment_proof_reference": "UPI/AXIS/552210034" }
```

- **Effect:** Razorpay refund is issued (unless `mode="manual"`), `raw_status` →
  `processed`, `paid_at` set, and the proof fields (`payment_proof.reference`,
  `screenshot_url`, `on_file=true`) are captured.
- **Response (200):** `{ "refund": { … } }` — the full **detail payload**, now
  `status="paid"`, all three steps done, `next_action=null` ("Refund settled").

> **Payment proof.** The detail screen labels this *"Payment proof required before
> marking Paid"* and `payment_proof.required_before_paid` is `true`. The endpoint
> **captures** whatever proof is sent (`payment_proof_reference` + optional
> `screenshot`) at this step. Treat supplying proof as a **product requirement**: if
> the server does not strictly reject a Mark-Paid call lacking proof, the
> "required" flag is **product-advisory** and the app should still enforce it
> client-side before sending.

---

**5. New Refund (standalone) — `POST /api/booking/v1/admin/refunds/create/`**

The **New Refund** form (no booking pre-selected — the admin types a reference).
Resolves a carwash (`DT-…`) **or** DI (`SR-…`) booking from `booking_reference`,
then issues a refund via the existing refund service (Razorpay for online payments,
capped at the amount paid).

- **Body:**

  | Form element | Field | Notes |
  |---|---|---|
  | Booking reference | `booking_reference` | **Required.** Resolves a carwash `DT-…` **or** DI `SR-…` booking. `404` if not found. |
  | Tier (100 / 70 / 0) | `percent` | Maps the tier buttons to a percent. Provide `percent` **or** `amount`. |
  | Override / Amount (₹) | `amount` | Override → a typed rupee amount. Provide `amount` **or** `percent`. |
  | Reason chip | `reason` | One of the refund-reason enum (see §10.1). |
  | Notes | `comment` | Free text. Optional. |
  | (advanced) recorded-only | `mode: "manual"` | Record-only — skips the gateway. |
  | (DI only) which payment | `payment_kind` | `advance` \| `balance` — picks which DI payment to refund. |

```json
{ "booking_reference": "DT-412-7a3c", "percent": 100,
  "reason": "cancellation_by_customer", "comment": "per call" }
```

- Issued via the same `issue_refund` service as §5 (Razorpay for online payments;
  cap = amount paid, enforced under a row lock; offline/cash or `mode=manual`
  records a processed refund with no gateway call).
- **Issues directly to Paid.** This is an **admin-initiated** refund, so it
  **bypasses** the Approve step (§10.3): the row is created already at
  `raw_status="processed"` (badge **Paid**), with `paid_at` set. Use the
  **Approve → Mark Paid** flow (§10.3–§10.4) only for *customer-requested* refunds.
- **Response (201):** `{ "refund": { … } }` — the created `BookingRefund` (`id`,
  `reference`, `amount`, `percent`, `reason`, `comment`, `status`,
  `razorpay_refund_id`, …).

> The existing **per-booking** refund endpoints still exist for refunding a
> *known* booking by id (with pre-fill) — see §5:
> `POST /api/booking/v1/admin/refunds/carwash/{booking_id}/` and
> `POST /api/booking/v1/admin/refunds/driver-inspection/{di_booking_id}/`. Like the
> standalone create, these are **admin-initiated** and **issue directly to Paid**
> (`processed`) — they do **not** go through the Approve step. The standalone create
> here is the same operation reached by **reference** instead of by booking id.

---

**6. Decline a refund — `POST /api/booking/v1/admin/refunds/decline/`**

The detail screen's **Decline** button — the terminal off-ramp. Available from
**Requested** *or* **Approved** states (a booking sitting in `refund_requested`).
**No money moves** — it records an audit row and returns the booking to a settled
state. Declined is terminal.

- **Body:**

  | Field | Type | Notes |
  |---|---|---|
  | `booking_reference` | string | **Required.** Must resolve to a booking in `refund_requested`, else `400`. `404` if the reference is unknown. |
  | `reason` | enum \| null | A refund-reason enum value (optional). An invalid value → `400`. |
  | `comment` | string \| null | Free text. Optional. |

- **Effect:** records a `declined` `BookingRefund` (₹0, audit only) and returns the
  booking to a **settled** state — **carwash → `confirmed`**, **DI → `cancelled`**.
- **Response (201):** `{ "refund": { … } }` — the recorded `declined` row.

---

> **Mockup vs. real references.** The New Refund form's mockup shows a
> `DD-KL-…` booking-reference placeholder, but **real references are**
> `DT-{id}-{checksum}` (carwash) and `SR-{DR|IN}-{date}-{seq}` (DI). The app must
> send a **real** reference — `DD-KL-…` is **mockup-only** and will `404`.

---

## 11 · Reviews

The **Reviews** screens — a searchable, filterable, sortable **list** of review
cards plus a single-review **detail** screen. Both are **read-only**. Served by
`AdminReviewListView` / `AdminReviewDetailView`
([shop/views/admin_review.py](../shop/views/admin_review.py)) with
`AdminReviewListSerializer` / `AdminReviewDetailSerializer`
([shop/serializers/admin_review.py](../shop/serializers/admin_review.py)).

- **Permissions:** `IsAdmin` (admin or superadmin).

> **Read-only — no moderation in v0.1.** These endpoints only *read* reviews;
> there are no flag / hide / delete / reply actions. The feed is **carwash
> `ShopReview` only** — every card shows a shop, and only `ShopReview` carries a
> shop FK. Driver/inspector reviews are **out of scope for v0.1**.

Mapping the screens → endpoints:

| Screen element | Endpoint |
|---|---|
| Reviews list (cards) | `GET /api/shop/v1/admin/reviews/` |
| Search / rating / shop / date / "Has written review" filters | `GET /api/shop/v1/admin/reviews/?…` (query params) |
| Sort sheet (Recent / Rating high→low / low→high) | `GET /api/shop/v1/admin/reviews/?sort=…` |
| Review detail screen | `GET /api/shop/v1/admin/reviews/{review_id}/` |

---

**1. Reviews list — `GET /api/shop/v1/admin/reviews/`**

- **Permissions:** `IsAdmin` (admin or superadmin).
- **Query params:**

  | Param | Type | Purpose |
  |---|---|---|
  | `search` | string | Customer name (first/last) **or** shop name (`icontains`). |
  | `rating` | enum | `any` (default — no filter) · `5` (5★ only, `rating ≥ 5`) · `4` (4★ & up, `rating ≥ 4`) · `3` (3★ & up, `rating ≥ 3`). |
  | `shop` | int | The shop filter chips — restrict to one `shop_id`. |
  | `date` | enum | Window on `created_at`: `7d` (**DEFAULT** — "Last 7 days") · `30d` · `all`. |
  | `has_comment` | bool | `true` → only reviews with non-empty text (the "Has written review" chip). |
  | `sort` | enum | `recent` (default — newest first) · `rating_desc` (high→low) · `rating_asc` (low→high). |
  | `page`, `page_size` | int | Pagination (`page_size` default 20, max 100). |

  **Sort options (`sort`):**

  | Value | Sort sheet label | Order |
  |---|---|---|
  | `recent` | Recent | `created_at` descending (the default). |
  | `rating_desc` | Rating: high → low | `rating` descending, then newest. |
  | `rating_asc` | Rating: low → high | `rating` ascending, then newest. |

> **⚠️ The date window defaults to the last 7 days.** With no `?date=`, the list
> only returns reviews from the **last 7 days** (matching the screen's "Last 7
> days" header). Pass **`?date=all`** for the full history (or `?date=30d` for 30
> days).

- **Response (200)** — a **custom paginated envelope** (`{count, page, page_size,
  next, previous, results}`, not the standard DRF envelope). Each result is a card:
```json
{
  "count": 74,
  "page": 1,
  "page_size": 20,
  "next": "https://…/api/shop/v1/admin/reviews/?page=2&page_size=20",
  "previous": null,
  "results": [
    {
      "id": 312,
      "rating": 5.0,
      "comment": "Spotless finish and the driver was on time.",
      "has_comment": true,
      "customer_name": "Priya Menon",
      "shop_name": "AquaShine Thathampally",
      "shop_id": 1,
      "created_at": "2026-06-18T09:38:00Z"
    },
    {
      "id": 309,
      "rating": 4.0,
      "comment": null,
      "has_comment": false,
      "customer_name": "Anil Kumar",
      "shop_name": "AquaShine Thathampally",
      "shop_id": 1,
      "created_at": "2026-06-17T14:05:00Z"
    }
  ]
}
```

Field reference (each `results[]` card):

| Field | Type | Meaning |
|---|---|---|
| `id` | int | Review id (open the detail with this). |
| `rating` | float | Star rating, e.g. `5.0`. |
| `comment` | string \| null | The written review text; `null` when none. |
| `has_comment` | bool | `true` when `comment` is non-empty (drives the "written review" indicator). |
| `customer_name` | string \| null | Reviewer's full name (first + last), else username. |
| `shop_name` | string \| null | The reviewed shop's name. |
| `shop_id` | int | The reviewed shop's id. |
| `created_at` | datetime | When the review was left (render relative). |

---

**2. Review detail — `GET /api/shop/v1/admin/reviews/{review_id}/`**

The single-review **detail** screen. Read-only.

- **Permissions:** `IsAdmin` (admin or superadmin).
- `404` (`{"detail": "Review not found."}`) if the id doesn't exist.
- **Response (200):**
```json
{
  "id": 312,
  "rating": 5.0,
  "comment": "Spotless finish and the driver was on time.",
  "tags": ["Quick", "Friendly", "Spotless"],
  "customer_name": "Priya Menon",
  "customer_phone": "+919847022119",
  "shop_name": "AquaShine Thathampally",
  "shop_id": 1,
  "booking_reference": "DT-0529-0043",
  "booking_id": 559,
  "handled_by": "Sajan Varghese",
  "is_flagged": false,
  "created_at": "2026-06-18T09:38:00Z"
}
```

Field reference:

| Field | Type | Meaning |
|---|---|---|
| `id` | int | Review id. |
| `rating` | float | Star rating, e.g. `5.0`. |
| `comment` | string \| null | The written review text. |
| `tags` | list[string] | Free-form tag tokens, e.g. `["Quick","Friendly","Spotless"]` (empty list if none). |
| `customer_name` | string \| null | Reviewer's full name (first + last), else username. |
| `customer_phone` | string \| null | Reviewer's phone — for the **call** button. |
| `shop_name` | string \| null | The reviewed shop's name. |
| `shop_id` | int | The reviewed shop's id. |
| `booking_reference` | string \| null | The linked carwash booking's reference (e.g. `DT-0529-0043`); `null` if the review has no booking. |
| `booking_id` | int \| null | The linked carwash booking id; `null` if none. |
| `handled_by` | string \| null | The worker who handled the booking — derived from the booking's `BookingAssignment` → driver/inspector → user name. `null` if no booking or unassigned. |
| `is_flagged` | bool | Informational only — there is **no** moderation action exposed (see note). |
| `created_at` | datetime | When the review was left. |

> **`handled_by` is derived, not stored.** It's resolved via the review's booking
> → that booking's most-recent `BookingAssignment` → the assigned driver/inspector's
> user name. It's `null` when the review has **no booking**, or the booking was
> **never assigned**.

> **Footer "View only · no moderation in v0.1."** These endpoints are **read-only**:
> no flag / hide / delete actions are exposed. `is_flagged` is returned for
> information only — there is no endpoint to set or clear it in v0.1.

---

## 12 · Offers — Coupons

The **Offers** screen with its **Coupons** tab — a searchable, filterable,
sortable **list** of coupon cards plus **Add Coupon** and **Edit Coupon** forms.
Served by `CouponViewSet` + `CouponFilter`
([booking/views/coupon_view_set.py](../booking/views/coupon_view_set.py)),
with `CouponSerializer` (read,
[booking/serializers/coupon_serializer.py](../booking/serializers/coupon_serializer.py))
and `CouponCreateUpdateSerializer` (write,
[booking/serializers/coupon_create_update_serializer.py](../booking/serializers/coupon_create_update_serializer.py)),
over the `Coupons` model
([booking/models/coupons.py](../booking/models/coupons.py)). The router registers
`coupons` → basename `coupon` under `/api/booking/v1/`.

- **Permissions:** **list / retrieve** require `IsAuthenticated` (admins manage;
  customers get read-only access). **create / update / delete** require `IsAdmin`
  (admin or superadmin).

> **Banners tab is OUT OF SCOPE.** The Offers screen also has a **Banners** tab —
> it is not covered here; this section documents **Coupons** only.

Mapping the screens → endpoints:

| Screen element | Endpoint |
|---|---|
| Coupons list (cards) | `GET /api/booking/v1/coupons/` |
| Search (code / description) | `GET /api/booking/v1/coupons/?search=…` |
| Filter sheet (STATUS chips) | `GET /api/booking/v1/coupons/?lifecycle=…` |
| Sort sheet (Most recent / A–Z) | `GET /api/booking/v1/coupons/?ordering=…` |
| Add Coupon (create) | `POST /api/booking/v1/coupons/` |
| Open Edit form (retrieve) | `GET /api/booking/v1/coupons/{id}/` |
| Edit Coupon (save) | `PATCH /api/booking/v1/coupons/{id}/` |
| Delete coupon | `DELETE /api/booking/v1/coupons/{id}/` |

> **Status / lifecycle is DERIVED, not stored.** A coupon's
> **Active / Scheduled / Paused / Expired** badge is **computed** from the stored
> `status` boolean (the "Active now" toggle) + the `start_date`/`end_date` window
> + `usage`/`limit` — there is no stored lifecycle column:
>
> - **Scheduled** — `status=true` **and** now `<` `start_date`.
> - **Active** — `status=true`, now within `[start_date, end_date]`, **and** `usage < limit`.
> - **Paused** — `status=false` (manually toggled off) **and** not expired.
> - **Expired** — now `>` `end_date` **OR** `usage >= limit` (this wins over Paused/Scheduled/Active).
>
> The read serializer exposes `lifecycle_status` (the badge string) and
> `is_active` (bool) as **computed, read-only** fields.

---

**1. Coupons list — `GET /api/booking/v1/coupons/`**

- **Permissions:** `IsAuthenticated`.
- **Pagination:** standard DRF envelope (`{count, next, previous, results}`).
- **Query params:**

  | Param | Type | Purpose |
  |---|---|---|
  | `search` | string | Matches the coupon code (`name`) **or** `description` (`icontains`). |
  | `lifecycle` | enum (csv) | The Filter sheet's STATUS chips — comma-separated subset of `active` · `scheduled` · `paused` · `expired`. Derived (see status model above); multiple values are OR-ed. |
  | `ordering` | enum | `-created_at` (**default** — "Most recent") · `name` (A–Z). |
  | `page` | int | Standard DRF page number. |

  **Sort options (`ordering`):**

  | Value | Sort sheet label | Order |
  |---|---|---|
  | `-created_at` | Most recent | `created_at` descending (the default). |
  | `name` | A–Z | Coupon code ascending. |

- **Response (200)** — standard DRF paginated envelope; each `results[]` entry is
  a coupon card. The progress bar renders `usage` / `limit`:
```json
{
  "count": 12,
  "next": "https://…/api/booking/v1/coupons/?page=2",
  "previous": null,
  "results": [
    {
      "id": 7,
      "name": "FIRST50",
      "description": "50% off your first wash",
      "discount_type": "percentage",
      "discount_percentage": "50.00",
      "flat_amount": null,
      "max_discount": "150.00",
      "min_order": "300.00",
      "discount_label": "50% OFF",
      "limit": 1000,
      "per_user_limit": 1,
      "usage": 214,
      "usage_remaining": 786,
      "applies_to_all_shops": true,
      "shop_ids": [],
      "start_date": "2026-06-01T00:00:00Z",
      "end_date": "2026-07-31T23:59:59Z",
      "status": true,
      "is_active": true,
      "lifecycle_status": "active",
      "created_at": "2026-05-28T11:02:00Z",
      "updated_at": "2026-06-20T09:14:00Z"
    },
    {
      "id": 5,
      "name": "MONSOON100",
      "description": "Flat ₹100 off at select shops",
      "discount_type": "flat",
      "discount_percentage": "0.00",
      "flat_amount": "100.00",
      "max_discount": null,
      "min_order": "500.00",
      "discount_label": "₹100 OFF",
      "limit": 500,
      "per_user_limit": null,
      "usage": 500,
      "usage_remaining": 0,
      "applies_to_all_shops": false,
      "shop_ids": [1, 3],
      "start_date": "2026-05-01T00:00:00Z",
      "end_date": "2026-06-30T23:59:59Z",
      "status": true,
      "is_active": false,
      "lifecycle_status": "expired",
      "created_at": "2026-04-26T08:00:00Z",
      "updated_at": "2026-06-15T10:30:00Z"
    }
  ]
}
```

Field reference (each `results[]` card — `CouponSerializer`):

| Field | Type | Meaning |
|---|---|---|
| `id` | int | Coupon id (open the Edit form / delete with this). |
| `name` | string | The coupon **code** (unique). |
| `description` | string \| null | Free-text description. |
| `discount_type` | enum | `percentage` or `flat`. |
| `discount_percentage` | decimal | Percent off (when `discount_type=percentage`; `0`–`100`). |
| `flat_amount` | decimal \| null | Flat ₹ discount (when `discount_type=flat`). |
| `max_discount` | decimal \| null | Optional rupee **cap** on a percentage discount. |
| `min_order` | decimal \| null | Minimum order amount required to apply. |
| `discount_label` | string | Badge text, e.g. `"50% OFF"` / `"₹100 OFF"`. |
| `limit` | int | Total redemption limit across all customers. |
| `per_user_limit` | int \| null | Max uses per customer; `null` = unlimited. |
| `usage` | int | Times redeemed so far (read-only). |
| `usage_remaining` | int | `max(0, limit − usage)`. |
| `applies_to_all_shops` | bool | `true` = global; `false` = restricted to `shop_ids`. |
| `shop_ids` | list[int] | The specific shops it applies to (empty when global). |
| `start_date` | datetime | Validity window start. |
| `end_date` | datetime | Validity window end. |
| `status` | bool | The **"Active now"** toggle (stored). `false` = paused. |
| `is_active` | bool | **Computed** — `true` only when currently redeemable. |
| `lifecycle_status` | enum | **Computed** badge — `active` · `scheduled` · `paused` · `expired`. |
| `created_at` | datetime | When the coupon was created. |
| `updated_at` | datetime | Last modified. |

The progress bar = `usage` / `limit` (and `usage_remaining` = `limit − usage`).

---

**2. Coupon detail / open Edit form — `GET /api/booking/v1/coupons/{id}/`**

- **Permissions:** `IsAuthenticated`.
- Returns the same `CouponSerializer` shape as a list card (above). Use it to
  populate the **Edit Coupon** form.
- `404` if the id doesn't exist.

---

**3. Add Coupon — `POST /api/booking/v1/coupons/`**

- **Permissions:** `IsAdmin` (admin or superadmin).
- **Request body** (`CouponCreateUpdateSerializer`):

  | Field | Type | Required | Notes |
  |---|---|---|---|
  | `name` | string | ✅ | Coupon **code** — must be unique (`400` on collision). |
  | `description` | string | — | Optional free-text. |
  | `discount_type` | enum | ✅ | `percentage` or `flat`. |
  | `discount_percentage` | decimal | conditional | **Required & `> 0`** when `discount_type=percentage` (`0`–`100`). |
  | `flat_amount` | decimal | conditional | **Required & `> 0`** when `discount_type=flat`. |
  | `max_discount` | decimal | — | Optional rupee cap for a percentage discount. |
  | `min_order` | decimal | — | Optional minimum order amount. |
  | `applies_to_all_shops` | bool | — | `true` = global; `false` = specific shops. |
  | `shop_ids` | list[int] | conditional | Write-only. **Required to be non-empty when `applies_to_all_shops=false`** (else `400`); ignored when global. |
  | `limit` | int | ✅ | Total redemption limit. |
  | `per_user_limit` | int | — | Max uses per customer; `null` = unlimited. |
  | `start_date` | datetime | ✅ | Validity window start. |
  | `end_date` | datetime | ✅ | Validity window end — **must be after `start_date`** (else `400`). |
  | `status` | bool | — | The "Active now" toggle (defaults `true`). |

  `usage`, `is_active`, `lifecycle_status`, `discount_label`, `created_at`,
  `updated_at` are **read-only / computed** and not accepted on write.

- **Example request:**
```json
{
  "name": "FIRST50",
  "description": "50% off your first wash",
  "discount_type": "percentage",
  "discount_percentage": "50.00",
  "max_discount": "150.00",
  "min_order": "300.00",
  "applies_to_all_shops": true,
  "limit": 1000,
  "per_user_limit": 1,
  "start_date": "2026-06-01T00:00:00Z",
  "end_date": "2026-07-31T23:59:59Z",
  "status": true
}
```
- **Response (201):** the created coupon in the read (`CouponSerializer`) shape.

---

**4. Edit Coupon — `PATCH /api/booking/v1/coupons/{id}/`**

- **Permissions:** `IsAdmin` (admin or superadmin).
- Send only the changed fields (partial update). Cross-field validation merges
  incoming values with the stored instance, so e.g. changing only `discount_type`
  still re-checks the matching amount field. (`PUT` for a full replace also works;
  `PATCH` is the edit path.)
- **Example — bump the percent, pause it via the toggle, extend the window:**
```json
{
  "discount_percentage": "60.00",
  "status": false,
  "end_date": "2026-08-31T23:59:59Z"
}
```
- **Response (200):** the updated coupon in the read (`CouponSerializer`) shape.
  In the example above, with `status=false` the computed `lifecycle_status`
  becomes `"paused"` (assuming it isn't already expired).

---

**5. Delete coupon — `DELETE /api/booking/v1/coupons/{id}/`**

- **Permissions:** `IsAdmin` (admin or superadmin).
- **Response (204):** no content.

---

> **Validation rules (write).** Enforced by `CouponCreateUpdateSerializer`,
> returning `400` with a field-keyed message:
> - `end_date` **must be after** `start_date`.
> - **Percentage** coupons need `discount_percentage > 0`.
> - **Flat** coupons need `flat_amount > 0`.
> - **Specific-shop** coupons (`applies_to_all_shops=false`) need **≥ 1**
>   `shop_ids` — on partial update the check falls back to the already-saved
>   shops if `shop_ids` is omitted.

> **Customer-facing preview.** Discount preview on the booking flow is handled by
> the separate **`POST /api/booking/v1/validate-coupon/`** endpoint (customer
> surface — not part of admin Offers). It previews the rupee discount for a
> coupon code + order amount via the same `Coupons.validate_redemption` logic; it
> does **not** create or modify coupons. Not re-documented here.
