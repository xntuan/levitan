# Xcode Project Setup Guide

**Version:** 1.0
**Date:** November 10, 2025
**Estimated Time:** 15-20 minutes

---

## Overview

This guide will help you create an Xcode project and import all the source files we've created.

---

## Prerequisites

- macOS 11.0+ (Big Sur or later)
- Xcode 13.0+
- At least 5GB free disk space

---

## Step 1: Create New Xcode Project

1. **Launch Xcode**
   - Open Xcode from Applications or Spotlight

2. **Create Project**
   - Click "Create a new Xcode project"
   - Or: File → New → Project (⌘ + Shift + N)

3. **Choose Template**
   - Select **iOS** tab
   - Choose **App** template
   - Click **Next**

4. **Configure Project**
   ```
   Product Name: Ink
   Team: [Your team]
   Organization Identifier: com.yourcompany
   Bundle Identifier: com.yourcompany.ink
   Interface: UIKit App Delegate (NOT SwiftUI!)
   Language: Swift
   Use Core Data: Unchecked
   Include Tests: Checked
   ```
   - Click **Next**

5. **Choose Location**
   - Navigate to: `/path/to/levitan/`
   - **Important:** Choose "levitan" folder, NOT "InkApp"
   - Create Git repository: Uncheck (we already have one)
   - Click **Create**

---

## Step 2: Organize Project Structure

### Delete Default Files

Xcode created some files we don't need:

