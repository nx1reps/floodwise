import SwiftUI

// MARK: - Bespoke FloodWise Color Tokens (High-End Electric Dark Aesthetic)
extension Color {
    // Pure Obsidian & Deep Navy Canvas
    static let fwObsidian = Color(red: 4/255, green: 7/255, blue: 14/255)
    static let fwOceanDark = fwObsidian
    static let fwNavyBase = Color(red: 9/255, green: 17/255, blue: 31/255)
    static let fwMidnight = Color(red: 13/255, green: 24/255, blue: 44/255)
    
    // Electric Neon Semantic Status (Never generic pastel)
    static let fwNeonTeal = Color(red: 0/255, green: 245/255, blue: 212/255) // #00F5D4
    static let fwEmeraldGlow = Color(red: 16/255, green: 220/255, blue: 145/255)
    static let fwElectricAmber = Color(red: 255/255, green: 183/255, blue: 3/255) // #FFB703
    static let fwCrimsonPulse = Color(red: 255/255, green: 42/255, blue: 109/255) // #FF2A6D
    
    // Status Semantic Shortcuts
    static let fwGreen = fwEmeraldGlow
    static let fwYellow = fwElectricAmber
    static let fwRed = fwCrimsonPulse
    
    // Glass Surface Tokens
    static let fwGlassHighlight = Color.white.opacity(0.18)
    static let fwGlassBorder = Color.white.opacity(0.24)
}

// MARK: - Dynamic Living Gradient Background (Topographic Depth & Radar Glow)
struct DynamicLivingBackground: View {
    let riskLevel: RiskLevel
    @State private var pulse: Bool = false
    
    var body: some View {
        ZStack {
            Color.fwObsidian.ignoresSafeArea()
            
            // Background atmospheric radial aurora
            RadialGradient(
                gradient: Gradient(colors: [
                    statusAuraColor.opacity(0.38),
                    statusAuraColor.opacity(0.10),
                    Color.clear
                ]),
                center: .top,
                startRadius: 30,
                endRadius: pulse ? 620 : 540
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: pulse)
            
            // Secondary low-light cyan atmospheric refraction
            Circle()
                .fill(Color.fwNeonTeal.opacity(0.06))
                .frame(width: 450, height: 450)
                .blur(radius: 90)
                .offset(x: -140, y: 320)
                .ignoresSafeArea()
        }
        .onAppear {
            pulse = true
        }
    }
    
    private var statusAuraColor: Color {
        switch riskLevel {
        case .lowerRisk: return Color.fwEmeraldGlow
        case .moderateRisk: return Color.fwElectricAmber
        case .highRisk: return Color.fwCrimsonPulse
        }
    }
}

// MARK: - Native Liquid Glass Modifier with Specular Light Refraction
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var strokeColor: Color = Color.white.opacity(0.22)
    var interactiveGlow: Color? = nil
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.55), radius: 24, x: 0, y: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.50),
                                strokeColor.opacity(0.35),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(interactiveGlow ?? Color.clear, lineWidth: 1.5)
                    .blur(radius: 3)
            )
    }
}

extension View {
    func liquidGlass(
        radius: CGFloat = 24,
        strokeColor: Color = Color.white.opacity(0.22),
        glow: Color? = nil
    ) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: radius, strokeColor: strokeColor, interactiveGlow: glow))
    }
}
