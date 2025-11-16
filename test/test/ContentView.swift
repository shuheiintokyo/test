//
//  ContentView.swift
//  test
//
//  Updated to test Receipt OCR functionality
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Original Test View
            OriginalTestView()
                .tabItem {
                    Label("テスト", systemImage: "hammer.fill")
                }
                .tag(0)
            
            // Tab 2: Receipt OCR Reader
            ReceiptOCRView()
                .tabItem {
                    Label("レシートOCR", systemImage: "doc.text.viewfinder")
                }
                .tag(1)
        }
    }
}

// MARK: - Original Test View
struct OriginalTestView: View {
    @State private var message = "Hello"
    @State private var isLoading = false
    @State private var nameList = NameList()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text(message)
                    .font(.title)
                    .fontWeight(.bold)
                
                if isLoading {
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Fetching name from cloud...")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    greetingFlow()
                }) {
                    Text("Say Hello and Hi")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isLoading)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Original Test")
        }
    }
    
    func greetingFlow() {
        message = "Hello"
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            fetchNameFromCloud()
            message = "Hi \(nameList.name)"
            isLoading = false
        }
    }
    
    func fetchNameFromCloud() {
        nameList.name = "John"
        print("Name fetched from cloud: \(nameList.name)")
    }
}

// MARK: - Model for names from cloud database
struct NameList {
    var name: String = ""
}

// MARK: - Preview
#Preview {
    ContentView()
}
