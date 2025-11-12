# MaLiang Demo

Simple drawing app using the [MaLiang](https://github.com/Harley-xk/MaLiang) library (MIT licensed).

## What is MaLiang?

MaLiang is a professional-grade Metal-based drawing library for iOS with:
- ✅ Smooth, responsive drawing with Apple Pencil support
- ✅ Automatic pressure sensitivity (3D Touch + Apple Pencil)
- ✅ High-performance Metal rendering
- ✅ Built-in undo/redo
- ✅ Customizable brushes with textures
- ✅ Proven in production apps

## How to Open

**IMPORTANT:** Open the **workspace**, not the project:

```bash
open MaLiangDemo.xcworkspace
```

**DO NOT** open `MaLiangDemo.xcodeproj` - CocoaPods requires you use the workspace file.

## What's Included

This demo has:
- Simple white drawing canvas
- Basic brush controls (size slider)
- Clear, Undo, Redo buttons
- Clean, minimal UI

## Current Features

The demo implements:
- ✅ Free drawing with customizable brush size
- ✅ Undo/Redo functionality
- ✅ Clear canvas
- ✅ Black ink on white background

## Try It Out

1. **Open the workspace:**
   ```bash
   cd MaLiang-Demo
   open MaLiangDemo.xcworkspace
   ```

2. **Build and run** (Cmd+R)

3. **Test drawing:**
   - Draw with your finger or Apple Pencil
   - Adjust brush size with the slider
   - Test undo/redo
   - Clear the canvas

## Next Steps

If MaLiang works well for you, we can:
1. Add layer support (MaLiang supports multiple layers)
2. Integrate your template system
3. Add pattern/hatching brushes with custom textures
4. Build the template gallery UI on top of MaLiang
5. Keep your business logic (templates, progress tracking, etc.)

## Comparison

**Custom Implementation (Archive-CustomImplementation/):**
- ❌ Complex Metal shader code
- ❌ Drawing crashes and bugs
- ❌ Lots of manual work needed
- ✅ Full control over everything

**MaLiang:**
- ✅ Battle-tested, production-ready
- ✅ Smooth drawing out of the box
- ✅ Active maintenance
- ✅ Great documentation
- ❌ Less control over low-level rendering

## License

MaLiang is MIT licensed, which means you can use it freely in commercial apps.
