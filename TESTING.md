# Testing & Validation Guide

This guide helps you verify that your bus label detection system is working correctly at each stage.

## Testing Phases

1. [Model Training Validation](#phase-1-model-training-validation)
2. [CoreML Export Validation](#phase-2-coreml-export-validation)
3. [Xcode Integration Validation](#phase-3-xcode-integration-validation)
4. [Runtime Testing](#phase-4-runtime-testing)

---

## Phase 1: Model Training Validation

### During Training (in Colab)

**What to check:**
- Training starts without errors
- Loss decreases over epochs
- mAP (mean Average Precision) increases
- Training completes successfully

**Expected output:**
```
Epoch 1/100: loss=1.234, mAP50=0.45
Epoch 50/100: loss=0.567, mAP50=0.78
Epoch 100/100: loss=0.234, mAP50=0.89
Training complete!
```

**Success criteria:**
- ✅ Final mAP50 > 0.7 (70% accuracy)
- ✅ Loss decreasing trend
- ✅ No CUDA errors
- ✅ best.pt file created

**Troubleshooting:**
| Issue | Solution |
|-------|----------|
| CUDA out of memory | Reduce batch size in training |
| Dataset not found | Re-run Roboflow download cell |
| Training stuck at 0% | Check GPU is enabled |

### After Training

**Verify model file:**
```python
import os
model_path = "/content/runs/detect/train/weights/best.pt"
if os.path.exists(model_path):
    size_mb = os.path.getsize(model_path) / (1024 * 1024)
    print(f"✅ Model found: {size_mb:.2f} MB")
else:
    print("❌ Model not found")
```

**Expected:** Model size ~5-15 MB

---

## Phase 2: CoreML Export Validation

### During Export

**What to check:**
- Export completes without errors
- .mlpackage directory is created
- No warnings about unsupported operations

**Expected output:**
```
Exporting model to CoreML format...
✅ Model exported to CoreML format successfully!
📦 The exported model will be in the same directory as best.pt
Look for: best.mlpackage or best_nms.mlpackage
```

**Verify export:**
```python
import os
weights_dir = "/content/runs/detect/train/weights/"
files = os.listdir(weights_dir)
mlpackages = [f for f in files if f.endswith('.mlpackage')]
print(f"Found {len(mlpackages)} CoreML packages: {mlpackages}")
```

**Success criteria:**
- ✅ At least one .mlpackage file exists
- ✅ File size ~5-15 MB
- ✅ Successfully copied to Google Drive

### Validate CoreML Model (Optional)

If you have coremltools installed locally:

```python
import coremltools as ct

# Load the model
model = ct.models.MLModel("yolov11n.mlpackage")

# Check specifications
print(f"Model type: {model.get_spec().description}")
print(f"Input: {model.get_spec().description.input}")
print(f"Output: {model.get_spec().description.output}")
```

**Expected:**
- Input: Image (RGB, 640×640)
- Output: Coordinates, Confidence, etc.
- No errors loading

---

## Phase 3: Xcode Integration Validation

### Step 1: Model Added to Project

**Checklist:**
- [ ] yolov11n.mlpackage visible in Project Navigator
- [ ] File Inspector shows Type: "Core ML Model"
- [ ] Target Membership includes your app target
- [ ] Model icon shows in Navigator (brain icon)

**Verify in Xcode:**
1. Click on yolov11n.mlpackage
2. You should see model details in editor
3. Look for "Model Class" and "Model Type"

### Step 2: Build Validation

**Build the project:**
```
Product → Build (⌘B)
```

**Check build log for:**
```
CompileCoreMLModels yolov11n.mlpackage
    ✓ Compiling yolov11n.mlpackage
    ✓ Compiled model: yolov11n.mlmodelc
```

**Success criteria:**
- ✅ Build succeeds (green checkmark)
- ✅ No errors about missing model
- ✅ No CoreML compilation errors
- ✅ Build folder contains .mlmodelc

**Troubleshooting:**
| Issue | Solution |
|-------|----------|
| Model not compiling | Check Type in File Inspector |
| Model not found | Verify Target Membership |
| Compilation errors | Re-export from notebook |

### Step 3: Bundle Validation

**Check compiled model in app bundle:**

Add temporary code to verify:
```swift
func verifyModelExists() {
    let modelURL = Bundle.main.url(forResource: "yolov11n", withExtension: "mlmodelc")
    if let url = modelURL {
        print("✅ Model found at: \(url)")
    } else {
        print("❌ Model not in bundle")
        
        // List all bundle resources
        let resources = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil)
        print("Available .mlmodelc files: \(resources ?? [])")
    }
}
```

Call this in `onAppear` and check Xcode console.

**Expected output:**
```
✅ Model found at: file:///.../yolov11n.mlmodelc
```

---

## Phase 4: Runtime Testing

### Test 1: Model Loading

**What to test:**
- App launches without crashes
- No "model not found" errors
- Model loads successfully

**How to test:**
1. Run app on simulator or device
2. Check Xcode console for error messages
3. Verify no red error text in app UI

**Success criteria:**
- ✅ No error messages displayed
- ✅ Console shows successful model load
- ✅ No crashes

**Expected console output:**
```
(No errors about model loading)
```

**If errors occur:**
```
Detection failed: Model 'yolov11n.mlmodelc' not found...
```
→ Go back to Phase 3

### Test 2: Detection Functionality

**Test with sample image:**

**Method A: Use provided test image**
1. Add image to Assets catalog named "6371-883"
2. Run app
3. Image loads and processes automatically

**Method B: Use custom image**
1. Change line 369 in BusLabelDetectorView.swift:
```swift
if let image = UIImage(named: "your-image-name") {
```
2. Run app

**What to check:**
- Processing indicator appears
- Image displays correctly
- Bounding boxes appear (if bus labels present)
- OCR text shown in yellow bubbles
- Detection list populated

**Success criteria:**
- ✅ Image loads
- ✅ Processing completes (< 5 seconds)
- ✅ Detections appear (if applicable)
- ✅ Confidence scores shown
- ✅ OCR text extracted

### Test 3: Detection Accuracy

**Create test suite:**

| Image Type | Expected Result |
|------------|----------------|
| Clear bus label, good lighting | High confidence (>0.8), correct OCR |
| Bus label at angle | Medium confidence (0.5-0.8), may have OCR |
| Poor lighting | Lower confidence, may miss |
| No bus label | No detections (correct) |
| Multiple labels | Multiple detections |

**How to test:**
1. Prepare diverse test images
2. Add to Assets catalog
3. Process each image
4. Record results

**Evaluation criteria:**
- Precision: % of detections that are correct
- Recall: % of actual labels detected
- OCR accuracy: % of correctly read numbers

**Target performance:**
- Precision: > 80%
- Recall: > 70%
- OCR accuracy: > 85% (on clear labels)

### Test 4: Edge Cases

**Test unusual scenarios:**

1. **Very small bus labels**
   - Expected: May not detect (acceptable)
   
2. **Very large bus labels**
   - Expected: Should detect with high confidence

3. **Partial bus labels (cropped)**
   - Expected: May detect, lower confidence

4. **Similar objects (not bus labels)**
   - Expected: Should not detect (or very low confidence)

5. **Multiple buses in one image**
   - Expected: Multiple detections

### Test 5: Performance Testing

**Measure performance metrics:**

Add timing code:
```swift
let startTime = Date()
await detectObjects(in: image)
let duration = Date().timeIntervalSince(startTime)
print("Detection took: \(duration * 1000)ms")
```

**Expected performance:**
- **Simulator**: 200-500ms per image
- **Real device**: 50-200ms per image

**Test on different devices:**
- iPhone 12 or newer: < 100ms
- iPhone 8-11: 100-200ms
- iPad: Similar to iPhone

**Memory usage:**
- Check in Xcode Instruments
- Expected: 50-150 MB during detection
- Should return to baseline after

---

## Automated Testing Checklist

Copy this checklist for each test run:

### Model Training
- [ ] Training completes without errors
- [ ] Final mAP50 > 0.7
- [ ] best.pt created (~5-15 MB)

### CoreML Export
- [ ] Export completes successfully
- [ ] .mlpackage created
- [ ] Copied to Google Drive
- [ ] Downloaded to Mac

### Xcode Setup
- [ ] Model added to project
- [ ] Type set to "Core ML Model"
- [ ] Target membership checked
- [ ] Build succeeds
- [ ] No compilation errors

### Runtime
- [ ] App launches successfully
- [ ] Model loads without errors
- [ ] Test image processes
- [ ] Detections appear (when applicable)
- [ ] OCR extracts text
- [ ] Performance acceptable (< 500ms)

---

## Debugging Tools

### Xcode Console Filters

Filter console output for relevant messages:
```
model          # Model-related messages
detection      # Detection messages
Vision         # Vision framework messages
CoreML         # CoreML messages
```

### Common Debug Outputs

**Successful detection:**
```
(No error messages, detections displayed)
```

**Model not found:**
```
Detection failed: Model 'yolov11n.mlmodelc' not found in app bundle...
Found .mlpackage: yolov11n.mlpackage
```

**Invalid model format:**
```
Detection failed: Invalid detection results from model...
Vision returned: VNCoreMLFeatureValueObservation
```

**No detections (valid):**
```
(No error, empty detection list - correct if no labels in image)
```

---

## Performance Benchmarks

### Expected Metrics

| Device | Load Time | Inference Time | Memory |
|--------|-----------|----------------|--------|
| iPhone 14 Pro | < 500ms | 50-80ms | 60 MB |
| iPhone 12 | < 800ms | 80-120ms | 70 MB |
| iPhone 8 | < 1000ms | 150-200ms | 80 MB |
| iPad Pro | < 500ms | 40-70ms | 70 MB |
| Simulator | < 1000ms | 200-500ms | 100 MB |

### Optimization Tips

If performance is slow:
1. Test on real device (not simulator)
2. Build in Release mode (not Debug)
3. Close other apps
4. Ensure GPU is being used
5. Consider smaller model variant

---

## Regression Testing

After making changes, re-run these critical tests:

1. **Smoke test**: App launches and loads model
2. **Basic detection**: Detects known bus label
3. **OCR test**: Extracts correct bus number
4. **No crash test**: Handles images without labels
5. **Performance test**: Still meets timing targets

---

## Reporting Issues

If you find bugs, include:

1. **Environment**
   - Device/Simulator
   - iOS version
   - Xcode version

2. **Model info**
   - Training date
   - mAP score
   - Export method

3. **Observed behavior**
   - What you did
   - What happened
   - What you expected

4. **Console output**
   - Relevant error messages
   - Stack traces

5. **Test image** (if applicable)
   - Image that caused issue
   - Expected vs actual result

---

## Success Criteria Summary

Your system is working correctly if:

✅ **Training**: mAP50 > 70%, model exports successfully  
✅ **Integration**: Xcode builds without errors  
✅ **Loading**: Model loads in < 1 second  
✅ **Detection**: Finds bus labels with > 80% precision  
✅ **OCR**: Extracts text with > 85% accuracy  
✅ **Performance**: Processes images in < 500ms  
✅ **Stability**: No crashes or memory leaks  

If all criteria met: **System is production-ready! 🎉**
