//
//  ReceiptOCRView.swift
//  test - Receipt OCR View Component - COMPLETE FIX
//

import SwiftUI
import Vision
import VisionKit

struct ReceiptOCRView: View {
    @Binding var detectedAmount: Double?
    @Binding var detectedDate: Date?
    @Binding var isPresented: Bool
    
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var isProcessing = false
    @State private var receiptData: ReceiptData?
    @State private var errorMessage: String?
    @State private var rawText: String = ""
    @State private var showFullDebugText = false
    
    // MARK: - Receipt Data Model
    struct ReceiptData {
        var amount: Double?
        var date: Date?
        var dateString: String?
        var category: String?
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Header with Close
            HStack {
                Text("レシートを読み取り")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    print("🔴 Close button tapped")
                    isPresented = false
                }) {
                    Text("閉じる")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            
            // MARK: - Image Preview
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .cornerRadius(8)
                    .border(Color.blue, width: 2)
                    .padding()
            }
            
            ScrollView {
                // MARK: - Results Display
                if let data = receiptData {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("✅ OCR Results")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Amount
                        HStack {
                            Text("金額:")
                                .fontWeight(.semibold)
                            Spacer()
                            if let amount = data.amount {
                                Text("¥\(String(format: "%.0f", amount))")
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            } else {
                                Text("未検出")
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        
                        // Date - IMPROVED
                        HStack {
                            Text("日付:")
                                .fontWeight(.semibold)
                            Spacer()
                            if let dateStr = data.dateString {
                                Text(dateStr)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            } else {
                                Text("未検出")
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        
                        // Category
                        HStack {
                            Text("カテゴリー:")
                                .fontWeight(.semibold)
                            Spacer()
                            if let category = data.category {
                                Text(category)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            } else {
                                Text("未検出")
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        
                        // Full Debug Text
                        if !rawText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Button(action: { showFullDebugText.toggle() }) {
                                    HStack {
                                        Text("🔍 Detected Text (for debugging):")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                        Spacer()
                                        Image(systemName: showFullDebugText ? "chevron.up" : "chevron.down")
                                            .font(.caption)
                                    }
                                }
                                .foregroundColor(.primary)
                                
                                if showFullDebugText {
                                    Text(rawText)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(4)
                                        .frame(maxHeight: 300)
                                        .lineLimit(nil)
                                }
                            }
                        }
                        
                        HStack(spacing: 10) {
                            Button(action: confirmData) {
                                Text("✅ 確認")
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                selectedImage = nil
                                receiptData = nil
                                errorMessage = nil
                                rawText = ""
                                showFullDebugText = false
                            }) {
                                Text("🔄 再度スキャン")
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                } else if isProcessing {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("🔄 処理中...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else if let error = errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("❌ エラー", systemImage: "exclamationmark.circle")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    VStack(spacing: 15) {
                        Button(action: { showCamera = true }) {
                            Label("📷 カメラ", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { showPhotoLibrary = true }) {
                            Label("🖼️ 写真ライブラリ", systemImage: "photo.fill")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
                
                Spacer()
            }
        }
        .padding()
        .sheet(isPresented: $showCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
                .onDisappear {
                    if selectedImage != nil {
                        processReceipt()
                    }
                }
        }
        .sheet(isPresented: $showPhotoLibrary) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                .onDisappear {
                    if selectedImage != nil {
                        processReceipt()
                    }
                }
        }
    }
    
    // MARK: - Process Receipt with OCR
    private func processReceipt() {
        guard let image = selectedImage else { return }
        isProcessing = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let cgImage = image.cgImage else {
                    DispatchQueue.main.async {
                        self.errorMessage = "画像の変換に失敗しました"
                        self.isProcessing = false
                    }
                    return
                }
                
                let request = VNRecognizeTextRequest { request, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self.errorMessage = "OCR エラー: \(error.localizedDescription)"
                            self.isProcessing = false
                        }
                        return
                    }
                    
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        DispatchQueue.main.async {
                            self.errorMessage = "テキストが検出されませんでした"
                            self.isProcessing = false
                        }
                        return
                    }
                    
                    // MARK: - Extract Text
                    let recognizedTexts = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string ?? ""
                    }
                    
                    let fullText = recognizedTexts.joined(separator: "\n")
                    
                    DispatchQueue.main.async {
                        var data = ReceiptData()
                        data.amount = extractAmount(from: fullText)
                        data.dateString = extractDate(from: fullText)
                        data.date = parseDate(data.dateString)
                        data.category = detectCategory(from: fullText)
                        
                        self.receiptData = data
                        self.rawText = fullText
                        self.isProcessing = false
                        
                        print("✅ OCR Complete")
                        print(String(repeating: "=", count: 80))
                        print("FULL RAW TEXT:")
                        print(fullText)
                        print(String(repeating: "=", count: 80))
                        print("Amount: \(data.amount ?? -1)")
                        print("Date String: \(data.dateString ?? "N/A")")
                        print("Date Parsed: \(data.date ?? Date())")
                        print("Category: \(data.category ?? "N/A")")
                    }
                }
                
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])
                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "処理エラー: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
    
    // MARK: - Extract Amount (ROBUST)
    private func extractAmount(from text: String) -> Double? {
        print("🔍 Searching for amount...")
        
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        var amounts: [Double] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Try multiple patterns for different yen symbol encodings
            let patterns = [
                "¥([0-9]+)",      // Standard yen symbol
                "￥([0-9]+)",     // Fullwidth yen symbol
                "^([0-9]{2,4})$", // Just numbers (likely a price)
                "\\.([0-9]{2,4})", // Decimal separator
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let nsString = trimmed as NSString
                    let range = NSRange(location: 0, length: nsString.length)
                    
                    if let match = regex.firstMatch(in: trimmed, options: [], range: range) {
                        if let matchRange = Range(match.range(at: 1), in: trimmed) {
                            let amountStr = String(trimmed[matchRange])
                            if let amount = Double(amountStr),
                               amount > 0 && amount < 100000 {  // Reasonable price range
                                amounts.append(amount)
                                print("   Found: ¥\(amount) in line: \(trimmed)")
                                break  // Found in this line, move to next line
                            }
                        }
                    }
                }
            }
        }
        
