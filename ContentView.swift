import SwiftUI
import Charts
import Combine

// MARK: - 1. DESIGN SYSTEM & THEME
// "iOS 26" Aesthetic: Deep blurs, mesh gradients, and floating glass.

struct AppTheme {
    static let primary = Color(hex: "5BFDFF") // Cyan-ish
    static let secondary = Color(hex: "A65BFF") // Purple
    static let accent = Color(hex: "FF5B89") // Pink/Red for stim
    static let background = Color(hex: "050510") // Deep space blue/black
    
    static let gradientColors: [Color] = [
        Color(hex: "0F1C3F"),
        Color(hex: "29103A"),
        Color(hex: "0F1C3F")
    ]
}

// Extension for Hex Colors
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - 2. REUSABLE UI COMPONENTS

// The "iOS 26" Glass Card
struct GlassCard<Content: View>: View {
    var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .opacity(0.9)
            
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            content
                .padding()
        }
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
    }
}

// Animated Background Mesh
struct AnimatedMeshBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.3))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: animate ? -100 : 100, y: animate ? -100 : 100)
                    
                    Circle()
                        .fill(AppTheme.secondary.opacity(0.3))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: animate ? 100 : -100, y: animate ? 100 : -50)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
        .ignoresSafeArea()
    }
}

// Custom Toggle Style
struct NeuroToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? AppTheme.primary : Color.white.opacity(0.1))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(.white)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                )
                .onTapGesture {
                    withAnimation(.spring()) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

// MARK: - 3. DATA MODELS & LOGIC (The "Brain")

enum BrainState: String {
    case focused = "Deep Focus"
    case flow = "Flow State"
    case distracted = "Distracted"
    case artifact = "Signal Noise"
}

struct BrainDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let alpha: Double
    let theta: Double
    let focusScore: Double
}

class NeuroEngine: ObservableObject {
    // Hardware Simulation
    @Published var isConnected = false
    @Published var batteryLevel = 0.85
    @Published var signalQuality = 100 // %
    
    // DSP & Real-time Data
    @Published var currentFocusScore: Double = 0.0
    @Published var currentState: BrainState = .distracted
    @Published var liveData: [BrainDataPoint] = []
    @Published var isStimulating: Bool = false
    
    // Session Management
    @Published var sessionDuration: TimeInterval = 0
    private var timer: AnyCancellable?
    private var dataTimer: AnyCancellable?
    
    init() {
        // Start background data simulation if connected
    }
    
    func connectDevice() {
        // Simulating BLE Handshake
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { self.isConnected = true }
            self.startStreaming()
        }
    }
    
    func disconnectDevice() {
        withAnimation { self.isConnected = false }
        stopStreaming()
    }
    
    func startSession() {
        sessionDuration = 0
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { _ in self.sessionDuration += 1 }
    }
    
    func stopSession() {
        timer?.cancel()
    }
    
    private func startStreaming() {
        dataTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
            .sink { _ in self.generatePacket() }
    }
    
    private func stopStreaming() {
        dataTimer?.cancel()
    }
    
    // THE CORE DSP LOGIC (Simulated)
    private func generatePacket() {
        // Simulate EEG variability
        let rawAlpha = Double.random(in: 0.3...0.8)
        let rawTheta = Double.random(in: 0.2...0.6)
        
        // Calculate Ratio (Simple Mock)
        let ratio = rawAlpha / (rawTheta + 0.1)
        let normalizedScore = min(max(ratio * 100, 0), 100)
        
        // Smoothing
        let smoothedScore = (currentFocusScore * 0.9) + (normalizedScore * 0.1)
        self.currentFocusScore = smoothedScore
        
        // State Machine
        if smoothedScore > 80 { currentState = .flow }
        else if smoothedScore > 50 { currentState = .focused }
        else { currentState = .distracted }
        
        // Closed Loop Logic: Stimulate if distracted for too long
        if currentState == .distracted && !isStimulating {
            isStimulating = true // Trigger TES/Light
        } else if currentState == .flow {
            isStimulating = false
        }
        
        // Store Data
        let point = BrainDataPoint(timestamp: Date(), alpha: rawAlpha, theta: rawTheta, focusScore: smoothedScore)
        liveData.append(point)
        if liveData.count > 50 { liveData.removeFirst() } // Keep buffer small for UI
    }
}

