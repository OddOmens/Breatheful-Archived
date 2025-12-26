import SwiftUI
import UIKit
import AVFoundation

// MARK: - Animation Settings and Models
struct BreathingMode: Identifiable {
    let id: Int
    let name: String
    let description: String
    let iconName: String
    let inhaleTime: Double
    let inhaleHoldTime: Double
    let exhaleTime: Double
    let exhaleHoldTime: Double
    
    // Total duration for display purposes
    var totalDuration: Double {
        inhaleTime + inhaleHoldTime + exhaleTime + exhaleHoldTime
    }
}

enum VoiceGuidanceType: String {
    case none = "No Guidance"
    case breathingCues = "Breathing Cues"
    case story = "Relaxation Story"
}

struct VoiceStory: Identifiable {
    let id: String
    let title: String
    let narrator: String
    let duration: TimeInterval
    let filename: String
    let description: String
}

enum VoiceOption: String, CaseIterable, Identifiable {
    // Breathing cue voices
    case none = "No Guide"
    case kai = "Kai"
    case zen = "Zen"
    case luma = "Luma"
    case amara = "Amara"
    
    // Timed guided sessions
    case lumaOneMin = "Luma One Minute"
    case lumaTwoMin = "Luma Two Minutes"
    case lumaFiveMin = "Luma Five Minutes"
    case kaiOneMin = "Kai One Minute"
    case kaiTwoMin = "Kai Two Minutes"
    case kaiFiveMin = "Kai Five Minutes"
    
    var id: String { self.rawValue }
    
    var guidanceType: VoiceGuidanceType {
        switch self {
        case .none:
            return .none
        case .kai, .zen, .luma, .amara:
            return .breathingCues
        case .lumaOneMin, .lumaTwoMin, .lumaFiveMin, .kaiOneMin, .kaiTwoMin, .kaiFiveMin:
            return .story
        }
    }
    
    // Stories don't appear in the standard picker
    static var breathingCuesOptions: [VoiceOption] {
        return [.none, .kai, .zen, .luma, .amara]
    }
    
    static var storyOptions: [VoiceOption] {
        return [.lumaOneMin, .lumaTwoMin, .lumaFiveMin, .kaiOneMin, .kaiTwoMin, .kaiFiveMin]
    }
}

class AudioCueManager {
    static let shared = AudioCueManager()
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var storyPlayers: [String: AVAudioPlayer] = [:]
    private let voiceVolume: Float = 1.0 // Maximum volume for voice
    
    // Callback for when a story completes
    var onStoryComplete: (() -> Void)?
    
    // Store strong references to delegates to prevent deallocation
    private var storyPlayerDelegates: [String: StoryPlayerDelegate] = [:]
    
    private init() {
        preloadAudioFiles()
        preloadStoryFiles()
    }
    
    private func preloadAudioFiles() {
        let voices = ["Kai", "Zen", "Luma", "Amara"]
        let actions = ["BreatheIn", "Hold", "BreatheOut"]
        
        for voice in voices {
            for action in actions {
                let filename = "\(voice)_\(action)"
                if let url = Bundle.main.url(forResource: filename, withExtension: "mp3") {
                    do {
                        let player = try AVAudioPlayer(contentsOf: url)
                        player.prepareToPlay()
                        player.volume = voiceVolume // Set voice volume to maximum
                        audioPlayers[filename] = player
                    } catch {
                        print("Failed to preload audio cue \(filename): \(error)")
                    }
                } else {
                    print("Audio file \(filename).mp4 not found in bundle")
                }
            }
        }
    }
    
