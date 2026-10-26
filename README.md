# FloodWise

**Cross-domain situational flood radar and commuter safety engine for iOS.**

FloodWise synthesizes real-time government sensory data—NOAA tidal water levels, National Weather Service (NWS) Doppler precipitation, and USGS stream gauges—into an instantaneous situational risk score, actionable "leave-by" evacuation windows, vehicle clearance calculators, and live street hazard reports.

Built with a focus on coastal tidal basins (such as Hampton Roads, VA / 757, South Florida, and the Gulf Coast) as well as inland river flash flood zones.

---

## Key Features

- **Instant Situational Radar (The 2-Second Answer)**:
  - Dynamic fluid wave status gauge with real-time risk level scoring (0–100).
  - Clear plain-English hazard summary and predictive "leave-by" travel windows.
  - Interactive scenario mode selector allowing instant evaluation of live data, sunny day astronomical King Tides, and severe coastal surge emergencies.

- **Vehicle Clearance Safety Studio ("Can My Car Make It?")**:
  - Calibrated against vehicle profiles: Compact Sedans (5.5" clearance), Electric Vehicles (6.8" battery seal threshold), SUVs / Crossovers (8.5"), and High-Clearance 4x4 Trucks (11.5").
  - Instant clearance delta comparison against current flood depth to prevent engine hydrolock, saltwater battery submersion, and hydroplaning hazards.

- **Interactive 24-Hour Flood & Surge Forecast**:
  - Scrubbable timeline tracking projected water surge height, peak high tide crests, and rain accumulation curves.

- **Live Flood Radar Map (MapKit)**:
  - 3D pitch and flyover satellite hybrid toggles.
  - Real-time animated radar sweep beacon and concentric range rings.
  - Active street hazard markers with depth indicators (Ankle, Hubcap, Impassable).
  - Layer filters for Doppler radar, coastal surge departures, and USGS river stages.

- **Live Intersection Flood Cams & Community Hazard Reporting**:
  - Simulated optical street water-level gauges at notorious flood intersections.
  - 2-tap anonymous community hazard reporting with 4-hour automatic expiration.

---

## Architecture & Data Sources

FloodWise connects directly to federal environmental observation networks:
- **NOAA CO-OPS**: Water level observations, tidal predictions, and meteorological departures.
- **NWS Weather.gov**: Active flash flood watches, warnings, and hourly precipitation Doppler rates.
- **USGS Water Services**: Instantaneous streamflow and gauge height metrics.

### Technology Stack
- **SwiftUI & Swift 6**: Built for iOS 17+ / iOS 18+.
- **MapKit**: Dynamic camera positioning, annotations, and realistic 3D elevation.
- **Combine**: Reactive state management and timer subscriptions.
- **CoreLocation**: On-device coordinate positioning and local monitoring regions.

---

## Getting Started

### Prerequisites
- macOS 14.0 or later
- Xcode 16.0 or later
- iOS 17.0+ Simulator or physical device

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/nx1reps/floodwise.git
   cd floodwise
   ```

2. Open the Xcode project:
   ```bash
   open Floodwise.xcodeproj
   ```

3. Select your destination (e.g. `iPhone 16` or `iPhone 17`) and press **Cmd + R** to run.
