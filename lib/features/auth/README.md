# Auth Feature — 3-Layer Architecture

## Folder Structure

```
lib/features/auth/
├── domain/                          # Business logic & contracts
│   ├── entities/
│   │   ├── user.dart               # User entity
│   │   └── session.dart            # Session entity
│   └── repositories/
│       └── auth_repository.dart    # Abstract auth repository interface
├── application/                     # Riverpod logic (state management)
│   ├── states/
│   │   └── auth_state.dart         # Auth state (Initial, Loading, OtpSent, Success, Error)
│   ├── providers/
│   │   └── auth_provider.dart      # Riverpod providers & state notifier
│   └── usecases/
│       ├── send_otp_usecase.dart   # Send OTP logic
│       ├── verify_otp_usecase.dart # Verify OTP logic
│       ├── login_usecase.dart      # Login with credentials
│       └── logout_usecase.dart     # Logout logic
├── infrastructure/                  # API calls & local storage
│   ├── data_sources/
│   │   ├── auth_api.dart           # Remote API calls (send-otp, verify-otp, login)
│   │   └── auth_local_ds.dart      # Local storage (Hive) for user & session
│   ├── models/
│   │   └── auth_response_model.dart # Response model for auth endpoints
│   └── repositories/
│       └── auth_repository_impl.dart # Concrete repository implementation
└── presentation/
    └── screens/
        └── login_screen.dart        # Login UI (Driver OTP + Admin password)
```

## API Endpoints Integrated

### 1. Send OTP
- **Endpoint:** `POST /api/accounts/v1/send-otp/`
- **Body:** `{ phone, role }`
- **Use Case:** Driver sends phone → receives OTP

### 2. Verify OTP
- **Endpoint:** `POST /api/accounts/v1/verify-otp/`
- **Body:** `{ phone, otp_code, role }`
- **Response:** User object + session cookies
- **Use Case:** Driver enters OTP → authenticates

### 3. Login with Username/Password
- **Endpoint:** `POST /api/accounts/v1/login/`
- **Body:** `{ username, password }`
- **Response:** User object + session cookies
- **Use Case:** Admin/Driver login with credentials

## Implementation Details

### Session Management
- **Type:** Django session-based (cookie auth)
- **Cookies:** `sessionid` (required on all authenticated requests)
- **CSRF:** `csrftoken` required for unsafe methods (POST/PUT/PATCH/DELETE)

### Local Storage (Hive)
- **User Box:** Stores authenticated user data
- **Session Box:** Stores sessionid, csrftoken, expiry

### State Management (Riverpod)
- `authStateProvider` — StateNotifierProvider managing auth state
- `authRepositoryProvider` — Provides repository instance
- States: `AuthInitial`, `AuthLoading`, `OtpSent`, `AuthSuccess`, `AuthError`

### UI Integration
- **Login Screen:** Removed all hardcoded demo data
  - Phone inputs cleared
  - Demo credentials removed
  - Demo OTP validation removed
  - API calls integrated via Riverpod
  - State listeners for success/error handling

## Configuration

### Environment Variables
Add to `.env`:
```
API_BASE_URL=http://156.67.104.149:8110
```

### Dependencies Added
- `flutter_dotenv: ^5.1.0` — Environment variable management
- `dio: ^5.3.1` — HTTP client with interceptors
- `http: ^1.1.0` — Alternative HTTP client

### Hive Configuration
Ensure these typeIds are unique in your project:
- User model typeId: (to be added)
- Session model typeId: (to be added)

## Usage in UI

```dart
// Watch auth state
final authState = ref.watch(authStateProvider);

// Send OTP
ref.read(authStateProvider.notifier).sendOtp(
  phone: '+91...',
  role: 'driver',
);

// Verify OTP
ref.read(authStateProvider.notifier).verifyOtp(
  phone: '+91...',
  otpCode: '1234',
  role: 'driver',
);

// Login with credentials
ref.read(authStateProvider.notifier).login(
  username: 'driver_ravi',
  password: 'password',
);

// Logout
ref.read(authStateProvider.notifier).logout();
```

## Next Steps

1. **Hive Models:** Create @HiveType classes for User and Session with proper typeIds
2. **HTTP Interceptors:** Add session & CSRF token management to Dio interceptors
3. **Error Handling:** Enhance error messages based on API response codes
4. **Token Refresh:** Implement refresh token logic if backend supports it
5. **Testing:** Add unit tests for repositories and usecases
