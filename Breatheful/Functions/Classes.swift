import SwiftUI



extension ColorInfo {
    var lighterColor: Color {
        return color.opacity(0.7)
    }
    
    var darkerColor: Color {
        return color.opacity(1.3)
    }
}



class CircleOptionManager: ObservableObject {
    @UserDefault("selectedCircleDesign", defaultValue: CircleDesign.stroked)
    private var storedOption: CircleDesign

    var selectedOption: CircleDesign {
        get { storedOption }
        set {
            storedOption = newValue
            objectWillChange.send()
        }
    }
}

class SettingsViewModel: ObservableObject {
    
    @Published var isGuideEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isGuideEnabled, forKey: "isGuideEnabled")
        }
    }
    
    @Published var isProfileEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isProfileEnabled, forKey: "isProfileEnabled")
        }
    }
    
    @Published var areTextGuideEnabled: Bool {
        didSet {
            UserDefaults.standard.set(areTextGuideEnabled, forKey: "areTextGuideEnabled")
        }
    }
    
    @Published var arePhrasesEnabled: Bool {
        didSet {
            UserDefaults.standard.set(arePhrasesEnabled, forKey: "arePhrasesEnabled")
        }
    }
    
    init() {
        self.isGuideEnabled = UserDefaults.standard.bool(forKey: "isGuideEnabled")
        self.arePhrasesEnabled = UserDefaults.standard.bool(forKey: "arePhrasesEnabled")
        self.areTextGuideEnabled = UserDefaults.standard.bool(forKey: "areTextGuideEnabled")
        self.isProfileEnabled = UserDefaults.standard.bool(forKey: "isProfileEnabled")
    }
}


