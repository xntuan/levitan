# PencilKit Demo

Simple drawing app using **Apple's PencilKit** - the official iOS drawing framework.

## What is PencilKit?

PencilKit is Apple's native framework for drawing and sketching, introduced in iOS 13:
- ✅ **Official Apple framework** - No external dependencies
- ✅ **Production-ready** - Used in Notes.app and other Apple apps
- ✅ **Built-in tool picker** - Apple's beautiful tool selection UI
- ✅ **Automatic Apple Pencil support** - Pressure, tilt, double-tap
- ✅ **Finger drawing** - Works with touch too
- ✅ **Built-in undo/redo** - System-level undo management
- ✅ **Simple API** - Just use PKCanvasView

## How to Open

Open the **project** directly:

```bash
cd /Users/Levitan/PencilKit-Demo
open PencilKitDemo.xcodeproj
```

Then press **⌘R** to build and run!

## Features

This demo includes:
- ✅ Drawing canvas with PencilKit
- ✅ Apple's built-in tool picker (pen, marker, pencil, eraser, lasso)
- ✅ Color picker
- ✅ Ruler tool
- ✅ Clear, Undo, Redo buttons
- ✅ Automatic pressure sensitivity
- ✅ Works with finger AND Apple Pencil

## What You Get Out of the Box

**Apple's Tool Picker Includes:**
- Multiple pen types (pen, marker, pencil)
- Eraser tool
- Lasso selection tool
- Color palette
- Width adjustment
- Opacity control
- Ruler for straight lines

**All this with ZERO code** - PencilKit provides it automatically!

## Comparison

### Custom Implementation (Archive-CustomImplementation/)
- ❌ 80+ files of complex Metal code
- ❌ Drawing crashes and bugs
- ❌ Range errors
- ❌ Auto-dismiss issues
- ✅ Full control over rendering

### MaLiang (MaLiang-Demo/)
- ✅ Production-ready drawing
- ❌ External dependency (CocoaPods)
- ❌ "Weird" behavior (per user feedback)
- ❌ Swift version compatibility issues
- ✅ Customizable brushes

### **PencilKit (This Demo)**
- ✅ **Apple's official framework**
- ✅ **No external dependencies**
- ✅ **Used in Apple's own apps**
- ✅ **Built-in beautiful UI**
- ✅ **Zero maintenance**
- ✅ **Guaranteed compatibility**
- ❌ Less control over low-level rendering

## How PencilKit Works

**Super simple API:**

```swift
// 1. Create canvas
let canvasView = PKCanvasView()

// 2. Show tool picker (Apple's UI)
let toolPicker = PKToolPicker()
toolPicker.setVisible(true, forFirstResponder: canvasView)

// That's it! You have a full drawing app.
```

## Adding Layers (For Your App)

PencilKit drawings can be composed:
- Each layer = one PKCanvasView
- Render them as images and composite
- Or use your existing Metal compositor with PencilKit drawings

## Next Steps

If you like PencilKit, we can:
1. ✅ Keep the PencilKit drawing engine
2. ✅ Add your template system on top
3. ✅ Implement layers (multiple PKCanvasViews or compositing)
4. ✅ Add your mask system for "stay inside the lines"
5. ✅ Build your gallery and progress tracking
6. ✅ Keep all your business logic

**Benefits:**
- Reliable, Apple-quality drawing
- No crashes or weird behavior
- Automatic updates from Apple
- Beautiful built-in UI
- Focus your time on the unique features (templates, layers, progress)

## Documentation

Official Apple docs: https://developer.apple.com/documentation/pencilkit
