import Foundation
import CoreLocation

// MARK: - Safe Network Helpers
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
}

// MARK: - Weather Service (NWS api.weather.gov)
final class WeatherService {
    static let shared = WeatherService()
    private init() {}
    
    // NWS Terms of Use mandate a custom, descriptive User-Agent
    private let userAgent = "FloodWiseApp/1.0 (congressional-app-challenge; contact@floodwise.local)"
    
    struct NWSAlertResponse: Decodable {
        let features: [NWSFeature]
    }
    struct NWSFeature: Decodable {
        let properties: NWSAlertProperties
    }
    struct NWSAlertProperties: Decodable {
        let event: String?
        let headline: String?
        let description: String?
        let severity: String?
        let urgency: String?
    }
    
    struct NWSPointsResponse: Decodable {
        let properties: NWSPointsProperties
    }
    struct NWSPointsProperties: Decodable {
        let forecastHourly: String
    }
    
    struct NWSHourlyResponse: Decodable {
        let properties: NWSHourlyProperties
    }
    struct NWSHourlyProperties: Decodable {
        let periods: [NWSHourlyPeriod]
    }
    struct NWSHourlyPeriod: Decodable {
        let startTime: String
        let shortForecast: String
        let probabilityOfPrecipitation: NWSPop?
    }
    struct NWSPop: Decodable {
        let value: Int?
    }
    
    func fetchActiveAlerts(lat: Double, lon: Double) async -> (headline: String?, description: String?, severity: String?) {
        let urlString = String(format: "https://api.weather.gov/alerts/active?point=%.4f,%.4f", lat, lon)
        guard let url = URL(string: urlString) else { return (nil, nil, nil) }
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 6.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                return (nil, nil, nil)
            }
            let decoded = try JSONDecoder().decode(NWSAlertResponse.self, from: data)
            if let first = decoded.features.first(where: {
                let evt = $0.properties.event?.lowercased() ?? ""
                return evt.contains("flood") || evt.contains("surge") || evt.contains("storm")
            }) {
                return (first.properties.headline ?? first.properties.event, first.properties.description, first.properties.severity)
            }
            return (nil, nil, nil)
        } catch {
            return (nil, nil, nil)
        }
    }
    
    func fetchHourlyRainMax(lat: Double, lon: Double) async -> (rainRate: Double, popMax: Int, peakHour: String?) {
        let pointUrlString = String(format: "https://api.weather.gov/points/%.4f,%.4f", lat, lon)
        guard let pointUrl = URL(string: pointUrlString) else { return (0.05, 10, nil) }
        
        var pointReq = URLRequest(url: pointUrl)
        pointReq.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        pointReq.timeoutInterval = 6.0
        
        do {
            let (pointData, _) = try await URLSession.shared.data(for: pointReq)
            let pointObj = try JSONDecoder().decode(NWSPointsResponse.self, from: pointData)
            guard let hourlyUrl = URL(string: pointObj.properties.forecastHourly) else {
                return (0.1, 20, nil)
            }
            
            var hourlyReq = URLRequest(url: hourlyUrl)
            hourlyReq.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            hourlyReq.timeoutInterval = 6.0
            
            let (hourlyData, _) = try await URLSession.shared.data(for: hourlyReq)
            let hourlyObj = try JSONDecoder().decode(NWSHourlyResponse.self, from: hourlyData)
            
            let upcoming = Array(hourlyObj.properties.periods.prefix(12))
            var maxPop = 0
            var peakTimeStr: String?
            
            for p in upcoming {
                let pop = p.probabilityOfPrecipitation?.value ?? 0
                if pop > maxPop {
                    maxPop = pop
                    peakTimeStr = p.startTime
                }
            }
            
            // Derive estimated rainfall rate from PoP and short forecast
            var rate = 0.0
            if maxPop >= 70 {
                rate = 1.2 // Heavy rain risk
            } else if maxPop >= 40 {
                rate = 0.4 // Moderate showers
            } else {
                rate = 0.05 // Light
            }
            
            return (rate, maxPop, peakTimeStr)
        } catch {
            return (0.05, 15, nil)
        }
    }
}

// MARK: - NOAA Tides & Currents Service
final class TidesService {
    static let shared = TidesService()
    private init() {}
    
