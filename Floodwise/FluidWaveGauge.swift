import SwiftUI

// MARK: - Sine Wave Shape with phase and amplitude
struct WaveShape: Shape {
    var offset: Angle
    var percent: Double
    var amplitude: CGFloat = 8
    
    var animatableData: AnimatablePair<Double, Double> {
        get {
            AnimatablePair(offset.radians, percent)
        }
        set {
            offset = Angle(radians: newValue.first)
            percent = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        let waterHeight = height * CGFloat(1.0 - percent)
        
        path.move(to: CGPoint(x: 0, y: waterHeight))
        
        for x in stride(from: 0, through: width, by: 4) {
            let relativeX = x / 40
            let sine = sin(relativeX + CGFloat(offset.radians))
            let y = waterHeight + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Interactive Fluid Wave Gauge
struct FluidWaveGauge: View {
    let score: Int // 0 - 100
    let level: RiskLevel
    let primaryReason: String
    let leaveByTime: String?
    
    @State private var wavePhase: Double = 0
    
    private var normalizedFill: Double {
        // Minimum visual water level 0.15, maximum 0.85
        let clamped = max(0, min(100, Double(score)))
        return 0.15 + (clamped / 100.0) * 0.70
    }
    
    private var statusAccentColor: Color {
        switch level {
        case .lowerRisk: return .fwEmeraldGlow
        case .moderateRisk: return .fwElectricAmber
        case .highRisk: return .fwCrimsonPulse
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Top Status Bar: Level Badge & Score Capsule
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: level.sfSymbol)
                        .font(.title3.weight(.bold))
                        .foregroundColor(statusAccentColor)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(level.rawValue)
                            .font(.system(.subheadline, design: .rounded).weight(.black))
                            .foregroundColor(.white)
                        Text(level.statusShortTitle)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                
                Spacer()
                
                // Score Pill
                HStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(statusAccentColor)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("/ 100")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                        Text("RISK")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(statusAccentColor.opacity(0.8))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusAccentColor.opacity(0.16))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusAccentColor.opacity(0.35), lineWidth: 1)
                )
            }
            
            // Center Stage: Animated Liquid Wave Sphere with Dual Waterlines
            HStack(spacing: 20) {
                // Liquid Sphere
                ZStack {
                    // Outer Ring Glow
                    Circle()
                        .stroke(statusAccentColor.opacity(0.25), lineWidth: 5)
                        .frame(width: 106, height: 106)
                        .shadow(color: statusAccentColor.opacity(0.3), radius: 8)
                    
                    // Sphere Interior Mask
                    Circle()
                        .fill(Color.fwNavyBase)
                        .frame(width: 100, height: 100)
                        .overlay(
                            ZStack {
                                // Background Wave (Layer 1)
                                WaveShape(
                                    offset: Angle(degrees: wavePhase * 0.75),
                                    percent: normalizedFill,
                                    amplitude: 6
                                )
                                .fill(statusAccentColor.opacity(0.35))
                                
                                // Foreground Wave (Layer 2)
                                WaveShape(
                                    offset: Angle(degrees: -wavePhase),
                                    percent: normalizedFill,
                                    amplitude: 8
                                )
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            statusAccentColor.opacity(0.85),
                                            statusAccentColor.opacity(0.55)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                
                                // Glass Sheen Reflection
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.6), Color.clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            }
                            .clipShape(Circle())
                        )
                    
                    // Center Floating Status Metric
                    VStack(spacing: 0) {
                        Image(systemName: "water.waves")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 3)
                        Text("\(Int(normalizedFill * 100))%")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 3)
                    }
                }
                .frame(width: 106, height: 106)
                
                // Explanatory Reason & Action Guidance
                VStack(alignment: .leading, spacing: 8) {
                    Text(primaryReason)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let leave = leaveByTime {
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                                .font(.caption.bold())
                                .foregroundColor(statusAccentColor)
                            Text(leave)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(statusAccentColor.opacity(0.20))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(statusAccentColor.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(18)
        .liquidGlass(radius: 24, strokeColor: statusAccentColor.opacity(0.35), glow: statusAccentColor.opacity(0.18))
        .onAppear {
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                wavePhase = 360
            }
        }
    }
}