    private func preloadStoryFiles() {
        let stories = ["Luma_OneMinute", "Luma_TwoMinute", "Luma_FiveMinute", "Kai_OneMinute", "Kai_TwoMinute", "Kai_FiveMinute"]
        
        for story in stories {
            if let url = Bundle.main.url(forResource: story, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = voiceVolume
                    storyPlayers[story] = player
                } catch {
                    print("Failed to preload story \(story): \(error)")
                }
            } else {
                print("Story file \(story).mp3 not found in bundle")
            }
        }
    }
    
    func playBreathCue(_ phase: AnimationSettings.PhaseType, voiceOption: VoiceOption) {
        guard voiceOption != .none && voiceOption.guidanceType == .breathingCues else { return }
        
        let voice = voiceOption.rawValue
        let actionKey: String
        
        switch phase {
        case .inhale:
            actionKey = "BreatheIn"
        case .inhaleHold, .exhaleHold:
            actionKey = "Hold"
        case .exhale:
            actionKey = "BreatheOut"
        }
        
        let cueKey = "\(voice)_\(actionKey)"
        
        // Lower background music volume temporarily when voice cue is playing
        let originalMusicVolume = AudioManager.shared.currentVolume
        AudioManager.shared.setVolume(0.3) // Reduce background music volume
        
        if let player = audioPlayers[cueKey] {
            player.currentTime = 0
            player.play()
            
            // Restore original music volume after voice cue finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
                AudioManager.shared.setVolume(originalMusicVolume)
            }
        } else {
            // If player wasn't found, still restore volume after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                AudioManager.shared.setVolume(originalMusicVolume)
            }
        }
    }
    
    func playStory(for voiceOption: VoiceOption, completion: @escaping () -> Void) {
        guard voiceOption.guidanceType == .story else { return }
        
        // Get story filename based on voice option
        let storyFilename: String
        switch voiceOption {
        case .lumaOneMin:
            storyFilename = "Luma_OneMinute"
        case .lumaTwoMin:
            storyFilename = "Luma_TwoMinute"
        case .lumaFiveMin:
            storyFilename = "Luma_FiveMinute"
        case .kaiOneMin:
            storyFilename = "Kai_OneMinute"
        case .kaiTwoMin:
            storyFilename = "Kai_TwoMinute"
        case .kaiFiveMin:
            storyFilename = "Kai_FiveMinute"
        default:
            return
        }
        
        // Store completion handler
        self.onStoryComplete = completion
        
        // Lower background music
        let originalMusicVolume = AudioManager.shared.currentVolume
        AudioManager.shared.setVolume(0.2) // Lower than breathing cues
        
        if let player = storyPlayers[storyFilename] {
            player.currentTime = 0
            
            // Create and store a strong reference to delegate
            let delegate = StoryPlayerDelegate(completion: { [weak self] in
                AudioManager.shared.setVolume(originalMusicVolume)
                self?.onStoryComplete?()
                // Remove delegate reference when complete
                self?.storyPlayerDelegates[storyFilename] = nil
            })
            
            // Store strong reference to prevent deallocation
            storyPlayerDelegates[storyFilename] = delegate
            
            // Set delegate
            player.delegate = delegate
            
            player.play()
        } else {
            // If player wasn't found, call completion immediately
            AudioManager.shared.setVolume(originalMusicVolume)
            completion()
        }
    }
    
    func stopAllStories() {
        var wasPlaying = false
        
        for (filename, player) in storyPlayers {
            if player.isPlaying {
                player.stop()
                wasPlaying = true
                // Remove delegate reference when stopped
                storyPlayerDelegates[filename] = nil
            }
        }
        
        // If a story was playing, call the completion handler
        if wasPlaying && onStoryComplete != nil {
            onStoryComplete?()
        }
        
        // Clear delegate references
        storyPlayerDelegates.removeAll()
        
        // Restore music volume
        AudioManager.shared.setVolume(AudioManager.shared.currentVolume)
    }
}

// Helper class for AVAudioPlayer delegate callbacks
class StoryPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let completion: () -> Void
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
        super.init()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        completion()
    }
}

class AnimationSettings: ObservableObject {
    @Published var currentMode: BreathingMode
    @Published var currentPhase: PhaseType = .inhale
    @Published var scale: CGFloat = 0.5
    @Published var remainingTime: Double = 0
    @Published var isActive: Bool = false
    @Published var timer: Timer? = nil
    @Published var voiceOption: VoiceOption = .none
    @Published var isPlayingStory: Bool = false
    
    enum PhaseType {
        case inhale
        case inhaleHold
        case exhale
        case exhaleHold
        
        var text: String {
            switch self {
            case .inhale: return "Inhale".localized
            case .inhaleHold: return "Hold".localized
            case .exhale: return "Exhale".localized
            case .exhaleHold: return "Hold".localized
            }
        }
    }
    
    init() {
        // Initialize with the saved default breathing mode
        let defaultModeId = UserDefaults.standard.integer(forKey: "defaultBreathingMode")
        
        // Find the saved mode in the modes array
        if let savedMode = BreathingView.modes.first(where: { $0.id == defaultModeId }) {
            self.currentMode = savedMode
        } else {
            // Fallback to standard breathing mode if no saved mode is found
            self.currentMode = BreathingView.modes.first(where: { $0.id == 2 })!
        }
        
        // Load saved voice option preference
        if let savedVoiceOption = UserDefaults.standard.string(forKey: "voiceOption"),
           let option = VoiceOption(rawValue: savedVoiceOption) {
            // If a story option was saved, reset to none to prevent auto-play on app launch
            if option.guidanceType == .story {
                self.voiceOption = .none
                UserDefaults.standard.set(VoiceOption.none.rawValue, forKey: "voiceOption")
            } else {
                self.voiceOption = option
            }
        }
    }
    
    func startBreathingCycle() {
        isActive = true
        currentPhase = .inhale
        runPhase()
    }
    
    func stopBreathingCycle() {
        isActive = false
        timer?.invalidate()
        timer = nil
        scale = 0.5
        currentPhase = .inhale
        
        // Also stop any playing stories
        AudioCueManager.shared.stopAllStories()
        isPlayingStory = false
    }
    