1. In Project Navigator, **delete** these files:
   - `ViewController.swift` (we have our own)
   - `Main.storyboard` (we're doing programmatic UI)
   - `LaunchScreen.storyboard` (optional, can keep)

2. When prompted, choose **Move to Trash**

### Import Our Source Files

1. **Open Finder**
   - Navigate to `/path/to/levitan/InkApp/`

2. **Drag Folders into Xcode**
   - Select all folders:
     - App/
     - Models/
     - ViewControllers/
     - Rendering/
     - Managers/
     - Supporting Files/ (not Resources yet)

3. **Import Dialog**
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to targets: Ink
   - Click **Finish**

4. **Import Tests**
   - Drag `InkApp/Tests/` folder
   - Add to target: InkTests
   - Click **Finish**

---

## Step 3: Configure Info.plist

Our custom Info.plist has important settings:

1. **Replace Default Info.plist**
   - In Project Navigator, find `Info.plist`
   - Delete it (Move to Trash)
   - Drag our `InkApp/Supporting Files/Info.plist` into project
   - Add to target: Ink

2. **Or, Update Build Settings** (if above doesn't work)
   - Select project in Navigator
   - Select "Ink" target
   - Build Settings tab
   - Search for "Info.plist File"
   - Set to: `InkApp/Supporting Files/Info.plist`

---

## Step 4: Add Metal Shader File

Metal shaders need special handling:

1. **Check Shaders.metal is Added**
   - Should be in `Rendering/Shaders.metal`
   - If not visible, drag from Finder

2. **Verify Build Phase**
   - Select project → Ink target
   - Build Phases tab
   - Expand "Compile Sources"
   - Ensure `Shaders.metal` is listed
   - If not, click + and add it

---

## Step 5: Configure Frameworks

Ensure required frameworks are linked:

1. **Select Ink Target**
   - Project Navigator → Ink project → Ink target

2. **General Tab**
   - Scroll to "Frameworks, Libraries, and Embedded Content"
   - Should see: Foundation, UIKit (automatically included)

3. **Add Metal Frameworks** (if not present)
   - Click + button
   - Search and add:
     - Metal.framework
     - MetalKit.framework
     - CoreGraphics.framework
   - All should be set to "Do Not Embed"

---

## Step 6: Update Scene Configuration

Since we deleted Main.storyboard:

1. **Edit Info.plist**
   - Open `Supporting Files/Info.plist`
   - Find key: `UIApplicationSceneManifest`
   - Expand → UISceneConfigurations → UIWindowSceneSessionRoleApplication
   - Find `UISceneStoryboardFile`
   - **Delete** this key (we don't use storyboards)

2. **Or, Verify SceneDelegate**
   - Open `App/SceneDelegate.swift`
   - Check that `scene(_:willConnectTo:)` creates window programmatically:
   ```swift
   window = UIWindow(windowScene: windowScene)
   window?.rootViewController = CanvasViewController()
   window?.makeKeyAndVisible()
   ```

---

## Step 7: Configure Build Settings

Optimize for our needs:

1. **Select Ink Target**
   - Build Settings tab
   - Search for each setting below

2. **Key Settings:**

   ```
   Swift Language Version: Swift 5
   iOS Deployment Target: 15.0
   Supported Devices: iPhone, iPad
   Device Orientation: All
   Strip Debug Symbols: NO (for Debug)
   Enable Bitcode: NO
   Dead Code Stripping: YES
   Metal Validation: Enabled (Debug) / Disabled (Release)
   ```

3. **Signing & Capabilities**
   - Select your Team
   - Signing: Automatically manage signing
   - Bundle Identifier: com.yourcompany.ink

---

## Step 8: Create Asset Catalog Structure

1. **Expand Resources Folder** (if added)
   - Or create new: File → New → Asset Catalog
   - Name it: Assets

2. **Add Folders in Assets.xcassets**
   - Right-click → New Folder
   - Create:
     - Colors/ (for design tokens)
     - Icons/
     - Templates/ (will add later)

---

## Step 9: Add Test Target Configuration

Configure unit tests:

1. **Select InkTests Target**
   - Build Settings tab

2. **Key Settings:**
   ```
   Host Application: Ink
   Bundle Loader: $(TEST_HOST)
   Test Host: $(BUILT_PRODUCTS_DIR)/Ink.app/Ink
   ```

3. **Check Test Files**
   - All .swift files in Tests/ folder should be added to InkTests target

---

## Step 10: First Build & Run

Time to test!

1. **Select Simulator**
   - Toolbar: Choose "iPad Pro (12.9-inch)" simulator
   - Or any iPad/iPhone simulator

2. **Build Project**
   - Product → Build (⌘ + B)
   - **Expected:** Success with 0 warnings

3. **Run App**
   - Product → Run (⌘ + R)
   - **Expected:** White canvas appears (Metal rendering working!)

4. **Check Console**
   - Should see: "Metal initialized successfully" (or similar)
   - No red errors

---

## Step 11: Run Unit Tests

Verify all code works:

1. **Run All Tests**
   - Product → Test (⌘ + U)
   - Or: Click diamond next to test class

2. **Expected Results:**
   - ✅ PatternGeneratorTests: All pass
   - ✅ BrushEngineTests: All pass
   - ✅ LayerManagerTests: All pass
   - Total: 35+ tests pass

3. **If Tests Fail:**
   - Check @testable import Ink is present
   - Verify files are in correct target
   - Check for any build errors

---

## Step 12: Verify Metal Rendering

1. **Run on iPad Simulator**
   - Should see white canvas

2. **Test Gestures**
   - Pinch to zoom (⌥ + drag on simulator)
   - Two-finger pan (⌥ + Shift + drag)
   - Touch canvas (should see console logs)

3. **Check FPS**
   - Debug Navigator (⌘ + 7)
   - Should show ~60 FPS

---

## Troubleshooting

### Problem: "Metal is not supported"
**Solution:**
- Use iPad simulator (not iPhone)
- Or use physical device
- Some old simulators don't support Metal

### Problem: Build fails with "No such module"
**Solution:**
- Check framework linking (Step 5)
- Clean build folder (⌘ + Shift + K)
- Rebuild (⌘ + B)

### Problem: Shaders.metal won't compile
**Solution:**
- Verify it's in "Compile Sources" build phase
- Check Metal Language Version in Build Settings
- Should be: Metal 2.0+

### Problem: Tests won't run
**Solution:**
- Verify test files are in InkTests target
- Check @testable import Ink statement
- Ensure Host Application is set to Ink

### Problem: "Missing Info.plist"
**Solution:**
- Check Build Settings → Info.plist File path
- Should point to: `InkApp/Supporting Files/Info.plist`
- Try cleaning and rebuilding

### Problem: SceneDelegate crashes on launch
**Solution:**
- Verify Info.plist has correct scene configuration
- Check that UISceneStoryboardFile key is removed
- Verify programmatic window creation in SceneDelegate

---

## Project Structure (Final)

After setup, your Xcode project should look like:

```
Ink.xcodeproj
├── Ink/
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift
│   ├── Models/
│   │   ├── Layer.swift
│   │   ├── Brush.swift
│   │   ├── Stroke.swift
│   │   └── Project.swift
│   ├── ViewControllers/
│   │   └── CanvasViewController.swift
│   ├── Rendering/
│   │   ├── MetalRenderer.swift
│   │   └── Shaders.metal
│   ├── Managers/
│   │   ├── LayerManager.swift
│   │   ├── BrushEngine.swift
│   │   ├── PatternGenerator.swift
│   │   └── ExportManager.swift
│   ├── Supporting Files/
│   │   ├── Info.plist
│   │   ├── DesignTokens.swift
│   │   └── Extensions.swift
│   └── Resources/
│       └── Assets.xcassets
├── InkTests/
│   ├── PatternGeneratorTests.swift
│   ├── BrushEngineTests.swift
│   └── LayerManagerTests.swift
└── Products/
    └── Ink.app
```

---

## Verification Checklist

After completing all steps:

- [ ] Project builds successfully (⌘ + B)
- [ ] Zero warnings
- [ ] App runs on simulator
- [ ] White canvas appears
- [ ] Console shows no errors
- [ ] All unit tests pass (⌘ + U)
- [ ] Gestures work (zoom, pan)
- [ ] Touch events logged to console
- [ ] ~60 FPS in Debug Navigator
- [ ] No crashes

---

## Next Steps

Once your Xcode project is set up:

1. **Read TESTING.md** - Learn how to test thoroughly
2. **Run Performance Tests** - Use Instruments
3. **Continue Development** - Implement Week 3 tasks
4. **Add UI Components** - Build Template Gallery

---

## Getting Help

If you encounter issues:

1. Check this guide's Troubleshooting section
2. Clean build folder (⌘ + Shift + K)
3. Restart Xcode
4. Check Apple Developer docs
5. Post in team channel with error details

---

**Estimated Completion Time:** 15-20 minutes
**Difficulty:** Easy (step-by-step guide)
**Status:** ✅ Ready to use

---

**Last Updated:** November 10, 2025
**Tested On:** Xcode 14.0, macOS 12.6
