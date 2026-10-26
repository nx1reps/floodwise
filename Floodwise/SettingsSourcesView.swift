import SwiftUI

struct SettingsSourcesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.fwOceanDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Section: App & Mission
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "drop.fill")
                                    .font(.title2)
                                    .foregroundColor(.cyan)
                                Text("About FloodWise")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                            }
                            
                            Text("FloodWise was created for the Congressional App Challenge to solve the 'silent flood' problem in tidal and river communities across America. Originating in the 757 (Hampton Roads, VA)—where roads submerge under blue skies on sunny king tides—it synthesizes disparate government data streams into a single 2-second answer.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                                .lineSpacing(4)
                        }
                        .padding()
                        .liquidGlass(radius: 18)
                        
                        // Section: Official Data Attribution
                        VStack(alignment: .leading, spacing: 14) {
                            Text("GOVERNMENT DATA SOURCES")
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.6))
                            
                            SourceRow(
                                title: "NOAA Tides & Currents (CO-OPS)",
                                subtitle: "Real-time water levels & astronomical tide predictions at coastal ocean stations.",
                                icon: "water.waves"
                            )
                            
                            SourceRow(
                                title: "National Weather Service (api.weather.gov)",
                                subtitle: "Hourly precipitation forecast, flash flood alerts, and regional Doppler grids.",
                                icon: "cloud.heavyrain.fill"
                            )
                            
                            SourceRow(
                                title: "USGS National Water Dashboard",
                                subtitle: "Real-time river stage & stream gauge height across thousands of US waterways.",
                                icon: "mountain.2.fill"
                            )
                            
                            Text("Note: FloodWise uses official public APIs provided by the US Federal Government. This software is not endorsed by or affiliated with NOAA, NWS, or USGS.")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 4)
                        }
                        .padding()
                        .liquidGlass(radius: 18)
                        
                        // Section: Privacy & Safety
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SAFETY & PRIVACY COMMITMENTS")
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "hand.raised.slash.fill")
                                    .foregroundColor(.fwGreen)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Zero Tracking & No Ad Networks")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text("Coordinates are used only in-memory to request regional weather grids. No accounts, cookies, or analytics tracking.")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "shield.lefthalf.filled.trianglebadge.exclamationmark")
                                    .foregroundColor(.fwYellow)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Emergency Safety Notice")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text("FloodWise provides situational guidance and does not replace official evacuation orders or emergency directives from local civil defense.")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding()
                        .liquidGlass(radius: 18)
                        
                        // Footer
                        HStack {
                            Spacer()
                            Text("FloodWise v1.0 • Congressional App Challenge 2026")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.4))
                            Spacer()
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Sources & Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
}

struct SourceRow: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.cyan)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
            }
        }
    }
}
