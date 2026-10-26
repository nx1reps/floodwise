import SwiftUI

struct ContentView: View {
    @StateObject private var state = FloodWiseState()
    @AppStorage("hasCompletedOnboarding_v1") private var hasCompletedOnboarding: Bool = false
    @State private var selectedTab: Int = 0
    
    // Sheets
    @State private var showingAddPlace = false
    @State private var showingReportFlooding = false
    @State private var showingSettings = false
    @State private var showingAlertDetail = false
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(isCompleted: $hasCompletedOnboarding, state: state)
            } else {
                mainAutopilotContainer
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Main Autopilot-Style App Container
    private var mainAutopilotContainer: some View {
        ZStack(alignment: .bottom) {
            // Selected Tab Content
            Group {
                switch selectedTab {
                case 0:
                    homeRadarDashboard
                case 1:
                    FloodRadarMapView(state: state)
                case 2:
                    SavedPlacesManagerView(state: state)
                default:
                    SettingsSourcesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Autopilot Floating Glass Bottom Dock
            floatingGlassDock
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingAddPlace) {
            AddPlaceSheet(state: state)
        }
        .sheet(isPresented: $showingReportFlooding) {
            ReportFloodingSheet(state: state)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSourcesView()
        }
        .sheet(isPresented: $showingAlertDetail) {
            OfficialAlertDetailView(state: state)
        }
    }
    
    // MARK: - Tab 0: Home Situational Dashboard
    private var homeRadarDashboard: some View {
        ZStack {
            // Dynamic living gradient that shifts with flood risk
            DynamicLivingBackground(riskLevel: state.currentAssessment.level)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // Top Location Selector & Controls
                    topBar
                    
                    // Demo Scenario Switcher (One-tap showcase for judges & testers)
                    demoScenarioPillBar
                    
                    // Fluid Wave Liquid Status Card (Apple Editor's Choice Hero)
                    FluidWaveGauge(
                        score: state.currentAssessment.score,
                        level: state.currentAssessment.level,
                        primaryReason: state.currentAssessment.primaryReason,
                        leaveByTime: state.currentAssessment.leaveByTime
                    )
                    
                    // Trio Sensor Metric Micro-Gauges
                    sensorChipsRow
                    
                    // Active Official Warning Banner
                    if let alert = state.currentAssessment.activeAlertHeadline {
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            showingAlertDetail = true
                        }) {
                            officialAlertBanner(headline: alert)
                        }
                    }
                    
                    // "Can My Car Make It?" Vehicle Clearance Safety Studio
                    VehicleClearanceCard(state: state)
                    
                    // Real Live Interactive Map Preview Card
                    DashboardMiniMapView(state: state) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedTab = 1
                        }
                    }
                    
                    // 24-Hour Scrubbable Tide & Surge Curve
                    HourlyTideScrubberView(forecast: state.hourlyForecast)
                    
                    // Live Intersection Flood Cameras
                    FloodCameraGalleryView(feeds: state.cameraFeeds)
                    
                    // Community Hazard Reports Section
                    communityReportsSection
                    
                    // Trust & Legal Footer
                    trustFooter
                    
                    // Spacer for floating dock
                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 20)
            }
            .refreshable {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                await state.refreshData()
            }
        }
    }
    
    // MARK: - Demo Scenario Switcher Bar
    private var demoScenarioPillBar: some View {
        HStack(spacing: 8) {
            ForEach(DemoScenario.allCases) { scenario in
                let isSelected = (state.activeScenario == scenario)
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        state.setScenario(scenario)
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: scenario.icon)
                            .font(.system(size: 10, weight: .bold))
                        Text(scenario.shortTitle)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected 
                            ? (scenario == .stormSurge ? Color.fwCrimsonPulse : (scenario == .sunnyKingTide ? Color.fwElectricAmber : Color.fwNeonTeal))
                            : Color.white.opacity(0.06)
                    )
                    .foregroundColor(isSelected ? .black : .white.opacity(0.75))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
        .padding(6)
        .liquidGlass(radius: 16)
    }
    
    // MARK: - Floating Glass Bottom Dock (Autopilot Style)
    private var floatingGlassDock: some View {
        HStack(spacing: 12) {
            dockTabItem(index: 0, title: "Overview", icon: "shield.lefthalf.filled")
            dockTabItem(index: 1, title: "Live Map", icon: "map.fill")
            dockTabItem(index: 2, title: "Places", icon: "mappin.and.ellipse")
            dockTabItem(index: 3, title: "Sources", icon: "slider.horizontal.3")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .liquidGlass(radius: 28, strokeColor: Color.white.opacity(0.3), glow: Color.fwNeonTeal.opacity(0.2))
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    private func dockTabItem(index: Int, title: String, icon: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = index
            }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline.bold())
                if selectedTab == index {
                    Text(title)
                        .font(.caption.bold())
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, selectedTab == index ? 16 : 12)
            .background(selectedTab == index ? Color.fwNeonTeal.opacity(0.25) : Color.clear)
            .foregroundColor(selectedTab == index ? .fwNeonTeal : .white.opacity(0.65))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selectedTab == index ? Color.fwNeonTeal.opacity(0.6) : Color.clear, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Top Navigation Bar
    private var topBar: some View {
        HStack(alignment: .center) {
            Menu {
                ForEach(state.savedPlaces) { place in
                    Button(action: {
                        state.selectPlace(place)
                    }) {
                        HStack {
                            Text(place.name)
                            if place.id == state.selectedPlace.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Divider()
                
                Button(action: {
                    showingAddPlace = true
                }) {
                    Label("Add / Switch Place...", systemImage: "plus.circle")
                }
                
                Button(action: {
                    state.requestCurrentLocation()
                }) {
                    Label("Use Current GPS", systemImage: "location.fill")
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: state.selectedPlace.isCurrentLocation ? "location.fill" : "mappin.circle.fill")
                        .foregroundColor(.fwNeonTeal)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(state.selectedPlace.name)
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Text(state.selectedPlace.subtitle)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .liquidGlass(radius: 20)
            }
            
            Spacer()
            
            // Re-onboard / Demo Reset
            Button(action: {
                withAnimation {
                    hasCompletedOnboarding = false
                }
            }) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundColor(.fwNeonTeal)
                    .frame(width: 40, height: 40)
                    .liquidGlass(radius: 20)
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Sensor Metric Micro-Gauges Row (No truncation, crystal clear)
    private var sensorChipsRow: some View {
        HStack(spacing: 10) {
            ForEach(state.currentAssessment.readings) { item in
                let isElevated = item.isElevated
                let accentColor: Color = isElevated ? (item.kind == .rain ? .cyan : .fwElectricAmber) : .fwNeonTeal
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: chipIcon(for: item.kind))
                            .font(.caption.bold())
                            .foregroundColor(accentColor)
                        Spacer()
                        Circle()
                            .fill(isElevated ? Color.fwElectricAmber : Color.fwEmeraldGlow)
                            .frame(width: 6, height: 6)
                    }
                    
                    Text(item.valueDisplay)
                        .font(.system(.subheadline, design: .rounded).weight(.black))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(item.subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(1)
                    
                    Text(shortAttribution(item.agencyAttribution))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .liquidGlass(
                    radius: 16,
                    strokeColor: isElevated ? accentColor.opacity(0.4) : Color.white.opacity(0.12)
                )
            }
        }
    }
    
    // MARK: - Official Warning Banner
    private func officialAlertBanner(headline: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.fwCrimsonPulse.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "exclamationmark.octagon.fill")
                    .foregroundColor(.fwCrimsonPulse)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("NWS OFFICIAL FLOOD WARNING")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.fwCrimsonPulse)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.bold())
                        .foregroundColor(.white.opacity(0.4))
                }
                Text(headline)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .liquidGlass(radius: 18, strokeColor: Color.fwCrimsonPulse.opacity(0.6), glow: Color.fwCrimsonPulse.opacity(0.2))
    }
    
    // MARK: - Community Reports Section
    private var communityReportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("COMMUNITY STREET SENSORS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Neighbor Road Hazards")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                Spacer()
                
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    showingReportFlooding = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Report")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.fwNeonTeal)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                    .shadow(color: Color.fwNeonTeal.opacity(0.3), radius: 6)
                }
            }
            
            if state.reports.isEmpty {
                Text("No recent community reports near \(state.selectedPlace.name). All clear!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .liquidGlass(radius: 16)
            } else {
                VStack(spacing: 10) {
                    ForEach(state.reports.prefix(4)) { report in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(depthColor(for: report.depthCategory).opacity(0.25))
                                    .frame(width: 42, height: 42)
                                Image(systemName: report.depthCategory.icon)
                                    .font(.headline)
                                    .foregroundColor(depthColor(for: report.depthCategory))
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(report.streetName)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(report.timeAgoString)
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                Text(report.depthCategory.rawValue)
                                    .font(.caption.bold())
                                    .foregroundColor(depthColor(for: report.depthCategory))
                                
                                if let note = report.note, !note.isEmpty {
                                    Text(note)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.75))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(12)
                        .liquidGlass(radius: 16)
                    }
                }
            }
        }
    }
    
    // MARK: - Trust & Legal Footer
    private var trustFooter: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.fwNeonTeal)
                    .font(.caption)
                Text("Real-Time Government Sensors")
                    .font(.caption2.bold())
                    .foregroundColor(.white.opacity(0.8))
            }
            Text("Synthesizes NOAA CO-OPS, NWS Weather.gov, and USGS Stream Water.")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            Text("Built for Hampton Roads 757 & flood-vulnerable coastal rivers.")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helpers
    private func chipIcon(for kind: SensorKind) -> String {
        switch kind {
        case .rain: return "cloud.heavyrain.fill"
        case .tide: return "water.waves"
        case .river: return "mountain.2.fill"
        }
    }
    
    private func shortAttribution(_ raw: String) -> String {
        if raw.contains("NOAA") { return "NOAA CO-OPS" }
        if raw.contains("NWS") { return "NWS Doppler" }
        if raw.contains("USGS") { return "USGS Water" }
        return raw
    }
    
    private func depthColor(for category: FloodReport.DepthCategory) -> Color {
        switch category {
        case .puddle: return .cyan
        case .hubcap: return .fwElectricAmber
        case .impassable: return .fwCrimsonPulse
        }
    }
}