    func playStory(option: VoiceOption) {
        guard option.guidanceType == .story && !isPlayingStory else { return }
        
        isPlayingStory = true
        self.voiceOption = option
        
        // Save the selected option temporarily
        UserDefaults.standard.set(option.rawValue, forKey: "voiceOption")
        
        // Play the story, and reset to "No Guide" when it completes
        AudioCueManager.shared.playStory(for: option) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isPlayingStory = false
                self.voiceOption = .none
                UserDefaults.standard.set(VoiceOption.none.rawValue, forKey: "voiceOption")
                print("Guided session complete - reset to No Guide")
            }
        }
    }
    
    private func runPhase() {
        guard isActive else { return }
        
        let duration: Double
        let nextPhase: PhaseType
        let targetScale: CGFloat
        
        switch currentPhase {
        case .inhale:
            duration = currentMode.inhaleTime
            nextPhase = currentMode.inhaleHoldTime > 0 ? .inhaleHold : .exhale
            targetScale = 0.8
            
        case .inhaleHold:
            duration = currentMode.inhaleHoldTime
            nextPhase = .exhale
            targetScale = 0.8
            
        case .exhale:
            duration = currentMode.exhaleTime
            nextPhase = currentMode.exhaleHoldTime > 0 ? .exhaleHold : .inhale
            targetScale = 0.5
            
        case .exhaleHold:
            duration = currentMode.exhaleHoldTime
            nextPhase = .inhale
            targetScale = 0.5
        }
        
        // Skip phases with zero duration
        if duration == 0 {
            currentPhase = nextPhase
            runPhase()
            return
        }
        
        // Play audio cue at the start of each phase (only for breathing cue voices)
        if voiceOption.guidanceType == .breathingCues {
            AudioCueManager.shared.playBreathCue(currentPhase, voiceOption: voiceOption)
        }
        
        remainingTime = duration
        
        withAnimation(.easeInOut(duration: duration)) {
            scale = targetScale
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.remainingTime -= 1
            if self.remainingTime <= 0 {
                timer.invalidate()
                self.currentPhase = nextPhase
                self.runPhase()
            }
        }
    }
}


// MARK: - Main Content View
struct ContentView: View {
    @AppStorage("launchCount") private var launchCount: Int = 0
    @StateObject var settings = AnimationSettings()
    @EnvironmentObject var circleOptionManager: CircleOptionManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var colorManager: ColorManager
    @StateObject var randomTextViewModel = RandomTextViewModel()
    @EnvironmentObject var userProfile: UserProfile
    @ObservedObject private var settingsViewModel = SettingsViewModel()
    @State private var wiggle = false
    @State private var rotationDegree = 0.0
    @State private var waveOffset = Angle(degrees: 0)
    @State private var verticalOffset: CGFloat = 0.0
    @State private var isBreathingViewPresented: Bool = false
    @State private var isAudioViewPresented: Bool = false
    @State private var isGuideViewPresented: Bool = false
    @State private var isProfileViewPresented: Bool = false
    @StateObject private var circleStyleManager = CircleStyleManager.shared
    @State private var rotationAngle: Double = 0
    @State private var isAnimating = false
    @State private var navigationOpacity: Double = 1.0
    @State private var dimTimer: Timer?
    
    // Panic attack mode state
    @State private var isPanicModePresented: Bool = false
    @State private var swipeOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    // Custom menu state
    @State private var showCustomMenu: Bool = false
    
    // Navigation state for menu items
    @State private var showAnalytics: Bool = false
    @State private var showCustomize: Bool = false
    @State private var showLanguage: Bool = false
    @State private var showHelp: Bool = false
    
    // Navigation state for bottom buttons
    @State private var showBreathing: Bool = false
    @State private var showAudio: Bool = false
    @State private var showVoice: Bool = false
    @State private var showGuide: Bool = false
    
    // Haptic feedback
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    // Constants
    let iconSize: CGFloat = 24
    let textSize: CGFloat = 10
    let swipeThreshold: CGFloat = 100
    
