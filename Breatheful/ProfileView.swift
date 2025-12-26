import SwiftUI
import Combine
import UserNotifications
import CoreData
import HealthKit

class UserProfile: ObservableObject {
    @Published var name: String = ""
    @Published var preferredBreathingMode: String = "Normal"
    @Published var preferredAudioMode: String = "Nature"
    @Published var dailyUsageMinutes: [Date: Int] = [:]
    @Published var dailyGoal: Int = 10 // Default daily goal in minutes
    @Published var weeklyAverage: Int = 0
    @Published var morningReminder: Date?
    @Published var afternoonReminder: Date?
    @Published var nightReminder: Date?
    @Published var morningReminderEnabled: Bool = false
    @Published var afternoonReminderEnabled: Bool = false
    @Published var nightReminderEnabled: Bool = false
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    private var lastNotifiedUsage: Int = 0 // Track the last notified usage
    private var goalNotificationSent: Bool = false // Flag to track if notification has been sent for the current goal
    @Published var isHealthKitEnabled: Bool = false
    @Published var healthKitSyncStatus: String = "Not configured"

    private var timer: Timer?
    private var startTime: Date?
    private let context = CoreDataManager.shared.context
    private var profile: Profile?
    private let healthKitManager = HealthKitManager.shared

    init() {
        fetchProfile()
        requestNotificationPermissions()
        setupHealthKit()
    }

    private func fetchProfile() {
        let request: NSFetchRequest<Profile> = Profile.fetchRequest()
        do {
            let profiles = try context.fetch(request)
            if let profile = profiles.first {
                self.profile = profile
                self.loadProfileData(from: profile)
            } else {
                createNewProfile()
            }
        } catch {
            print("Failed to fetch profile: \(error)")
        }
    }

    private func loadProfileData(from profile: Profile) {
        self.name = profile.name ?? ""
        self.preferredBreathingMode = profile.preferredBreathingMode ?? "Normal"
        self.preferredAudioMode = profile.preferredAudioMode ?? "Nature"
        if let data = profile.dailyUsageMinutes {
            self.dailyUsageMinutes = (try? JSONDecoder().decode([Date: Int].self, from: data)) ?? [:]
        }
        self.dailyGoal = Int(profile.dailyGoal)
        self.weeklyAverage = Int(profile.weeklyAverage)
        self.morningReminder = profile.morningReminder
        self.afternoonReminder = profile.afternoonReminder
        self.nightReminder = profile.nightReminder
        self.morningReminderEnabled = profile.morningReminderEnabled
        self.afternoonReminderEnabled = profile.afternoonReminderEnabled
        self.nightReminderEnabled = profile.nightReminderEnabled
    }

    private func createNewProfile() {
        self.profile = Profile(context: context)
        self.name = ""
        self.preferredBreathingMode = "Normal"
        self.preferredAudioMode = "Nature"
        self.dailyGoal = 10
        saveProfile()
    }

    func deleteBreathingData() {
        dailyUsageMinutes.removeAll()  // Clear the dailyUsageMinutes dictionary
        weeklyAverage = 0  // Reset the weekly average
        saveProfile()  // Save the changes to Core Data
    }

