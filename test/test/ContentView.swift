//
//  ContentView.swift
//  test - Receipt OCR Reader
//
//  Updated to test Receipt OCR functionality
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var detectedAmount: Double?
    @State private var detectedDate: Date?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // MARK: - Tab 1: Original Test View
            VStack(spacing: 20) {
                Text("Original Test")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This is the original test view from your project.")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("テスト", systemImage: "hammer.fill")
            }
            .tag(0)
            
            // MARK: - Tab 2: Receipt OCR Reader
            ReceiptOCRViewContainer(
                detectedAmount: $detectedAmount,
                detectedDate: $detectedDate
            )
            .tabItem {
                Label("レシートOCR", systemImage: "doc.text.viewfinder")
            }
            .tag(1)
        }
    }
}

// MARK: - ReceiptOCRView Container
struct ReceiptOCRViewContainer: View {
    @Binding var detectedAmount: Double?
    @Binding var detectedDate: Date?
    @State private var isPresented = true
    
    var body: some View {
        ReceiptOCRView(
            detectedAmount: $detectedAmount,
            detectedDate: $detectedDate,
            isPresented: $isPresented
        )
    }
}

#Preview {
    ContentView()
}