// MARK: - 4. VIEWS

struct SmartbrainApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject var engine = NeuroEngine()
    @State private var selectedTab = 0
    
    init() {
        // Custom Tab Bar Appearance
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundStyle(AppTheme.primary)
                    Text("SMARTBRAIN")
                        .font(.system(.headline, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(.white)
                    Spacer()
                    DeviceStatusBadge(engine: engine)
                }
                .padding(.horizontal)
                .padding(.top, 50)
                
                // Content View Swticher
                ZStack {
                    if selectedTab == 0 { DashboardView(engine: engine) }
                    if selectedTab == 1 { SessionView(engine: engine) }
                    if selectedTab == 2 { HistoryView() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom Floating Tab Bar
                GlassCard {
                    HStack(spacing: 0) {
                        TabButton(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) { selectedTab = 0 }
                        TabButton(icon: "waveform.path.ecg", title: "Session", isSelected: selectedTab == 1) { selectedTab = 1 }
                        TabButton(icon: "chart.bar.fill", title: "History", isSelected: selectedTab == 2) { selectedTab = 2 }
                    }
                    .padding(.vertical, 8)
                }
                .frame(height: 80)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - SUBVIEWS

struct DashboardView: View {
    @ObservedObject var engine: NeuroEngine
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Ready to Sync?")
                                    .font(.title2)
                                    .bold()
                                    .foregroundStyle(.white)
                                Text("Last session: 4 hours ago")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            if !engine.isConnected {
                                Button(action: { engine.connectDevice() }) {
                                    Text("CONNECT")
                                        .font(.caption)
                                        .bold()
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.primary)
                                        .foregroundStyle(.black)
                                        .cornerRadius(20)
                                }
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primary)
                                    .font(.title)
                            }
                        }
                        
                        Divider().background(.white.opacity(0.2))
                        
                        HStack {
                            MetricCompact(label: "Recovery", value: "82%", icon: "battery.100")
                            Spacer()
                            MetricCompact(label: "Focus Avg", value: "7.4", icon: "bolt.fill")
                            Spacer()
                            MetricCompact(label: "Streak", value: "12 Days", icon: "flame.fill")
                        }
                    }
                }
                
                // Protocol Selector
                Text("Select Protocol")
                    .font(.headline)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ProtocolCard(title: "Deep Work", desc: "Alpha suppression", color: AppTheme.primary)
                        ProtocolCard(title: "Calm", desc: "Theta enhancement", color: AppTheme.secondary)
                        ProtocolCard(title: "Focus", desc: "Beta boost", color: AppTheme.accent)
                    }
                    .padding(.horizontal)
                }
                
                // Recent Insight
                GlassCard {
                    HStack(spacing: 15) {
                        ZStack {
                            Circle().fill(AppTheme.secondary.opacity(0.2)).frame(width: 50, height: 50)
                            Image(systemName: "lightbulb.fill").foregroundStyle(AppTheme.secondary)
                        }
                        VStack(alignment: .leading) {
                            Text("Insight")
                                .font(.caption)
                                .bold()
                                .foregroundStyle(AppTheme.secondary)
                            Text("Your focus peaks at 10:00 AM.")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                }
            }
            .padding(.top)
        }
    }
}

struct SessionView: View {
    @ObservedObject var engine: NeuroEngine
    @State private var isSessionActive = false
    
