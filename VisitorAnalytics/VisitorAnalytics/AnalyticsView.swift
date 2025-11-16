import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTimeRange = TimeRange.today
    @State private var showingDetailedStats = false
    
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Key Metrics Cards
                    VStack(spacing: 15) {
                        HStack(spacing: 15) {
                            MetricCard(
                                title: "Total Visitors",
                                value: "\(filteredVisitors.count)",
                                icon: "person.3.fill",
                                color: .blue
                            )
                            
                            MetricCard(
                                title: "Currently In",
                                value: "\(dataManager.activeVisitors.count)",
                                icon: "door.left.hand.open",
                                color: .green
                            )
                        }
                        
                        HStack(spacing: 15) {
                            MetricCard(
                                title: "Avg. Duration",
                                value: averageStayDuration,
                                icon: "clock.fill",
                                color: .orange
                            )
                            
                            MetricCard(
                                title: "Peak Hour",
                                value: peakHour,
                                icon: "flame.fill",
                                color: .red
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Group Distribution
                    GroupDistributionView(visitors: filteredVisitors)
                        .padding(.horizontal)
                    
                    // Gender Distribution
                    GenderDistributionView(visitors: filteredVisitors)
                        .padding(.horizontal)
                    
                    // Nationality Breakdown
                    NationalityBreakdownView(visitors: filteredVisitors)
                        .padding(.horizontal)
                    
                    // Visit Reasons Chart
                    VisitReasonsChartView(visitors: filteredVisitors)
                        .padding(.horizontal)
                    
                    // Hourly Traffic Pattern
                    HourlyTrafficView(visitors: filteredVisitors)
                        .padding(.horizontal)
                    
                    // Age Distribution
                    AgeDistributionView(visitors: filteredVisitors)
                        .padding(.horizontal)
                    
                    // Discovery Method Stats
                    DiscoveryMethodView(visitors: filteredVisitors)
                        .padding(.horizontal)
                    
                    // Top Countries/Prefectures
                    if !topLocations.isEmpty {
                        TopLocationsView(locations: topLocations)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .onAppear {
                dataManager.loadTodayStats()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var filteredVisitors: [Visitor] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            return dataManager.allVisitors.filter {
                $0.entryTime >= startOfDay
            }
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return dataManager.allVisitors.filter {
                $0.entryTime >= startOfWeek
            }
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return dataManager.allVisitors.filter {
                $0.entryTime >= startOfMonth
            }
        case .all:
            return dataManager.allVisitors
        }
    }
    
    var averageStayDuration: String {
        let completedVisits = filteredVisitors.filter { $0.exitTime != nil }
        guard !completedVisits.isEmpty else { return "N/A" }
        
        let totalSeconds = completedVisits.reduce(0) { sum, visitor in
            let duration = (visitor.exitTime ?? Date()).timeIntervalSince(visitor.entryTime)
            return sum + duration
        }
        
        let avgSeconds = totalSeconds / Double(completedVisits.count)
        let hours = Int(avgSeconds) / 3600
        let minutes = (Int(avgSeconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var peakHour: String {
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        
        for visitor in filteredVisitors {
            let hour = calendar.component(.hour, from: visitor.entryTime)
            hourCounts[hour, default: 0] += 1
        }
        
        if let maxHour = hourCounts.max(by: { $0.value < $1.value })?.key {
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            let date = calendar.date(bySettingHour: maxHour, minute: 0, second: 0, of: Date())!
            return formatter.string(from: date)
        }
        
        return "N/A"
    }
    
    var topLocations: [(String, Int)] {
        var locationCounts: [String: Int] = [:]
        
        for visitor in filteredVisitors {
            if let country = visitor.country {
                locationCounts[country, default: 0] += 1
            } else if let prefecture = visitor.prefecture {
                locationCounts[prefecture, default: 0] += 1
            }
        }
        
        return locationCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }
}

// MARK: - Metric Card Component

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Group Distribution View

struct GroupDistributionView: View {
    let visitors: [Visitor]
    
    var groupCounts: (singles: Int, pairs: Int, groups: Int) {
        let singles = visitors.filter { $0.groupType == .single }.count
        let pairs = visitors.filter { $0.groupType == .pair }.count
        let groups = visitors.filter { $0.groupType == .group }.count
        return (singles, pairs, groups)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Group Distribution")
                .font(.headline)
            
            HStack(spacing: 20) {
                GroupTypeBar(
                    type: "Singles",
                    count: groupCounts.singles,
                    total: visitors.count,
                    color: .purple
                )
                
                GroupTypeBar(
                    type: "Pairs",
                    count: groupCounts.pairs,
                    total: visitors.count,
                    color: .orange
                )
                
                GroupTypeBar(
                    type: "Groups",
                    count: groupCounts.groups,
                    total: visitors.count,
                    color: .pink
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct GroupTypeBar: View {
    let type: String
    let count: Int
    let total: Int
    let color: Color
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(color)
                        .frame(height: geometry.size.height * CGFloat(percentage))
                        .cornerRadius(4)
                }
            }
            .frame(height: 100)
            
            Text(type)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(percentage * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Gender Distribution View

struct GenderDistributionView: View {
    let visitors: [Visitor]
    
    var genderData: [(String, Int)] {
        var counts: [String: Int] = [
            "Male": 0,
            "Female": 0,
            "Other": 0,
            "Not Specified": 0
        ]
        
        for visitor in visitors {
            if let gender = visitor.gender {
                counts[gender.rawValue, default: 0] += 1
            } else {
                counts["Not Specified", default: 0] += 1
            }
        }
        
        return counts.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gender Distribution")
                .font(.headline)
            
            ForEach(genderData, id: \.0) { gender, count in
                HStack {
                    Text(gender)
                        .font(.subheadline)
                        .frame(width: 100, alignment: .leading)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(colorForGender(gender))
                                .frame(width: geometry.size.width * CGFloat(count) / CGFloat(visitors.count))
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 20)
                    
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 30)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    func colorForGender(_ gender: String) -> Color {
        switch gender {
        case "Male": return .blue
        case "Female": return .pink
        case "Other": return .purple
        default: return .gray
        }
    }
}

// MARK: - Nationality Breakdown View

struct NationalityBreakdownView: View {
    let visitors: [Visitor]
    
    var nationalityData: [(String, Int, Color)] {
        var counts: [String: Int] = [:]
        
        for visitor in visitors {
            let category = visitor.nationality?.rawValue ?? "Not Specified"
            counts[category, default: 0] += 1
        }
        
        return counts.map { (key, value) in
            let color: Color = {
                switch key {
                case "Local": return .green
                case "Domestic": return .blue
                case "International": return .orange
                default: return .gray
                }
            }()
            return (key, value, color)
        }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visitor Origin")
                .font(.headline)
            
            HStack(spacing: 4) {
                ForEach(nationalityData, id: \.0) { nationality, count, color in
                    if count > 0 {
                        VStack {
                            Text("\(count)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(color)
                            Text(nationality)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(color.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Visit Reasons Chart View

struct VisitReasonsChartView: View {
    let visitors: [Visitor]
    
    var reasonsData: [(String, Int)] {
        var counts: [String: Int] = [:]
        
        for visitor in visitors {
            if let reason = visitor.visitReason {
                counts[reason.rawValue, default: 0] += 1
            }
        }
        
        return counts.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visit Purpose")
                .font(.headline)
            
            if !reasonsData.isEmpty {
                ForEach(reasonsData, id: \.0) { reason, count in
                    HStack {
                        Text(reason)
                            .font(.subheadline)
                        Spacer()
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            } else {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Hourly Traffic View

struct HourlyTrafficView: View {
    let visitors: [Visitor]
    
    var hourlyData: [(hour: Int, count: Int)] {
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        
        // Initialize all hours
        for hour in 0..<24 {
            hourCounts[hour] = 0
        }
        
        // Count visitors per hour
        for visitor in visitors {
            let hour = calendar.component(.hour, from: visitor.entryTime)
            hourCounts[hour, default: 0] += 1
        }
        
        return hourCounts.map { ($0.key, $0.value) }.sorted { $0.hour < $1.hour }
    }
    
    var maxCount: Int {
        hourlyData.map { $0.count }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Traffic")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(hourlyData, id: \.hour) { hour, count in
                        VStack {
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            
                            Rectangle()
                                .fill(count > 0 ? Color.blue : Color.gray.opacity(0.2))
                                .frame(width: 20, height: CGFloat(count) / CGFloat(maxCount) * 60)
                                .cornerRadius(2)
                            
                            Text("\(hour)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Age Distribution View

struct AgeDistributionView: View {
    let visitors: [Visitor]
    
    var ageData: [(level: Int, count: Int)] {
        var counts: [Int: Int] = [:]
        
        for level in 1...5 {
            counts[level] = visitors.filter { $0.ageLevel == level }.count
        }
        
        return counts.map { ($0.key, $0.value) }.sorted { $0.level < $1.level }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Age Distribution")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(ageData, id: \.level) { level, count in
                    VStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            Rectangle()
                                .fill(index < level ? Color.green : Color.gray.opacity(0.2))
                                .frame(width: 40, height: 8)
                                .cornerRadius(2)
                        }
                        
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Text("Age ranges from younger to older")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Discovery Method View

struct DiscoveryMethodView: View {
    let visitors: [Visitor]
    
    var discoveryData: [(method: String, count: Int, percentage: Double)] {
        var counts: [String: Int] = [:]
        
        for visitor in visitors {
            if let reason = visitor.barReason {
                counts[reason.rawValue, default: 0] += 1
            }
        }
        
        let total = counts.values.reduce(0, +)
        
        return counts.map { (key, value) in
            let percentage = total > 0 ? Double(value) / Double(total) * 100 : 0
            return (key, value, percentage)
        }.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How They Found Us")
                .font(.headline)
            
            if !discoveryData.isEmpty {
                VStack(spacing: 8) {
                    ForEach(discoveryData, id: \.method) { method, count, percentage in
                        HStack {
                            Text(method)
                                .font(.subheadline)
                            Spacer()
                            Text("\(count)")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("(\(Int(percentage))%)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Top Locations View

struct TopLocationsView: View {
    let locations: [(String, Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Locations")
                .font(.headline)
            
            ForEach(Array(locations.enumerated()), id: \.offset) { index, location in
                HStack {
                    Text("\(index + 1).")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text(location.0)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(location.1) visitors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
