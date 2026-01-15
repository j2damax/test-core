# Xcode Project Setup Guide

This guide walks through setting up the YOLOv11 CoreML model in your Xcode project.

## Prerequisites

- Xcode 14.0 or later
- iOS 15.0+ deployment target
- `yolov11n.mlpackage` downloaded from Google Drive (after training)

## Step-by-Step Setup

### 1. Add the CoreML Model to Your Project

1. **Download the model**
   - After running `aisee_test.ipynb`, download `yolov11n.mlpackage` from Google Drive
   - Save it to a convenient location on your Mac

2. **Add to Xcode**
   - Open your Xcode project
   - In the Project Navigator (⌘1), right-click your project folder
   - Select "Add Files to [Your Project]..."
   - Navigate to `yolov11n.mlpackage`
   - **Important**: Check "Copy items if needed"
   - Ensure your app target is selected under "Add to targets"
   - Click "Add"

### 2. Configure the Model

1. **Select the model file**
   - Click on `yolov11n.mlpackage` in the Project Navigator
   - The model details will appear in the editor

2. **Verify File Inspector settings**
   - Open the File Inspector (⌘⌥1) on the right panel
   - Under "Type", ensure it says "CoreML Model" or "Default - Core ML Model"
   - If it says "Default - Data" or something else:
     - Click the dropdown
     - Select "Core ML Model" (or similar)
   - Under "Target Membership", verify your app target is checked

3. **Check Model Info**
   - In the editor, you should see:
     - Model type: Object Detection
     - Inputs: Image (typically 640×640 RGB)
     - Outputs: Coordinates, Confidence, etc.
   - If the model info doesn't appear, it might not be recognized as a CoreML model

### 3. Clean and Build

1. **Clean Build Folder**
   - Product → Clean Build Folder (⇧⌘K)
   - This ensures any cached data is cleared

2. **Build the Project**
   - Product → Build (⌘B)
   - During build, Xcode compiles `yolov11n.mlpackage` → `yolov11n.mlmodelc`
   - The compiled model is embedded in your app bundle

3. **Verify Build Success**
   - Check the build log for any errors
   - The model should compile without warnings

### 4. Add BusLabelDetectorView to Your App

1. **Add the Swift file**
   - Drag `BusLabelDetectorView.swift` into your Xcode project
   - Ensure it's added to your app target

2. **Update your App or ContentView**
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

3. **Add a test image (optional)**
   - The code references a test image named "6371-883"
   - Add a bus label image to your Assets catalog with this name
   - Or modify line 369 in `BusLabelDetectorView.swift` to use a different image

### 5. Run the App

1. **Select a simulator or device**
   - Choose iOS 15.0+ simulator or physical device
   - Physical device recommended for better performance

2. **Run the app** (⌘R)
   - The app should launch
   - It will automatically attempt to load and process the test image

## Troubleshooting

### Model Not Found Error

**Error**: "Model 'yolov11n.mlmodelc' not found in app bundle"

**Checklist**:
- [ ] Is `yolov11n.mlpackage` visible in Project Navigator?
- [ ] Is Target Membership checked in File Inspector?
- [ ] Is Type set to "Core ML Model" in File Inspector?
- [ ] Did you Clean Build Folder?
- [ ] Did the build complete successfully?

**Solution**:
1. Select `yolov11n.mlpackage` in Project Navigator
2. File Inspector → Type → "Core ML Model"
3. File Inspector → Target Membership → Check your app target
4. Product → Clean Build Folder (⇧⌘K)
5. Product → Build (⌘B)

### Model Not Compiling

**Symptom**: Build succeeds but model still not found at runtime

**Possible Causes**:
- Model is treated as generic data file, not CoreML
- Model not included in Copy Bundle Resources build phase

**Solution**:
1. Select your project in Project Navigator
2. Select your app target
3. Go to "Build Phases" tab
4. Expand "Copy Bundle Resources"
5. Look for `yolov11n.mlpackage` or `yolov11n.mlmodelc`
6. If missing, click "+" and add `yolov11n.mlpackage`
7. Clean and rebuild

### Invalid Results Error

**Error**: "Invalid detection results from model. Vision returned: ..."

**Cause**: The model might not be in the correct format for Vision framework

**Solution**:
1. Verify the model was exported with `format='coreml'` in the notebook
2. Ensure NMS was enabled during export (`nms=True`)
3. Re-export the model from the notebook
4. Replace the old model in Xcode with the new one

### No Detections Found

**Symptom**: App runs but detects nothing

**Possible Causes**:
- Model not trained on similar images
- Confidence threshold too high
- Image format issues

**Solution**:
1. Verify your test image contains a bus label
2. Lower confidence threshold in code (line 172):
   ```swift
   .filter { $0.confidence > 0.3 }  // Reduced from 0.5
   ```
3. Check that training data was similar to test images

## Verification Steps

After setup, verify everything works:

1. **Build Log Check**
   - Build should show: "Compiling yolov11n.mlpackage"
   - No errors or warnings about the model

2. **Runtime Check**
   - App launches without crashes
   - No error messages displayed
   - Detections appear (if test image has bus labels)

3. **Model Info Check**
   - In Xcode, click on `yolov11n.mlpackage`
   - Should show model architecture and specifications
   - If blank, model might be corrupted

## Advanced Configuration

### Changing Model Input Size

If you need a different input size:

1. Re-export from notebook with different `imgsz`:
   ```python
   model.export(format='coreml', nms=True, imgsz=320)  # Smaller/faster
   ```

2. Update in Swift if needed (usually automatic)

### Adjusting Confidence Threshold

Lower threshold = more detections (but more false positives):
```swift
.filter { $0.confidence > 0.3 }  // Line 172
```

Higher threshold = fewer detections (but more accurate):
```swift
.filter { $0.confidence > 0.7 }  // Line 172
```

### Using Different Model Variants

For better accuracy (larger model):
- Train with `yolo11s.pt` or `yolo11m.pt` instead of `yolo11n.pt`
- Export and integrate the same way
- Update model name in Swift code

## Best Practices

✅ **Always use .mlpackage format** (modern, preferred by Apple)  
✅ **Include NMS in the model** for better mobile performance  
✅ **Test on real device** for accurate performance metrics  
✅ **Monitor memory usage** with Instruments  
✅ **Version control your model** (or at least document training parameters)  
✅ **Keep model size reasonable** for app download size  

## Resources

- [CoreML Documentation](https://developer.apple.com/documentation/coreml)
- [Vision Framework Guide](https://developer.apple.com/documentation/vision)
- [ML Model Deployment](https://developer.apple.com/machine-learning/models/)
- [Xcode CoreML Tools](https://developer.apple.com/documentation/coreml/converting_trained_models_to_core_ml)

## Support

If you encounter issues not covered here:

1. Check the console output in Xcode for detailed error messages
2. Verify model format using `coremltools` in Python
3. Review Apple's CoreML documentation
4. Check Ultralytics YOLOv11 export documentation