    // View Properties
    var isGuideEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "isGuideEnabled")
    }
    
    var isProfileEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "isProfileEnabled")
    }
    
    var areTextGuideEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "areTextGuideEnabled")
    }
    
    var arePhrasesEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "arePhrasesEnabled")
    }
    
    var computedForegroundColor: Color {
        let selectedColor = ColorManager.colorInfos[colorManager.selectedColorIndex].color
        if circleOptionManager.selectedOption == .filled ||
           circleOptionManager.selectedOption == .filledGlow ||
           circleOptionManager.selectedOption == .filledGradient {
            return selectedColor.contrastingColor
        } else {
            return themeManager.currentTheme == .dark ? .white : .black
        }
    }
    
    // Add state method to handle returning from panic mode
    func returnFromPanicMode() {
        withAnimation(.easeOut(duration: 0.3)) {
            self.swipeOffset = 0
            self.isPanicModePresented = false
        }
    }
    
    var body: some View {
        NavigationStack {
            // Main content instead of hidden navigation links
            ZStack {
                // Panic Mode View (behind main content)
                if isDragging || isPanicModePresented {
                    PanicAttackView(onReturn: returnFromPanicMode)
                        .environmentObject(themeManager)
                        .environmentObject(colorManager)
                        .environmentObject(circleOptionManager)
                        .transition(.identity)
                }
            
                // Main Content
                VStack {
                    Spacer()
                    
                    // Breathing Circle
                    ZStack {
                        BreathingCircleView(
                            design: circleStyleManager.currentDesign,
                            color: ColorManager.colorInfos[colorManager.selectedColorIndex].color,
                            scale: settings.scale,
                            size: 360
                        )
                        
                        // Phase and Timer Text
                        if areTextGuideEnabled {
                            VStack {
                                Text(settings.currentPhase.text)
                                    .font(.system(size: 24, weight: .bold))
                                    .padding(.bottom, 4)
                                    .foregroundColor(computedForegroundColor)
                                
                                Text(String(format: "%02d", Int(settings.remainingTime)))
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(computedForegroundColor)
                            }
                            .padding()
                        }
                    }
                    .onAppear {
                        self.settings.startBreathingCycle()
                        startDimTimer()
                        feedbackGenerator.prepare()
                    }
                    
                    if arePhrasesEnabled {
                        RandomTextView(viewModel: randomTextViewModel)
                    }
                    
                    // Panic button hint
                    Text("Swipe left during panic attacks".localized)
                        .font(.system(size: 12))
                        .foregroundColor(Color("AccentColor").opacity(0.5))
                        .padding(.vertical, 8)

                    
                    Spacer()
                    
                    // Bottom Navigation
                    HStack(spacing: 30) {
                        Button(action: {
                            showBreathing = true
                        }) {
                            navButtonContent(iconName: "cusWind", labelText: "Breathe".localized)
                        }
                        
                        Button(action: {
                            showAudio = true
                        }) {
                            navButtonContent(iconName: "cusAudio", labelText: "Audio".localized)
                        }
                        
                        Button(action: {
                            showVoice = true
                        }) {
                            navButtonContent(iconName: "speaker.wave.2", labelText: "Voice".localized)
                        }
                        
                        if isGuideEnabled {
                            Button(action: {
                                showGuide = true
                            }) {
                                navButtonContent(iconName: "cusArticle", labelText: "Guide".localized)
                            }
                        }
                        
                        // Replace Menu with button for custom menu
                        Button(action: {
                            // Show custom menu and ensure it stays visible
                            showCustomMenu = true
                            dimTimer?.invalidate()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                navigationOpacity = 1.0
                            }
                        }) {
                            VStack {
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: iconSize, height: iconSize)
                                    .foregroundColor(Color("AccentColor"))
                                Text("More".localized)
                                    .font(.system(size: textSize))
                                    .foregroundColor(Color("AccentColor"))
                            }
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 15)
                    .glassEffect()
                    
                    .opacity(navigationOpacity)
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                }
                .background(Color(UIColor.systemBackground))
                .offset(x: swipeOffset)
                .animation(.interpolatingSpring(stiffness: 300, damping: 30).speed(0.7), value: swipeOffset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            // Allow left swipe when not in panic mode, right swipe when in panic mode
                            if (!isPanicModePresented && gesture.translation.width < 0) ||
                               (isPanicModePresented && gesture.translation.width > 0) {
                                self.isDragging = true
                                // Apply direct offset with slight resistance
                                let baseOffset = isPanicModePresented ? -UIScreen.main.bounds.width : 0
                                let translation = gesture.translation.width * 0.8
                                withAnimation(.none) {
                                    self.swipeOffset = isPanicModePresented ?
                                        min(0, baseOffset + translation) :
                                        max(-UIScreen.main.bounds.width, translation)
                                }
                            }
                        }
                        .onEnded { gesture in
                            self.isDragging = false
                            
                            if isPanicModePresented {
                                // Return to main view if swiped right far enough
                                if gesture.translation.width > self.swipeThreshold {
                                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30).speed(0.7)) {
                                        self.swipeOffset = 0
                                        self.isPanicModePresented = false
                                    }
                                } else {
                                    // Return to panic view
                                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30).speed(0.7)) {
                                        self.swipeOffset = -UIScreen.main.bounds.width
                                    }
                                }
                            } else {
                                // Enter panic mode if swiped left far enough
                                if gesture.translation.width < -self.swipeThreshold {
                                    feedbackGenerator.notificationOccurred(.warning)
                                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30).speed(0.7)) {
                                        self.swipeOffset = -UIScreen.main.bounds.width
                                        self.isPanicModePresented = true
                                    }
                                } else {
                                    // Return to main view
                                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30).speed(0.7)) {
                                        self.swipeOffset = 0
                                    }
                                }
                            }
                        }
                )
                
                // Custom Menu Overlay (on top of everything)
                CustomMenuView(
                    isShowing: $showCustomMenu,
                    onAnalyticsTapped: {
                        showCustomMenu = false
                        showAnalytics = true
                    },
                    onCustomizeTapped: {
                        showCustomMenu = false
                        showCustomize = true
                    },
                    onLanguageTapped: {
                        showCustomMenu = false
                        showLanguage = true
                    },
                    onHelpTapped: {
                        showCustomMenu = false
                        showHelp = true
                    }
                )
                .zIndex(100) // Ensure it's on top
            }
            // Add navigation destinations using the new API
            .navigationDestination(isPresented: $showAnalytics) {
                ProfileView()
                    .environmentObject(userProfile)
                    .environmentObject(themeManager)
                    .environmentObject(colorManager)
            }
            .navigationDestination(isPresented: $showCustomize) {
                CustomizeView()
                    .environmentObject(themeManager)
                    .environmentObject(colorManager)
                    .environmentObject(circleOptionManager)
                    .environmentObject(userProfile)
            }
            .navigationDestination(isPresented: $showLanguage) {
                LanguageSelectionView()
                    .environmentObject(themeManager)
                    .environmentObject(colorManager)
            }
            .navigationDestination(isPresented: $showHelp) {
                HelpView()
                    .environmentObject(themeManager)
                    .environmentObject(colorManager)
            }
            // Navigation destinations for bottom buttons
            .navigationDestination(isPresented: $showBreathing) {
                BreathingView(settings: settings)
            }
            .navigationDestination(isPresented: $showAudio) {
                AudioView()
            }
            .navigationDestination(isPresented: $showVoice) {
                VoiceView(settings: settings)
            }
            .navigationDestination(isPresented: $showGuide) {
                GuideView()
            }
            .onTapGesture {
                // Only handle tap if custom menu isn't showing
                if !showCustomMenu {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        navigationOpacity = 1.0
                    }
                    dimTimer?.invalidate()
                    startDimTimer()
                }
            }
            .onAppear {
                userProfile.startTracking()
                startDimTimer()
                feedbackGenerator.prepare()
                
                // Play the saved audio track
                let savedTrackId = UserDefaults.standard.integer(forKey: "selectedTrackId")
                if savedTrackId != 0, // 0 means no track saved
                   let savedTrack = AudioView().tracks.first(where: { $0.id == savedTrackId }) {
                    AudioManager.shared.playAudio(fileName: savedTrack.fileName, fileType: savedTrack.fileType)
                }
            }
            .onDisappear {
                userProfile.stopTracking()
                dimTimer?.invalidate()
            }
        }
    }
    
    // MARK: - Subviews
    var breathingCircleView: some View {
        Group {
            switch circleOptionManager.selectedOption {
            case .none:
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 0, dash: [00, 0]))
                    .foregroundColor(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                    .scaleEffect(settings.scale)
                
            case .stroked:
                Circle()
                    .stroke(lineWidth: 20)
                    .foregroundColor(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                    .scaleEffect(settings.scale)
                
            // Add all your other circle style cases here...
            // The pattern continues with the same structure but using settings.scale
            
            default:
                Circle()
                    .stroke(lineWidth: 2)
                    .foregroundColor(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                    .scaleEffect(settings.scale)
            }
        }
    }

    // MARK: - Helper Methods
    func navButtonContent(iconName: String, labelText: String) -> some View {
        VStack {
            if iconName.hasPrefix("speaker") {
                Image(systemName: iconName)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(Color("AccentColor"))
            } else {
                Image(iconName)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(Color("AccentColor"))
            }
            Text(labelText)
                .font(.system(size: textSize))
                .foregroundColor(Color("AccentColor"))
        }
    }
    
    private func startDimTimer() {
        // Only start dim timer if menu is not open
        guard !showCustomMenu else { return }
        
        dimTimer?.invalidate()
        dimTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                navigationOpacity = 0.0
            }
        }
    }
}

