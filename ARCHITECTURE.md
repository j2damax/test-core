# Bus Label Detection Workflow

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRAINING PHASE (Google Colab)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. Dataset Download (Roboflow)                                  │
│     └─> Bus label images + annotations                          │
│                                                                   │
│  2. YOLOv11 Training                                             │
│     └─> Input: 640x640 images                                   │
│     └─> Output: best.pt (PyTorch model)                         │
│                                                                   │
│  3. CoreML Export                                                │
│     └─> Input: best.pt                                          │
│     └─> Process: Ultralytics export with NMS                    │
│     └─> Output: yolov11n.mlpackage                              │
│                                                                   │
│  4. Save to Google Drive                                         │
│     └─> Download yolov11n.mlpackage to Mac                      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    BUILD PHASE (Xcode)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. Add Model to Project                                         │
│     └─> yolov11n.mlpackage → Xcode project                      │
│                                                                   │
│  2. Xcode Compilation                                            │
│     └─> .mlpackage → .mlmodelc (compiled CoreML)                │
│                                                                   │
│  3. App Bundle Integration                                       │
│     └─> yolov11n.mlmodelc embedded in app                       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    RUNTIME PHASE (iOS Device)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. Image Input                                                  │
│     └─> UIImage from camera/gallery/assets                      │
│                                                                   │
│  2. Object Detection (YOLO)                                      │
│     ├─> Load yolov11n.mlmodelc                                  │
│     ├─> Vision framework processes image                        │
│     ├─> Model inference (on-device)                             │
│     └─> Output: Bounding boxes + confidence scores              │
│                                                                   │
│  3. Text Recognition (OCR)                                       │
│     ├─> For each detected bounding box                          │
│     ├─> Vision's text recognition                               │
│     └─> Output: Bus number text                                 │
│                                                                   │
│  4. Display Results                                              │
│     ├─> Draw red bounding boxes                                 │
│     ├─> Show bus numbers in yellow bubbles                      │
│     └─> List detections with confidence                         │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
Training Data                Model Export              iOS Integration
─────────────               ──────────────           ─────────────────

Bus Images                   PyTorch Model            CoreML Model
    ↓                            ↓                         ↓
Annotations     →→→→→     YOLOv11 Training  →→→→→   .mlpackage
    ↓                            ↓                         ↓
data.yaml                    best.pt          →→→→→   .mlmodelc
                                                          ↓
                                                   iOS App Bundle
```

## Component Responsibilities

### Python/Notebook (aisee_test.ipynb)
- Dataset management
- Model training
- CoreML export
- Cloud storage

### Swift/iOS (BusLabelDetectorView.swift)
- Model loading
- Image preprocessing
- Inference execution
- OCR processing
- UI rendering

## File Formats

| Format | Usage | Size | Platform |
|--------|-------|------|----------|
| `.pt` | PyTorch training | ~5-10 MB | Python/Training |
| `.mlpackage` | CoreML source | ~5-10 MB | Xcode/iOS |
| `.mlmodelc` | Compiled CoreML | ~5-10 MB | iOS Runtime |

## Key Technologies

### Training Stack
- **Ultralytics YOLOv11**: Object detection architecture
- **PyTorch**: Deep learning framework
- **Roboflow**: Dataset management
- **coremltools**: Model conversion

### iOS Stack
- **CoreML**: Apple's ML framework
- **Vision**: Computer vision framework
- **SwiftUI**: UI framework
- **UIKit**: Image handling

## Performance Characteristics

### Training (Google Colab T4 GPU)
- Training time: 30-60 minutes (100 epochs)
- Export time: 1-2 minutes
- GPU memory: ~4-8 GB

### iOS Runtime (iPhone/iPad)
- Model loading: < 1 second
- Inference time: 50-200ms per image
- Memory usage: ~50-100 MB
- Works offline (on-device)

## Model Specifications

### Input
- Format: RGB Image
- Size: 640×640 pixels
- Type: Multi-dimensional array [1, 3, 640, 640]

### Output (Vision-compatible)
- Type: VNRecognizedObjectObservation[]
- Contains: Bounding boxes, confidence scores, labels
- Coordinates: Normalized (0-1), bottom-left origin

### Processing
- NMS threshold: Built into model
- Confidence threshold: 0.5 (configurable in Swift)
- Max detections: Varies by image content

## Error Handling

```
Model Loading
    ├─> File not found → Diagnostic error message
    ├─> Wrong format → Invalid results error
    └─> Success → Continue to inference

Inference
    ├─> Invalid image → Error propagation
    ├─> No detections → Empty results (valid)
    └─> Success → OCR processing

OCR
    ├─> No text found → nil text (valid)
    ├─> Error → Error propagation
    └─> Success → Display results
```

## Coordinate Systems

### Vision Framework
- Origin: Bottom-left
- Range: 0.0 to 1.0 (normalized)
- Y-axis: Up is positive

### SwiftUI
- Origin: Top-left
- Range: Pixel coordinates
- Y-axis: Down is positive

### Conversion
```swift
// Vision → SwiftUI
let x = visionRect.minX * imageRect.width + imageRect.minX
let y = (1 - visionRect.maxY) * imageRect.height + imageRect.minY
let width = visionRect.width * imageRect.width
let height = visionRect.height * imageRect.height
```

## Best Practices Implementation

✅ **Model Packaging**: Modern .mlpackage format  
✅ **NMS Integration**: Included in model (better performance)  
✅ **Vision Framework**: Standardized Apple API  
✅ **Async Processing**: Non-blocking UI updates  
✅ **Error Diagnostics**: Detailed error messages  
✅ **Memory Efficiency**: Proper resource management  
✅ **Coordinate Accuracy**: Correct system conversions  
✅ **Aspect Ratio**: Maintained for accurate detection  

## Security & Privacy

- **On-device processing**: No data sent to servers
- **No network required**: Works offline
- **No data collection**: Images stay on device
- **User privacy**: Full control over data

## Future Enhancements

Possible improvements:
1. Real-time video detection
2. Multi-language OCR support
3. Multiple bus label detection
4. Direction/route information extraction
5. Integration with transit APIs
6. Augmented reality overlay
7. Accessibility features
8. Battery optimization
