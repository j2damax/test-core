# Frequently Asked Questions (FAQ)

Common questions and answers about the Bus Label Detection system.

## General Questions

### Q: What does this project do?

**A:** This project trains a YOLOv11 object detection model to identify bus labels in images, then uses OCR to extract the bus number text. The trained model is exported to CoreML format for use in iOS applications, enabling on-device, real-time bus label detection on iPhones and iPads.

### Q: Do I need programming experience?

**A:** Basic knowledge is helpful but not required. The notebook is designed to run cell-by-cell in Google Colab (free), and the Swift code is ready to use. Follow the QUICKSTART.md guide for step-by-step instructions.

### Q: Is this free to use?

**A:** Yes! The project uses:
- Free Google Colab (with GPU)
- Free open-source libraries (Ultralytics, coremltools)
- Free Apple frameworks (CoreML, Vision)

You only need a Google account and a Mac with Xcode.

---

## Training Questions

### Q: How long does training take?

**A:** On Google Colab with T4 GPU:
- Dataset download: 2-5 minutes
- Training (100 epochs): 30-60 minutes
- Export to CoreML: 1-2 minutes
- **Total: About 40-70 minutes**

### Q: Can I train on my own computer?

**A:** Yes, but you need:
- NVIDIA GPU with CUDA support
- At least 8GB GPU memory
- Python 3.8+ with dependencies

Google Colab is recommended as it provides free GPU access.

### Q: Can I use my own bus label images?

**A:** Absolutely! Replace the Roboflow dataset download with your own:
1. Upload images to Roboflow
2. Annotate bus labels (bounding boxes)
3. Export in YOLOv11 format
4. Update the Roboflow API code in the notebook

### Q: How many images do I need for training?

**A:** Recommended:
- **Minimum**: 50-100 images
- **Good**: 200-500 images
- **Better**: 500-1000+ images

More diverse images = better model generalization.

### Q: What if training fails or stops?

**A:** Common solutions:
1. **CUDA out of memory**: Reduce batch size or use smaller model
2. **Runtime disconnected**: Colab has time limits; save checkpoints
3. **Dataset error**: Re-run the download cell
4. **Low accuracy**: Need more training data or longer training

---

## Export Questions

### Q: What's the difference between .pt, .mlpackage, and .mlmodelc?

**A:** 
- **`.pt`**: PyTorch model format (training)
- **`.mlpackage`**: CoreML source format (Xcode can compile)
- **`.mlmodelc`**: Compiled CoreML model (iOS runtime)

You train → `.pt`, export → `.mlpackage`, Xcode compiles → `.mlmodelc`

### Q: Why do I need to enable NMS in the export?

**A:** NMS (Non-Maximum Suppression) removes duplicate detections. Including it in the model:
- Reduces code complexity
- Improves performance
- Ensures consistent behavior

Always use `nms=True` when exporting.

### Q: Can I export to other formats?

**A:** Yes! Ultralytics supports:
- ONNX (cross-platform)
- TensorFlow/TFLite (Android)
- TensorRT (NVIDIA)
- OpenVINO (Intel)

But for iOS, CoreML is the best choice.

### Q: What if export fails?

**A:** Check:
1. Ultralytics version is up to date (`pip install -U ultralytics`)
2. coremltools is installed (`pip install coremltools`)
3. Model training completed successfully
4. Enough disk space in Colab

---

## Xcode / iOS Questions

### Q: What iOS version is required?

**A:** 
- **Minimum**: iOS 15.0
- **Recommended**: iOS 16.0+
- **Best**: Latest iOS version

Newer iOS versions have better CoreML performance.

### Q: Does it work on iPad?

**A:** Yes! The code works on:
- iPhone (iOS 15+)
- iPad (iPadOS 15+)
- Mac (with Mac Catalyst, if adapted)

### Q: Why is the model not found in my app?

**A:** This is the most common issue. Solutions:

1. **Check File Inspector**
   - Select yolov11n.mlpackage
   - Type must be "Core ML Model", not "Data"

2. **Check Target Membership**
   - File Inspector → Target Membership
   - Your app target must be checked

3. **Clean and Rebuild**
   - ⇧⌘K (Clean Build Folder)
   - ⌘B (Build)

4. **Verify model name**
   - Must be exactly `yolov11n.mlpackage`
   - Case-sensitive!

See XCODE_SETUP.md for detailed troubleshooting.