// MARK: - Supporting Types


extension Color {
    var contrastingColor: Color {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 0]
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return brightness > 0.5 ? .black : .white
    }
}

struct BreathingShape: Shape {
    var progress: CGFloat // 0 for square, 1 for circle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let sides = 4 // number of sides for square
        let angleIncrement = 2 * .pi / CGFloat(sides)
        
        for i in 0..<sides {
            let angle = CGFloat(i) * angleIncrement
            let squarePoint = CGPoint(
                x: center.x + (radius * cos(angle)),
                y: center.y + (radius * sin(angle))
            )
            let circlePoint = CGPoint(
                x: center.x + (radius * cos(angle + angleIncrement / 2)),
                y: center.y + (radius * sin(angle + angleIncrement / 2))
            )
            let x = mix(a: squarePoint.x, b: circlePoint.x, t: progress)
            let y = mix(a: squarePoint.y, b: circlePoint.y, t: progress)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        
        return path
    }
    
    private func mix(a: CGFloat, b: CGFloat, t: CGFloat) -> CGFloat {
        return a * (1 - t) + b * t
    }
}

class BreathingSettings: ObservableObject {
    static let shared = BreathingSettings()  // Singleton instance
    @Published var selectedModeId: Int {
        didSet {
            UserDefaults.standard.set(selectedModeId, forKey: "defaultBreathingMode")
        }
    }
    
    private init() {
        // Load saved mode ID or default to Standard (2) if none exists
        self.selectedModeId = UserDefaults.standard.integer(forKey: "defaultBreathingMode")
        if self.selectedModeId == 0 { // UserDefaults returns 0 if key doesn't exist
            self.selectedModeId = 2 // Set to Standard mode as fallback
        }
    }
}

