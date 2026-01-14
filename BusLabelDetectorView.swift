//
//  BusLabelDetectorView.swift
//  Bus Label Detection POC
//
//  A standalone proof of concept for detecting bus labels using YOLOv11 and OCR
//

import SwiftUI
import Vision
import CoreML
import UIKit

// MARK: - Detection Result Models

/// Represents a single detected bus label with its bounding box and OCR result
struct DetectionResult: Identifiable {
    let id = UUID()
    let boundingBox: CGRect // In Vision coordinates (normalized, bottom-left origin)
    let confidence: Float
    let ocrText: String?
}

// MARK: - ViewModel

@Observable
class LabelDetectorModel {
    var detections: [DetectionResult] = []
    var isProcessing = false
    var errorMessage: String?
    var processedImage: UIImage?
    
    // MARK: - Main Detection Function
    
    /// Performs object detection and OCR on the provided image
    /// - Parameter image: The UIImage to process
    func performDetection(on image: UIImage) {
        Task {
            await MainActor.run {
                isProcessing = true
                errorMessage = nil
                detections = []
                processedImage = image
            }
            
            do {
                // Step 1: Run YOLO detection
                let detectedObjects = try await detectObjects(in: image)
                
                // Step 2: Perform OCR on each detection concurrently
                let results = try await withThrowingTaskGroup(of: DetectionResult.self) { group in
                    for detection in detectedObjects {
                        group.addTask {
                            let ocrText = try await self.performOCR(on: image, in: detection.boundingBox)
                            return DetectionResult(
                                boundingBox: detection.boundingBox,
                                confidence: detection.confidence,
                                ocrText: ocrText
                            )
                        }
                    }
                    
                    var allResults: [DetectionResult] = []
                    for try await result in group {
                        allResults.append(result)
                    }
                    return allResults
                }
                
                await MainActor.run {
                    self.detections = results
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = Self.describe(error: error)
                    self.isProcessing = false
                }
            }
        }
    }

    private static func describe(error: Error) -> String {
        var parts: [String] = []

        if let localized = (error as? LocalizedError)?.errorDescription, !localized.isEmpty {
            parts.append(localized)
        } else {
            let desc = String(describing: error)
            parts.append(desc.isEmpty ? "Unknown error" : desc)
        }

        let ns = error as NSError
        // Only include details when we actually have a meaningful error domain.
        if ns.domain != "" {
            parts.append("(domain: \(ns.domain), code: \(ns.code))")
        }
        if let reason = ns.userInfo[NSLocalizedFailureReasonErrorKey] as? String, !reason.isEmpty {
            parts.append("Reason: \(reason)")
        }
        if let recovery = ns.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String, !recovery.isEmpty {
            parts.append("Suggestion: \(recovery)")
        }

        // print parts as a string to the terminal
        print("Detection failed: " + parts.joined(separator: " "))
        return "Detection failed: " + parts.joined(separator: " ")
    }
    
    // MARK: - YOLO Object Detection
    
