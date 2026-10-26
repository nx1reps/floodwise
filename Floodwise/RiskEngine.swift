import Foundation

final class RiskEngine {
    static let shared = RiskEngine()
    private init() {}
    
    /// Synthesizes government data streams into an instant, defensible risk status
    func evaluate(
        lat: Double,
        lon: Double,
        alertHeadline: String?,
        alertSeverity: String?,
        rainRate: Double,
        popMax: Int,
        peakRainHour: String?,
        tideStation: String?,
        tideAnomalyFt: Double,
        isCoastal: Bool,
        riverSite: String?,
        riverStageFt: Double
    ) -> RiskAssessment {
        var score: Int = 0
        var triggers: [String] = []
        var sensorReadings: [SensorReading] = []
        
        // 1. Alert Evaluation (Max 50 points)
        var hasActiveWarning = false
        if let headline = alertHeadline {
            let lower = headline.lowercased()
            if lower.contains("warning") {
                score += 50
                hasActiveWarning = true
                triggers.append("Active NWS Flood Warning")
            } else if lower.contains("watch") || lower.contains("advisory") {
                score += 25
                triggers.append("NWS Flood Watch / Advisory")
            }
        }
        
        // 2. Coastal Tide Evaluation (Max 30 points)
        if isCoastal {
            let tideElevated = tideAnomalyFt >= 1.2
            if tideAnomalyFt >= 1.8 {
                score += 30
                triggers.append(String(format: "King Tide (+%.1fft above normal)", tideAnomalyFt))
            } else if tideAnomalyFt >= 1.0 {
                score += 18
                triggers.append(String(format: "High tide surge (+%.1fft)", tideAnomalyFt))
            } else if tideAnomalyFt >= 0.5 {
                score += 8
            }
            
            sensorReadings.append(
                SensorReading(
                    kind: .tide,
                    valueDisplay: String(format: "+%.1f ft", tideAnomalyFt),
                    subtitle: tideElevated ? "Surge above normal" : "Normal cycle",
                    agencyAttribution: "NOAA CO-OPS (\(tideStation ?? "Coast"))",
                    isElevated: tideElevated
                )
            )
        } else {
            // Non-coastal region: show inland status
            sensorReadings.append(
                SensorReading(
                    kind: .tide,
                    valueDisplay: "Inland",
                    subtitle: "No coastal surge risk",
                    agencyAttribution: "NOAA CO-OPS",
                    isElevated: false
                )
            )
        }
        
        // 3. Rainfall Evaluation (Max 25 points)
        let rainElevated = rainRate >= 0.8 || popMax >= 70
        if rainRate >= 1.0 {
            score += 25
            triggers.append(String(format: "Intense downpour (~%.1fin/hr)", rainRate))
        } else if rainRate >= 0.4 || popMax >= 60 {
            score += 15
            triggers.append("Moderate rain bands")
        } else if popMax >= 30 {
            score += 6
        }
        
        sensorReadings.append(
            SensorReading(
                kind: .rain,
                valueDisplay: String(format: "%.1f in/hr", rainRate),
                subtitle: String(format: "%d%% precip chance", popMax),
                agencyAttribution: "NWS Weather.gov",
                isElevated: rainElevated
            )
        )
        
        // 4. River Stage Evaluation (Max 25 points)
        let riverElevated = riverStageFt >= 8.0
        if riverStageFt >= 10.0 {
            score += 25
            triggers.append(String(format: "River above flood stage (%.1fft)", riverStageFt))
        } else if riverStageFt >= 7.5 {
            score += 14
            triggers.append("River near action stage")
        } else {
            score += 2
        }
        
        sensorReadings.append(
            SensorReading(
                kind: .river,
                valueDisplay: String(format: "%.1f ft", riverStageFt),
                subtitle: riverElevated ? "Action/Flood stage" : "Within normal banks",
                agencyAttribution: "USGS Water (\(riverSite ?? "USGS"))",
                isElevated: riverElevated
            )
        )
        
        // Final Score Clamping
        score = min(100, score)
        
        // Determine Level
        let level: RiskLevel
        if score >= 50 || hasActiveWarning {
            level = .highRisk
        } else if score >= 25 {
            level = .moderateRisk
        } else {
            level = .lowerRisk
        }
        
        // Synthesize Plain-English Reason
        let primaryReason: String
        if !triggers.isEmpty {
            primaryReason = triggers.joined(separator: " + ") + ". Low-lying intersections are prone to pooling."
        } else {
            primaryReason = "No flood watches, low tidal surge, and light rain. Roads remain passable."
        }
        
        // Leave-By Recommendation
        var leaveBy: String? = nil
        if level == .highRisk {
            leaveBy = "Leave before 5:15 PM"
        } else if level == .moderateRisk {
            leaveBy = "Plan alternate route"
        }
        
        return RiskAssessment(
            level: level,
            score: score,
            primaryReason: primaryReason,
            leaveByTime: leaveBy,
            activeAlertHeadline: alertHeadline,
            activeAlertDescription: nil,
            readings: sensorReadings,
            evaluatedAt: Date()
        )
    }
}
