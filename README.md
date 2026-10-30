# Flutter Product Browser

A small Flutter app that signs in against the public [DummyJSON API](https://dummyjson.com), keeps the access token in platform-secure storage, and lets the signed-in user browse a paginated product list and open product details.

- **State management / DI / routing:** [GetX](https://pub.dev/packages/get)
- **Secure storage:** [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) (Keychain on iOS, Keystore-encrypted storage on Android)
- **HTTP:** [http](https://pub.dev/packages/http)

## Running the app

```bash
flutter pub get
flutter run
```

Sign in with the demo credentials:

- Username: `emilys`
- Password: `emilyspass`

Run the unit tests with `flutter test` and the analyzer with `flutter analyze`.

## Features

| Area | What is implemented |
|---|---|
| Login | Username/password form with non-empty validation, password visibility toggle, in-progress state, duplicate-submission guard, server error message (e.g. `Invalid credentials`). |
| Session | Token stored securely after login; restored on cold start (and validated against `/auth/me`); cleared on logout, which returns to the login screen. Authenticated routes are guarded by a GetX middleware. |
| Product list | `GET /products?limit=20&skip=N`, infinite scroll pagination that stops at the end, pull-to-refresh that resets to page one, loading / error (with retry) / empty states, inline "load more" error with retry. |
| Product detail | `GET /products/{id}`; shows images (swipeable gallery), title, brand, category, price with discount, rating, stock/availability, description and warranty/shipping/return info when present. |

## Project structure

```text
lib/
├── app/
│   ├── app.dart                      # GetMaterialApp: theme, routes
│   └── bindings/initial_binding.dart # app-wide singletons
├── core/
│   ├── constants/                    # API endpoints, page size, storage keys
│   ├── errors/app_exception.dart     # sealed error hierarchy with user-facing messages
│   ├── network/api_client.dart       # shared HTTP client (auth header, error mapping, JSON)
│   ├── routes/                       # route names, GetPage table, auth middlewares
│   ├── storage/token_storage.dart    # TokenStorage contract + secure implementation
│   └── theme/app_theme.dart
├── features/
│   ├── auth/
│   │   ├── data/        # AuthRemoteDataSource, AuthRepositoryImpl
│   │   ├── domain/      # AuthUser, AuthSession, AuthRepository contract
│   │   └── presentation/# AuthController, LoginController, AuthBinding, LoginPage
│   └── products/
│       ├── data/        # ProductsRemoteDataSource, ProductsRepositoryImpl
│       ├── domain/      # Product, PaginatedProducts, ProductsRepository contract
│       └── presentation/# ProductsController, ProductDetailController, bindings, pages, widgets
└── main.dart
```

### Why this structure

The app has exactly two features (auth, products), so a feature-first layout keeps everything about one feature in one folder while still separating **presentation** (widgets + GetX controllers), **domain** (plain models and repository contracts) and **data** (API data sources, repository implementations, parsing). `core/` holds the handful of things both features share.

Deliberate simplifications for this scope:

- **No use-case classes.** Each controller action maps 1:1 to a repository call, so a use-case layer would only add indirection. Repository interfaces are kept because they are the seam used for unit testing.
- **Models are parsed in the domain folder** (`fromJson` factories) rather than having separate DTO + entity + mapper triples. The API is the only data source, so one model per concept is enough.
- **Repositories are thin** (they mostly forward to the data source). The one place a repository has real logic — `AuthRepositoryImpl.restoreSession` — is where the layering pays off: the controller does not need to know about tokens, 401s or offline handling.

## GetX: controllers, bindings and routes

### Dependency registration

`InitialBinding` (invoked in `main()` before `runApp`) registers everything that lives for the whole app:

- `TokenStorage` and `ApiClient` as permanent singletons.
- Data sources and repositories with `Get.lazyPut(..., fenix: true)` — created on first use, recreated if GetX ever disposes them.
- `AuthController` as a **permanent** controller, because route middlewares and the products screen need the session state at any time.

Route-level bindings add only what the route needs and let GetX dispose it when the route is popped:

| Route | Binding | Registers |
|---|---|---|
| `/login` | `AuthBinding` | `LoginController` (form state: text controllers, form key, obscure toggle). Scoped to the route so the `TextEditingController`s are disposed when leaving. |
| `/products` | `ProductsBinding` | `ProductsController` |
| `/products/:id` | `ProductDetailBinding` | `ProductDetailController`, built from `Get.parameters['id']` and the `Product` passed as `Get.arguments`. |

### Controllers

- **`AuthController`** – `isAuthenticated`, `user`, `isLoggingIn`, `loginError`. Exposes `restoreSession()`, `login()`, `logout()`. It owns navigation after login/logout (`Get.offAllNamed`) since those are session transitions.
- **`LoginController`** – only form concerns. Validates, unfocuses, and delegates to `AuthController.login`.
- **`ProductsController`** – list state (see [Pagination and states](#pagination-refresh-and-requesterror-states)). Owns the `ScrollController` so the "near the end" detection stays out of the widget.
- **`ProductDetailController`** – shows the product passed from the list immediately and refreshes it from `/products/{id}`; errors are only shown full-screen when there is nothing to display.

`Rx` observables are used only for values the UI reacts to; plain fields (`_skip`, `_generation`) hold internal bookkeeping.

### Routing and route protection

Named routes live in `core/routes/app_routes.dart`, the `GetPage` table in `app_pages.dart`. Two `GetMiddleware`s guard them:

- `AuthMiddleware` on `/products` and `/products/:id` redirects to `/login` when `AuthController.isAuthenticated` is false.
- `GuestMiddleware` on `/login` redirects to `/products` when a session already exists.

Because `main()` awaits `AuthController.restoreSession()` before `runApp`, the initial route (`/products` or `/login`) and the middlewares always see a known authentication state; there is no flash of the wrong screen.

## API layer and repository boundaries

```
Widget ──▶ Controller ──▶ Repository (contract) ──▶ RemoteDataSource ──▶ ApiClient ──▶ http
```

- **`ApiClient`** is the only place that knows about HTTP. It builds URLs, attaches `Authorization: Bearer <token>` when a token is stored, enforces a timeout, and converts every failure into an `AppException`:
  - `SocketException` / `TimeoutException` / `ClientException` → `NetworkException`
  - 401 / 403 → `UnauthorizedException` (using DummyJSON's `message` when present)
  - other non-2xx → `ServerException(statusCode, message)`
  - non-object or invalid JSON → `ParseException`
- **Data sources** call `ApiClient` with the right path/query/body and parse the JSON into models (`AuthSession`, `PaginatedProducts`, `Product`). Model factories throw `ParseException` when required fields are missing, so a malformed response never reaches the UI as a crash.
- **Repositories** implement the domain contracts. `AuthRepositoryImpl` combines the remote source with `TokenStorage`; `ProductsRepositoryImpl` forwards to the remote source.
- **Controllers** catch `AppException` and expose `e.message`; widgets never see exceptions or HTTP details.

Nothing is hardcoded: a wrong password really returns the server's `Invalid credentials`, and the list really pages through all 194 DummyJSON products.

## Token storage, restore and clearing

- **Store:** `AuthRepositoryImpl.login` writes `accessToken` through the `TokenStorage` interface. `SecureTokenStorage` wraps `FlutterSecureStorage` (Keychain with `first_unlock_this_device` accessibility on iOS; Keystore-wrapped AES-GCM on Android). The token is never logged, never kept in `SharedPreferences`, and the only in-memory copy lives in the storage plugin.
- **Use:** `ApiClient` reads the token per request and adds the bearer header.
- **Restore:** on launch `restoreSession()` reads the token. If present, it calls `GET /auth/me`:
  - success → authenticated, user profile available (greeting in the app bar);
  - `UnauthorizedException` (expired/revoked) → token deleted, user sent to login;
  - any other error (offline) → session kept, user shown as authenticated without a profile, so a flaky network does not log people out.
- **Clear:** `logout()` deletes the token, resets `AuthController` state and `Get.offAllNamed('/login')` clears the navigation stack.

## Pagination, refresh and request/error states

`ProductsController` keeps these observables:

| Field | Meaning |
|---|---|
| `status` (`initial / loading / success / error`) | State of the **first** page. |
| `products` | Accumulated items. |
| `errorMessage` | First-page error → full-screen `ErrorView` with Retry. |
| `isLoadingMore`, `loadMoreError`, `hasMore` | Footer state → spinner / inline error with Retry / "You've reached the end". |
| `refreshError` | Pull-to-refresh failed while items were already visible → the page shows a SnackBar and keeps the list. |

Behaviour:

- **First load** – `loadFirstPage()` sets `status = loading`, requests `limit=20&skip=0`, then `success` or `error`. `isEmpty` (success with no items) renders `EmptyView`, which is itself pull-to-refreshable.
- **Pagination** – the `ScrollController` listener calls `loadMore()` when within 300 px of the bottom. `loadMore()` is a no-op while another page is in flight, when `hasMore` is false, or before the first page succeeded, so duplicate requests are impossible. `hasMore` is derived from the API's `skip + products.length < total`.
- **Pull-to-refresh** – `refreshProducts()` re-requests page one, replaces the list and resets `skip`/`hasMore`. On failure it keeps the current items and sets `refreshError`.
- **Race protection** – every reset bumps an internal `_generation` counter; responses from an older generation (e.g. a "load more" that was running when the user pulled to refresh) are discarded instead of being appended to the fresh list. This is covered by a unit test.

## Tests

`flutter test` runs 44 unit tests (no network, no platform channels):

- `test/core/api_client_test.dart` – URL/query building, bearer header, JSON body, and the mapping of 401 / 5xx / socket errors / bad JSON to `AppException`s (using `http`'s `MockClient`).
- `test/features/products/models_test.dart` – parsing, optional fields, `hasMore`, `ParseException` on malformed payloads.
- `test/features/auth/auth_repository_test.dart` – token persisted on login only, restore paths (no token / valid / rejected / offline), logout clears.
- `test/features/auth/auth_controller_test.dart` – restore, in-progress flag, trimming, error exposure, duplicate-submission guard, logout.
- `test/features/products/products_controller_test.dart` – first load, error + retry, empty state, paging with `skip`, stop at end, no duplicate load-more, inline error, refresh reset, stale-response discard.
- `test/features/products/product_detail_controller_test.dart` – initial product shown then refreshed, error only when nothing to show.

The end-to-end flow (restore from Keychain, validation, wrong password, login, 20 → 60 items via scrolling, refresh back to 20, detail, logout clearing the token) was also exercised against the live API on an iOS simulator during development.

## Assumptions, limitations and trade-offs

- **Access token only.** DummyJSON also returns a `refreshToken`; it is not stored or used. Access tokens expire after 60 minutes, after which `/auth/me` returns 401 on the next cold start and the user is asked to sign in again. The products endpoints themselves are public, so an expired token does not break browsing within a session.
- **Session validation is best-effort.** When `/auth/me` cannot be reached, the stored token is trusted so the app stays usable offline-ish (the list itself still needs a network).
- **Images use `Image.network`** with loading/error builders rather than a caching package, to keep dependencies minimal.
- **Detail page fetch.** The list already has the full product payload, so the detail page shows it instantly and refreshes from `/products/{id}` in the background; a failed refresh is silent when data is already on screen.
- **Package name.** The generated placeholder package name `github` was renamed to `product_browser` for readable imports; the Android `applicationId` / iOS bundle identifier were left as generated.
- **No deep-link handling** beyond what GetX named routes provide; `/products/:id` is only reached from the list.
- **Tests focus on logic**, not pixels: controllers and repositories are tested through fakes; widgets are kept thin so they need little testing.
