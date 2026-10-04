# Delivery Demo MVP Status

Last checked: 2026-10-04 (Asia/Bangkok)

```text
BRANCH=codex/demo-delivery-mvp

BACKEND_FOUND=false
BACKEND_BASE_URL=https://startle-kilogram-greeting.ngrok-free.dev
SWAGGER_FOUND=false
API_V2_REACHABLE=false
API_MODE=V2 + LEGACY COMPAT (runtime default)

IDENTITY=client compatibility implemented; backend unavailable
JWT=Bearer/session support implemented; login response must provide token
CURRENT_USER=API status check implemented; backend unavailable
ORDER=legacy flow retained; V2 backend unavailable
DELIVERY_QUOTE=legacy adapter retained; backend unavailable
DRIVER_ASSIGNMENT=legacy flow retained; backend unavailable
DRIVER_JOB_LIST=V2 endpoint not discovered; explicit legacy adapter retained
GPS=real device GPS code retained; legacy upload endpoint retained
MAP_ROUTE=real API first; simulator only when DEMO_MODE=true
PICKUP=legacy transition retained
PROOF=legacy proof endpoint retained
COMPLETE_DELIVERY=V2-first repository with explicit legacy fallback
COD_WALLET=V2-first repository with explicit legacy fallback

FLUTTER_ANALYZE=PASS (exit code 0, No issues found!)
FLUTTER_TEST=PASS (9 tests)
GIT_DIFF_CHECK=PASS
APP_BUILD=PASS (Android debug APK with DEMO_MODE=true)
APK_PATH=demo/shipperapp-demo.apk (local ignored copy)
COLD_START_TEST=PASS: process force-stop -> relaunch -> offline home -> online -> assignment -> accept -> pickup proof -> in transit -> delivery proof -> complete -> COD 350,000
SECOND_RUN_AFTER_RESET=PASS: RESET DEMO DATA -> offline/COD 0 -> assignment restored -> full delivery -> COD 350,000
MAP_GRACEFUL_FALLBACK=PASS: DEMO ROUTE and markers remain usable when map tiles fail
CAMERA_DEMO_FALLBACK=PASS: Sử dụng minh chứng Demo works for pickup and delivery
DEMO_MUTATES_REMOTE_BACKEND=false

KNOWN_BLOCKERS=No reachable backend/Swagger; real API integration remains unverified. Map tiles may be blocked by the current network, but route geometry, markers, and the DEMO ROUTE label remain available.
READY_FOR_DEMO=true (DEMO_MODE only)
```

Run configuration when a backend is available:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=https://startle-kilogram-greeting.ngrok-free.dev --dart-define=DEMO_MODE=true --dart-define=ENABLE_LEGACY_COMPAT=true
```
