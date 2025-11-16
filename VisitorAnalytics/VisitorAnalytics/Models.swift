import Foundation

struct Visitor: Identifiable, Codable {
    var id: String = UUID().uuidString
    var gender: Gender?
    var nationality: Nationality?
    var country: String?
    var prefecture: String?
    var visitReason: VisitReason?
    var barReason: BarReason?
    var ageLevel: Int?
    var groupType: GroupType?
    var entryTime: Date = Date()
    var exitTime: Date?
    var isActive: Bool = true
    
    enum Gender: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
    }
    
    enum Nationality: String, Codable, CaseIterable {
        case local = "Local"
        case domestic = "Domestic"
        case international = "International"
    }
    
    enum VisitReason: String, Codable, CaseIterable {
        case travel = "Travel"
        case business = "Business"
        case other = "Other"
    }
    
    enum BarReason: String, Codable, CaseIterable {
        case recommendation = "Recommendation"
        case random = "Random"
        case visitedBefore = "Visited Before"
        case regular = "Regular"
        case friends = "Friends"
        case other = "Other"
    }
    
    enum GroupType: String, Codable {
        case single = "Single"
        case pair = "Pair"
        case group = "Group"
    }
    
    var timeSpent: String {
        let interval = (exitTime ?? Date()).timeIntervalSince(entryTime)
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

// Country data
struct Country: Identifiable {
    let id = UUID()
    let name: String
    let flag: String
    
    static let countries = [
        Country(name: "Australia", flag: "🇦🇺"),
        Country(name: "Brazil", flag: "🇧🇷"),
        Country(name: "Canada", flag: "🇨🇦"),
        Country(name: "China", flag: "🇨🇳"),
        Country(name: "France", flag: "🇫🇷"),
        Country(name: "Germany", flag: "🇩🇪"),
        Country(name: "India", flag: "🇮🇳"),
        Country(name: "Italy", flag: "🇮🇹"),
        Country(name: "Japan", flag: "🇯🇵"),
        Country(name: "Korea", flag: "🇰🇷"),
        Country(name: "Mexico", flag: "🇲🇽"),
        Country(name: "Netherlands", flag: "🇳🇱"),
        Country(name: "Russia", flag: "🇷🇺"),
        Country(name: "Singapore", flag: "🇸🇬"),
        Country(name: "Spain", flag: "🇪🇸"),
        Country(name: "Thailand", flag: "🇹🇭"),
        Country(name: "UK", flag: "🇬🇧"),
        Country(name: "USA", flag: "🇺🇸"),
        Country(name: "Vietnam", flag: "🇻🇳")
    ].sorted { $0.name < $1.name }
}

// Japanese Prefectures
struct Prefecture {
    static let prefectures = [
        "Aichi", "Akita", "Aomori", "Chiba", "Ehime", "Fukui", "Fukuoka",
        "Fukushima", "Gifu", "Gunma", "Hiroshima", "Hokkaido", "Hyogo",
        "Ibaraki", "Ishikawa", "Iwate", "Kagawa", "Kagoshima", "Kanagawa",
        "Kochi", "Kumamoto", "Kyoto", "Mie", "Miyagi", "Miyazaki", "Nagano",
        "Nagasaki", "Nara", "Niigata", "Oita", "Okayama", "Okinawa", "Osaka",
        "Saga", "Saitama", "Shiga", "Shimane", "Shizuoka", "Tochigi",
        "Tokushima", "Tokyo", "Tottori", "Toyama", "Wakayama", "Yamagata",
        "Yamaguchi", "Yamanashi"
    ].sorted()
}
