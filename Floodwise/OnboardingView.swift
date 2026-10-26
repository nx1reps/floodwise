import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @ObservedObject var state: FloodWiseState
    @State private var currentStep: Int = 0
    
    var body: some View {
        ZStack {
            Color.fwObsidian.ignoresSafeArea()
            
            // Living atmosphere backdrop with dynamic radar aura
            RadialGradient(
                colors: [Color.fwNeonTeal.opacity(0.32), Color.fwNavyBase, Color.fwObsidian],
                center: .top,
                startRadius: 20,
                endRadius: 550
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Top Progress Indicators
                HStack(spacing: 8) {
                    ForEach(0..<4) { idx in
                        Capsule()
                            .fill(idx <= currentStep ? Color.fwNeonTeal : Color.white.opacity(0.18))
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                            .animation(.spring(), value: currentStep)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                Spacer()
                
                // Step Carousel
                TabView(selection: $currentStep) {
                    // Step 0: The Origin & The Problem
                    onboardingSlide(
                        tag: 0,
                        icon: "cloud.heavyrain.circle.fill",
                        iconColor: .fwNeonTeal,
                        badge: "ORIGIN STORY • 757 VA",
                        headline: "Floods don't wait\nfor storms.",
                        body: "In Hampton Roads, VA (the 757) and coastal river basins across America, streets submerge under bright blue skies during astronomical high tides. Standard weather apps only track rain percentage—not the water beneath your wheels."
                    )
                    
                    // Step 1: The Cross-Domain Radar
                    onboardingSlide(
                        tag: 1,
                        icon: "shield.lefthalf.filled.badge.checkmark",
                        iconColor: .fwEmeraldGlow,
                        badge: "INSTANT SITUATIONAL RADAR",
                        headline: "One look.\nOne answer.",
                        body: "FloodWise synthesizes NOAA coastal water levels, National Weather Service precipitation Doppler, and USGS stream gauges into a 2-second Green/Yellow/Red status and an exact 'leave-by' window."
                    )
                    
                    // Step 2: Crowdsourced Street Sensors
                    onboardingSlide(
                        tag: 2,
                        icon: "car.side.and.exclamationmark",
                        iconColor: .fwElectricAmber,
                        badge: "COMMUNITY HAZARD SENSORS",
                        headline: "Neighbors clear\nthe commute.",
                        body: "When water reaches the curb or hubcaps, drivers drop 2-tap anonymous hazard pins. All reports automatically expire in 4 hours so roads stay verified."
                    )
                    
                    // Step 3: Apple Location Privacy & Transparent Permissions
                    locationSlide(tag: 3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                Spacer()
                
                // Bottom Action Flow
                VStack(spacing: 12) {
                    if currentStep < 3 {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentStep += 1
                            }
                        }) {
                            HStack {
                                Text("Continue")
                                    .font(.headline.weight(.black))
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.fwNeonTeal, Color(red: 0/255, green: 180/255, blue: 216/255)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.black)
                            .cornerRadius(18)
                            .shadow(color: Color.fwNeonTeal.opacity(0.4), radius: 14, x: 0, y: 7)
                        }
                    } else {
                        // Native iOS Location Authorization Button
                        Button(action: {
                            state.requestCurrentLocation()
                            withAnimation {
                                isCompleted = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Allow Precise Location")
                                    .font(.headline.weight(.black))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.fwNeonTeal)
                            .foregroundColor(.black)
                            .cornerRadius(18)
                            .shadow(color: Color.fwNeonTeal.opacity(0.45), radius: 16, x: 0, y: 8)
                        }
                        
                        Button(action: {
                            withAnimation {
                                isCompleted = true
                            }
                        }) {
                            Text("Skip & Explore Default Cities (Norfolk, Miami, Houston)")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.75))
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func onboardingSlide(tag: Int, icon: String, iconColor: Color, badge: String, headline: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 68))
                .foregroundColor(iconColor)
                .shadow(color: iconColor.opacity(0.6), radius: 24, x: 0, y: 10)
            
            Text(badge)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(.fwNeonTeal)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.fwNeonTeal.opacity(0.15))
                .cornerRadius(8)
            
            Text(headline)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(2)
            
            Text(body)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .padding(26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(radius: 28)
        .padding(.horizontal, 24)
        .tag(tag)
    }
    
    private func locationSlide(tag: Int) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 68))
                .foregroundColor(.fwNeonTeal)
                .shadow(color: Color.fwNeonTeal.opacity(0.6), radius: 24, x: 0, y: 10)
            
            Text("HONEST PRIVACY ARCHITECTURE")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(.fwNeonTeal)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.fwNeonTeal.opacity(0.15))
                .cornerRadius(8)
            
            Text("Never flood on\nyour commute.")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                privacyBullet(icon: "shield.checkered", text: "Zero tracking, zero cookies, no account required.")
                privacyBullet(icon: "memorychip", text: "GPS processed strictly in-memory for government Doppler radar bounds.")
                privacyBullet(icon: "nosign", text: "Your location is never saved, uploaded, or sold.")
            }
            .padding(.top, 6)
        }
        .padding(26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(radius: 28)
        .padding(.horizontal, 24)
        .tag(tag)
    }
    
    private func privacyBullet(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundColor(.fwNeonTeal)
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
        }
    }
}
