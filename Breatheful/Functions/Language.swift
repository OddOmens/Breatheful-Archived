import SwiftUI
import Foundation

struct SupportedLanguage: Identifiable {
    let id: String  // Use language code as a unique ID
    let name: String
    let flagEmoji: String  // Add this property
}

// Define available languages
let languages = [
    SupportedLanguage(id: "zh-Hans", name: "Chinese (Simplified)", flagEmoji: "🇨🇳"),
    SupportedLanguage(id: "en", name: "English", flagEmoji: "🇬🇧"),
    SupportedLanguage(id: "fr", name: "French", flagEmoji: "🇫🇷"),
    SupportedLanguage(id: "de", name: "German", flagEmoji: "🇩🇪"),
    SupportedLanguage(id: "hi", name: "Hindi", flagEmoji: "🇮🇳"),
    SupportedLanguage(id: "ja", name: "Japanese", flagEmoji: "🇯🇵"),
    SupportedLanguage(id: "pt-PT", name: "Portuguese (Portugal)", flagEmoji: "🇵🇹"),
    SupportedLanguage(id: "es", name: "Spanish", flagEmoji: "🇪🇸")
    // Extend with more languages as needed
]



private var associatedKey: UInt8 = 0

// Manages the app's current language setting
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var selectedLanguage: SupportedLanguage

    init() {
        let storedLanguageCode = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
        
        // First try exact match
        if let exactMatch = languages.first(where: { $0.id == storedLanguageCode }) {
            self.selectedLanguage = exactMatch
        } 
        // Then try prefix match for backward compatibility (e.g., "zh" -> "zh-Hans")
        else if let prefixMatch = languages.first(where: { $0.id.starts(with: storedLanguageCode + "-") || storedLanguageCode.starts(with: $0.id + "-") }) {
            self.selectedLanguage = prefixMatch
            // Update the stored value to the full code
            UserDefaults.standard.set(prefixMatch.id, forKey: "selectedLanguage")
        } 
        // Default to English if no match found
        else {
            self.selectedLanguage = languages.first { $0.id == "en" } ?? languages[0]
        }
        
        Bundle.setLanguage(selectedLanguage.id)
    }

    func updateLanguage(to language: SupportedLanguage) {
        selectedLanguage = language
        UserDefaults.standard.set(language.id, forKey: "selectedLanguage")
        Bundle.setLanguage(language.id)
    }
}

// Extension to Bundle to switch the app's language dynamically
extension Bundle {
    static func setLanguage(_ language: String) {
        object_setClass(Bundle.main, AnyLanguageBundle.self)
        
        let path = Bundle.main.path(forResource: language, ofType: "lproj")
        #if DEBUG
        if path == nil {
            print("Warning: Could not find .lproj bundle for language: \(language)")
        }
        #endif
        
        objc_setAssociatedObject(
            Bundle.main,
            &associatedKey,
            path != nil ? Bundle(path: path!) : nil,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}

private class AnyLanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let associatedBundle = objc_getAssociatedObject(self, &associatedKey) as? Bundle
        if let result = associatedBundle?.localizedString(forKey: key, value: value, table: tableName), !result.isEmpty {
            return result
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

// SwiftUI view for language selection
struct LanguageSelectionView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List(languages, id: \.id) { language in
            Button(action: {
                languageManager.updateLanguage(to: language)
            }) {
                HStack {
                    Text("\(language.flagEmoji) \(language.name)")
                        .foregroundColor(Color("AccentColor"))
                    
                    Spacer()
                    
                    // Display a checkmark if this is the selected language
                    if languageManager.selectedLanguage.id == language.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color("AccentColor"))
                    }
                }
            }
            .foregroundColor(Color("AccentColor"))
        }
        .listRowBackground(Color.clear)
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .navigationTitle("Select Language".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image("arrow-left")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color("AccentColor"))
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                }
            }
        }
    }
}

extension String {
    var localized: String {
        NSLocalizedString(self, tableName: nil, bundle: .main, value: "", comment: "")
    }
}
