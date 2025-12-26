import SwiftUI
import Combine
import Foundation

struct ColorInfo {
    var name: String
    var color: Color
}

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
    
    var description: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
        
    }
}

class ThemeManager: ObservableObject {
    
    enum ThemeType: String {
        case light, dark, system
    }
    
    @Published var currentTheme: ThemeType {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "theme")
            applyTheme()
        }
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "theme"),
           let theme = ThemeType(rawValue: savedTheme) {
            currentTheme = theme
        } else {
            currentTheme = .system
        }
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.applyTheme()
            }
            .store(in: &cancellables)
        
        applyTheme()
    }
    
    func applyTheme() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            switch currentTheme {
            case .light:
                windowScene.windows.first?.overrideUserInterfaceStyle = .light
            case .dark:
                windowScene.windows.first?.overrideUserInterfaceStyle = .dark
            case .system:
                windowScene.windows.first?.overrideUserInterfaceStyle = .unspecified
            }
        }
    }

}

class ColorManager: ObservableObject {
    static let shared = ColorManager()
    
    @Published var selectedColorIndex: Int {
        didSet {
            UserDefaults.standard.set(selectedColorIndex, forKey: "SelectedColorIndex")
        }
    }
    
    static let colorInfos: [ColorInfo] = [
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

    
    var currentColor: Color {
        Self.colorInfos[selectedColorIndex].color
    }
    
    init() {
        self.selectedColorIndex = UserDefaults.standard.integer(forKey: "SelectedColorIndex")
    }
}
