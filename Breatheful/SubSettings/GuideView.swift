import SwiftUI

struct GuideView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userProfile: UserProfile

    var body: some View {
        VStack {
            TabView {
                GuidePageView(
                    image: "guideImage00",
                    number: "",
                    title: "guideTitle00".localized,
                    description: "guideDesc00".localized
                )
                GuidePageView(
                    image: "guideImage01",
                    number: "01.",
                    title: "guideTitle01".localized,
                    description: "guideDesc01".localized
                )
                GuidePageView(
                    image: "guideImage02",
                    number: "02.",
                    title: "guideTitle02".localized,
                    description: "guideDesc02".localized
                )
                GuidePageView(
                    image: "guideImage03",
                    number: "03.",
                    title: "guideTitle03".localized,
                    description: "guideDesc03".localized
                )
                GuidePageView(
                    image: "guideImage04",
                    number: "04.",
                    title: "guideTitle04".localized,
                    description: "guideDesc04".localized
                )
                GuidePageView(
                    image: "guideImage05",
                    number: "05.",
                    title: "guideTitle05".localized,
                    description: "guideDesc05".localized
                )
                GuidePageView(
                    image: "guideImage06",
                    number: "06.",
                    title: "guideTitle06".localized,
                    description: "guideDesc06".localized
                )
                GuidePageView(
                    image: "guideImage07",
                    number: "07.",
                    title: "guideTitle07".localized,
                    description: "guideDesc07".localized
                )
                GuidePageView(
                    image: "guideImage08",
                    number: "08.",
                    title: "guideTitle08".localized,
                    description: "guideDesc08".localized
                )
                GuidePageView(
                    image: "guideImage09",
                    number: "09.",
                    title: "guideTitle09".localized,
                    description: "guideDesc09".localized
                )
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .onAppear {
                userProfile.stopTracking()
            }
            .onDisappear {
                userProfile.startTracking()
            }

        }
        .navigationBarTitle("Guide".localized, displayMode: .inline)
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

struct GuidePageView: View {
    let image: String
    let number: String
    let title: String
    let description: String
    
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading) {
            Image(image)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 600)
                .padding(.top, 40)
                .colorMultiply(themeManager.currentTheme == .dark ? Color.white.opacity(0.8) : Color.white)
            
            Spacer(minLength: 20)
            
            Text(number)
                .font(.system(size: 16))
                .padding(.bottom, 5)
            Text(title)
                .font(.system(size: 36))
                .fontWeight(.bold)
                .padding(.bottom, 5)
            Text(description)
                .font(.system(size: 24))
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
        .transition(.slide)
    }
}
