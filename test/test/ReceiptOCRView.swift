//
//  ReceiptOCRView.swift
//  test - Receipt OCR View Component
//
//  Fixed for iOS 14+ compatibility
//

import SwiftUI
import Vision
import VisionKit

struct ReceiptOCRView: View {
    @Binding var detectedAmount: Double?
    @Binding var detectedDate: Date?
    @Binding var isPresented: Bool
    
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var isProcessing = false
    @State private var receiptData: ReceiptData?
    @State private var errorMessage: String?
    
    // MARK: - Receipt Data Model
    struct ReceiptData {
        var amount: Double?
        var date: Date?
        var dateString: String?
        var category: String?
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
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
                
                // MARK: - Results Display
                if let data = receiptData {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("✅ OCR Results")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let amount = data.amount {
                            HStack {
                                Text("金額:")
                                Spacer()
                                Text("¥\(String(format: "%.0f", amount))")
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                        }
                        
                        if let dateStr = data.dateString {
                            HStack {
                                Text("日付:")
                                Spacer()
                                Text(dateStr)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                        }
                        
                        if let category = data.category {
                            HStack {
                                Text("カテゴリー:")
                                Spacer()
                                Text(category)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                        }
                        
                        HStack(spacing: 10) {
                            Button(action: confirmData) {
                                Text("✅ 確認")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                selectedImage = nil
                                receiptData = nil
                                errorMessage = nil
                            }) {
                                Text("🔄 再度スキャン")
                                    .frame(maxWidth: .infinity)
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
                        // MARK: - Camera Button
                        Button(action: { showCamera = true }) {
                            Label("📷 カメラ", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        // MARK: - Photo Library Button (Fixed)
                        Button(action: { showPhotoLibrary = true }) {
                            Label("🖼️ 写真ライブラリ", systemImage: "photo.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("レシートを読み取り")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { isPresented = false }
                }
            }
            // MARK: - Camera Sheet
            .sheet(isPresented: $showCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
                    .onDisappear {
                        if selectedImage != nil {
                            processReceipt()
                        }
                    }
            }
            // MARK: - Photo Library Sheet (Fixed)
            .sheet(isPresented: $showPhotoLibrary) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                    .onDisappear {
                        if selectedImage != nil {
                            processReceipt()
                        }
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
                    
                    // MARK: - Extract Text Correctly
                    let recognizedTexts = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string ?? ""
                    }
                    
                    let fullText = recognizedTexts.joined(separator: "\n")
                    
                    DispatchQueue.main.async {
                        var data = ReceiptData()
                        data.amount = extractAmount(from: fullText)
                        data.dateString = extractDate(from: fullText)
                        data.category = detectCategory(from: fullText)
                        
                        self.receiptData = data
                        self.isProcessing = false
                        
                        print("✅ OCR Complete")
                        print("Amount: \(data.amount ?? -1)")
                        print("Date: \(data.dateString ?? "N/A")")
                        print("Category: \(data.category ?? "N/A")")
                    }
                }
                
                // MARK: - Configure Recognition Request (Fixed)
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
    
    // MARK: - Extract Amount
    private func extractAmount(from text: String) -> Double? {
        let patterns = [
            "¥([0-9,]+)",
            "([0-9,]+)円",
            "金額\\s*¥?([0-9,]+)",
            "合計\\s*¥?([0-9,]+)",
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = text as NSString
                let range = NSRange(location: 0, length: nsString.length)
                
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    if let range = Range(match.range(at: 1), in: text) {
                        let amount = String(text[range])
                            .replacingOccurrences(of: ",", with: "")
                        return Double(amount)
                    }
                }
            }
        }
        return nil
    }
    
    // MARK: - Extract Date
    private func extractDate(from text: String) -> String? {
        let patterns = [
            "([0-9]{1,2})/([0-9]{1,2})",
            "([0-9]{4})/([0-9]{1,2})/([0-9]{1,2})",
            "([0-9]{1,2})月([0-9]{1,2})日",
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = text as NSString
                let range = NSRange(location: 0, length: nsString.length)
                
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    var dateString = ""
                    for i in 1..<match.numberOfRanges {
                        if let range = Range(match.range(at: i), in: text) {
                            dateString += String(text[range])
                            if i < match.numberOfRanges - 1 {
                                dateString += "/"
                            }
                        }
                    }
                    return dateString
                }
            }
        }
        return nil
    }
    
    // MARK: - Detect Category
    private func detectCategory(from text: String) -> String? {
        let lowerText = text.lowercased()
        
        let coffeeKeywords = ["coffee", "café", "カフェ", "コーヒー", "ラッセ", "ティー", "tea"]
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
