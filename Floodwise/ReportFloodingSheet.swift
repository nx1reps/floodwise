import SwiftUI

struct ReportFloodingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var state: FloodWiseState
    
    @State private var street: String = ""
    @State private var selectedDepth: FloodReport.DepthCategory = .hubcap
    @State private var note: String = ""
    @State private var didSubmit: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.fwOceanDark.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header Banner
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.fwYellow)
                            Text("Help Keep Neighbors Safe")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        Text("Reports remain anonymous and auto-expire after 4 hours. Never enter moving floodwaters.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass(radius: 16)
                    .padding(.horizontal)
                    
                    // Street Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("STREET OR INTERSECTION")
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("e.g. Granby St & 21st St", text: $street)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    .padding(.horizontal)
                    
                    // Depth Selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ESTIMATED WATER DEPTH")
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.6))
                        
                        ForEach(FloodReport.DepthCategory.allCases, id: \.self) { depth in
                            Button(action: {
                                selectedDepth = depth
                            }) {
                                HStack {
                                    Image(systemName: depth.icon)
                                        .font(.title3)
                                        .frame(width: 30)
                                        .foregroundColor(selectedDepth == depth ? .cyan : .white.opacity(0.7))
                                    
                                    Text(depth.rawValue)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if selectedDepth == depth {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.cyan)
                                    }
                                }
                                .padding()
                                .background(selectedDepth == depth ? Color.cyan.opacity(0.15) : Color.white.opacity(0.05))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(selectedDepth == depth ? Color.cyan.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Optional Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OPTIONAL DETAILS")
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("e.g. Right lane blocked, storm drain bubbling", text: $note)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Submit Button
                    Button(action: {
                        state.submitReport(street: street, depth: selectedDepth, note: note.isEmpty ? nil : note)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Post Hazard Report (2-Tap)")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .shadow(color: Color.cyan.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .padding(.top, 10)
            }
            .navigationTitle("Report Flooding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
}