    func saveProfile() {
        profile?.name = name
        profile?.preferredBreathingMode = preferredBreathingMode
        profile?.preferredAudioMode = preferredAudioMode
        profile?.dailyUsageMinutes = try? JSONEncoder().encode(dailyUsageMinutes)
        profile?.dailyGoal = Int64(dailyGoal)
        profile?.weeklyAverage = Int64(weeklyAverage)
        profile?.morningReminder = morningReminder
        profile?.afternoonReminder = afternoonReminder
        profile?.nightReminder = nightReminder
        profile?.morningReminderEnabled = morningReminderEnabled
        profile?.afternoonReminderEnabled = afternoonReminderEnabled
        profile?.nightReminderEnabled = nightReminderEnabled
        profile?.selectedYear = Int64(selectedYear)

        do {
            try context.save()
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
    
    func applicationDidEnterBackground() {
        stopTracking()
    }

    func applicationWillEnterForeground() {
        startTracking()
    }
    

    func startTracking() {
        print("Starting Breathing Tracking")
        startTime = Date()
        startTimer()
    }

    func stopTracking() {
        print("Ending Breathing Tracking")
        if let startTime = startTime {
            let duration = Int(Date().timeIntervalSince(startTime) / 60)
            let today = Calendar.current.startOfDay(for: Date())
            dailyUsageMinutes[today, default: 0] += duration
            calculateWeeklyAverage()
            saveProfile()
            
            // Sync to HealthKit if enabled
            if isHealthKitEnabled && duration > 0 {
                syncSessionToHealthKit(startDate: startTime, duration: duration)
            }
        }
        stopTimer()
    }

    func startTimer() {
        stopTimer() // Ensure any existing timer is invalidated first
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.timerFired()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func timerFired() {
        let today = Calendar.current.startOfDay(for: Date())
        dailyUsageMinutes[today, default: 0] += 1
        calculateWeeklyAverage()
        saveProfile()
        checkDailyGoal()
    }

    func calculateWeeklyAverage() {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let filteredUsage = dailyUsageMinutes.filter { $0.key >= oneWeekAgo }
        let totalMinutes = filteredUsage.values.reduce(0, +)
        weeklyAverage = filteredUsage.isEmpty ? 0 : totalMinutes / filteredUsage.count
    }

    func monthlyUsage(for year: Int) -> [Int] {
        let calendar = Calendar.current
        var usage: [Int] = Array(repeating: 0, count: 12)
        for month in 1...12 {
            let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
            let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
            let monthUsage = range.reduce(0) { total, day -> Int in
                let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
                return total + dailyUsageMinutes[date, default: 0]
            }
            usage[month - 1] = monthUsage
        }
        return usage
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func scheduleNotification(for date: Date?, title: String, subtitle: String, identifier: String) {
        guard let date = date else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = subtitle
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.hour, .minute], from: date), repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled with identifier: \(identifier)")
            }
        }
    }

    private func removeNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func updateReminder(_ time: Date?, title: String, identifier: String, enabled: Bool) {
        if enabled {
            scheduleNotification(for: time, title: "Breatheful", subtitle: "It's time for your \(title.lowercased()) breathing.", identifier: identifier)
        } else {
            removeNotification(identifier: identifier)
        }
    }

    func checkDailyGoal() {
        let today = Calendar.current.startOfDay(for: Date())
        let usage = dailyUsageMinutes[today, default: 0]
        
        if usage >= dailyGoal && !goalNotificationSent {
            sendGoalNotification()
            goalNotificationSent = true
        }
    }

    func sendGoalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Congratulations!"
        content.body = "You've hit your daily goal of \(dailyGoal) minutes."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - HealthKit Integration
    
    private func setupHealthKit() {
        isHealthKitEnabled = healthKitManager.isHealthKitAvailable && healthKitManager.isAuthorized
        updateHealthKitStatus()
    }
    
    func requestHealthKitPermission() {
        guard healthKitManager.isHealthKitAvailable else {
            healthKitSyncStatus = "HealthKit not available on this device"
            return
        }
        
        healthKitSyncStatus = "Requesting permission..."
        
        healthKitManager.requestAuthorization()
        
        // Update status after a delay to allow for authorization
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateHealthKitStatus()
        }
    }
    
    private func updateHealthKitStatus() {
        if !healthKitManager.isHealthKitAvailable {
            healthKitSyncStatus = "Not available on this device"
            isHealthKitEnabled = false
        } else if healthKitManager.isAuthorized {
            healthKitSyncStatus = "Connected and syncing"
            isHealthKitEnabled = true
        } else {
            healthKitSyncStatus = "Permission required"
            isHealthKitEnabled = false
        }
    }
    
    private func syncSessionToHealthKit(startDate: Date, duration: Int) {
        guard duration > 0 else { return }
        
        let durationInSeconds = TimeInterval(duration * 60)
        let endDate = startDate.addingTimeInterval(durationInSeconds)
        
        healthKitManager.saveMindfulSession(startDate: startDate, endDate: endDate) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("Successfully synced \(duration) minutes to HealthKit")
                } else {
                    print("Failed to sync to HealthKit: \(error?.localizedDescription ?? "Unknown error")")
                }
                self?.updateHealthKitStatus()
            }
        }
    }
    
    func syncHistoricalDataToHealthKit() {
        guard isHealthKitEnabled else {
            healthKitSyncStatus = "Permission required"
            return
        }
        
        healthKitSyncStatus = "Syncing historical data..."
        
        healthKitManager.saveHistoricalMindfulSessions(from: dailyUsageMinutes) { [weak self] savedCount, errors in
            DispatchQueue.main.async {
                if errors.isEmpty {
                    self?.healthKitSyncStatus = "Synced \(savedCount) sessions successfully"
                } else {
                    self?.healthKitSyncStatus = "Synced \(savedCount) sessions with \(errors.count) errors"
                }
            }
        }
    }

}

