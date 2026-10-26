import SwiftUI

struct VehicleClearanceCard: View {
    @ObservedObject var state: FloodWiseState
    @State private var showingPickerSheet: Bool = false
    
    var body: some View {
        let assessment = state.vehicleClearanceAssessment
        
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "car.side.and.exclamationmark")
                        .font(.caption.bold())
                        .foregroundColor(.fwNeonTeal)
                    Text("VEHICLE CLEARANCE SAFETY CHECK")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white.opacity(0.65))
                }
                Spacer()
                
                Button(action: {
                    showingPickerSheet = true
                }) {
                    HStack(spacing: 4) {
                        Text("Switch Car")
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.fwNeonTeal)
                }
            }
            
            // Selected Vehicle Selector Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VehicleProfile.defaultProfiles) { vehicle in
                        let isSelected = (vehicle.id == state.selectedVehicle.id)
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                state.selectedVehicle = vehicle
                            }
                            let feedback = UIImpactFeedbackGenerator(style: .light)
                            feedback.impactOccurred()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: vehicle.icon)
                                    .font(.subheadline)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(vehicle.name)
                                        .font(.system(size: 11, weight: .bold))
                                    Text("\(String(format: "%.1f", vehicle.clearanceInches))\" clearance")
                                        .font(.system(size: 9))
                                        .foregroundColor(isSelected ? .black.opacity(0.8) : .white.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(isSelected ? Color.fwNeonTeal : Color.white.opacity(0.06))
                            .foregroundColor(isSelected ? .black : .white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.fwNeonTeal : Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            // Safety Verdict Banner
            HStack(spacing: 12) {
                Image(systemName: assessment.isSafe ? "checkmark.circle.fill" : "exclamationmark.octagon.fill")
                    .font(.title2.weight(.bold))
                    .foregroundColor(assessment.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(assessment.status)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(assessment.color)
                    Text(assessment.advisory)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(12)
            .background(assessment.color.opacity(0.12))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(assessment.color.opacity(0.35), lineWidth: 1)
            )
        }
        .padding(16)
        .liquidGlass(radius: 20)
        .sheet(isPresented: $showingPickerSheet) {
            vehiclePickerModal
        }
    }
    
    // Vehicle Selection Modal
    private var vehiclePickerModal: some View {
        NavigationStack {
            ZStack {
                Color.fwObsidian.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("Select your vehicle type to calibrate personalized street flood risk:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    VStack(spacing: 10) {
                        ForEach(VehicleProfile.defaultProfiles) { profile in
                            Button(action: {
                                state.selectedVehicle = profile
                                showingPickerSheet = false
                            }) {
                                HStack(spacing: 14) {
                                    Image(systemName: profile.icon)
                                        .font(.title2)
                                        .foregroundColor(.fwNeonTeal)
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(profile.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("\(profile.category) • Ground Clearance: \(String(format: "%.1f", profile.clearanceInches)) in")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    if profile.id == state.selectedVehicle.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.fwNeonTeal)
                                    }
                                }
                                .padding()
                                .liquidGlass(
                                    radius: 16,
                                    strokeColor: profile.id == state.selectedVehicle.id ? Color.fwNeonTeal.opacity(0.7) : Color.white.opacity(0.1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Vehicle Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingPickerSheet = false
                    }
                    .foregroundColor(.fwNeonTeal)
                }
            }
        }
        .presentationDetents([.fraction(0.55)])
    }
}
