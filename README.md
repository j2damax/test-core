# Bus Label Detection - YOLOv11 to CoreML

A complete solution for training a YOLOv11 bus label detection model and integrating it into iOS applications using CoreML.

## 🎯 Purpose

This project enables detecting bus labels (bus numbers) in images and extracting the bus number text using:
- **YOLOv11** for object detection (bus label bounding boxes)
- **Vision OCR** for text recognition (extracting bus numbers)
- **CoreML** for on-device iOS inference

## 📁 Project Structure

- `aisee_test.ipynb` - Jupyter notebook for training and exporting the YOLOv11 model to CoreML
- `BusLabelDetectorView.swift` - SwiftUI view implementing the detection pipeline
- `README.md` - This documentation

## 🚀 Complete Workflow

### Part 1: Model Training & Export (Python/Colab)

1. **Open the notebook in Google Colab**
   - Upload `aisee_test.ipynb` to Google Colab
   - Select Runtime → Change runtime type → GPU (T4 recommended)

2. **Run the notebook cells sequentially**
   - Install Ultralytics YOLO
   - Download training dataset from Roboflow
   - Train YOLOv11 model (100 epochs, ~30-60 minutes)
   - Export to CoreML format
   - Save to Google Drive

3. **Download the CoreML model**
   - After training completes, download `yolov11n.mlpackage` from your Google Drive
   - This is the model that will be integrated into your iOS app

### Part 2: iOS Integration (Swift/Xcode)

1. **Add model to Xcode project**
   ```
   - Drag yolov11n.mlpackage into your Xcode project navigator
   - Check "Copy items if needed"
   - Ensure it's added to your app target
   ```

2. **Configure model in Xcode**
   ```
   - Select yolov11n.mlpackage in the project navigator
   - In File Inspector (right panel), set Type to "Core ML Model"
   - Verify Target Membership is checked for your app
   ```

3. **Clean and rebuild**
   ```
   - Product → Clean Build Folder (⌘⇧K)
   - Product → Build (⌘B)
   - The model will be compiled to yolov11n.mlmodelc
   ```

4. **Use BusLabelDetectorView in your app**
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

## 🔧 Technical Details

### Model Specifications

- **Framework**: YOLOv11n (nano variant for mobile efficiency)
- **Input**: 640x640 RGB images
- **Output**: Object detections with bounding boxes and confidence scores
- **Classes**: Bus labels (trained on custom dataset)
- **NMS**: Non-Maximum Suppression included in CoreML model
- **Format**: .mlpackage (CoreML 5+)

### Swift Implementation

The `BusLabelDetectorView.swift` implements:

1. **Object Detection Pipeline**
   - Loads CoreML model using Vision framework
   - Performs inference on input images
   - Filters detections by confidence threshold (>0.5)

2. **OCR Pipeline**
   - Uses Vision's text recognition on detected regions
   - Extracts bus numbers from bounding boxes
   - Returns recognized text with high accuracy

3. **UI Features**
   - Displays original image with detection overlays
   - Shows bounding boxes in red
   - Displays recognized text in yellow bubbles
   - Lists all detections with confidence scores

### Coordinate System Handling

The implementation correctly handles coordinate system conversions:
- **Vision**: Normalized coordinates (0-1), bottom-left origin
- **SwiftUI**: Pixel coordinates, top-left origin
- **Aspect Fit**: Maintains image aspect ratio for accurate detection

## 📋 Requirements

### Python/Colab Requirements
- Python 3.8+
- ultralytics (YOLO implementation)
- coremltools (for CoreML export)
- roboflow (dataset management)
- Google Colab with GPU runtime

### iOS Requirements
- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+
- Vision framework
- CoreML framework

## 🎓 Best Practices Followed

### Apple CoreML Guidelines
✅ Model packaged as .mlpackage (modern CoreML format)  
✅ NMS included in model for better performance  
✅ Vision framework integration for standardized inference  
✅ Proper error handling and diagnostics  
✅ Efficient on-device processing  

### Implementation Quality
✅ Async/await for non-blocking inference  
✅ Concurrent OCR processing for multiple detections  
✅ Proper coordinate system conversions  
✅ Memory-efficient image handling  
✅ Comprehensive error messages  

## 🔍 Troubleshooting

### Model Not Found Error
**Problem**: "Model 'yolov11n.mlmodelc' not found in app bundle"

**Solutions**:
1. Verify `yolov11n.mlpackage` is in the Xcode project
2. Check File Inspector → Type is set to "Core ML Model"
3. Confirm Target Membership is checked
4. Clean Build Folder and rebuild

### Model Not Compiling
**Problem**: .mlpackage exists but not compiled to .mlmodelc

**Solutions**:
1. Check Xcode treats it as Core ML model, not generic data
2. Verify deployment target is iOS 15.0+
3. Check Build Phases → Copy Bundle Resources includes the model

### No Detections Returned
**Problem**: Model runs but returns no detections

**Solutions**:
1. Check image quality and bus label visibility
2. Verify model was trained on similar data
3. Adjust confidence threshold in Swift code (line 172)
4. Ensure image is properly oriented

## 📚 References

- [Apple Machine Learning Models](https://developer.apple.com/machine-learning/models/)
- [CoreML Tools Documentation](https://apple.github.io/coremltools/docs-guides/)
- [Ultralytics YOLOv11](https://docs.ultralytics.com/models/yolo11/)
- [Vision Framework](https://developer.apple.com/documentation/vision)

## 📝 License

This is a proof-of-concept project. Ensure you have appropriate licenses for:
- Training data usage
- Model deployment in your application
- Any third-party dependencies

## 🤝 Contributing

To improve this project:
1. Train with more diverse bus label data
2. Optimize model size for faster inference
3. Add support for different bus label styles
4. Implement real-time video detection
5. Add multi-language OCR support