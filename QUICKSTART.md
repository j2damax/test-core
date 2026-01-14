# Quick Start Guide

Get your bus label detection model running in iOS in 3 main steps.

## 🎯 Overview

1. **Train the model** (30-60 minutes on Google Colab)
2. **Export to CoreML** (2 minutes)
3. **Integrate in iOS** (10 minutes)

---

## Step 1: Train & Export the Model

### 1.1 Open in Google Colab

1. Go to [Google Colab](https://colab.research.google.com/)
2. File → Upload notebook
3. Upload `aisee_test.ipynb` from this repository
4. Runtime → Change runtime type → Select "T4 GPU"

### 1.2 Run Training

Execute all cells in order (Runtime → Run all):

```
✓ Cell 1-2: Setup and install dependencies (~1 min)
✓ Cell 3-4: Download dataset from Roboflow (~2 min)
✓ Cell 5: Train YOLOv11 model (~30-60 min)
✓ Cell 6: Export to CoreML format (~2 min)
✓ Cell 7-9: Save to Google Drive (~1 min)
```

### 1.3 Download Model

1. Open your Google Drive
2. Find `yolov11n.mlpackage` in the root folder
3. Download it to your Mac
4. You now have the CoreML model ready for iOS!

---

## Step 2: Setup Xcode Project

### 2.1 Add Model to Xcode

1. Open your Xcode project
2. Drag `yolov11n.mlpackage` into Project Navigator
3. Check ✓ "Copy items if needed"
4. Check ✓ your app target

### 2.2 Configure Model

1. Select `yolov11n.mlpackage` in Project Navigator
2. File Inspector (right panel) → Type → "Core ML Model"
3. Verify Target Membership is checked

### 2.3 Add Detection View

1. Drag `BusLabelDetectorView.swift` into your project
2. Ensure it's added to your app target

---

## Step 3: Use in Your App

### 3.1 Update Your App Entry Point

```swift
import SwiftUI

@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            BusLabelDetectorView()
        }
    }
}
```

### 3.2 Clean and Build

1. Product → Clean Build Folder (⇧⌘K)
2. Product → Build (⌘B)
3. Product → Run (⌘R)

### 3.3 Test the Detection

The app will:
- Load the CoreML model
- Process test images
- Detect bus labels
- Extract bus numbers using OCR
- Display results with bounding boxes

---

## ✅ Verification

You should see:
- ✓ No build errors
- ✓ App launches successfully  
- ✓ Detections appear on images (if bus labels present)
- ✓ OCR text shown in yellow bubbles
- ✓ Detection list shows confidence scores

---

## 🚨 Common Issues

### "Model not found"
→ Check File Inspector → Type = "Core ML Model"  
→ Clean Build Folder and rebuild

### "No detections"
→ Verify image contains visible bus labels  
→ Lower confidence threshold in code (line 172)

### "Invalid results"
→ Re-export model from notebook with `nms=True`  
→ Ensure model format is correct

---

## 📚 Next Steps

- **Customize detection**: Adjust confidence threshold in Swift code
- **Add your images**: Replace test image with your own bus photos
- **Improve model**: Train with more diverse dataset
- **Optimize performance**: Test on real device for best results

For detailed troubleshooting, see [XCODE_SETUP.md](XCODE_SETUP.md)

For complete documentation, see [README.md](README.md)

---

## 💡 Tips

- **Use real device** for accurate performance testing
- **Train with diverse data** for better generalization
- **Monitor memory usage** with Xcode Instruments
- **Keep model size small** for faster app downloads
- **Test edge cases** (poor lighting, angles, distances)

---

**Questions?** Check the troubleshooting sections in README.md and XCODE_SETUP.md
