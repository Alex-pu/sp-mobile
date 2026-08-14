# SP Mobile

Lightweight Flutter POS app for cashiers and owners.

## Current Status

This folder contains the first source scaffold for the Flutter app:

- Android Flutter project
- first-run shop pairing screen
- backend JWT login
- secure token storage
- API client
- sync bootstrap call
- local SQLite product cache
- cashier home
- online shift start
- product search using local products
- barcode scanning from local products
- pending sales reconciliation to the backend batch endpoint
- close-shift guard that requires pending sales to be synced first
- receipt preview and local reprint history
- ESC/POS receipt byte rendering and printer settings

Run dependencies and tests with:

```bash
flutter pub get
flutter analyze
flutter test
```

## Runtime Config

Use Dart defines:

```bash
flutter run --dart-define=API_BASE_URL=https://your-backend.example.com/api
```

The Neon Auth URL is included as:

```bash
--dart-define=NEON_AUTH_URL=https://ep-tiny-surf-ayijej8k.neonauth.c-5.us-east-2.aws.neon.tech/neondb/auth
```

The current mobile scaffold uses the backend JWT/PIN auth endpoints. Auth is isolated behind `AuthRepository`, so Neon Auth can be plugged in without changing screens.

## Device Pairing

The owner creates a one-time invite from the backend:

```http
POST /api/device-invites
```

The app accepts the token on first launch and stores the linked shop in secure storage. Cashier login happens after the phone is paired to a shop.

## First Cashier MVP

1. Pair device to shop.
2. Login.
3. Bootstrap user, shop, current shift, and products.
4. Start shift online.
5. Sell from local products by search or barcode scan.
6. Save transactions locally and reduce the local stock view.
7. Sync pending transactions when online.
8. Preview receipt and reprint recent receipts.
9. Close shift online after all pending sales sync.

## Offline Sync

Cash sales are saved in `offline_transactions` with `pending` status. The cashier home screen shows the pending count and sends queued sales to:

```http
POST /api/transactions/batch
```

Synced or already-known transactions are marked `synced`; failed rows remain `pending` with `last_error` for retry.

## Shift Close

Cashiers cannot close a shift while pending local sales exist. The close screen submits closing cash to:

```http
PUT /api/shifts/<shiftId>/close
```

The backend returns expected cash and variance, which the app shows after closing.

## Receipts

Receipts are rendered from local transaction payloads, so a cashier can preview or reprint recent receipts even before the sale has synced. `PrinterRepository` is currently a placeholder for the thermal printer integration.

## Printer

The app targets the common paired Bluetooth ESC/POS thermal printer using 80mm paper. Pair the printer normally in Android Bluetooth settings, then select it from the app's paired-printer list. Printing uses `print_bluetooth_thermal` to connect by MAC address and send ESC/POS bytes.
