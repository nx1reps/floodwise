import Foundation
import SwiftUI
import CoreLocation
import Combine

@MainActor
final class FloodWiseState: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var savedPlaces: [SavedPlace] = []
    @Published var selectedPlace: SavedPlace
    @Published var currentAssessment: RiskAssessment = .placeholderLowerRisk
    @Published var isLoading: Bool = false
    @Published var reports: [FloodReport] = []
    @Published var lastRefreshed: Date = Date()
    @Published var locationPermissionDenied: Bool = false
    
    @Published var activeScenario: DemoScenario = .live
    @Published var selectedVehicle: VehicleProfile = VehicleProfile.defaultProfiles[0]
    @Published var hourlyForecast: [HourlyTideForecast] = []
    @Published var cameraFeeds: [FloodCameraFeed] = []
    
    private let locationManager = CLLocationManager()
    private let placesKey = "FloodWise_SavedPlaces_v1"
    private let reportsKey = "FloodWise_LocalReports_v1"
    
    override init() {
        // Load stored places or default to Hampton Roads (Norfolk 757)
        if let data = UserDefaults.standard.data(forKey: placesKey),
           let decoded = try? JSONDecoder().decode([SavedPlace].self, from: data),
           !decoded.isEmpty {
            self.savedPlaces = decoded
            self.selectedPlace = decoded[0]
        } else {
            self.savedPlaces = SavedPlace.defaults
            self.selectedPlace = SavedPlace.defaults[0]
        }
        
        super.init()
        self.locationManager.delegate = self
        loadStoredReports()
        seedSampleReportsIfEmpty()
        updateMockFeeds(for: self.selectedPlace, level: self.currentAssessment.level)
        
        // Initial data fetch
        Task {
            await refreshData()
        }
    }
    
    // MARK: - Interactive Scenario Switcher (Instant Apple Editor Demo)
    func setScenario(_ scenario: DemoScenario) {
        self.activeScenario = scenario
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
        
        switch scenario {
        case .live:
            Task {
                await refreshData()
            }
        case .sunnyKingTide:
            // "Blue Sky Flood": 0 rain, but +2.4ft astronomical king tide cresting at high tide
            self.currentAssessment = RiskAssessment(
                level: .moderateRisk,
                score: 68,
                primaryReason: "Sunny Day King Tide: Water is rising through storm drains despite 0% rain. Curb flooding active in low-lying intersections.",
                leaveByTime: "Peak Crest at 8:45 PM • Move Cars Now",
                activeAlertHeadline: "NWS Coastal Flood Advisory • High Astronomical Tide",
                activeAlertDescription: "Tidal departure +2.4 ft above normal high tide. Vulnerable low-elevation roadways including Colley Ave and Boush St will experience 6-10 in of saltwater inundation.",
                readings: [
                    SensorReading(kind: .tide, valueDisplay: "+2.4 ft", subtitle: "King Tide Anomaly", agencyAttribution: "NOAA CO-OPS (Sewells Pt)", isElevated: true),
                    SensorReading(kind: .rain, valueDisplay: "0.0 in/hr", subtitle: "Clear Skies (0% Rain)", agencyAttribution: "NWS Weather.gov", isElevated: false),
                    SensorReading(kind: .river, valueDisplay: "4.8 ft", subtitle: "Tidal backflow in basins", agencyAttribution: "USGS Stream", isElevated: true)
                ],
                evaluatedAt: Date()
            )
            updateMockFeeds(for: self.selectedPlace, level: .moderateRisk)
            
        case .stormSurge:
            // Emergency Nor'easter / Tropical Surge
            self.currentAssessment = RiskAssessment(
                level: .highRisk,
                score: 94,
                primaryReason: "CRITICAL FLOOD EMERGENCY: +3.9 ft coastal storm surge + 1.8 in/hr torrential rain bands. Multiple underpasses submerged.",
                leaveByTime: "IMPASSABLE: Evacuation Window Closed",
                activeAlertHeadline: "NWS FLASH FLOOD WARNING • IMMEDIATE SHELTER IN PLACE",
                activeAlertDescription: "Life-threatening flash flooding underway. Water depths exceed 14 inches on major arterials. Do not attempt to drive through flooded roads.",
                readings: [
                    SensorReading(kind: .tide, valueDisplay: "+3.9 ft", subtitle: "Severe Surge", agencyAttribution: "NOAA CO-OPS (Sewells Pt)", isElevated: true),
                    SensorReading(kind: .rain, valueDisplay: "1.8 in/hr", subtitle: "Torrential Downpour (100%)", agencyAttribution: "NWS Doppler Radar", isElevated: true),
                    SensorReading(kind: .river, valueDisplay: "11.2 ft", subtitle: "Major Flood Stage", agencyAttribution: "USGS Water (Storm)", isElevated: true)
                ],
                evaluatedAt: Date()
            )
            updateMockFeeds(for: self.selectedPlace, level: .highRisk)
        }
    }
    
    // MARK: - Vehicle Clearance Calculator
    var vehicleClearanceAssessment: (status: String, isSafe: Bool, color: Color, advisory: String) {
        let currentWaterInches: Double = {
            switch currentAssessment.level {
            case .lowerRisk: return 1.2
            case .moderateRisk: return 7.5
            case .highRisk: return 14.0
            }
        }()
        
        let diff = selectedVehicle.clearanceInches - currentWaterInches
        
        if diff >= 2.5 {
            return (
                status: "PASSABLE FOR \(selectedVehicle.name.uppercased())",
                isSafe: true,
                color: .fwEmeraldGlow,
                advisory: "Clearance margin is +\(String(format: "%.1f", diff)) inches. Drive slowly to avoid bow wave splash."
            )
        } else if diff >= -0.5 {
            return (
                status: "BORDERLINE HAZARD (CAUTION)",
                isSafe: false,
                color: .fwElectricAmber,
                advisory: selectedVehicle.evWarning 
                    ? "Submerged EV battery seals risk saltwater corrosion! Reroute immediately."
                    : "Water level matches vehicle floorboard clearance (\(String(format: "%.1f", selectedVehicle.clearanceInches)) in). Turn around!"
            )
        } else {
            return (
                status: "HIGH DANGER: SUBMERSION RISK",
                isSafe: false,
                color: .fwCrimsonPulse,
                advisory: "Water (\(String(format: "%.1f", currentWaterInches)) in) exceeds clearance (\(String(format: "%.1f", selectedVehicle.clearanceInches)) in). Severe risk of engine hydro-lock and car floating!"
            )
        }
    }
    
    func updateMockFeeds(for place: SavedPlace, level: RiskLevel) {
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Generate dynamic 24-hr tide & surge forecast curve
        var forecast: [HourlyTideForecast] = []
        for offset in 0..<12 {
            let hour = (currentHour + offset * 2) % 24
            let timeStr = hour == 0 ? "12 AM" : (hour < 12 ? "\(hour) AM" : (hour == 12 ? "12 PM" : "\(hour - 12) PM"))
            
            let isPeakTide = (offset == 2) || (offset == 8)
            let baseTide: Double = {
                switch level {
                case .lowerRisk: return isPeakTide ? 1.2 : 0.2
                case .moderateRisk: return isPeakTide ? 2.8 : 1.4
                case .highRisk: return isPeakTide ? 4.2 : 2.6
                }
            }()
            
            let rain: Double = {
                switch level {
                case .lowerRisk: return 0.05
                case .moderateRisk: return 0.1
                case .highRisk: return isPeakTide ? 1.8 : 0.9
                }
            }()
            
            let score: Int = {
                switch level {
                case .lowerRisk: return isPeakTide ? 18 : 6
                case .moderateRisk: return isPeakTide ? 74 : 45
                case .highRisk: return isPeakTide ? 96 : 82
                }
            }()
            
            let note = isPeakTide ? "Peak High Tide Crest" : (score > 50 ? "Water Inundation" : "Normal Flow")
            forecast.append(HourlyTideForecast(timeLabel: timeStr, tideHeightFt: baseTide, rainRateInches: rain, riskScore: score, isPeak: isPeakTide, note: note))
        }
        self.hourlyForecast = forecast
        
        // Generate Camera Feeds
        self.cameraFeeds = [
            FloodCameraFeed(
                id: "cam1",
                intersection: "The Hague Bridge / Colley Ave",
                city: place.name,
                waterDepthInches: level == .highRisk ? 15.2 : (level == .moderateRisk ? 8.4 : 1.1),
                isPassable: level == .lowerRisk,
                cameraViewName: "Tidal Estuary Inundation Cam",
                lastCheckedMinAgo: 2
            ),
            FloodCameraFeed(
                id: "cam2",
                intersection: "Downtown Railroad Underpass",
                city: place.name,
                waterDepthInches: level == .highRisk ? 22.0 : (level == .moderateRisk ? 6.2 : 0.0),
                isPassable: level != .highRisk,
                cameraViewName: "Depressed Grade Basin Sensor",
                lastCheckedMinAgo: 5
            ),
            FloodCameraFeed(
                id: "cam3",
                intersection: "Boush St & Brambleton Ave",
                city: place.name,
                waterDepthInches: level == .highRisk ? 11.5 : (level == .moderateRisk ? 4.8 : 0.5),
                isPassable: level != .highRisk,
                cameraViewName: "Commuter Arterial Traffic Cam",
                lastCheckedMinAgo: 1
            )
        ]
    }
    
    func selectPlace(_ place: SavedPlace) {
        self.selectedPlace = place
        Task {
            await refreshData()
        }
    }
    
    func addPlace(name: String, subtitle: String, lat: Double, lon: Double) {
        let newPlace = SavedPlace(name: name, subtitle: subtitle, latitude: lat, longitude: lon, isCurrentLocation: false)
        savedPlaces.append(newPlace)
        savePlaces()
        selectPlace(newPlace)
    }
    
    func deletePlace(at offsets: IndexSet) {
        savedPlaces.remove(atOffsets: offsets)
        if savedPlaces.isEmpty {
            savedPlaces = [SavedPlace.defaults[0]]
        }
        if !savedPlaces.contains(where: { $0.id == selectedPlace.id }) {
            selectedPlace = savedPlaces[0]
        }
        savePlaces()
        Task {
            await refreshData()
        }
    }
    
    private func savePlaces() {
        if let encoded = try? JSONEncoder().encode(savedPlaces) {
            UserDefaults.standard.set(encoded, forKey: placesKey)
        }
    }
    
    // MARK: - Core Refresh Orchestrator
    func refreshData() async {
        isLoading = true
        defer {
            isLoading = false
            lastRefreshed = Date()
        }
        
        let lat = selectedPlace.latitude
        let lon = selectedPlace.longitude
        
        // Concurrently query government APIs
        async let alertsTask = WeatherService.shared.fetchActiveAlerts(lat: lat, lon: lon)
        async let rainTask = WeatherService.shared.fetchHourlyRainMax(lat: lat, lon: lon)
        async let tideTask = TidesService.shared.fetchNearestTideAnomaly(lat: lat, lon: lon)
        async let riverTask = RiverService.shared.fetchNearestGauge(lat: lat, lon: lon)
        
        let (alertHeadline, alertDesc, alertSev) = await alertsTask
        let (rainRate, popMax, peakHour) = await rainTask
        let (tideStation, tideAnomaly, isCoastal) = await tideTask
        let (riverSite, riverStage, isRiverElevated) = await riverTask
        
        // Feed into deterministic RiskEngine
        let assessment = RiskEngine.shared.evaluate(
            lat: lat,
            lon: lon,
            alertHeadline: alertHeadline,
            alertSeverity: alertSev,
            rainRate: rainRate,
            popMax: popMax,
            peakRainHour: peakHour,
            tideStation: tideStation,
            tideAnomalyFt: tideAnomaly,
            isCoastal: isCoastal,
            riverSite: riverSite,
            riverStageFt: riverStage
        )
        
        self.currentAssessment = assessment
        updateMockFeeds(for: self.selectedPlace, level: assessment.level)
    }
    
    // MARK: - Community Reports
    func submitReport(street: String, depth: FloodReport.DepthCategory, note: String?) {
        let report = FloodReport(
            latitude: selectedPlace.latitude,
            longitude: selectedPlace.longitude,
            streetName: street.isEmpty ? "Near \(selectedPlace.name)" : street,
            depthCategory: depth,
            note: note,
            reportedAt: Date()
        )
        reports.insert(report, at: 0)
        saveReports()
    }
    
    private func saveReports() {
        if let encoded = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(encoded, forKey: reportsKey)
        }
    }
    
    private func loadStoredReports() {
        if let data = UserDefaults.standard.data(forKey: reportsKey),
           let decoded = try? JSONDecoder().decode([FloodReport].self, from: data) {
            self.reports = decoded.filter { !$0.isExpired }
        }
    }
    
    private func seedSampleReportsIfEmpty() {
        if reports.isEmpty {
            reports = [
                FloodReport(
                    latitude: 36.8508,
                    longitude: -76.2859,
                    streetName: "Colley Ave & 49th St",
                    depthCategory: .hubcap,
                    note: "Water rising past the curb line near the underpass.",
                    reportedAt: Date().addingTimeInterval(-25 * 60)
                ),
                FloodReport(
                    latitude: 36.8530,
                    longitude: -76.2910,
                    streetName: "Boush St & Brambleton",
                    depthCategory: .impassable,
                    note: "Sedan stalled in intersection. Avoid right lane.",
                    reportedAt: Date().addingTimeInterval(-70 * 60)
                ),
                FloodReport(
                    latitude: 36.8620,
                    longitude: -76.2750,
                    streetName: "Monticello Ave",
                    depthCategory: .puddle,
                    note: "Minor pooling along curb drains.",
                    reportedAt: Date().addingTimeInterval(-140 * 60)
                )
            ]
        }
    }
    
    // MARK: - CoreLocation
    func requestCurrentLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            let currentPlace = SavedPlace(
                name: "Current Location",
                subtitle: "GPS Precise",
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                isCurrentLocation: true
            )
            // Update or insert current location at head
            if let idx = self.savedPlaces.firstIndex(where: { $0.isCurrentLocation }) {
                self.savedPlaces[idx] = currentPlace
            } else {
                self.savedPlaces.insert(currentPlace, at: 0)
            }
            self.selectPlace(currentPlace)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationPermissionDenied = true
        }
    }
}
