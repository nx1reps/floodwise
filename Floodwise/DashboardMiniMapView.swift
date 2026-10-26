import SwiftUI
import MapKit
import Combine

struct DashboardMiniMapView: View {
    @ObservedObject var state: FloodWiseState
    var onSelectFullscreen: () -> Void
    
    @State private var sweepAngle: Double = 0
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onSelectFullscreen()
        }) {
            ZStack(alignment: .bottom) {
                // Interactive Mini Map Canvas
                Map(initialPosition: .camera(
                    MapCamera(
                        centerCoordinate: state.selectedPlace.coordinate,
                        distance: 9000,
                        heading: 15,
                        pitch: 40
                    )
                )) {
                    // Center Location Anchor with Radar Rings
                    Annotation(state.selectedPlace.name, coordinate: state.selectedPlace.coordinate) {
                        ZStack {
                            Circle()
                                .stroke(Color.fwNeonTeal.opacity(0.4), lineWidth: 1.5)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .stroke(Color.fwNeonTeal.opacity(0.2), lineWidth: 1)
                                .frame(width: 50, height: 50)
                            
                            // Radar Sweep indicator
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.fwNeonTeal.opacity(0.8), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 2, height: 40)
                                .offset(y: -20)
                                .rotationEffect(.degrees(sweepAngle))
                            
                            Circle()
                                .fill(statusColor)
                                .frame(width: 20, height: 20)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(color: statusColor, radius: 8)
                        }
                    }
                    
                    // Nearby Hazard Pins
                    ForEach(state.reports.prefix(3)) { report in
                        Annotation(report.streetName, coordinate: CLLocationCoordinate2D(latitude: report.latitude, longitude: report.longitude)) {
                            ZStack {
                                Circle()
                                    .fill(Color.fwCrimsonPulse.opacity(0.35))
                                    .frame(width: 32, height: 32)
                                Circle()
                                    .fill(Color.fwCrimsonPulse)
                                    .frame(width: 18, height: 18)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                Image(systemName: report.depthCategory.icon)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
                .colorScheme(.dark)
                .frame(height: 145)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .disabled(true) // Treat whole card as a tap target
                
                // Bottom HUD Overlay Strip
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.fwNeonTeal)
                            .frame(width: 8, height: 8)
                            .shadow(color: .fwNeonTeal, radius: 4)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("LIVE FLOOD RADAR MAP")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.fwNeonTeal)
                            Text("\(state.reports.count) local hazard reports tracked")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Open Fullscreen")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.fwNeonTeal)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.55))
                    .cornerRadius(12)
                }
                .padding(12)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.85), Color.black.opacity(0.3)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.fwNeonTeal.opacity(0.3), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: Color.black.opacity(0.4), radius: 14, x: 0, y: 6)
        }
        .onReceive(timer) { _ in
            sweepAngle = (sweepAngle + 5).truncatingRemainder(dividingBy: 360)
        }
    }
    
    private var statusColor: Color {
        switch state.currentAssessment.level {
        case .lowerRisk: return .fwEmeraldGlow
        case .moderateRisk: return .fwElectricAmber
        case .highRisk: return .fwCrimsonPulse
        }
    }
}
