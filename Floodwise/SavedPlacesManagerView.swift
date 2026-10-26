import SwiftUI

struct SavedPlacesManagerView: View {
    @ObservedObject var state: FloodWiseState
    @State private var showingAddPlace = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.fwOceanDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Section Header
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("MONITORED REGIONS")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white.opacity(0.6))
                                Text("Saved Places (Max 5)")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddPlace = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Add Place")
                                        .font(.caption.bold())
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.cyan)
                                .foregroundColor(.black)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                        
                        // Places List Cards
                        VStack(spacing: 12) {
                            ForEach(state.savedPlaces) { place in
                                Button(action: {
                                    state.selectPlace(place)
                                }) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(place.id == state.selectedPlace.id ? Color.cyan : Color.white.opacity(0.08))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: place.isCurrentLocation ? "location.fill" : "mappin.and.ellipse")
                                                .font(.headline)
                                                .foregroundColor(place.id == state.selectedPlace.id ? .black : .cyan)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(place.name)
                                                    .font(.headline.weight(.bold))
                                                    .foregroundColor(.white)
                                                if place.id == state.selectedPlace.id {
                                                    Text("ACTIVE")
                                                        .font(.system(size: 9, weight: .black))
                                                        .foregroundColor(.black)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.cyan)
                                                        .cornerRadius(6)
                                                }
                                            }
                                            
                                            Text(place.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption.bold())
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding()
                                    .liquidGlass(
                                        radius: 18,
                                        strokeColor: place.id == state.selectedPlace.id ? Color.cyan.opacity(0.6) : Color.white.opacity(0.12)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Origin Story Spotlight: The 757
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(.cyan)
                                Text("HAMPTON ROADS, VA (757) ROOTS")
                                    .font(.caption.bold())
                                    .foregroundColor(.cyan)
                            }
                            Text("FloodWise was built out of Ghent, Norfolk where sunny-day tidal flooding traps cars in low-lying intersections during astronomical lunar highs. Switching between coastal cities shows how river and tidal signals vary across the country.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(3)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlass(radius: 18)
                        .padding(.horizontal)
                    }
                    .padding(.top, 14)
                }
            }
            .navigationTitle("Saved Places")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddPlace) {
                AddPlaceSheet(state: state)
            }
        }
    }
}