### Q: Can I use a different model name?

**A:** Yes! Update line 121 in BusLabelDetectorView.swift:
```swift
guard let modelURL = Bundle.main.url(forResource: "your-model-name", withExtension: "mlmodelc")
```

And update error messages to match.

### Q: How do I test with my own images?

**A:** Two options:

**Option 1**: Change test image (line 369):
```swift
if let image = UIImage(named: "your-image-name") {
```

**Option 2**: Add image picker:
```swift
// Add PhotosUI import and picker
```

### Q: Why are there no detections?

**A:** Possible reasons:
1. **No bus labels in image** (correct behavior)
2. **Confidence too high**: Lower threshold (line 172)
3. **Model not trained on similar images**: Retrain with better data
4. **Image quality poor**: Use clearer images

### Q: How accurate is the OCR?

**A:** Depends on:
- Image quality: Clear images → 90%+ accuracy
- Lighting: Good lighting → Better results
- Angle: Front-facing → More accurate
- Text size: Larger text → Easier to read

Vision's OCR is quite good for English numbers.

---

## Performance Questions

### Q: How fast is the detection?

**A:** Typical performance:
- **iPhone 14 Pro**: 50-80ms per image
- **iPhone 12**: 80-120ms
- **iPhone 8**: 150-200ms
- **Simulator**: 200-500ms

Always test on real device for accurate metrics.

### Q: Does it work offline?

**A:** Yes! Once the model is in the app:
- No internet required
- Fully on-device processing
- Complete privacy (no data sent anywhere)

### Q: How much battery does it use?

**A:** Very efficient:
- Uses Apple's optimized CoreML
- Leverages Neural Engine (on supported devices)
- Minimal battery impact for occasional use

Continuous video detection would use more battery.

### Q: What about app size?

**A:** Model adds ~5-15 MB to your app:
- YOLOv11n (nano): ~5-6 MB
- YOLOv11s (small): ~10-12 MB
- YOLOv11m (medium): ~25-30 MB

Nano variant is recommended for mobile.

---

## Model Improvement Questions

### Q: How can I improve detection accuracy?

**A:** 
1. **More training data**: 500+ diverse images
2. **Better annotations**: Accurate bounding boxes
3. **Data augmentation**: Vary lighting, angles, distances
4. **Longer training**: 150-200 epochs
5. **Larger model**: Use yolo11s.pt or yolo11m.pt

### Q: How do I handle different bus label styles?

**A:** Include examples in training:
- Different colors
- Different fonts
- Different sizes
- Different countries/regions

Model learns from variety.

### Q: Can I detect other things besides bus labels?

**A:** Yes! Change your training data:
1. Annotate different objects (cars, signs, etc.)
2. Train with same process
3. Model will detect those objects instead

The architecture is generic object detection.

### Q: How do I add more classes?

**A:** In training data:
1. Annotate multiple object types
2. Label each type differently
3. Train as usual
4. Model outputs multiple classes

Update Swift code to handle multiple classes if needed.

---

## Advanced Questions

### Q: Can I do real-time video detection?

**A:** Yes, but requires code changes:
1. Use AVCaptureSession for camera feed
2. Process frames in real-time
3. Handle frame rate vs. inference time tradeoff

Consider using smaller model or lower resolution for real-time.

### Q: How do I improve OCR accuracy?

**A:** 
1. **Preprocess images**: Enhance contrast, denoise
2. **Crop precisely**: Tight crop around text
3. **Upscale if needed**: Larger text → better recognition
4. **Set language**: Configure Vision for specific languages
5. **Post-process**: Validate format (e.g., bus numbers are typically numeric)

### Q: Can I run multiple models?

**A:** Yes! You can:
1. Load multiple CoreML models
2. Run them sequentially or in parallel
3. Combine results

Example: Detection model + Classification model

### Q: How do I reduce model size?

**A:** Options:
1. **Use smaller variant**: yolo11n (smallest)
2. **Quantization**: Convert to FP16 or INT8
3. **Pruning**: Remove less important weights
4. **Knowledge distillation**: Train smaller model from larger

CoreML tools support quantization.

### Q: Can I update the model without updating the app?

**A:** Not directly. CoreML models are bundled with the app. Options:
1. **App update**: Release new version with updated model
2. **Server-side**: Use remote inference (requires internet)
3. **Hybrid**: Bundle base model, download updates

On-device models require app update.

---

## Privacy & Security Questions