    /// Detects objects using the YOLO Core ML model
    /// - Parameter image: The UIImage to process
    /// - Returns: Array of detected objects with bounding boxes
    private func detectObjects(in image: UIImage) async throws -> [(boundingBox: CGRect, confidence: Float)] {
        guard let cgImage = image.cgImage else {
            throw DetectionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Load the Core ML model
            guard let modelURL = Bundle.main.url(forResource: "yolov11n", withExtension: "mlmodelc") else {
                let discovery = Self.discoverBundledModels()

                let hasMlpackage = discovery.mlpackages.contains(where: { $0 == "yolov11n.mlpackage" })
                let hint: String
                if hasMlpackage && discovery.mlmodelcs.isEmpty {
                    hint = "Found yolov11n.mlpackage in the app bundle, but no compiled .mlmodelc exists. This typically means Xcode is treating the file as 'Default - Data' instead of a Core ML model, so it is not being compiled. In Xcode: select yolov11n.mlpackage → File Inspector → set Type to 'Core ML Model' (or similar), ensure Target Membership is checked, then Clean Build Folder and rebuild."
                } else if discovery.mlmodelcs.isEmpty && discovery.mlpackages.isEmpty {
                    hint = "No .mlmodelc or .mlpackage resources found in the app bundle. Ensure the model is added to the Xcode project (not just copied into the folder) and included in the AiSee target."
                } else {
                    var parts: [String] = []
                    if !discovery.mlmodelcs.isEmpty {
                        parts.append("Found .mlmodelc: \(discovery.mlmodelcs.joined(separator: ", ")).")
                    }
                    if !discovery.mlpackages.isEmpty {
                        parts.append("Found .mlpackage: \(discovery.mlpackages.joined(separator: ", ")).")
                    }
                    parts.append("Ensure the compiled model name is exactly yolov11n.mlmodelc.")
                    hint = parts.joined(separator: " ")
                }

                continuation.resume(throwing: DetectionError.modelNotFound(details: hint))
                return
            }
            
            do {
                let mlModel = try MLModel(contentsOf: modelURL)
                let visionModel = try VNCoreMLModel(for: mlModel)
                
                // Create the Vision request
                let request = VNCoreMLRequest(model: visionModel) { request, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let results = request.results as? [VNRecognizedObjectObservation] else {
                        let observedTypes: String
                        if let results = request.results {
                            observedTypes = results.map { String(describing: type(of: $0)) }.joined(separator: ", ")
                        } else {
                            observedTypes = "(no results)"
                        }
                        continuation.resume(
                            throwing: DetectionError.invalidResults(details: "Vision returned: \(observedTypes). This usually means the model is not an Object Detection model in a Vision-compatible format.")
                        )
                        return
                    }
                    
                    // Filter for high-confidence detections (> 0.5)
                    let detections = results
                        .filter { $0.confidence > 0.5 }
                        .map { observation -> (boundingBox: CGRect, confidence: Float) in
                            return (boundingBox: observation.boundingBox, confidence: observation.confidence)
                        }
                    
                    continuation.resume(returning: detections)
                }
                
                // Configure request to maintain aspect ratio
                // Using scaleFit ensures the image isn't distorted, which is critical for
                // accurate detection and proper coordinate conversion from Vision to SwiftUI
                request.imageCropAndScaleOption = .scaleFit
                
                // Perform the request
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])
                
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func discoverBundledModels() -> (mlmodelcs: [String], mlpackages: [String]) {
        let bundleURL = Bundle.main.bundleURL

        var mlmodelcs = Set<String>()
        var mlpackages = Set<String>()

        if let enumerator = FileManager.default.enumerator(
            at: bundleURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) {
            for case let url as URL in enumerator {
                let name = url.lastPathComponent
                if name.hasSuffix(".mlmodelc") {
                    mlmodelcs.insert(name)
                } else if name.hasSuffix(".mlpackage") {
                    mlpackages.insert(name)
                }
            }
        }

        return (mlmodelcs: Array(mlmodelcs).sorted(), mlpackages: Array(mlpackages).sorted())
    }
    
    // MARK: - OCR Processing
    
    /// Performs OCR on a specific region of interest in the image
    /// - Parameters:
    ///   - image: The UIImage to process
    ///   - boundingBox: The region of interest in Vision coordinates
    /// - Returns: Recognized text string or nil
    private func performOCR(on image: UIImage, in boundingBox: CGRect) async throws -> String? {
        guard let cgImage = image.cgImage else {
            throw DetectionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create text recognition request
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Get the top candidate text from all observations
                let recognizedText = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")
                
                continuation.resume(returning: recognizedText.isEmpty ? nil : recognizedText)
            }
            
            // Configure for accurate text recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            
            // Set region of interest to the detected bounding box
            // Vision coordinates are already normalized (0.0 to 1.0)
            request.regionOfInterest = boundingBox
            
            do {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - Detection Errors

enum DetectionError: LocalizedError {
    case invalidImage
    case modelNotFound(details: String)
    case invalidResults(details: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process the image"
        case .modelNotFound(let details):
            return "Model 'yolov11n.mlmodelc' not found in app bundle. \(details)"
        case .invalidResults(let details):
            return "Invalid detection results from model. \(details)"
        }
    }
}

// MARK: - SwiftUI View

struct BusLabelDetectorView: View {
    @State private var viewModel = LabelDetectorModel()
    
    var body: some View {
        VStack {
            if viewModel.isProcessing {
                ProgressView("Processing...")
                    .padding()
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Image with overlays
            GeometryReader { geometry in
                ZStack {
                    if let image = viewModel.processedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        
                        // Overlay detections
                        Canvas { context, size in
                            drawDetections(
                                context: context,
                                size: size,
                                detections: viewModel.detections,
                                imageSize: image.size
                            )
                        }
                    } else {
                        Text("No image loaded")
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
            
            // Load and process button
            Button("Load Test Image") {
                loadAndProcessTestImage()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            // Detection results list
            if !viewModel.detections.isEmpty {
                List(viewModel.detections) { detection in
                    VStack(alignment: .leading) {
                        Text("Confidence: \(String(format: "%.2f", detection.confidence))")
                            .font(.caption)
                        if let text = detection.ocrText {
                            Text("OCR: \(text)")
                                .font(.headline)
                        } else {
                            Text("No text detected")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(height: 150)
            }
        }
        .onAppear {
            // Automatically load test image on appear
            loadAndProcessTestImage()
        }
    }
    
    // MARK: - Helper Functions
    
    /// Loads the test image from assets and triggers detection
    private func loadAndProcessTestImage() {
        if let image = UIImage(named: "6371-883") {
            viewModel.performDetection(on: image)
        } else {
            viewModel.errorMessage = "Test image 'test_bus_image' not found in assets"
        }
    }
    
    /// Draws detection overlays on the canvas
    /// - Parameters:
    ///   - context: The graphics context
    ///   - size: The size of the canvas
    ///   - detections: Array of detection results
    ///   - imageSize: The original image size
    private func drawDetections(
        context: GraphicsContext,
        size: CGSize,
        detections: [DetectionResult],
        imageSize: CGSize
    ) {
        // Calculate the actual image display rect (considering aspect fit)
        let imageRect = calculateImageRect(canvasSize: size, imageSize: imageSize)
        
        for detection in detections {
            // Convert Vision coordinates to SwiftUI coordinates
            let swiftUIRect = convertVisionToSwiftUI(
                visionRect: detection.boundingBox,
                imageRect: imageRect
            )
            
            // Draw red bounding box
            var path = Path()
            path.addRect(swiftUIRect)
            context.stroke(
                path,
                with: .color(.red),
                lineWidth: 3
            )
            
            // Draw OCR text in yellow bubble if available
            if let ocrText = detection.ocrText {
                let textPosition = CGPoint(
                    x: swiftUIRect.minX,
                    y: swiftUIRect.minY - 25
                )
                
                // Draw background bubble
                let textSize = estimateTextSize(ocrText)
                let bubbleRect = CGRect(
                    x: textPosition.x,
                    y: textPosition.y,
                    width: textSize.width + 10,
                    height: textSize.height + 6
                )
                
                var bubblePath = Path()
                bubblePath.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: 5, height: 5))
                context.fill(bubblePath, with: .color(.yellow.opacity(0.9)))
                
                // Draw text
                context.draw(
                    Text(ocrText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black),
                    at: CGPoint(x: textPosition.x + 5, y: textPosition.y + 12),
                    anchor: .leading
                )
            }
        }
    }
    
    /// Converts Vision coordinate system (normalized, bottom-left origin) to SwiftUI (pixel-based, top-left origin)
    /// - Parameters:
    ///   - visionRect: The bounding box in Vision coordinates
    ///   - imageRect: The actual image display rect in SwiftUI coordinates
    /// - Returns: The converted CGRect in SwiftUI coordinates
    private func convertVisionToSwiftUI(visionRect: CGRect, imageRect: CGRect) -> CGRect {
        // Vision coordinates are normalized (0.0 to 1.0) with bottom-left origin
        // SwiftUI coordinates are pixel-based with top-left origin
        
        // Convert from normalized to pixel coordinates
        let x = visionRect.minX * imageRect.width + imageRect.minX
        let width = visionRect.width * imageRect.width
        let height = visionRect.height * imageRect.height
        
        // Flip Y-axis: Vision's bottom-left becomes SwiftUI's top-left
        // visionRect.minY is from bottom, so (1 - visionRect.maxY) gives position from top
        let y = (1 - visionRect.maxY) * imageRect.height + imageRect.minY
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    /// Calculates the actual display rect of an image in aspect-fit mode
    /// - Parameters:
    ///   - canvasSize: The size of the canvas/container
    ///   - imageSize: The original image size
    /// - Returns: The rect where the image is actually displayed
    private func calculateImageRect(canvasSize: CGSize, imageSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let canvasAspect = canvasSize.width / canvasSize.height
        
        var displayWidth: CGFloat
        var displayHeight: CGFloat
        
        if imageAspect > canvasAspect {
            // Image is wider - fit to width
            displayWidth = canvasSize.width
            displayHeight = canvasSize.width / imageAspect
        } else {
            // Image is taller - fit to height
            displayHeight = canvasSize.height
            displayWidth = canvasSize.height * imageAspect
        }
        
        let x = (canvasSize.width - displayWidth) / 2
        let y = (canvasSize.height - displayHeight) / 2
        
        return CGRect(x: x, y: y, width: displayWidth, height: displayHeight)
    }
    
    /// Estimates the size needed to display text
    /// - Parameter text: The text to estimate
    /// - Returns: Estimated CGSize
    private func estimateTextSize(_ text: String) -> CGSize {
        let font = UIFont.systemFont(ofSize: 16, weight: .bold)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size
    }
}

// MARK: - Preview

#Preview {
    BusLabelDetectorView()
}
