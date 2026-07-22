# Pure Vision iOS

Real-time face and body censoring for iPhone and iPad. An iOS port inspired by [PuryFi Pure Vision](https://pury.fi).

## Features

- **Real-time Camera Censoring** - Detect and censor faces/bodies live through your camera
- **Photo Library Censoring** - Import photos and apply censoring effects
- **Multiple Censor Styles** - Blur, Pixelate, Mosaic, Black Bar, Darken
- **Configurable Detection** - Target faces, bodies, or both
- **Adjustable Intensity** - Fine-tune the strength of each censor effect
- **Confidence Display** - Optional detection confidence overlay
- **Save to Library** - Export censored photos directly

## Requirements

- iOS 17.0+
- Xcode 16.0+
- macOS Sonoma or later (for building)

## Build Instructions

### Option 1: Using XcodeGen (Recommended)

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```

2. Generate the Xcode project:
   ```bash
   cd PureVisioniOS
   xcodegen generate
   ```

3. Open the generated project:
   ```bash
   open PureVisioniOS.xcodeproj
   ```

4. Select your development team in Signing & Capabilities

5. Build and run on your device

### Option 2: Manual Xcode Project

1. Open Xcode and create a new iOS App project
2. Name it `PureVisioniOS`
3. Drag all files from `PureVisioniOS/` into the project
4. Set the deployment target to iOS 17.0
5. Add camera and photo library permissions in Info.plist
6. Build and run

### Building an IPA

1. In Xcode, select **Product > Archive**
2. Once archiving completes, click **Distribute App**
3. Choose **Development** or **Ad Hoc**
4. Follow the export wizard to generate the `.ipa` file

## Architecture

```
PureVisioniOS/
├── App/
│   ├── PureVisionApp.swift        # App entry point
│   └── ContentView.swift          # Root tab view
├── Views/
│   ├── CameraView.swift           # Live camera with censoring overlay
│   ├── CameraPreviewView.swift    # AVCaptureVideoPreview wrapper
│   ├── OverlayView.swift          # Censor effect overlays
│   ├── PhotoPickerView.swift      # Photo library picker & processor
│   └── SettingsView.swift         # App settings
├── Services/
│   ├── CameraManager.swift        # AVFoundation camera management
│   ├── DetectionService.swift     # Vision framework face/body detection
│   ├── CensorProcessor.swift      # CoreImage censor effect rendering
│   └── PhotoLibraryManager.swift  # Photos framework integration
├── Models/
│   ├── CensorType.swift           # Censor effect types & modes
│   ├── DetectionResult.swift      # Detection data model
│   └── AppState.swift             # Shared app state
├── Resources/
├── Assets.xcassets/
├── Info.plist
└── PureVisioniOS.entitlements
```

## Technologies

- **SwiftUI** - UI framework
- **AVFoundation** - Camera capture
- **Vision** - On-device face and body detection (VNDetectFaceLandmarksRequest, VNDetectHumanRectanglesRequest)
- **CoreImage** - Real-time image processing and censor effects
- **PhotosUI** - Photo library integration

## Permissions

| Permission | Usage |
|-----------|-------|
| Camera | Real-time face/body detection and censoring |
| Photo Library | Import photos for censoring |
| Photo Library (Write) | Save censored photos |

## License

MIT