struct ProfileView: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var isSettingsViewPresented: Bool = false
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var colorManager: ColorManager
    @ObservedObject private var settingsViewModel = SettingsViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var isCalendarViewPresented: Bool = false

    let iconSize: CGFloat = 24
    let textSize: CGFloat = 10

    let colorInfos: [ColorInfo] = [
        // Dull (Default), Vibrant, and Pastel pairs
        ColorInfo(name: "Default".localized, color: Color("colorDefault")),
        ColorInfo(name: "Dull Red".localized, color: Color("colorDullRed")),
        ColorInfo(name: "Vibrant Red".localized, color: Color("colorVibrantRed")),
        ColorInfo(name: "Pastel Red".localized, color: Color("colorPastelRed")),
        ColorInfo(name: "Dull Orange".localized, color: Color("colorDullOrange")),
        ColorInfo(name: "Vibrant Orange".localized, color: Color("colorVibrantOrange")),
        ColorInfo(name: "Pastel Orange".localized, color: Color("colorPastelOrange")),
        ColorInfo(name: "Dull Yellow".localized, color: Color("colorDullYellow")),
        ColorInfo(name: "Vibrant Yellow".localized, color: Color("colorVibrantYellow")),
        ColorInfo(name: "Pastel Yellow".localized, color: Color("colorPastelYellow")),
        ColorInfo(name: "Dull Green".localized, color: Color("colorDullGreen")),
        ColorInfo(name: "Vibrant Green".localized, color: Color("colorVibrantGreen")),
        ColorInfo(name: "Pastel Green".localized, color: Color("colorPastelGreen")),
        ColorInfo(name: "Dull Cyan".localized, color: Color("colorDullCyan")),
        ColorInfo(name: "Vibrant Cyan".localized, color: Color("colorVibrantCyan")),
        ColorInfo(name: "Pastel Cyan".localized, color: Color("colorPastelCyan")),
        ColorInfo(name: "Dull Blue".localized, color: Color("colorDullBlue")),
        ColorInfo(name: "Vibrant Blue".localized, color: Color("colorVibrantBlue")),
        ColorInfo(name: "Pastel Blue".localized, color: Color("colorPastelBlue")),
        ColorInfo(name: "Dull Purple".localized, color: Color("colorDullPurple")),
        ColorInfo(name: "Vibrant Purple".localized, color: Color("colorVibrantPurple")),
        ColorInfo(name: "Pastel Purple".localized, color: Color("colorPastelPurple")),
        ColorInfo(name: "Dull Magenta".localized, color: Color("colorDullMagenta")),
        ColorInfo(name: "Vibrant Magenta".localized, color: Color("colorVibrantMagenta")),
        ColorInfo(name: "Pastel Magenta".localized, color: Color("colorPastelMagenta"))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileSection
                    remindersSection
                    healthKitSection
                    usageSection
                    
                    TabView {
                        CalendarView()
                            .environmentObject(userProfile)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        
                        BarGraphView(data: userProfile.monthlyUsage(for: userProfile.selectedYear), title: "Monthly Usage (\(userProfile.selectedYear))", maxValue: 2000)
                        
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: 550) // Consistent height for all tabs
                    
                    
                }
                .padding()
                .background(Color(.systemBackground))
                .onAppear {
                    userProfile.stopTracking()
                    checkDailyGoal()
                }
                .onDisappear {
                    userProfile.startTracking()
                }
                .navigationBarTitle("Profile", displayMode: .inline)
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
        }
    }

    var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(colorInfos[colorManager.selectedColorIndex].color)
                    .font(.title2)
                Text("Name")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            TextField("Enter your name", text: $userProfile.name)
                .padding(12)
                .background(Color("AccentColor").opacity(0.08))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("AccentColor").opacity(0.2), lineWidth: 1)
                )
                .onChange(of: userProfile.name) { oldValue, newValue in
                    userProfile.saveProfile()
                }
        }
        .padding(16)
        .background(Color("AccentColor").opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("AccentColor").opacity(0.2), lineWidth: 1)
        )
    }

    var usageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(colorInfos[colorManager.selectedColorIndex].color)
                    .font(.title2)
                Text("Usage & Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Daily Goal Setting
            VStack(spacing: 12) {
                HStack {
                    Text("Daily Goal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Stepper("\(userProfile.dailyGoal) min", value: $userProfile.dailyGoal, in: 1...60)
                        .labelsHidden()
                    Text("\(userProfile.dailyGoal) min")
                        .foregroundColor(colorInfos[colorManager.selectedColorIndex].color)
                        .fontWeight(.semibold)
                }
                .padding(12)
                .background(Color("AccentColor").opacity(0.05))
                .cornerRadius(8)
                .onChange(of: userProfile.dailyGoal) { oldValue, newValue in
                    userProfile.saveProfile()
                    userProfile.checkDailyGoal()
                }
                
                // Usage Stats
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(colorInfos[colorManager.selectedColorIndex].color)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Today's Usage")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(userProfile.dailyUsageMinutes[Calendar.current.startOfDay(for: Date()), default: 0]) minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(userProfile.dailyUsageMinutes[Calendar.current.startOfDay(for: Date()), default: 0]) min")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(colorInfos[colorManager.selectedColorIndex].color)
                    }
                    
                    Divider()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(colorInfos[colorManager.selectedColorIndex].color)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weekly Average")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Past 7 days average")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(userProfile.weeklyAverage) min/day")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(colorInfos[colorManager.selectedColorIndex].color)
                    }
                    
                    Divider()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(colorInfos[colorManager.selectedColorIndex].color)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Sessions")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("All time usage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(userProfile.dailyUsageMinutes.values.reduce(0, +)) min")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(colorInfos[colorManager.selectedColorIndex].color)
                    }
                }
                .padding(12)
                .background(Color("AccentColor").opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color("AccentColor").opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("AccentColor").opacity(0.2), lineWidth: 1)
        )
    }


    var remindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "bell.circle.fill")
                    .foregroundColor(colorInfos[colorManager.selectedColorIndex].color)
                    .font(.title2)
                Text("Daily Reminders")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Reminder Cards
            VStack(spacing: 12) {
                reminderCard(
                    time: $userProfile.morningReminder,
                    title: "Morning",
                    subtitle: "Start your day mindfully",
                    icon: "sun.max.fill",
                    isEnabled: $userProfile.morningReminderEnabled,
                    identifier: "morningReminder"
                )
                
                reminderCard(
                    time: $userProfile.afternoonReminder,
                    title: "Afternoon",
                    subtitle: "Take a mindful break",
                    icon: "sun.haze.fill",
                    isEnabled: $userProfile.afternoonReminderEnabled,
                    identifier: "afternoonReminder"
                )
                
                reminderCard(
                    time: $userProfile.nightReminder,
                    title: "Evening",
                    subtitle: "Wind down peacefully",
                    icon: "moon.stars.fill",
                    isEnabled: $userProfile.nightReminderEnabled,
                    identifier: "nightReminder"
                )
            }
        }
        .padding(16)
        .background(Color("AccentColor").opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("AccentColor").opacity(0.2), lineWidth: 1)
        )
    }

    func reminderCard(time: Binding<Date?>, title: String, subtitle: String, icon: String, isEnabled: Binding<Bool>, identifier: String) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .foregroundColor(isEnabled.wrappedValue ? colorInfos[colorManager.selectedColorIndex].color : .gray)
                .font(.title2)
                .frame(width: 30)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isEnabled.wrappedValue ? .primary : .secondary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if isEnabled.wrappedValue {
                    DatePicker("Time", selection: Binding(
                        get: { time.wrappedValue ?? Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 60 * 60) },
                        set: { time.wrappedValue = $0 }
                    ), displayedComponents: .hourAndMinute)
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                    .onChange(of: time.wrappedValue) { oldValue, newValue in
                        userProfile.updateReminder(newValue, title: title, identifier: identifier, enabled: isEnabled.wrappedValue)
                    }
                }
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: isEnabled)
                .tint(colorInfos[colorManager.selectedColorIndex].color)
                .onChange(of: isEnabled.wrappedValue) { oldValue, enabled in
                    if enabled {
                        if time.wrappedValue == nil {
                            time.wrappedValue = Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 60 * 60)
                        }
                        userProfile.updateReminder(time.wrappedValue, title: title, identifier: identifier, enabled: enabled)
                    } else {
                        userProfile.updateReminder(time.wrappedValue, title: title, identifier: identifier, enabled: enabled)
                    }
                    userProfile.saveProfile()
                }
        }
        .padding(12)
        .background(Color("AccentColor").opacity(isEnabled.wrappedValue ? 0.08 : 0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color("AccentColor").opacity(isEnabled.wrappedValue ? 0.3 : 0.1), lineWidth: 1)
        )
    }
    
    func reminderToggle(time: Binding<Date?>, title: String, isEnabled: Binding<Bool>, identifier: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(title)")
                    .frame(width: 80, alignment: .leading)
                Spacer()
                if isEnabled.wrappedValue {
                    DatePicker("", selection: Binding(
                        get: { time.wrappedValue ?? Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 60 * 60) }, // Defaults to 12:00 PM
                        set: { time.wrappedValue = $0 }
                    ), displayedComponents: .hourAndMinute)
                    .datePickerStyle(DefaultDatePickerStyle())
                    .onChange(of: time.wrappedValue) { oldValue, newValue in
                        userProfile.updateReminder(newValue, title: title, identifier: identifier, enabled: isEnabled.wrappedValue)
                    }
                }
                Toggle("", isOn: isEnabled).tint(colorInfos[colorManager.selectedColorIndex].color)
                    .onChange(of: isEnabled.wrappedValue) { oldValue, enabled in
                        if enabled {
                            if time.wrappedValue == nil {
                                time.wrappedValue = Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 60 * 60) // Defaults to 12:00 PM
                            }
                            userProfile.updateReminder(time.wrappedValue, title: title, identifier: identifier, enabled: enabled)
                        } else {
                            userProfile.updateReminder(time.wrappedValue, title: title, identifier: identifier, enabled: enabled)
                        }
                        userProfile.saveProfile()
                    }
            }
        }
    }

    var healthKitSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .foregroundColor(colorInfos[colorManager.selectedColorIndex].color)
                        .font(.title2)
                    Text("HealthKit Integration")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Spacer()
                if userProfile.isHealthKitEnabled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            
            // Status Card
            HStack(spacing: 12) {
                Image(systemName: userProfile.isHealthKitEnabled ? "checkmark.circle" : "exclamationmark.circle")
                    .foregroundColor(userProfile.isHealthKitEnabled ? .green : .orange)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(userProfile.isHealthKitEnabled ? "Connected" : "Not Connected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(userProfile.healthKitSyncStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(Color("AccentColor").opacity(0.05))
            .cornerRadius(8)
            
            // Action Buttons
            if !userProfile.isHealthKitEnabled {
                Button(action: {
                    userProfile.requestHealthKitPermission()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Connect to Health App")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [colorInfos[colorManager.selectedColorIndex].color, colorInfos[colorManager.selectedColorIndex].color.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: colorInfos[colorManager.selectedColorIndex].color.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            } else {
                VStack(spacing: 12) {
                    // Sync Button
                    Button(action: {
                        userProfile.syncHistoricalDataToHealthKit()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title3)
                            Text("Sync Historical Data")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(colorInfos[colorManager.selectedColorIndex].color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(colorInfos[colorManager.selectedColorIndex].color.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorInfos[colorManager.selectedColorIndex].color.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Auto-sync Info
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Automatic Sync Enabled")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("New sessions sync automatically to Health")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .background(Color("AccentColor").opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("AccentColor").opacity(0.2), lineWidth: 1)
        )
    }

    private func checkDailyGoal() {
        if userProfile.dailyUsageMinutes[Calendar.current.startOfDay(for: Date()), default: 0] >= userProfile.dailyGoal {
            let content = UNMutableNotificationContent()
            content.title = "Congratulations!"
            content.body = "You've hit your daily goal of \(userProfile.dailyGoal) minutes."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct BarGraphView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var colorManager: ColorManager

    var data: [Int]
    var title: String
    var maxValue: Int
    let maxHeight: CGFloat = 100
    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let monthsOfYear = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    let colorInfos: [ColorInfo] = [
        // Dull (Default), Vibrant, and Pastel pairs
        ColorInfo(name: "Default".localized, color: Color("colorDefault")),
        ColorInfo(name: "Dull Red".localized, color: Color("colorDullRed")),
        ColorInfo(name: "Vibrant Red".localized, color: Color("colorVibrantRed")),
        ColorInfo(name: "Pastel Red".localized, color: Color("colorPastelRed")),
        ColorInfo(name: "Dull Orange".localized, color: Color("colorDullOrange")),
        ColorInfo(name: "Vibrant Orange".localized, color: Color("colorVibrantOrange")),
        ColorInfo(name: "Pastel Orange".localized, color: Color("colorPastelOrange")),
        ColorInfo(name: "Dull Yellow".localized, color: Color("colorDullYellow")),
        ColorInfo(name: "Vibrant Yellow".localized, color: Color("colorVibrantYellow")),
        ColorInfo(name: "Pastel Yellow".localized, color: Color("colorPastelYellow")),
        ColorInfo(name: "Dull Green".localized, color: Color("colorDullGreen")),
        ColorInfo(name: "Vibrant Green".localized, color: Color("colorVibrantGreen")),
        ColorInfo(name: "Pastel Green".localized, color: Color("colorPastelGreen")),
        ColorInfo(name: "Dull Cyan".localized, color: Color("colorDullCyan")),
        ColorInfo(name: "Vibrant Cyan".localized, color: Color("colorVibrantCyan")),
        ColorInfo(name: "Pastel Cyan".localized, color: Color("colorPastelCyan")),
        ColorInfo(name: "Dull Blue".localized, color: Color("colorDullBlue")),
        ColorInfo(name: "Vibrant Blue".localized, color: Color("colorVibrantBlue")),
        ColorInfo(name: "Pastel Blue".localized, color: Color("colorPastelBlue")),
        ColorInfo(name: "Dull Purple".localized, color: Color("colorDullPurple")),
        ColorInfo(name: "Vibrant Purple".localized, color: Color("colorVibrantPurple")),
        ColorInfo(name: "Pastel Purple".localized, color: Color("colorPastelPurple")),
        ColorInfo(name: "Dull Magenta".localized, color: Color("colorDullMagenta")),
        ColorInfo(name: "Vibrant Magenta".localized, color: Color("colorVibrantMagenta")),
        ColorInfo(name: "Pastel Magenta".localized, color: Color("colorPastelMagenta"))
    ]

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)

            ForEach(0..<data.count, id: \.self) { index in
                HStack {
                    Text(daysOfWeek.count == data.count ? daysOfWeek[index] : monthsOfYear[index])
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(4)
                        .background(Color("AccentColor").opacity(0.2))
                        .cornerRadius(4)
                        .frame(width: 50, alignment: .leading)
                    GeometryReader { geometry in
                        HStack {
                            Rectangle()
                                .fill(colorInfos[colorManager.selectedColorIndex].color)
                                .frame(width: barWidth(for: data[index], in: geometry.size.width), height: 20)
                            Spacer()
                            Text("\(data[index])")
                                .font(.caption)
                                .padding(.leading, 4)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color("AccentColor").opacity(0.1))
        .cornerRadius(8)
    }

    private func barWidth(for value: Int, in totalWidth: CGFloat) -> CGFloat {
        return value == 0 ? 0.8 : CGFloat(value) / CGFloat(maxValue) * totalWidth - 10 // Adjusted padding for bar
    }
}

struct CalendarView: View {
    private let calendar: Calendar
    private let monthFormatter: DateFormatter
    private let dayFormatter: DateFormatter
    private let weekDayFormatter: DateFormatter

    @State private var selectedDate = Date()
    @State private var selectedYear = 2024
    @State private var showYearPicker = false
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var colorManager: ColorManager
    private static var now = Date()

    init(calendar: Calendar = Calendar.current) {
        self.calendar = calendar
        self.monthFormatter = DateFormatter(dateFormat: "MMMM yyyy", calendar: calendar)
        self.dayFormatter = DateFormatter(dateFormat: "d", calendar: calendar)
        self.weekDayFormatter = DateFormatter(dateFormat: "EEEEE", calendar: calendar)
    }
    
    let colorInfos: [ColorInfo] = [
        // Dull (Default), Vibrant, and Pastel pairs
        ColorInfo(name: "Default".localized, color: Color("colorDefault")),
        ColorInfo(name: "Dull Red".localized, color: Color("colorDullRed")),
        ColorInfo(name: "Vibrant Red".localized, color: Color("colorVibrantRed")),
        ColorInfo(name: "Pastel Red".localized, color: Color("colorPastelRed")),
        ColorInfo(name: "Dull Orange".localized, color: Color("colorDullOrange")),
        ColorInfo(name: "Vibrant Orange".localized, color: Color("colorVibrantOrange")),
        ColorInfo(name: "Pastel Orange".localized, color: Color("colorPastelOrange")),
        ColorInfo(name: "Dull Yellow".localized, color: Color("colorDullYellow")),
        ColorInfo(name: "Vibrant Yellow".localized, color: Color("colorVibrantYellow")),
        ColorInfo(name: "Pastel Yellow".localized, color: Color("colorPastelYellow")),
        ColorInfo(name: "Dull Green".localized, color: Color("colorDullGreen")),
        ColorInfo(name: "Vibrant Green".localized, color: Color("colorVibrantGreen")),
        ColorInfo(name: "Pastel Green".localized, color: Color("colorPastelGreen")),
        ColorInfo(name: "Dull Cyan".localized, color: Color("colorDullCyan")),
        ColorInfo(name: "Vibrant Cyan".localized, color: Color("colorVibrantCyan")),
        ColorInfo(name: "Pastel Cyan".localized, color: Color("colorPastelCyan")),
        ColorInfo(name: "Dull Blue".localized, color: Color("colorDullBlue")),
        ColorInfo(name: "Vibrant Blue".localized, color: Color("colorVibrantBlue")),
        ColorInfo(name: "Pastel Blue".localized, color: Color("colorPastelBlue")),
        ColorInfo(name: "Dull Purple".localized, color: Color("colorDullPurple")),
        ColorInfo(name: "Vibrant Purple".localized, color: Color("colorVibrantPurple")),
        ColorInfo(name: "Pastel Purple".localized, color: Color("colorPastelPurple")),
        ColorInfo(name: "Dull Magenta".localized, color: Color("colorDullMagenta")),
        ColorInfo(name: "Vibrant Magenta".localized, color: Color("colorVibrantMagenta")),
        ColorInfo(name: "Pastel Magenta".localized, color: Color("colorPastelMagenta"))
    ]


    var computedForegroundColor: Color {
        let selectedColor = colorInfos[colorManager.selectedColorIndex].color
        if selectedColor == Color("colorDefault") && themeManager.currentTheme == .dark {
            return Color.black
        } else {
            return Color.white
        }
    }

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                HStack {
                    Button(action: {
                        withAnimation {
                            scrollToToday(proxy: proxy)
                        }
                    }) {
                        Text("Today")
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(colorInfos[colorManager.selectedColorIndex].color)
                            .foregroundColor(computedForegroundColor)
                            .cornerRadius(8)
                    }
                    Spacer()
                    Button(action: {
                        showYearPicker.toggle()
                    }) {
                        Text(String(selectedYear))
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(colorInfos[colorManager.selectedColorIndex].color)
                            .foregroundColor(computedForegroundColor)
                            .cornerRadius(8)
                    }
                    .actionSheet(isPresented: $showYearPicker) {
                        ActionSheet(
                            title: Text("Select Year"),
                            buttons: (2024...2035).map { year in
                                .default(Text(String(year))) {
                                    selectedYear = year
                                    userProfile.selectedYear = year
                                }
                            } + [.cancel()]
                        )
                    }
                }
                
                Divider().padding(.horizontal, -50)

                ScrollView {
                    CalendarViewComponent(
                        calendar: calendar,
                        selectedYear: $selectedYear,
                        date: $selectedDate,
                        content: { date in
                            VStack {
                                Text(dayFormatter.string(from: date))
                                    .font(.system(size: 14))
                                    .fontWeight(calendar.isDateInToday(date) ? .bold : .regular)
                                    .padding(8)
                                    .foregroundColor(calendar.isDateInToday(date) ? .white : .primary)
                                    .background(
                                        calendar.isDateInToday(date) ? colorInfos[colorManager.selectedColorIndex].color : Color.clear
                                    )
                                    .clipShape(Circle())
                                    .id(date) // Set ID for scrolling
                                Text("\(userProfile.dailyUsageMinutes[date, default: 0]) min")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.gray)
                                    .frame(maxWidth: .infinity)
                            }
                        },
                        trailing: { date in
                            VStack {
                                Text(dayFormatter.string(from: date))
                                    .padding(8)
                                    .foregroundColor(.gray)
                                Text("")
                                    .font(.subheadline)
                                    .foregroundColor(Color.gray)
                            }
                        },
                        header: { date in
                            Text(weekDayFormatter.string(from: date)).fontWeight(.bold)
                        },
                        title: { date in
                            Text(monthFormatter.string(from: date))
                                .font(.system(size: 20))
                                .padding(.vertical, 8)
                        }
                    )
                    .onAppear {
                        withAnimation {
                            scrollToToday(proxy: proxy)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color("AccentColor").opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color("AccentColor").opacity(0.2), lineWidth: 1)
        )
    }

    private func scrollToToday(proxy: ScrollViewProxy? = nil) {
        let today = Date()
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: today))!
        selectedYear = Calendar.current.component(.year, from: startOfMonth)  // Ensure selected year is set to the current year
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            proxy?.scrollTo(startOfMonth, anchor: .top)
        }
    }
}

public struct CalendarViewComponent<Day: View, Header: View, Title: View, Trailing: View>: View {
    private var calendar: Calendar
    @Binding private var date: Date
    @Binding private var selectedYear: Int
    private let content: (Date) -> Day
    private let trailing: (Date) -> Trailing
    private let header: (Date) -> Header
    private let title: (Date) -> Title

    @State private var months: [Date] = []

    let spaceName = "scroll"
    @State var wholeSize: CGSize = .zero
    @State var scrollViewSize: CGSize = .zero
    private let daysInWeek = 7

    public init(
        calendar: Calendar,
        selectedYear: Binding<Int>,
        date: Binding<Date>,
        @ViewBuilder content: @escaping (Date) -> Day,
        @ViewBuilder trailing: @escaping (Date) -> Trailing,
        @ViewBuilder header: @escaping (Date) -> Header,
        @ViewBuilder title: @escaping (Date) -> Title
    ) {
        self.calendar = calendar
        self._date = date
        self._selectedYear = selectedYear
        self.content = content
        self.trailing = trailing
        self.header = header
        self.title = title
    }

    public var body: some View {
        VStack {
            ForEach(months, id: \.self) { month in
                let monthStart = month.startOfMonth(using: calendar)
                let days = makeDays(from: monthStart, calendar: calendar)

                VStack {
                    Section(header: title(monthStart)) { }
                    LazyVGrid(columns: Array(repeating: GridItem(), count: daysInWeek), spacing: 10) {
                        ForEach(days.prefix(daysInWeek), id: \.self, content: header)
                    }
                    Divider()
                    LazyVGrid(columns: Array(repeating: GridItem(), count: daysInWeek), spacing: 10) {
                        ForEach(days, id: \.self) { date in
                            if calendar.isDate(date, equalTo: month, toGranularity: .month) {
                                content(date)
                            } else {
                                trailing(date)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .onChange(of: selectedYear) { oldValue, newYear in
            months = CalendarViewComponent.makeMonths(calendar: calendar, for: newYear)
        }
        .onAppear {
            months = CalendarViewComponent.makeMonths(calendar: calendar, for: selectedYear)
        }
    }

    private static func makeMonths(calendar: Calendar, for year: Int) -> [Date] {
        var months: [Date] = []
        if let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) {
            var date = startOfYear
            let endYear = year + 1
            while calendar.component(.year, from: date) < endYear {
                months.append(date)
                date = calendar.date(byAdding: .month, value: 1, to: date)!
            }
        }
        return months
    }

    private func makeDays(from date: Date, calendar: Calendar) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else {
            return []
        }

        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDays(for: dateInterval)
    }
}

private extension Calendar {
    func generateDates(for dateInterval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates = [dateInterval.start]

        enumerateDates(startingAfter: dateInterval.start, matching: components, matchingPolicy: .nextTime) { date, _, stop in
            guard let date = date else { return }
            guard date < dateInterval.end else {
                stop = true
                return
            }

            dates.append(date)
        }

        return dates
    }

    func generateDays(for dateInterval: DateInterval) -> [Date] {
        generateDates(for: dateInterval, matching: dateComponents([.hour, .minute, .second], from: dateInterval.start))
    }
}

private extension Date {
    func startOfMonth(using calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: self)) ?? self
    }
}

private extension DateFormatter {
    convenience init(dateFormat: String, calendar: Calendar) {
        self.init()
        self.dateFormat = dateFormat
        self.calendar = calendar
    }
}
