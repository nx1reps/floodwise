import Foundation
import CoreLocation

// MARK: - Risk Level
enum RiskLevel: String, Codable, CaseIterable {
    case lowerRisk = "LOWER RISK"
    case moderateRisk = "MODERATE RISK"
    case highRisk = "HIGH RISK"
    
    var sfSymbol: String {
        switch self {
        case .lowerRisk: return "checkmark.shield.fill"
        case .moderateRisk: return "exclamationmark.triangle.fill"
        case .highRisk: return "exclamationmark.octagon.fill"
        }
    }
    
    var statusShortTitle: String {
        switch self {
        case .lowerRisk: return "Passable / Low Risk"
        case .moderateRisk: return "Elevated Water Likely"
        case .highRisk: return "Active Flooding Danger"
        }
    }
}

// MARK: - Sensor Metric Kind
enum SensorKind: String, Codable {
    case rain = "Rainfall Rate"
    case tide = "Tide / Coastal"
    case river = "River / Stream"
}

struct SensorReading: Identifiable, Codable {
    var id: String { kind.rawValue }
    let kind: SensorKind
    let valueDisplay: String
    let subtitle: String
    let agencyAttribution: String // "NWS", "NOAA", "USGS"
    let isElevated: Bool
}

// MARK: - Risk Assessment
struct RiskAssessment: Codable {
    let level: RiskLevel
    let score: Int // 0 - 100
    let primaryReason: String
    let leaveByTime: String?
    let activeAlertHeadline: String?
    let activeAlertDescription: String?
    let readings: [SensorReading]
    let evaluatedAt: Date
    
    static var placeholderLowerRisk: RiskAssessment {
        RiskAssessment(
            level: .lowerRisk,
            score: 12,
            primaryReason: "Normal tidal cycle and light showers under 0.1 in/hr. Streets remain passable.",
            leaveByTime: nil,
            activeAlertHeadline: nil,
            activeAlertDescription: nil,
            readings: [
                SensorReading(kind: .rain, valueDisplay: "0.05 in/hr", subtitle: "Light mist", agencyAttribution: "NWS Weather.gov", isElevated: false),
                SensorReading(kind: .tide, valueDisplay: "+0.4 ft", subtitle: "Normal cycle", agencyAttribution: "NOAA CO-OPS", isElevated: false),
                SensorReading(kind: .river, valueDisplay: "3.2 ft", subtitle: "Below action stage", agencyAttribution: "USGS Water", isElevated: false)
            ],
            evaluatedAt: Date()
        )
    }
}

// MARK: - Saved Place
struct SavedPlace: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let name: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    var isCurrentLocation: Bool = false
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static let defaults: [SavedPlace] = [
        SavedPlace(
            name: "Downtown Norfolk (757)",
            subtitle: "Hampton Roads tidal zone • VA",
            latitude: 36.8508,
            longitude: -76.2859,
            isCurrentLocation: false
        ),
        SavedPlace(
            name: "French Quarter",
            subtitle: "Mississippi River / Coastal • New Orleans, LA",
            latitude: 29.9584,
            longitude: -90.0644,
            isCurrentLocation: false
        ),
        SavedPlace(
            name: "Miami Beach",
            subtitle: "Biscayne Bay King Tide zone • FL",
            latitude: 25.7907,
            longitude: -80.1300,
            isCurrentLocation: false
        ),
        SavedPlace(
            name: "Downtown Houston",
            subtitle: "Buffalo Bayou flash flood basin • TX",
            latitude: 29.7604,
            longitude: -95.3698,
            isCurrentLocation: false
        ),
        SavedPlace(
            name: "Boulder Creek",
            subtitle: "Mountain runoff & river basin • CO",
            latitude: 40.0150,
            longitude: -105.2705,
            isCurrentLocation: false
        )
    ]
}

// MARK: - Community Flood Report
struct FloodReport: Identifiable, Codable {
    var id: UUID = UUID()
    let latitude: Double
    let longitude: Double
    let streetName: String
    let depthCategory: DepthCategory
    let note: String?
    let reportedAt: Date
    
    enum DepthCategory: String, Codable, CaseIterable {
        case puddle = "Ankle Deep (~2 in)"
        case hubcap = "Curb / Hubcap Deep (~6-10 in)"
        case impassable = "Impassable / Stalled Cars (12+ in)"
        
        var icon: String {
            switch self {
            case .puddle: return "drop.fill"
            case .hubcap: return "car.side.fill"
            case .impassable: return "exclamationmark.octagon.fill"
            }
        }
    }
    
    var isExpired: Bool {
        Date().timeIntervalSince(reportedAt) > 4 * 3600
    }
    
    var timeAgoString: String {
        let diff = Int(Date().timeIntervalSince(reportedAt) / 60)
        if diff < 1 { return "Just now" }
        if diff < 60 { return "\(diff)m ago" }
        return "\(diff / 60)h ago"
    }
}

// MARK: - Data Source Metadata
struct DataSourceMetadata {
    static let agencies = "Data from NOAA CO-OPS, NWS Weather.gov, USGS Water Services"
    static let legalDisclaimer = "Not an official emergency alert. Always follow instructions from local emergency managers, law enforcement, and first responders."
}

// MARK: - Interactive Demo Scenarios
enum DemoScenario: String, CaseIterable, Identifiable {
    case live = "Live Data"
    case sunnyKingTide = "Sunny King Tide"
    case stormSurge = "Storm Surge Emergency"
    
    var id: String { rawValue }
    
    var shortTitle: String {
        switch self {
        case .live: return "Live Sensor"
        case .sunnyKingTide: return "King Tide ☀️"
        case .stormSurge: return "Surge Alert 🚨"
        }
    }
    
    var icon: String {
        switch self {
        case .live: return "antenna.radiowaves.left.and.right"
        case .sunnyKingTide: return "sun.max.fill"
        case .stormSurge: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Vehicle Clearance Profile
struct VehicleProfile: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let clearanceInches: Double
    let icon: String
    let maxSafeWaterInches: Double
    let evWarning: Bool
    
    static let defaultProfiles: [VehicleProfile] = [
        VehicleProfile(id: "sedan", name: "Compact / Sedan", category: "Low Clearance", clearanceInches: 5.5, icon: "car.fill", maxSafeWaterInches: 5.0, evWarning: false),
        VehicleProfile(id: "ev", name: "Electric EV (Sedan/SUV)", category: "High Voltage Pack", clearanceInches: 6.8, icon: "bolt.car.fill", maxSafeWaterInches: 6.0, evWarning: true),
        VehicleProfile(id: "crossover", name: "Crossover / SUV", category: "Standard", clearanceInches: 8.5, icon: "suv.side.fill", maxSafeWaterInches: 8.0, evWarning: false),
        VehicleProfile(id: "truck", name: "Pickup / 4x4 Truck", category: "High Clearance", clearanceInches: 11.5, icon: "truck.pickup.side.fill", maxSafeWaterInches: 11.0, evWarning: false)
    ]
}

// MARK: - Hourly Tide & Surge Forecast
struct HourlyTideForecast: Identifiable {
    var id: String { timeLabel }
    let timeLabel: String
    let tideHeightFt: Double
    let rainRateInches: Double
    let riskScore: Int
    let isPeak: Bool
    let note: String
}

// MARK: - Traffic & Flood Intersections
struct FloodCameraFeed: Identifiable {
    let id: String
    let intersection: String
    let city: String
    let waterDepthInches: Double
    let isPassable: Bool
    let cameraViewName: String
    let lastCheckedMinAgo: Int
}

