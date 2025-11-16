import SwiftUI

// MARK: - Model for names from cloud database
struct NameList {
    var name: String = ""
}

// MARK: - View Controller
struct ContentView: View {
    @State private var message = "Hello"
    @State private var isLoading = false
    @State private var nameList = NameList()
    
    var body: some View {
        VStack(spacing: 30) {
            // Display the greeting message
            Text(message)
                .font(.title)
                .fontWeight(.bold)
            
            // Show loading spinner while fetching
            if isLoading {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Fetching name from cloud...")
                        .foregroundColor(.gray)
                }
            }
            
            // Button to trigger the greeting flow
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
            .disabled(isLoading) // Disable button while loading
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Main greeting flow
    func greetingFlow() {
        // Step 1: Say Hello immediately
        message = "Hello"
        
        // Step 2: Start loading indicator
        isLoading = true
        
        // Step 3: Wait 1.5 seconds and fetch name from cloud
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Simulate fetching from cloud database
            fetchNameFromCloud()
            
            // Step 4: After fetch completes, say Hi with name
            message = "Hi \(nameList.name)"
            
            // Step 5: Stop loading indicator
            isLoading = false
        }
    }
    
    // MARK: - Simulate cloud database fetch
    func fetchNameFromCloud() {
        // In real app, this would be an actual API call
        // For now, we simulate fetching "John" from cloud
        nameList.name = "John"
        print("Name fetched from cloud: \(nameList.name)")
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
