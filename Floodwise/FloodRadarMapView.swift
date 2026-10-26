import SwiftUI
import MapKit
import Combine

struct FloodRadarMapView: View {
    @ObservedObject var state: FloodWiseState
    @State private var position: MapCameraPosition = .automatic
    @State private var showingReportSheet = false
    @State private var selectedHazard: FloodReport?
    
    // Interactive Radar Overlay Controls
    @State private var activeLayer: RadarLayer = .precipitation
    @State private var radarSweepAngle: Double = 0
    @State private var radarSweepTimer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()
    @State private var isSatellite: Bool = false
    @State private var is3DPitch: Bool = true
    @State private var showingRouteScan: Bool = false
    
    enum RadarLayer: String, CaseIterable {
        case precipitation = "Rain Doppler"
        case coastalSurge = "Tidal Surge"
        case riverBasin = "River Gauges"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Dark Cockpit Map Canvas with custom Camera & Overlays
            Map(position: $position) {
                // Monitored Focus Ring & Radar Sweep Anchor
                Annotation(state.selectedPlace.name, coordinate: state.selectedPlace.coordinate) {
                    ZStack {
                        // Ambient radar rings
                        Circle()
                            .stroke(layerAccentColor.opacity(0.35), lineWidth: 1.5)
                            .frame(width: 140, height: 140)
                        
                        Circle()
                            .stroke(layerAccentColor.opacity(0.20), lineWidth: 1)
                            .frame(width: 90, height: 90)
                        
                        // Sweeping radar beam indicator
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [layerAccentColor.opacity(0.7), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 2, height: 70)
                            .offset(y: -35)
                            .rotationEffect(.degrees(radarSweepAngle))
                        
                        // Center Core Shield Pin
                        Circle()
                            .fill(statusColor)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                            .shadow(color: statusColor, radius: 14)
                        
                        Image(systemName: "shield.fill")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                
                // Real-Time Community Flood Hazard Pins
                ForEach(state.reports) { report in
                    Annotation(report.streetName, coordinate: CLLocationCoordinate2D(latitude: report.latitude, longitude: report.longitude)) {
                        Button(action: {
                            selectedHazard = report
                        }) {
                            VStack(spacing: 3) {
                                ZStack {
                                    Circle()
                                        .fill(Color.fwCrimsonPulse.opacity(0.3))
                                        .frame(width: 48, height: 48)
                                    Circle()
                                        .fill(Color.fwCrimsonPulse)
                                        .frame(width: 28, height: 28)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        .shadow(color: Color.fwCrimsonPulse, radius: 8)
                                    Image(systemName: report.depthCategory.icon)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                HStack(spacing: 3) {
                                    Circle().fill(Color.fwCrimsonPulse).frame(width: 5, height: 5)
                                    Text(report.depthCategory.rawValue.split(separator: " ").first ?? "")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.85))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15), lineWidth: 1))
                            }
                        }
                    }
                }
            }
            .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .colorScheme(.dark)
            .ignoresSafeArea()
            .onReceive(radarSweepTimer) { _ in
                radarSweepAngle = (radarSweepAngle + 4).truncatingRemainder(dividingBy: 360)
            }
            