struct BreathingView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var colorManager: ColorManager
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var settings: AnimationSettings
    @ObservedObject var breathingSettings = BreathingSettings.shared
    
    static let modes: [BreathingMode] = [
        // EXISTING MODES:
        // Quick (2-0-2-0)
        BreathingMode(
            id: 0,
            name: "mode_quick_name".localized,
            description: "mode_quick_description".localized,
            iconName: "bolt",
            inhaleTime: 2.0,
            inhaleHoldTime: 0.0,
            exhaleTime: 2.0,
            exhaleHoldTime: 0.0
        ),
        
        // Shallow (3-0-3-0)
        BreathingMode(
            id: 1,
            name: "mode_shallow_name".localized,
            description: "mode_shallow_description".localized,
            iconName: "cusWind",
            inhaleTime: 3.0,
            inhaleHoldTime: 0.0,
            exhaleTime: 3.0,
            exhaleHoldTime: 0.0
        ),
        
        // Standard (4-0-4-0)
        BreathingMode(
            id: 2,
            name: "mode_standard_name".localized,
            description: "mode_standard_description".localized,
            iconName: "cusWind",
            inhaleTime: 4.0,
            inhaleHoldTime: 0.0,
            exhaleTime: 4.0,
            exhaleHoldTime: 0.0
        ),
        
        // Calm (4-4-4-4)
        BreathingMode(
            id: 3,
            name: "mode_calm_name".localized,
            description: "mode_calm_description".localized,
            iconName: "cusLeaf",
            inhaleTime: 4.0,
            inhaleHoldTime: 4.0,
            exhaleTime: 4.0,
            exhaleHoldTime: 4.0
        ),
        
        // Sleep (4-7-8-0)
        BreathingMode(
            id: 4,
            name: "mode_sleep_name".localized,
            description: "mode_sleep_description".localized,
            iconName: "cusNight",
            inhaleTime: 4.0,
            inhaleHoldTime: 7.0,
            exhaleTime: 8.0,
            exhaleHoldTime: 0.0
        ),
        
        // Focus (5-0-5-0)
        BreathingMode(
            id: 5,
            name: "mode_focus_name".localized,
            description: "mode_focus_description".localized,
            iconName: "cusWind",
            inhaleTime: 5.0,
            inhaleHoldTime: 0.0,
            exhaleTime: 5.0,
            exhaleHoldTime: 0.0
        ),
        
        // Deep Zen (8-4-8-4)
        BreathingMode(
            id: 6,
            name: "mode_deep_name".localized,
            description: "mode_deep_description".localized,
            iconName: "cusLeaf",
            inhaleTime: 8.0,
            inhaleHoldTime: 4.0,
            exhaleTime: 8.0,
            exhaleHoldTime: 4.0
        ),
        
        // Monk (5-5-5-5)
        BreathingMode(
            id: 7,
            name: "mode_monk_name".localized,
            description: "mode_monk_description".localized,
            iconName: "cusPeaceful",
            inhaleTime: 10.0,
            inhaleHoldTime: 5.0,
            exhaleTime: 8.0,
            exhaleHoldTime: 5.0
        ),
        
        // NEW MODES TO ADD:
        // Alternate Nostril (2-5-2-5)
        BreathingMode(
            id: 8,
            name: "mode_nostril_name".localized,
            description: "mode_nostril_description".localized,
            iconName: "cusWind",
            inhaleTime: 2.0,
            inhaleHoldTime: 5.0,
            exhaleTime: 2.0,
            exhaleHoldTime: 5.0
        ),
        
        // Calming (7-0-11-0)
        BreathingMode(
            id: 9,
            name: "mode_calming_name".localized,
            description: "mode_calming_description".localized,
            iconName: "cusWater",
            inhaleTime: 7.0,
            inhaleHoldTime: 0.0,
            exhaleTime: 11.0,
            exhaleHoldTime: 0.0
        ),
        
        // Box Breathing (4-4-4-4)
        BreathingMode(
            id: 10,
            name: "mode_box_name".localized,
            description: "mode_box_description".localized,
            iconName: "cusWind",
            inhaleTime: 4.0,
            inhaleHoldTime: 4.0,
            exhaleTime: 4.0,
            exhaleHoldTime: 4.0
        ),
        
        // Relaxing (4-7-8)
        BreathingMode(
            id: 11,
            name: "mode_relaxing_name".localized,
            description: "mode_relaxing_description".localized,
            iconName: "cusNight",
            inhaleTime: 4.0,
            inhaleHoldTime: 7.0,
            exhaleTime: 8.0,
            exhaleHoldTime: 0.0
        ),
        
        // Energizing (3-0-2-0)
        BreathingMode(
            id: 12,
            name: "mode_energizing_name".localized,
            description: "mode_energizing_description".localized,
            iconName: "bolt",
            inhaleTime: 3.0,
            inhaleHoldTime: 0.0,
            exhaleTime: 2.0,
            exhaleHoldTime: 0.0
        ),
        
        // Ocean Breath (5-2-5-2)
        BreathingMode(
            id: 13,
            name: "mode_ocean_name".localized,
            description: "mode_ocean_description".localized,
            iconName: "cusWater",
            inhaleTime: 5.0,
            inhaleHoldTime: 2.0,
            exhaleTime: 5.0,
            exhaleHoldTime: 2.0
        )
    ]
    
    let modes = BreathingView.modes  // Reference to static modes
    
    var body: some View {
        VStack {
            List(modes) { mode in
                ModeRow(mode: mode, isSelected: mode.id == settings.currentMode.id)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .onTapGesture {
                        self.settings.currentMode = mode
                        self.breathingSettings.selectedModeId = mode.id
                        UserDefaults.standard.set(mode.id, forKey: "defaultBreathingMode")
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    .listRowSeparator(.hidden)
                    .padding(.bottom,10)
            }
            .listStyle(PlainListStyle())
            .onAppear {
                userProfile.stopTracking()
            }
            .onDisappear {
                userProfile.startTracking()
            }
            .navigationBarTitle("Breathing Modes".localized, displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image("arrow-left")
                        .renderingMode(.template)
                        .foregroundColor(Color("AccentColor"))
                }
            )
        }.navigationBarBackButtonHidden(true)
    }
}

