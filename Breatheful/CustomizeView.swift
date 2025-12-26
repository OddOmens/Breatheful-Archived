import SwiftUI

struct CustomizeView: View {
    @EnvironmentObject var circleOptionManager: CircleOptionManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var userProfile: UserProfile
    @Environment(\.presentationMode) var presentationMode
    @State private var isDarkMode: Bool = false
    @ObservedObject private var viewModel = SettingsViewModel()
    
    var computedForegroundColor: Color {
        let selectedColor = ColorManager.colorInfos[colorManager.selectedColorIndex].color
        if selectedColor == Color("colorDefault") && isDarkMode {
            return Color.black
        } else {
            return Color.white
        }
    }
    
    var body: some View {
        List {
            // Theme Settings
            Section(header: Text("Theme").padding(.horizontal, 10).padding(.vertical, 5).glassEffect()) {
                // Dark Theme Toggle
                HStack {
                    Image(isDarkMode ? "lightbulb-alt-off" : "lightbulb-alt-on")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(computedForegroundColor)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(6)
                        .background(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                        .cornerRadius(80)
                    
                    Text("Dark Theme")
                    
                    Spacer()
                    
                    Toggle(isOn: $isDarkMode) {
                    }.tint(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                    .onChange(of: isDarkMode) { oldValue, newValue in
                        themeManager.currentTheme = newValue ? .dark : .light
                    }
                }
                
                // Accent Color Picker
                HStack {
                    Image("palette")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(computedForegroundColor)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(6)
                        .background(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                        .cornerRadius(80)
                    
                    Picker("Accent Color".localized, selection: $colorManager.selectedColorIndex) {
                        ForEach(ColorManager.colorInfos.indices, id: \.self) { index in
                            HStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundColor(ColorManager.colorInfos[index].color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black, lineWidth: 1)
                                    )
                                Text(ColorManager.colorInfos[index].name)
                            }
                            .tag(index)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .accentColor(Color("AccentColor")) 
                }
                
                // Icon Picker Navigation
                NavigationLink {
                    IconPickerView()
                } label: {
                    HStack {
                        Image("glasses")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(computedForegroundColor)
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(6)
                            .background(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                            .cornerRadius(80)
                        Text("Custom App Icon")
                            .foregroundColor(Color("AccentColor"))
                    }
                }
            }
            
            // Display Options
            Section(header: Text("Display Options").padding(.horizontal, 10).padding(.vertical, 5).glassEffect()) {
                // Show Guide Toggle
                HStack {
                    Image("annotation")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(computedForegroundColor)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(6)
                        .background(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                        .cornerRadius(80)
                    Toggle(isOn: $viewModel.isGuideEnabled) {
                        Text("Show Guide".localized)
                    }.tint(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                }
                
                /*HStack {
                    Image("annotation")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(computedForegroundColor)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(6)
                        .background(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                        .cornerRadius(80)
                    Toggle(isOn: $viewModel.isProfileEnabled) {
                        Text("Show Profile".localized)
                    }.tint(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                }*/
                
                HStack {
                    Image("annotation")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(computedForegroundColor)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(6)
                        .background(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                        .cornerRadius(80)
                    Toggle(isOn: $viewModel.areTextGuideEnabled) {
                        Text("Show Inhale and Exhale Text".localized)
                    }.tint(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                }
                
                // Show Phrases Toggle
                HStack {
                    Image("annotation")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(computedForegroundColor)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(6)
                        .background(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                        .cornerRadius(80)
                    Toggle(isOn: $viewModel.arePhrasesEnabled) {
                        Text("Show Phrases".localized)
                            .foregroundColor(Color("AccentColor"))
                    }.tint(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                }
            }
            
            // Breathing Circle Customization
            Section(header: Text("Breathing Circle").padding(.horizontal, 10).padding(.vertical, 5).glassEffect()) {
                // Guide Style Navigation
                NavigationLink {
                    BreathingGuidePreviewView(colorManager: colorManager, colorInfos: ColorManager.colorInfos)
                } label: {
                    HStack {
                        Image("brush")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(computedForegroundColor)
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(6)
                            .background(ColorManager.colorInfos[colorManager.selectedColorIndex].color)
                            .cornerRadius(80)
                        Text("Guide Style")
                            .foregroundColor(Color("AccentColor"))
                    }
                }
            }
        }
        .listRowBackground(Color.clear)
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .navigationTitle("Customize")
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
        .onAppear {
            isDarkMode = themeManager.currentTheme == .dark
        }
    }
}
