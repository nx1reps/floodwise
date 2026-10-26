import SwiftUI

struct HourlyTideScrubberView: View {
    let forecast: [HourlyTideForecast]
    @State private var selectedIndex: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header with active selection summary
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.caption.bold())
                        .foregroundColor(.fwNeonTeal)
                    Text("24-HOUR TIDE & SURGE TIMELINE")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white.opacity(0.65))
                }
                Spacer()
                
                if forecast.indices.contains(selectedIndex) {
                    let active = forecast[selectedIndex]
                    Text("\(active.timeLabel): \(String(format: "+%.1f ft", active.tideHeightFt)) surge")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(active.riskScore >= 50 ? .fwCrimsonPulse : (active.riskScore >= 25 ? .fwElectricAmber : .fwEmeraldGlow))
                }
            }
            
            // Horizontal scrubbable timeline
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(forecast.enumerated()), id: \.element.id) { index, item in
                        let isSelected = (index == selectedIndex)
                        let barColor: Color = {
                            if item.riskScore >= 50 { return .fwCrimsonPulse }
                            if item.riskScore >= 25 { return .fwElectricAmber }
                            return .fwEmeraldGlow
                        }()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                selectedIndex = index
                            }
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }) {
                            VStack(spacing: 6) {
                                // Time label
                                Text(item.timeLabel)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                
                                // Peak badge or icon
                                if item.isPeak {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.fwElectricAmber)
                                } else {
                                    Image(systemName: "water.waves")
                                        .font(.system(size: 9))
                                        .foregroundColor(barColor.opacity(0.8))
                                }
                                
                                // Height Bar Representation
                                ZStack(alignment: .bottom) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                        .frame(width: 6, height: 42)
                                    
                                    Capsule()
                                        .fill(barColor)
                                        .frame(width: 6, height: max(8, CGFloat(item.tideHeightFt) * 9.0))
                                }
                                
                                // Metric value
                                Text(String(format: "+%.1f'", item.tideHeightFt))
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                // Rain dot if raining
                                if item.rainRateInches > 0.05 {
                                    HStack(spacing: 2) {
                                        Circle().fill(Color.cyan).frame(width: 4, height: 4)
                                        Text(String(format: "%.1f\"", item.rainRateInches))
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.cyan)
                                    }
                                } else {
                                    Text("dry")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(isSelected ? barColor.opacity(0.20) : Color.white.opacity(0.04))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? barColor.opacity(0.8) : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
                            )
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .liquidGlass(radius: 20)
    }
}