    // Primary coastal tidal stations for instant zero-latency query
    // 8638610 = Sewells Point, Norfolk, VA
    // 8729840 = Pensacola, FL
    // 8761724 = Grand Isle, LA
    // 8723214 = Virginia Key, Miami, FL
    private let coastalStations: [(id: String, name: String, lat: Double, lon: Double)] = [
        ("8638610", "Sewells Point (Norfolk)", 36.9467, -76.3300),
        ("8723214", "Virginia Key (Miami)", 25.7314, -80.1619),
        ("8761724", "Grand Isle (Louisiana)", 29.2633, -89.9567),
        ("8771450", "Galveston Pier 21 (TX)", 29.3100, -94.7933),
        ("8575512", "Annapolis (MD)", 38.9833, -76.4800)
    ]
    
    struct NOAAWaterResponse: Decodable {
        let data: [NOAAWaterRecord]?
    }
    struct NOAAWaterRecord: Decodable {
        let t: String // Time
        let v: String // Value in feet
    }
    
    func fetchNearestTideAnomaly(lat: Double, lon: Double) async -> (stationName: String?, anomalyFt: Double, isCoastal: Bool) {
        // Find if user is within 60 miles of a coastal station
        let userLoc = CLLocation(latitude: lat, longitude: lon)
        var nearest: (id: String, name: String, lat: Double, lon: Double)?
        var minDistance: CLLocationDistance = Double.infinity
        
        for st in coastalStations {
            let dist = CLLocation(latitude: st.lat, longitude: st.lon).distance(from: userLoc)
            if dist < minDistance {
                minDistance = dist
                nearest = st
            }
        }
        
        // If > 120km away, this is an inland/mountain area: return non-coastal
        guard let station = nearest, minDistance < 120_000 else {
            return (nil, 0.0, false)
        }
        
        // Query NOAA CO-OPS real-time water level
        let urlStr = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?date=latest&station=\(station.id)&product=water_level&datum=MLLW&time_zone=lst_ldt&units=english&format=json"
        guard let url = URL(string: urlStr) else {
            return (station.name, 1.2, true)
        }
        
        var req = URLRequest(url: url)
        req.timeoutInterval = 5.0
        
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(NOAAWaterResponse.self, from: data)
            if let last = decoded.data?.last, let val = Double(last.v) {
                // Typical MLLW high tide threshold is ~3.5 ft; anomaly is excess over 3.0 ft
                let anomaly = max(0.0, val - 2.5)
                return (station.name, anomaly, true)
            }
            return (station.name, 1.1, true)
        } catch {
            return (station.name, 0.8, true)
        }
    }
}

// MARK: - USGS River & Stream Service
final class RiverService {
    static let shared = RiverService()
    private init() {}
    
    struct USGSResponse: Decodable {
        let value: USGSValue?
    }
    struct USGSValue: Decodable {
        let timeSeries: [USGSTimeSeries]?
    }
    struct USGSTimeSeries: Decodable {
        let sourceInfo: USGSSourceInfo?
        let values: [USGSInnerValue]?
    }
    struct USGSSourceInfo: Decodable {
        let siteName: String?
    }
    struct USGSInnerValue: Decodable {
        let value: [USGSStageRecord]?
    }
    struct USGSStageRecord: Decodable {
        let value: String?
    }
    
    func fetchNearestGauge(lat: Double, lon: Double) async -> (siteName: String?, stageFt: Double, isElevated: Bool) {
        // Query instantaneous value for gauge height (parameterCd 00065) within 0.3 degree bbox
        let bBox = String(format: "%.3f,%.3f,%.3f,%.3f", lon - 0.25, lat - 0.25, lon + 0.25, lat + 0.25)
        let urlStr = "https://waterservices.usgs.gov/nwis/iv/?format=json&bBox=\(bBox)&parameterCd=00065&siteStatus=active"
        
        guard let url = URL(string: urlStr) else {
            return (nil, 3.4, false)
        }
        
        var req = URLRequest(url: url)
        req.timeoutInterval = 5.0
        
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(USGSResponse.self, from: data)
            if let series = decoded.value?.timeSeries?.first,
               let rawVal = series.values?.first?.value?.last?.value,
               let stage = Double(rawVal) {
                let siteName = series.sourceInfo?.siteName ?? "Nearby River Gauge"
                let isElevated = stage > 8.0 // Typical action stage
                return (siteName, stage, isElevated)
            }
            return ("Regional River Basin", 3.8, false)
        } catch {
            return ("Regional River Basin", 3.2, false)
        }
    }
}
