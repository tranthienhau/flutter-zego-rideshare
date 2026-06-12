# Screenshot capture flow

Real captures from the iOS Simulator via an integration-test driver (no mockups).

## Steps

1. Boot the simulator:
   ```bash
   xcrun simctl boot "iPhone 16e"
   open -a Simulator
   ```
2. Scaffold the iOS platform folder (lib-only project) and get dependencies:
   ```bash
   flutter create . --platforms=ios --project-name flutter_zego_rideshare
   flutter pub get
   ```
3. Drive the screenshot test:
   ```bash
   flutter drive \
     --driver test_driver/integration_test.dart \
     --target integration_test/screenshot_test.dart \
     -d "889A2E50-D60F-4785-84BD-5700F9048279"
   ```
4. Build the demo GIF from the PNGs:
   ```bash
   cd screenshots
   ffmpeg -y -framerate 1 -pattern_type glob -i '*.png' \
     -vf "scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
     -loop 0 demo.gif
   ```

PNGs + `demo.gif` are written to `screenshots/` and embedded in `README.md`.

## How it works

- `test_driver/integration_test.dart` - `integrationDriver(onScreenshot:)` writes each PNG to `screenshots/<name>.png`.
- `integration_test/screenshot_test.dart` - two `testWidgets` blocks, each with a fresh `ProviderContainer`:
  - `capture home` pumps `RideshareApp` in its default empty state and shoots `01-home` (map preview, pickup/dropoff pickers, Request ride button).
  - `capture active ride and ZEGO call mask` overrides `rideControllerProvider` with a `SeededRideController` that pre-loads an en-route ride (driver matched, Stripe fare split, ephemeral call mask). It shoots `02-ride-matched`, then taps the call button to open the ZEGO call-masking bottom sheet and shoots `03-zego-call-mask` (proxy number + `zegoToken`).
- Seeding the ride via a Riverpod override keeps the screenshots deterministic, instead of waiting on the production state-machine timers.
- Each `shoot` calls `binding.convertFlutterSurfaceToImage()` + `pump(Duration)` + `binding.takeScreenshot('NN-name')`.