            // Top Floating HUD Control Bar
            VStack(spacing: 10) {
                // Status Header Pill & Control Toggles
                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 12, height: 12)
                            .shadow(color: statusColor, radius: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.selectedPlace.name)
                                .font(.headline.weight(.black))
                                .foregroundColor(.white)
                            Text("\(state.currentAssessment.level.rawValue) • RISK SCORE \(state.currentAssessment.score)/100")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(statusColor)
                        }
                    }
                    
                    Spacer()
                    
                    // 3D Pitch Tilt Toggle
                    Button(action: {
                        is3DPitch.toggle()
                        withAnimation(.spring()) {
                            position = .camera(
                                MapCamera(
                                    centerCoordinate: state.selectedPlace.coordinate,
                                    distance: 12000,
                                    heading: 0,
                                    pitch: is3DPitch ? 45 : 0
                                )
                            )
                        }
                    }) {
                        Text(is3DPitch ? "3D" : "2D")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(is3DPitch ? .black : .white)
                            .frame(width: 32, height: 32)
                            .background(is3DPitch ? Color.fwNeonTeal : Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    
                    // Satellite Hybrid Toggle
                    Button(action: {
                        withAnimation(.spring()) {
                            isSatellite.toggle()
                        }
                    }) {
                        Image(systemName: isSatellite ? "globe.americas.fill" : "map.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(isSatellite ? .black : .white)
                            .frame(width: 32, height: 32)
                            .background(isSatellite ? Color.fwNeonTeal : Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    
                    // Recenter GPS Button
                    Button(action: {
                        withAnimation(.spring()) {
                            position = .camera(
                                MapCamera(
                                    centerCoordinate: state.selectedPlace.coordinate,
                                    distance: 12000,
                                    heading: 0,
                                    pitch: is3DPitch ? 45 : 0
                                )
                            )
                        }
                    }) {
                        Image(systemName: "location.north.circle.fill")
                            .font(.title2)
                            .foregroundColor(.fwNeonTeal)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .liquidGlass(radius: 20)
                .padding(.horizontal)
                .padding(.top, 6)
                
                // Interactive Radar Layer Filter Pills (Doppler / Tidal Surge / River Basin)
                HStack(spacing: 8) {
                    ForEach(RadarLayer.allCases, id: \.self) { layer in
                        Button(action: {
                            withAnimation(.spring()) {
                                activeLayer = layer
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: iconForLayer(layer))
                                    .font(.caption2.bold())
                                Text(layer.rawValue)
                                    .font(.caption2.weight(.bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(activeLayer == layer ? layerAccentColor.opacity(0.3) : Color.white.opacity(0.06))
                            .foregroundColor(activeLayer == layer ? .white : .white.opacity(0.6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(activeLayer == layer ? layerAccentColor : Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Bottom HUD Status Bar (Autopilot Style)
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Circle().fill(Color.fwEmeraldGlow).frame(width: 6, height: 6)
                            Text("GOV SENSORS ACTIVE")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "cloud.heavyrain.fill").foregroundColor(.fwNeonTeal)
                                Text(state.currentAssessment.readings.first?.valueDisplay ?? "0.1 in/hr")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "water.waves").foregroundColor(.fwElectricAmber)
                                Text(state.currentAssessment.readings.dropFirst().first?.valueDisplay ?? "+0.5 ft")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Drop Hazard Pin Button
                    Button(action: {
                        showingReportSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Report Hazard")
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [.fwCrimsonPulse, .orange], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.fwCrimsonPulse.opacity(0.5), radius: 12, x: 0, y: 6)
                    }
                }
                .padding(14)
                .liquidGlass(radius: 22)
                .padding(.horizontal)
                .padding(.bottom, 80) // Clear floating dock
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportFloodingSheet(state: state)
        }
        .sheet(item: $selectedHazard) { hazard in
            HazardDetailSheet(hazard: hazard)
        }
        .onAppear {
            position = .camera(
                MapCamera(
                    centerCoordinate: state.selectedPlace.coordinate,
                    distance: 12000,
                    heading: 0,
                    pitch: 45
                )
            )
        }
        .onChange(of: state.selectedPlace) { newPlace in
            withAnimation(.spring()) {
                position = .camera(
                    MapCamera(
                        centerCoordinate: newPlace.coordinate,
                        distance: 12000,
                        heading: 0,
                        pitch: 45
                    )
                )
            }
        }
    }
    
    private var statusColor: Color {
        switch state.currentAssessment.level {
        case .lowerRisk: return .fwEmeraldGlow
        case .moderateRisk: return .fwElectricAmber
        case .highRisk: return .fwCrimsonPulse
        }
    }
    
    private var layerAccentColor: Color {
        switch activeLayer {
        case .precipitation: return .fwNeonTeal
        case .coastalSurge: return .fwElectricAmber
        case .riverBasin: return .cyan
        }
    }
    
    private func iconForLayer(_ layer: RadarLayer) -> String {
        switch layer {
        case .precipitation: return "cloud.heavyrain.fill"
        case .coastalSurge: return "water.waves"
        case .riverBasin: return "mountain.2.fill"
        }
    }
}

// MARK: - Selected Hazard Inspector
struct HazardDetailSheet: View {
    let hazard: FloodReport
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.fwObsidian.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: hazard.depthCategory.icon)
                            .font(.system(size: 38))
                            .foregroundColor(.fwCrimsonPulse)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hazard.streetName)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            Text("Reported \(hazard.timeAgoString) • Expires automatically in 4 hrs")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass(radius: 18)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WATER DEPTH REPORT")
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.6))
                        Text(hazard.depthCategory.rawValue)
                            .font(.headline)
                            .foregroundColor(.fwElectricAmber)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass(radius: 16)
                    
                    if let note = hazard.note {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DRIVER FIELD OBSERVATION")
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.6))
                            Text(note)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlass(radius: 16)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Hazard Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") { dismiss() }.foregroundColor(.fwNeonTeal)
                }
            }
        }
        .presentationDetents([.fraction(0.48)])
    }
}