    var body: some View {
        VStack {
            if isSessionActive {
                // LIVE SESSION UI
                VStack(spacing: 30) {
                    // Top Bar
                    HStack {
                        VStack(alignment: .leading) {
                            Text("LIVE SESSION")
                                .font(.caption)
                                .tracking(2)
                                .foregroundStyle(.gray)
                            Text(timeString(time: engine.sessionDuration))
                                .font(.system(size: 40, weight: .light, design: .monospaced))
                        }
                        Spacer()
                        Button(action: {
                            withAnimation {
                                isSessionActive = false
                                engine.stopSession()
                            }
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding()
                    
                    // Main Visualization (The Brain Ring)
                    ZStack {
                        // Background tracks
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 20)
                            .frame(width: 250, height: 250)
                        
                        // Active Progress
                        Circle()
                            .trim(from: 0, to: engine.currentFocusScore / 100)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [AppTheme.secondary, AppTheme.primary]),
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 250, height: 250)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.5), value: engine.currentFocusScore)
                        
                        // Center Info
                        VStack {
                            Text(String(format: "%.0f", engine.currentFocusScore))
                                .font(.system(size: 60, weight: .bold))
                            Text("FOCUS")
                                .font(.caption)
                                .tracking(4)
                            
                            // Stimulation Indicator
                            if engine.isStimulating {
                                Text("⚡ STIM ACTIVE")
                                    .font(.caption2)
                                    .bold()
                                    .padding(6)
                                    .background(AppTheme.accent.opacity(0.8))
                                    .cornerRadius(8)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    
                    // Real-time Chart
                    GlassCard {
                        VStack(alignment: .leading) {
                            Text("EEG BANDPOWER (ALPHA/THETA)")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                            
                            Chart {
                                ForEach(Array(engine.liveData.enumerated()), id: \.offset) { index, point in
                                    LineMark(
                                        x: .value("Time", index),
                                        y: .value("Focus", point.focusScore)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(
                                        LinearGradient(colors: [AppTheme.secondary, AppTheme.primary], startPoint: .bottom, endPoint: .top)
                                    )
                                    
                                    AreaMark(
                                        x: .value("Time", index),
                                        y: .value("Focus", point.focusScore)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(
                                        LinearGradient(colors: [AppTheme.secondary.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)
                                    )
                                }
                            }
                            .chartYAxis(.hidden)
                            .chartXAxis(.hidden)
                            .frame(height: 100)
                        }
                    }
                    
                    // State Badge
                    Text(engine.currentState.rawValue.uppercased())
                        .font(.headline)
                        .tracking(2)
                        .foregroundStyle(stateColor(for: engine.currentState))
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                }
            } else {
                // PRE-SESSION START
                VStack(spacing: 20) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.1))
                            .frame(width: 200, height: 200)
                            .blur(radius: 20)
                        
                        Button(action: {
                            if engine.isConnected {
                                withAnimation {
                                    isSessionActive = true
                                    engine.startSession()
                                }
                            }
                        }) {
                            Text("START")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                                .frame(width: 140, height: 140)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: AppTheme.primary.opacity(0.5), radius: 20, x: 0, y: 0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.primary, lineWidth: 2)
                                        .scaleEffect(engine.isConnected ? 1.1 : 1.0)
                                        .opacity(engine.isConnected ? 0.5 : 0)
                                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: engine.isConnected)
                                )
                        }
                        .disabled(!engine.isConnected)
                    }
                    
                    if !engine.isConnected {
                        Text("Connect Headset First")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else {
                        Text("Ready for Protocol 01")
                            .font(.caption)
                            .foregroundStyle(AppTheme.primary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
    }
    
    func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func stateColor(for state: BrainState) -> Color {
        switch state {
        case .focused, .flow: return AppTheme.primary
        case .distracted: return .yellow
        case .artifact: return .red
        }
    }
}

struct HistoryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Recent Sessions")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
                
                ForEach(0..<5) { item in
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Deep Work Protocol")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("Tue, Nov 24 • 25 min")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("84")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(AppTheme.primary)
                                Text("Score")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.top)
        }
    }
}

// MARK: - HELPER COMPONENTS

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? AppTheme.primary : .gray)
                
                if isSelected {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct DeviceStatusBadge: View {
    @ObservedObject var engine: NeuroEngine
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(engine.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(engine.isConnected ? "CONNECTED" : "OFFLINE")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(engine.isConnected ? .white : .gray)
            if engine.isConnected {
                Image(systemName: "battery.75")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}

struct MetricCompact: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(AppTheme.primary)
            Text(value)
                .font(.headline)
                .bold()
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }
}

struct ProtocolCard: View {
    let title: String
    let desc: String
    let color: Color
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(title)
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .frame(width: 120, height: 100)
        }
    }
}

#Preview {
    ContentView()
}