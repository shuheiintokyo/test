import SwiftUI

struct CurrentStatusView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedVisitor: Visitor?
    @State private var showingEditView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    if dataManager.activeVisitors.isEmpty {
                        Text("No visitors currently in the bar")
                            .foregroundColor(.gray)
                            .padding(.top, 50)
                    } else {
                        ForEach(dataManager.activeVisitors) { visitor in
                            VisitorRowView(visitor: visitor) {
                                selectedVisitor = visitor
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showingEditView = true
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Current Visitors")
            .navigationBarItems(trailing:
                VStack {
                    Text("\(dataManager.activeVisitors.count) Active")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            )
            .sheet(item: $selectedVisitor) { visitor in
                EditVisitorView(visitor: visitor)
                    .environmentObject(dataManager)
            }
            .onAppear {
                dataManager.loadActiveVisitors()
            }
        }
    }
}

struct VisitorRowView: View {
    let visitor: Visitor
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Group Type Badge
                        Text(visitor.groupType?.rawValue ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(groupTypeColor)
                            .cornerRadius(6)
                        
                        // Gender Badge if available
                        if let gender = visitor.gender {
                            Text(gender.rawValue)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple)
                                .cornerRadius(6)
                        }
                        
                        // Nationality Badge if available
                        if let nationality = visitor.nationality {
                            Text(nationality.rawValue)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .cornerRadius(6)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Entry: \(formattedTime)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("Duration: \(visitor.timeSpent)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    // Show country or prefecture if available
                    if let country = visitor.country {
                        HStack {
                            Image(systemName: "globe")
                                .font(.caption)
                            Text(country)
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    } else if let prefecture = visitor.prefecture {
                        HStack {
                            Image(systemName: "map")
                                .font(.caption)
                            Text(prefecture)
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var groupTypeColor: Color {
        switch visitor.groupType {
        case .single: return .blue
        case .pair: return .green
        case .group: return .orange
        case .none: return .gray
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: visitor.entryTime)
    }
}

struct EditVisitorView: View {
    @State var visitor: Visitor
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var showingExitConfirmation = false
    @State private var showCountryPicker = false
    @State private var showPrefecturePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Display entry time
                    HStack {
                        Text("Entry Time:")
                            .fontWeight(.medium)
                        Text(formattedDateTime)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Editable fields
                    VStack(alignment: .leading, spacing: 15) {
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
                        
                        // Country/Prefecture Picker
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
                        
                        // Age Level
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
                    
                    // Exit Button
                    Button(action: { showingExitConfirmation = true }) {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                            Text("Mark as Left")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Edit Visitor")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    Task {
                        await dataManager.updateVisitor(visitor)
                        dismiss()
                    }
                }
            )
            .alert("Confirm Exit", isPresented: $showingExitConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm", role: .destructive) {
                    Task {
                        visitor.exitTime = Date()
                        visitor.isActive = false
                        await dataManager.markVisitorAsLeft(visitor)
                        dismiss()
                    }
                }
            } message: {
                Text("Mark this visitor as having left the bar?")
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerView(selectedCountry: $visitor.country)
            }
            .sheet(isPresented: $showPrefecturePicker) {
                PrefecturePickerView(selectedPrefecture: $visitor.prefecture)
            }
        }
    }
    
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: visitor.entryTime)
    }
}