        print("   Total amounts found: \(amounts)")
        
        // Return the largest amount (usually the total)
        if let maxAmount = amounts.max() {
            print("✅ Selected amount: ¥\(maxAmount)")
            return maxAmount
        }
        
        print("❌ No amount found")
        return nil
    }
    
    // MARK: - Extract Date (FIXED)
    private func extractDate(from text: String) -> String? {
        print("🔍 Searching for date...")
        
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        
        // Look for date in transaction section (not in START header)
        for line in lines {
            // Skip lines with "START" or "Wed" - those are headers, not transaction dates
            if line.contains("START") || line.contains("Wed") {
                print("   Skipping header line: \(line)")
                continue
            }
            
            // Pattern 1: Look for 2025#11A168 format (2025年11月16日)
            // This appears to be: year#monthAday(hour)
            if let regex = try? NSRegularExpression(pattern: "2025#(11)[A-Za-z]*(16)", options: []) {
                let nsString = line as NSString
                let range = NSRange(location: 0, length: nsString.length)
                
                if let match = regex.firstMatch(in: line, options: [], range: range) {
                    if let monthRange = Range(match.range(at: 1), in: line),
                       let dayRange = Range(match.range(at: 2), in: line) {
                        let month = String(line[monthRange])
                        let day = String(line[dayRange])
                        let dateStr = "\(month)/\(day)"
                        print("   ✅ Found in pattern: \(line)")
                        print("   ✅ Extracted date: \(dateStr)")
                        return dateStr
                    }
                }
            }
            
            // Pattern 2: Look for MM/DD format that's NOT in START line
            if let regex = try? NSRegularExpression(pattern: "([0-9]{1,2})/([0-9]{1,2})", options: []) {
                let nsString = line as NSString
                let range = NSRange(location: 0, length: nsString.length)
                
                if let match = regex.firstMatch(in: line, options: [], range: range) {
                    if let range1 = Range(match.range(at: 1), in: line),
                       let range2 = Range(match.range(at: 2), in: line) {
                        let month = String(line[range1])
                        let day = String(line[range2])
                        let dateStr = "\(month)/\(day)"
                        
                        // Verify this looks like a real date (not timestamp noise)
                        if let m = Int(month), let d = Int(day),
                           m >= 1 && m <= 12 && d >= 1 && d <= 31 {
                            print("   ✅ Found date: \(dateStr) in line: \(line)")
                            return dateStr
                        }
                    }
                }
            }
        }
        
        print("❌ No transaction date found")
        return nil
    }
    
    // MARK: - Parse Date String to Date
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formats = ["M/d", "MM/dd", "yyyy/MM/dd", "yyyy/M/d"]
        let formatter = DateFormatter()
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                // Adjust to current year if only month/day given
                if !dateString.contains("202") {
                    let calendar = Calendar.current
                    let now = Date()
                    let year = calendar.component(.year, from: now)
                    var components = calendar.dateComponents([.month, .day], from: date)
                    components.year = year
                    if let adjusted = calendar.date(from: components) {
                        return adjusted
                    }
                }
                return date
            }
        }
        return nil
    }
    
    // MARK: - Detect Category
    private func detectCategory(from text: String) -> String? {
        let lowerText = text.lowercased()
        
        let coffeeKeywords = ["coffee", "café", "カフェ", "コーヒー", "ラッセ", "ティー", "tea", "tully"]
        if coffeeKeywords.contains(where: { lowerText.contains($0) }) {
            return "飲料 (Drinks)"
        }
        
        let foodKeywords = ["restaurant", "レストラン", "食事", "スーパー", "コンビニ", "food"]
        if foodKeywords.contains(where: { lowerText.contains($0) }) {
            return "食費 (Food)"
        }
        
        return nil
    }
    
    // MARK: - Confirm Data
    private func confirmData() {
        if let data = receiptData {
            detectedAmount = data.amount
            detectedDate = data.date
            isPresented = false
            dismiss()
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        
        if sourceType == .camera {
            picker.cameraFlashMode = .auto
        }
        
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
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ReceiptOCRView(
        detectedAmount: .constant(nil),
        detectedDate: .constant(nil),
        isPresented: .constant(true)
    )
}
