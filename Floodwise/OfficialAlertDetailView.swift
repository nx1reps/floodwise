import SwiftUI

struct OfficialAlertDetailView: View {
    @ObservedObject var state: FloodWiseState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.fwOceanDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Giant Threat Badge
                        HStack(spacing: 14) {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.fwRed)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NWS FLASH FLOOD WARNING")
                                    .font(.caption.bold())
                                    .foregroundColor(.fwRed)
                                Text(state.selectedPlace.name)
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlass(radius: 20, strokeColor: Color.fwRed.opacity(0.4))
                        
                        // Plain-English Translation Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PLAIN-ENGLISH TRANSLATION")
                                .font(.caption2.bold())
                                .foregroundColor(.cyan)
                            
                            Text("What this means for you right now:")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Water is actively covering or predicted to submerge roadways in low-lying sections within the next 2 to 4 hours. Do not drive through flooded underpasses or coastal intersections. Turn around, don't drown.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                                .lineSpacing(4)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlass(radius: 18)
                        
                        // Official Meteorological Advisory Text
                        VStack(alignment: .leading, spacing: 10) {
                            Text("OFFICIAL NWS TRANSMISSION")
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text(state.currentAssessment.activeAlertHeadline ?? "Active coastal and flash flood advisory in effect for the designated forecast zone. Heavy localized rainfall rates exceeding 1.2 in/hr coincide with high astronomical tides.")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white.opacity(0.75))
                                .lineSpacing(4)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlass(radius: 18)
                        
                        // Safety Checklist
                        VStack(alignment: .leading, spacing: 12) {
                            Text("EMERGENCY CHECKLIST")
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.6))
                            
                            checklistRow(icon: "car.side.rear.and.collision.hazard", text: "Move vehicles from underground parking & street gutters")
                            checklistRow(icon: "figure.walk", text: "Never walk or wade into standing floodwaters (hidden open manholes)")
                            checklistRow(icon: "powerplug.fill", text: "Avoid downed powerlines touching standing water")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlass(radius: 18)
                    }
                    .padding()
                }
            }
            .navigationTitle("Official Alert Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") { dismiss() }.foregroundColor(.cyan)
                }
            }
        }
    }
    
    private func checklistRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.fwYellow)
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
        }
    }
}