struct ModeRow: View {
    let mode: BreathingMode
    let isSelected: Bool
    
    @EnvironmentObject var colorManager: ColorManager
    
    var breathingPattern: String {
        var pattern = "\(Int(mode.inhaleTime))s in"
        if mode.inhaleHoldTime > 0 {
            pattern += " • \(Int(mode.inhaleHoldTime))s hold"
        }
        pattern += " • \(Int(mode.exhaleTime))s out"
        if mode.exhaleHoldTime > 0 {
            pattern += " • \(Int(mode.exhaleHoldTime))s hold"
        }
        return pattern
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(mode.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("AccentColor"))
                
                Text(mode.description)
                    .font(.system(size: 14))
                    .foregroundColor(Color("AccentColor"))
                    .lineLimit(2)
                
                Text(breathingPattern)
                    .font(.system(size: 12))
                    .foregroundColor(Color("AccentColor").opacity(0.8))
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            
            Spacer()
            
            Image(mode.iconName)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color("AccentColor"))
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(.trailing)
        }
        .background(Color("AccentColor").opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? ColorManager.colorInfos[colorManager.selectedColorIndex].color : Color.clear, lineWidth: 2)
        )
    }
}

class AudioSettings: ObservableObject {
    static let shared = AudioSettings()  // Singleton instance
    @Published var selectedTrackId: Int?
    
    private init() {}
}

class AudioManager: ObservableObject {
    static let shared = AudioManager()  // Singleton instance
    private var audioPlayer: AVAudioPlayer?
    private var currentTrackName: String?
    @Published var currentVolume: Float = 0.7 // Default volume
    
