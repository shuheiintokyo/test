//
//  ReceiptOCRView.swift
//
//  OCR Receipt Reader using Apple Vision Framework
//  - Recognizes text from receipt images
//  - Extracts amount, date, and category information
//  - Supports camera and photo library
//

import SwiftUI
import Vision
import PhotosUI

// MARK: - Models
struct ExtractedReceipt {
    var rawText: String = ""
    var amount: String = ""
    var date: String = ""
    var shopName: String = ""
    var category: String = ""
    var confidence: Double = 0.0
}

struct CategoryMatch {
    let category: String
    let largeCategory: String
    let keywords: [String]
}

// MARK: - Main Content View for OCR Testing
struct ReceiptOCRView: View {
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var selectedImage: UIImage?
    @State private var extractedReceipt: ExtractedReceipt?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // MARK: - Header
                Text("📸 Receipt OCR Reader")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Test OCR with Apple Vision Framework")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // MARK: - Image Display
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .cornerRadius(8)
                        .clipped()
                }
                
                // MARK: - Processing Indicator
                if isProcessing {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("OCRで文字を認識中...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // MARK: - Action Buttons
                HStack(spacing: 12) {
                    Button(action: { isShowingCamera = true }) {
                        Label("カメラ", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: { isShowingImagePicker = true }) {
                        Label("ギャラリー", systemImage: "photo.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                // MARK: - Error Message
                if let error = errorMessage {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        Button("閉じる") {
                            errorMessage = nil
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // MARK: - Extracted Data Display
                if let receipt = extractedReceipt {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("認識結果")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        // Shop Name
                        if !receipt.shopName.isEmpty {
                            HStack {
                                Text("店舗名:")
                                    .fontWeight(.semibold)
                                    .frame(width: 60, alignment: .leading)
                                Text(receipt.shopName)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .font(.caption)
                            Divider()
                        }
                        
                        // Date
                        if !receipt.date.isEmpty {
                            HStack {
                                Text("日付:")
                                    .fontWeight(.semibold)
                                    .frame(width: 60, alignment: .leading)
                                Text(receipt.date)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .font(.caption)
                            Divider()
                        }
                        
                        // Amount
                        if !receipt.amount.isEmpty {
                            HStack {
                                Text("金額:")
                                    .fontWeight(.semibold)
                                    .frame(width: 60, alignment: .leading)
                                Text("¥\(receipt.amount)")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            Divider()
                        }
                        
                        // Category
                        if !receipt.category.isEmpty {
                            HStack {
                                Text("推定\n分類:")
                                    .fontWeight(.semibold)
                                    .frame(width: 60, alignment: .leading)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(receipt.category)
                                        .foregroundColor(.orange)
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                            .font(.caption)
                            Divider()
                        }
                        
                        // Confidence
                        HStack {
                            Text("信頼度:")
                                .fontWeight(.semibold)
                                .frame(width: 60, alignment: .leading)
                            Text("\(Int(receipt.confidence * 100))%")
                                .foregroundColor(.purple)
                            Spacer()
                        }
                        .font(.caption)
                        
                        // MARK: - Raw Text Section (Expandable)
                        DisclosureGroup("認識テキスト (タップで展開)") {
                            VStack(alignment: .leading, spacing: 8) {
                                ScrollView {
                                    Text(receipt.rawText)
                                        .font(.caption2)
                                        .lineLimit(nil)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(4)
                                }
                                .frame(height: 150)
                            }
                        }
                        .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("レシートOCR")
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
                    .onChange(of: selectedImage) { newImage in
                        if newImage != nil {
                            processImage()
                        }
                    }
            }
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
                    .onChange(of: selectedImage) { newImage in
                        if newImage != nil {
                            processImage()
                        }
                    }
            }
        }
    }
    
    // MARK: - Image Processing
    private func processImage() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        errorMessage = nil
        
        // Convert UIImage to CIImage
        guard let ciImage = CIImage(image: image) else {
            errorMessage = "画像の処理に失敗しました"
            isProcessing = false
            return
        }
        
        // Create Vision request
        let recognizeTextRequest = VNRecognizeTextRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "OCR エラー: \(error.localizedDescription)"
                    self.isProcessing = false
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self.errorMessage = "テキスト認識に失敗しました"
                    self.isProcessing = false
                }
                return
            }
            
            // Extract all text
            let extractedText = observations
                .compactMap { $0.topCandidate(withConfidence: nil)?.string }
                .joined(separator: "\n")
            
            // Parse receipt data
            DispatchQueue.main.async {
                self.extractedReceipt = parseReceipt(extractedText)
                self.isProcessing = false
            }
        }
        
        // Configure request for Japanese text
        recognizeTextRequest.recognitionLanguages = ["ja-JP", "en-US"]
        recognizeTextRequest.recognitionLevel = .accurate
        
        // Process image
        let requests = [recognizeTextRequest]
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform(requests)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "画像処理エラー: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Receipt Parser
private func parseReceipt(_ text: String) -> ExtractedReceipt {
    var receipt = ExtractedReceipt(rawText: text)
    let lines = text.split(separator: "\n").map(String.init)
    
    // MARK: - Extract Amount (金額)
    // Look for patterns: 合計, 小計, 金額, ¥, 円
    for line in lines {
        // Pattern 1: "¥390", "¥3900"
        if let yen = extractYenAmount(line) {
            receipt.amount = yen
            receipt.confidence = max(receipt.confidence, 0.95)
            break
        }
        
        // Pattern 2: "合計 ¥390"
        if line.contains("合計") || line.contains("小計") {
            if let yen = extractYenAmount(line) {
                receipt.amount = yen
                receipt.confidence = max(receipt.confidence, 0.9)
                break
            }
        }
    }
    
    // MARK: - Extract Date (日付)
    // Look for patterns: YYYY年MM月DD日, MM/DD, 11/5など
    for line in lines {
        if let date = extractDate(line) {
            receipt.date = date
            receipt.confidence = max(receipt.confidence, 0.85)
            break
        }
    }
    
    // MARK: - Extract Shop Name
    // Usually in first few lines
    if lines.count > 0 {
        for i in 0..<min(3, lines.count) {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            // Look for shop names (filtered to avoid common words)
            if !line.isEmpty &&
               !line.contains("年") &&
               !line.contains("月") &&
               !line.contains("日") &&
               !line.contains("¥") &&
               line.count > 2 &&
               line.count < 30 {
                receipt.shopName = line
                break
            }
        }
    }
    
    // MARK: - Detect Category based on keywords
    receipt.category = detectCategory(text)
    
    return receipt
}

// MARK: - Helper: Extract Yen Amount
private func extractYenAmount(_ line: String) -> String? {
    // Pattern: ¥390, \390, 390円
    let patterns = [
        "¥(\\d+)", // ¥390
        "(\\d+)円", // 390円
        "\\$(\\d+)" // $390 (fallback)
    ]
    
    for pattern in patterns {
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex.firstMatch(in: line, range: range) {
                if let range = Range(match.range(at: 1), in: line) {
                    return String(line[range])
                }
            }
        }
    }
    
    return nil
}

// MARK: - Helper: Extract Date
private func extractDate(_ line: String) -> String? {
    // Patterns:
    // - YYYY年MM月DD日 (2025年11月16日)
    // - MM/DD (11/5)
    // - MM月DD日 (11月5日)
    
    let datePatterns = [
        "(\\d{4})年(\\d{1,2})月(\\d{1,2})日", // 2025年11月16日
        "(\\d{1,2})/(\\d{1,2})", // 11/5
        "(\\d{1,2})月(\\d{1,2})日" // 11月5日
    ]
    
    for pattern in datePatterns {
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex.firstMatch(in: line, range: range) {
                return String(line[Range(match.range, in: line)!])
            }
        }
    }
    
    return nil
}

// MARK: - Helper: Detect Category
private func detectCategory(_ text: String) -> String {
    let lowercaseText = text.lowercased()
    
    // Define category keywords (大分類 → 中分類)
    let categoryMatches: [CategoryMatch] = [
        // 食費 (Food)
        CategoryMatch(
            category: "食費 > コーヒー/カフェ",
            largeCategory: "食費",
            keywords: ["coffee", "café", "カフェ", "コーヒー", "tully's", "タリーズ", "スターバックス", "starbucks"]
        ),
        CategoryMatch(
            category: "食費 > レストラン/飲食",
            largeCategory: "食費",
            keywords: ["レストラン", "食堂", "飲食", "restaurant", "lunch", "dinner"]
        ),
        
        // 外出 (Outing/Dining)
        CategoryMatch(
            category: "外出 > バー/居酒屋",
            largeCategory: "外出",
            keywords: ["bar", "バー", "居酒屋", "pub", "izakaya"]
        ),
        
        // 買い物 (Shopping)
        CategoryMatch(
            category: "買い物 > スーパー",
            largeCategory: "買い物",
            keywords: ["スーパー", "supermarket", "スーパー", "デパート"]
        ),
        
        // 交通費 (Transport)
        CategoryMatch(
            category: "交通費 > 電車/バス",
            largeCategory: "交通費",
            keywords: ["suica", "pasmo", "電車", "train", "bus", "バス"]
        )
    ]
    
    // Check matches
    for match in categoryMatches {
        for keyword in match.keywords {
            if lowercaseText.contains(keyword.lowercased()) {
                return match.category
            }
        }
    }
    
    // Default category
    return "その他"
}

// MARK: - Preview
#Preview {
    ReceiptOCRView()
}
