import SwiftUI

struct AddPlaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var state: FloodWiseState
    
    @State private var name: String = ""
    @State private var subtitle: String = ""
    @State private var latitudeStr: String = ""
    @State private var longitudeStr: String = ""
    
    // Quick presets
    private let presets: [(name: String, desc: String, lat: Double, lon: Double)] = [
        ("Chesapeake, VA", "Great Dismal Swamp & Elizabeth River", 36.7682, -76.2875),
        ("Virginia Beach, VA", "Oceanfront / Lynnhaven Inlet", 36.8529, -75.9780),
        ("Charleston, SC", "The Battery & Lowcountry king tide", 32.7765, -79.9311),
        ("Tampa, FL", "Bayshore Blvd & Hillsborough River", 27.9506, -82.4572),
        ("Sacramento, CA", "Sacramento River / Delta basin", 38.5816, -121.4944)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.fwOceanDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("QUICK NATIONAL PRESETS")
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            ForEach(presets, id: \.name) { p in
                                Button(action: {
                                    state.addPlace(name: p.name, subtitle: p.desc, lat: p.lat, lon: p.lon)
                                    dismiss()
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(p.name)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text(p.desc)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.cyan)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(14)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Text("OR ENTER CUSTOM COORDINATES")
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        VStack(spacing: 12) {
                            TextField("Location Name (e.g. Grandma's House)", text: $name)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            
                            TextField("Subtitle (e.g. James River / Richmond, VA)", text: $subtitle)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            
                            HStack {
                                TextField("Latitude (e.g. 37.5407)", text: $latitudeStr)
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                
                                TextField("Longitude (e.g. -77.4360)", text: $longitudeStr)
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: {
                                if let lat = Double(latitudeStr), let lon = Double(longitudeStr), !name.isEmpty {
                                    state.addPlace(name: name, subtitle: subtitle.isEmpty ? "Custom Location" : subtitle, lat: lat, lon: lon)
                                    dismiss()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark")
                                    Text("Add Custom Place")
                                        .bold()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cyan)
                                .foregroundColor(.black)
                                .cornerRadius(14)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Add Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
}
