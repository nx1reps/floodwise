import SwiftUI

struct FloodCameraGalleryView: View {
    let feeds: [FloodCameraFeed]
    @State private var selectedFeed: FloodCameraFeed?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "video.fill")
                        .font(.caption.bold())
                        .foregroundColor(.fwNeonTeal)
                    Text("LIVE INTERSECTION FLOOD CAMS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white.opacity(0.65))
                }
                Spacer()
                Text("Simulated Sensors")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            // Horizontal Camera Feed Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(feeds) { feed in
                        Button(action: {
                            selectedFeed = feed
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                // Camera Simulation Box
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.fwMidnight, Color.fwNavyBase],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 190, height: 110)
                                    
                                    // Visual Street / Water Line Graphic
                                    VStack {
                                        Spacer()
                                        ZStack(alignment: .bottom) {
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.cyan.opacity(0.4), Color.blue.opacity(0.7)],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .frame(height: max(10, CGFloat(feed.waterDepthInches) * 3.5))
                                            
                                            // Waterline ruler
                                            HStack {
                                                Text("\(String(format: "%.1f", feed.waterDepthInches))\"")
                                                    .font(.system(size: 9, weight: .black))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 4)
                                                    .background(Color.black.opacity(0.6))
                                                    .cornerRadius(4)
                                                Spacer()
                                            }
                                            .padding(4)
                                        }
                                    }
                                    .frame(width: 190, height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    
                                    // REC Dot & Timestamp
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.red).frame(width: 6, height: 6)
                                        Text("LIVE")
                                            .font(.system(size: 8, weight: .black))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(feed.lastCheckedMinAgo)m ago")
                                            .font(.system(size: 8))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .padding(8)
                                    
                                    // Center Camera Icon
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Image(systemName: "video.badge.waveform")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white.opacity(0.35))
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                    .frame(width: 190, height: 110)
                                }
                                
                                // Intersection Info
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feed.intersection)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(feed.isPassable ? Color.fwEmeraldGlow : Color.fwCrimsonPulse)
                                            .frame(width: 5, height: 5)
                                        Text(feed.isPassable ? "Passable" : "Submerged / Caution")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(feed.isPassable ? .fwEmeraldGlow : .fwCrimsonPulse)
                                    }
                                }
                                .frame(width: 190, alignment: .leading)
                            }
                            .padding(10)
                            .liquidGlass(radius: 18)
                        }
                    }
                }
            }
        }
        .padding(16)
        .liquidGlass(radius: 20)
    }
}
