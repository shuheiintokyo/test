import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var visitors: [Visitor] = [Visitor()]
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(visitors.indices, id: \.self) { index in
                        VisitorBlockView(visitor: $visitors[index], blockNumber: index + 1)
                            .padding(.horizontal)
                    }
                    
                    // Add More Button
                    Button(action: addVisitor) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Another Visitor")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    Button(action: saveVisitors) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save All Visitors")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .padding(.top)
            }
            .navigationTitle("Check In Visitors")
            .alert("Save Status", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) {
                    if saveMessage.contains("Successfully") {
                        // Reset form after successful save
                        visitors = [Visitor()]
                    }
                }
            } message: {
                Text(saveMessage)
            }
        }
    }
    
    private func addVisitor() {
        visitors.append(Visitor())
    }
    
    private func saveVisitors() {
        // Determine group type based on count
        let groupType: Visitor.GroupType = visitors.count == 1 ? .single :
                                           visitors.count == 2 ? .pair : .group
        
        // Update group type for all visitors
        for index in visitors.indices {
            visitors[index].groupType = groupType
        }
        
        // Save to data manager
        Task {
            do {
                for visitor in visitors {
                    try await dataManager.saveVisitor(visitor)
                }
                await MainActor.run {
                    saveMessage = "Successfully saved \(visitors.count) visitor(s)"
                    showingSaveAlert = true
                }
            } catch {
                await MainActor.run {
                    saveMessage = "Error saving: \(error.localizedDescription)"
                    showingSaveAlert = true
                }
            }
        }
    }
}

struct VisitorBlockView: View {
    @Binding var visitor: Visitor
    let blockNumber: Int
    @State private var showCountryPicker = false
    @State private var showPrefecturePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Visitor #\(blockNumber)")
                .font(.headline)
                .foregroundColor(.blue)
            
            // Gender Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Gender")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 10) {
                    ForEach(Visitor.Gender.allCases, id: \.self) { gender in
                        Button(action: { visitor.gender = gender }) {
                            Text(gender.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(visitor.gender == gender ? Color.green : Color.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Nationality Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Nationality")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 10) {
                    ForEach(Visitor.Nationality.allCases, id: \.self) { nationality in
                        Button(action: {
                            visitor.nationality = nationality
                            // Reset country/prefecture when changing nationality
                            visitor.country = nil
                            visitor.prefecture = nil
                        }) {
                            Text(nationality.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(visitor.nationality == nationality ? Color.green : Color.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Country/Prefecture Picker based on nationality
            if visitor.nationality == .international {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Country")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Button(action: { showCountryPicker.toggle() }) {
                        HStack {
                            Text(visitor.country ?? "Select Country")
                                .foregroundColor(visitor.country != nil ? .primary : .gray)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            } else if visitor.nationality == .domestic {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prefecture")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Button(action: { showPrefecturePicker.toggle() }) {
                        HStack {
                            Text(visitor.prefecture ?? "Select Prefecture")
                                .foregroundColor(visitor.prefecture != nil ? .primary : .gray)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Age Level Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Age Range")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { level in
                        Button(action: { visitor.ageLevel = level }) {
                            Rectangle()
                                .fill(level <= (visitor.ageLevel ?? 0) ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 50, height: 30)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Visit Reason
            VStack(alignment: .leading, spacing: 8) {
                Text("Visit Reason")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 10) {
                    ForEach(Visitor.VisitReason.allCases, id: \.self) { reason in
                        Button(action: { visitor.visitReason = reason }) {
                            Text(reason.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(visitor.visitReason == reason ? Color.green : Color.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Bar Visit Reason
            VStack(alignment: .leading, spacing: 8) {
                Text("Why This Bar?")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Visitor.BarReason.allCases, id: \.self) { reason in
                            Button(action: { visitor.barReason = reason }) {
                                Text(reason.rawValue)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(visitor.barReason == reason ? Color.green : Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $visitor.country)
        }
        .sheet(isPresented: $showPrefecturePicker) {
            PrefecturePickerView(selectedPrefecture: $visitor.prefecture)
        }
    }
}

struct CountryPickerView: View {
    @Binding var selectedCountry: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(Country.countries) { country in
                Button(action: {
                    selectedCountry = country.name
                    dismiss()
                }) {
                    HStack {
                        Text(country.flag)
                            .font(.title2)
                        Text(country.name)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedCountry == country.name {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Country")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct PrefecturePickerView: View {
    @Binding var selectedPrefecture: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(Prefecture.prefectures, id: \.self) { prefecture in
                Button(action: {
                    selectedPrefecture = prefecture
                    dismiss()
                }) {
                    HStack {
                        Text(prefecture)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedPrefecture == prefecture {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Prefecture")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}
