import SwiftUI
import StoreKit
import UserNotifications

@main
struct BreathefulApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("launchCount") private var launchCount = 0
    @AppStorage("reviewPromptLastShown") private var reviewPromptLastShown = 0
    @AppStorage("userChoseToReviewLater") private var userChoseToReviewLater = false
    @AppStorage("userDeclinedToReview") private var userDeclinedToReview = false

    
    @StateObject var languageManager = LanguageManager.shared
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var colorManager = ColorManager()
    @StateObject private var circleOptionManager = CircleOptionManager()
    @StateObject private var userProfile = UserProfile()
    
    init() {
        incrementLaunchCount()
        requestNotificationPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(languageManager)
                    .environmentObject(userProfile)
                    .environmentObject(colorManager)
                    .environmentObject(themeManager)
                    .environmentObject(circleOptionManager)
                    .onAppear {
                        themeManager.applyTheme()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Adding delay for better user experience
                            checkAndPromptForReview()
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        print("applicationWillEnterForeground")
                        userProfile.applicationWillEnterForeground()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                        print("applicationDidEnterBackground")
                        userProfile.applicationDidEnterBackground()
                    }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("IDeaful: Error requesting notification permissions: \(error)")
            }
        }
    }
    
    private func incrementLaunchCount() {
        launchCount += 1
    }
    
    private func checkAndPromptForReview() {
        // Don't show if user has permanently declined
        guard !userDeclinedToReview else { return }
        
        // Show on launches 2, 5, and then every 50 launches after that
        let shouldShow = launchCount == 2 || 
                        launchCount == 5 || 
                        (launchCount > 5 && (launchCount - reviewPromptLastShown) >= 50)
        
        if shouldShow {
            DispatchQueue.main.async {
                guard let scene = UIApplication.shared.foregroundActiveScene else { return }
                if #available(iOS 18.0, *) {
                    AppStore.requestReview(in: scene)
                } else {
                    SKStoreReviewController.requestReview(in: scene)
                }
                reviewPromptLastShown = launchCount
            }
        }
    }
}