### Q: Is user data safe?

**A:** Very safe:
- All processing on-device
- No data sent to servers
- No analytics or tracking
- Images never leave the device
- Full user control

### Q: Do I need user permissions?

**A:** Depends on use case:
- **Camera access**: Yes (requires permission)
- **Photo library**: Yes (requires permission)
- **Bundled test images**: No permission needed

Add appropriate permission descriptions in Info.plist.

### Q: Can the model be extracted from the app?

**A:** Technically yes (like any bundled resource), but:
- Model is optimized for CoreML (not easily portable)
- Extracted model still requires interpretation
- Not a significant security risk for most apps

If concerned, consider server-side inference.

---

## Troubleshooting Questions

### Q: Build fails with "model not found"

**A:** See Xcode / iOS Questions above. Most common issue!

### Q: App crashes on launch

**A:** Check console for error message. Common causes:
1. Model format incompatible
2. iOS version too old
3. Memory issue (very large model)
4. Code syntax error

### Q: Detections are in wrong positions

**A:** Coordinate conversion issue. Verify:
1. Using `scaleFit` option in Vision request
2. Coordinate conversion is correct (Vision→SwiftUI)
3. Image aspect ratio maintained

Code should already handle this correctly.

### Q: OCR returns gibberish

**A:** Possible causes:
1. **Image region wrong**: Check bounding box accuracy
2. **Text too small**: Upscale before OCR
3. **Wrong language**: Configure Vision for correct language
4. **Poor image quality**: Enhance image quality

---

## Getting Help

### Q: Where can I get more help?

**A:** Resources:
1. **Documentation**: Read QUICKSTART.md, XCODE_SETUP.md, TESTING.md
2. **Apple Docs**: CoreML and Vision framework guides
3. **Ultralytics Docs**: YOLOv11 training and export
4. **Stack Overflow**: Search for CoreML or YOLO questions
5. **GitHub Issues**: Report bugs in the repository

### Q: How do I report a bug?

**A:** Include:
1. Description of the issue
2. Steps to reproduce
3. Expected vs actual behavior
4. Console output / error messages
5. Environment (Xcode version, iOS version, device)
6. Screenshots if applicable

See TESTING.md for detailed reporting template.

### Q: Can I contribute improvements?

**A:** Yes! Contributions welcome:
- Bug fixes
- Documentation improvements
- Performance optimizations
- New features
- Better test coverage

Follow standard GitHub contribution process.

---

## Best Practices

### Q: What are the best practices for production use?

**A:** Recommendations:

**Model:**
- ✅ Train with diverse, representative data
- ✅ Validate on separate test set
- ✅ Test edge cases thoroughly
- ✅ Monitor accuracy metrics

**Code:**
- ✅ Handle all error cases gracefully
- ✅ Provide user feedback during processing
- ✅ Test on multiple device types
- ✅ Optimize for battery and performance

**Privacy:**
- ✅ Add clear permission descriptions
- ✅ Explain why you need camera/photos access
- ✅ Don't collect user data without consent
- ✅ Follow Apple's privacy guidelines

**Testing:**
- ✅ Test on real devices (not just simulator)
- ✅ Test with various image qualities
- ✅ Monitor memory usage
- ✅ Check battery impact

See TESTING.md for comprehensive testing guide.

---

## Quick Reference

### File Overview
- `aisee_test.ipynb` → Training & export
- `BusLabelDetectorView.swift` → iOS detection UI
- `README.md` → Full documentation
- `QUICKSTART.md` → Fast setup guide
- `XCODE_SETUP.md` → Xcode integration details
- `TESTING.md` → Validation guide
- `ARCHITECTURE.md` → System design

### Key Commands

**Training:**
```bash
# In Colab, run all cells
Runtime → Run all
```

**Xcode:**
```
Clean: ⇧⌘K
Build: ⌘B
Run: ⌘R
```

**Swift:**
```swift
// Load model
Bundle.main.url(forResource: "yolov11n", withExtension: "mlmodelc")

// Adjust confidence
.filter { $0.confidence > 0.5 }
```

### Quick Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| Model not found | Check File Inspector → Type = "Core ML Model" |
| No detections | Lower confidence threshold |
| Slow performance | Test on real device |
| Wrong coordinates | Verify `scaleFit` is used |
| Poor OCR | Improve image quality |

---

Still have questions? Check the detailed documentation files or open an issue on GitHub!
