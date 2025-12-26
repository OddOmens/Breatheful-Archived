import SwiftUI

struct HelpView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var colorManager: ColorManager
    @Environment(\.openURL) var openURL
    @Environment(\.presentationMode) var presentationMode
    
    var computedForegroundColor: Color {
        let selectedColor = ColorManager.colorInfos[colorManager.selectedColorIndex].color
        if selectedColor == Color("colorDefault") && themeManager.currentTheme == .dark {
            return Color.black
        } else {
            return Color.white
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Support".localized).padding(.horizontal, 10).padding(.vertical, 5).glassEffect()) {
                Button(action: { openURL(URL(string: "https://docs.oddomens.com")!) }) {
                    SettingRowView(imageName: "message-square-info", title: LocalizedStringKey("Documentation"))
                }
                Button(action: { sendSupportEmail() }) {
                    SettingRowView(imageName: "mail", title: LocalizedStringKey("Email Support"))
                }
                Button(action: { sendReportIssueEmail() }) {
                    SettingRowView(imageName: "message-square-info", title: LocalizedStringKey("Report an Issue"))
                }
                Button(action: { sendRequestFeatureEmail() }) {
                    SettingRowView(imageName: "message-square-question", title: LocalizedStringKey("Request a Feature"))
                }
            }
            
            Section(header: Text("About Breatheful").padding(.horizontal, 10).padding(.vertical, 5).glassEffect()) {
                Button(action: { openURL(URL(string: "https://apps.apple.com/ca/app/breatheful/id6451128943")!) }) {
                    SettingRowView(imageName: "star", title: LocalizedStringKey("Rate Breatheful"))
                }

                NavigationLink(destination: VersionView()) {
                    HStack {
                        SettingRowView(imageName: "certificate-check", title: LocalizedStringKey("Version"))

                        Text("2025.12.01")
                            .font(.footnote)
                        Spacer()
                    }
                }
            }
            
            Section(header: Text("Privacy and Terms").padding(.horizontal, 10).padding(.vertical, 5).glassEffect()) {
                Button(action: { openURL(URL(string: "https://oddomens.com/privacy")!) }) {
                    SettingRowView(imageName: "cusArticle", title: LocalizedStringKey("Privacy Policy"))
                }
                Button(action: { openURL(URL(string: "https://oddomens.com/terms")!) }) {
                    SettingRowView(imageName: "cusArticle", title: LocalizedStringKey("Terms of Service"))
                }
            }
        }
        .listRowBackground(Color.clear)
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .navigationTitle("About")
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
    
    private func sendSupportEmail() {
        let emailSubject = "Breatheful App Support"
        let emailBody = "Hello, I need help with..."
        let emailAddress = "support@oddomens.com"

        let encodedSubject = emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let mailtoURL = URL(string: "mailto:\(emailAddress)?subject=\(encodedSubject)&body=\(encodedBody)") {
            openURL(mailtoURL)
        }
    }

    private func sendReportIssueEmail() {
        let emailSubject = "Breatheful - Report an Issue"
        let emailBody = "Please describe the issue you're experiencing:"
        let emailAddress = "support@oddomens.com"

        let encodedSubject = emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let mailtoURL = URL(string: "mailto:\(emailAddress)?subject=\(encodedSubject)&body=\(encodedBody)") {
            openURL(mailtoURL)
        }
    }

    private func sendRequestFeatureEmail() {
        let emailSubject = "Breatheful - Feature Request"
        let emailBody = "I would like to request the following feature:"
        let emailAddress = "support@oddomens.com"

        let encodedSubject = emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let mailtoURL = URL(string: "mailto:\(emailAddress)?subject=\(encodedSubject)&body=\(encodedBody)") {
            openURL(mailtoURL)
        }
    }
}

struct SettingRowView: View {
    let imageName: String
    let title: LocalizedStringKey
    @ObservedObject var colorManager = ColorManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var computedForegroundColor: Color {
        let selectedColor = ColorManager.colorInfos[colorManager.selectedColorIndex].color
        if selectedColor == Color("colorDefault") && themeManager.currentTheme == .dark {
            return Color.black
        } else {
            return Color.white
        }
    }
    
    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 20, height: 20)
                .padding(6)
                .foregroundColor(computedForegroundColor)
                .background(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                .cornerRadius(80)
            Text(title)
                .foregroundColor(Color("AccentColor"))
        }
    }
}