    private init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    func playAudio(fileName: String, fileType: String) {
        // If the same track is already playing, don't restart it
        if fileName == currentTrackName && audioPlayer?.isPlaying == true {
            return
        }
        
        if fileName.isEmpty {
            stopAudio()
            return
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileType) else {
            print("Audio file not found.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.numberOfLoops = -1  // Set to -1 for infinite loop
            audioPlayer?.volume = currentVolume
            audioPlayer?.play()
            currentTrackName = fileName
        } catch {
            print("Audio playback failed: \(error.localizedDescription)")
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        currentTrackName = nil
    }
    
    func setVolume(_ volume: Float) {
        let clampedVolume = max(0, min(1, volume))
        audioPlayer?.volume = clampedVolume
        
        // Only update the stored volume if this is not a temporary adjustment
        if volume > 0.3 {
            currentVolume = clampedVolume
        }
    }
}


struct AudioTrack: Identifiable {
    let id: Int
    let name: String
    let description: String
    let iconName: String
    let fileName: String
    let fileType: String
}

struct AudioView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var colorManager: ColorManager
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var audioSettings = AudioSettings.shared
    
    let tracks: [AudioTrack] = [
        // Silence
        AudioTrack(
            id: 0,
            name: "track_silence_name".localized,
            description: "track_silence_description".localized,
            iconName: "cusMute",
            fileName: "",
            fileType: "mp3"
        ),
        // Meditation
        AudioTrack(
            id: 1,
            name: "track_meditation_name".localized,
            description: "track_meditation_description".localized,
            iconName: "cusPeaceful",
            fileName: "meditation",
            fileType: "mp3"
        ),
        // Campfire
        AudioTrack(
            id: 2,
            name: "track_campfire_name".localized,
            description: "track_campfire_description".localized,
            iconName: "fire-smoke",
            fileName: "campfire",
            fileType: "mp3"
        ),
        // Forest
        AudioTrack(
            id: 3,
            name: "track_forest_name".localized,
            description: "track_forest_description".localized,
            iconName: "trees",
            fileName: "forest",
            fileType: "mp3"
        ),
        // Swamp
        AudioTrack(
            id: 4,
            name: "track_swamp_name".localized,
            description: "track_swamp_description".localized,
            iconName: "pompebled",
            fileName: "swamp",
            fileType: "mp3"
        ),
        // Rain
        AudioTrack(
            id: 5,
            name: "track_rain_name".localized,
            description: "track_rain_description".localized,
            iconName: "raindrops",
            fileName: "rain",
            fileType: "mp3"
        ),
        // Waves
        AudioTrack(
            id: 6,
            name: "track_waves_name".localized,
            description: "track_waves_description".localized,
            iconName: "water-wave",
            fileName: "waves",
            fileType: "mp3"
        ),
        // Wind
        AudioTrack(
            id: 7,
            name: "track_wind_name".localized,
            description: "track_wind_description".localized,
            iconName: "cusWind",
            fileName: "wind",
            fileType: "mp3"
        ),
        // Sprinkler
        AudioTrack(
            id: 8,
            name: "track_sprinkler_name".localized,
            description: "track_sprinkler_description".localized,
            iconName: "cusDroplet",
            fileName: "sprinkler",
            fileType: "mp3"
        ),
        // Cat
        AudioTrack(
            id: 9,
            name: "track_cat_name".localized,
            description: "track_cat_description".localized,
            iconName: "cusCat",
            fileName: "cat",
            fileType: "mp3"
        ),
        // Fan
        AudioTrack(
            id: 10,
            name: "track_fan_name".localized,
            description: "track_fan_description".localized,
            iconName: "cusFan",
            fileName: "fan",
            fileType: "mp3"
        ),
        // Piano
        AudioTrack(
            id: 11,
            name: "track_piano_name".localized,
            description: "track_piano_description".localized,
            iconName: "cusPiano",
            fileName: "piano",
            fileType: "mp3"
        ),
        // Lo-fi
        AudioTrack(
            id: 12,
            name: "track_lofi_name".localized,
            description: "track_lofi_description".localized,
            iconName: "cusMusic",
            fileName: "lofi",
            fileType: "mp3"
        ),
        // Water
        AudioTrack(
            id: 13,
            name: "track_water_name".localized,
            description: "track_water_description".localized,
            iconName: "cusWater",
            fileName: "water",
            fileType: "mp3"
        ),
        
        // Paddling
        AudioTrack(
            id: 14,
            name: "track_paddling_name".localized,
            description: "track_paddling_description".localized,
            iconName: "water-wave",
            fileName: "paddling",
            fileType: "mp3"
        ),
        
        // Dishwasher
        AudioTrack(
            id: 15,
            name: "track_dishwasher_name".localized,
            description: "track_dishwasher_description".localized,
            iconName: "cusWater",
            fileName: "dishwasher",
            fileType: "mp3"
        )
    ]
    var body: some View {
        VStack {
            List(tracks) { track in
                AudioRow(track: track, isSelected: audioSettings.selectedTrackId == track.id)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .onTapGesture {
                        AudioManager.shared.playAudio(fileName: track.fileName, fileType: track.fileType)
                        audioSettings.selectedTrackId = track.id
                        UserDefaults.standard.set(track.id, forKey: "selectedTrackId")
                    }
                    .listRowSeparator(.hidden)
                    .padding(.bottom, 10)
            }
            .listStyle(PlainListStyle())
            .onAppear {
                userProfile.stopTracking()
                let savedTrackId = UserDefaults.standard.integer(forKey: "selectedTrackId")
                audioSettings.selectedTrackId = savedTrackId
                
                // Play the saved track on launch
                if let savedTrack = tracks.first(where: { $0.id == savedTrackId }) {
                    AudioManager.shared.playAudio(fileName: savedTrack.fileName, fileType: savedTrack.fileType)
                }
            }
            .onDisappear {
                userProfile.startTracking()
            }
            .navigationBarTitle("Audio Tracks".localized, displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image("arrow-left")
                        .renderingMode(.template)
                        .foregroundColor(Color("AccentColor"))
                }
            )
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct AudioRow: View {
    let track: AudioTrack
    let isSelected: Bool
    
    @EnvironmentObject var colorManager: ColorManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(track.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("AccentColor"))
                Text(track.description)
                    .font(.system(size: 16))
                    .foregroundColor(Color("AccentColor"))
            }
            .padding()
            
            Spacer()
            
            Image(track.iconName)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color("AccentColor"))
                .scaledToFit()
                .frame(maxWidth: 50, maxHeight: 50)
                .padding(.trailing)
        }
        .background(Color("AccentColor").opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? ColorManager.colorInfos[colorManager.selectedColorIndex].color : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Menu Components
struct MenuOption: Identifiable {
    var id = UUID()
    var title: String
    var icon: String
}

struct CustomMenuView: View {
    @Binding var isShowing: Bool
    @Environment(\.colorScheme) var colorScheme
    var onAnalyticsTapped: () -> Void
    var onCustomizeTapped: () -> Void
    var onLanguageTapped: () -> Void
    var onHelpTapped: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            if isShowing {
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        isShowing = false
                    }
            }
            
            // Menu content
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    // Analytics option
                    menuButton(title: "Profile", icon: "user-alt-1") {
                        onAnalyticsTapped()
                    }
                    
                    Divider()
                        .padding(.leading, 16)
                    
                    // Customize option
                    menuButton(title: "Customize", icon: "brush") {
                        onCustomizeTapped()
                    }
                    
                    Divider()
                        .padding(.leading, 16)
                    
                    // Language option
                    menuButton(title: "Language", icon: "globe") {
                        onLanguageTapped()
                    }
                    
                    Divider()
                        .padding(.leading, 16)
                    
                    // About option
                    menuButton(title: "About", icon: "question") {
                        onHelpTapped()
                    }
                }
                .background(Color.clear)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .glassEffect(in: .rect(cornerRadius: 16.0))
            .frame(width: 250)
            .padding(.bottom, 20)
            .padding(.trailing, 20)
            .offset(y: isShowing ? 0 : 50)
            .opacity(isShowing ? 1 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
    }
    
    private func menuButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                Image(icon)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color("AccentColor"))
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .padding(6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }
}
