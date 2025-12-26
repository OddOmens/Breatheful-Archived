import SwiftUI

struct VoiceView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var colorManager: ColorManager
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var settings: AnimationSettings
    
    var body: some View {
        VStack {
            List {
                // Breathing Cues Section
                Section(header: Text("Breathing Cue Voices").padding(.horizontal, 10).padding(.vertical, 5).glassEffect()) {
                    ForEach(VoiceOption.breathingCuesOptions, id: \.id) { option in
                        VoiceOptionRow(option: option, isSelected: settings.voiceOption == option && !settings.isPlayingStory)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .onTapGesture {
                                // Stop any playing stories
                                AudioCueManager.shared.stopAllStories()
                                settings.isPlayingStory = false
                                
                                // Set the new voice option
                                settings.voiceOption = option
                                UserDefaults.standard.set(option.rawValue, forKey: "voiceOption")
                                
                                // Play a sample of the selected voice
                                if option != .none {
                                    AudioCueManager.shared.playBreathCue(.inhale, voiceOption: option)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .padding(.bottom, 10)
                    }
                }
                
                // Relaxation Stories Section
                Section(header: Text("Timed Guided Sessions").padding(.horizontal, 10).padding(.vertical, 5).glassEffect()) {
                    Text("Listen to a guided session with one of the voices. These will play once and automatically switch back to \"No Guide\" when finished.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    
                    ForEach(VoiceOption.storyOptions, id: \.id) { option in
                        StoryOptionRow(option: option, isPlaying: settings.voiceOption == option && settings.isPlayingStory)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .onTapGesture {
                                if settings.isPlayingStory {
                                    // Stop playing story if one is already playing
                                    AudioCueManager.shared.stopAllStories()
                                    settings.isPlayingStory = false
                                    settings.voiceOption = .none
                                    UserDefaults.standard.set(VoiceOption.none.rawValue, forKey: "voiceOption")
                                } else {
                                    // Play the selected story
                                    settings.playStory(option: option)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .padding(.bottom, 10)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationBarTitle("Voice Options".localized, displayMode: .inline)
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

struct VoiceOptionRow: View {
    let option: VoiceOption
    let isSelected: Bool
    
    @EnvironmentObject var colorManager: ColorManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(option.rawValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("AccentColor"))
                
                Text(voiceDescription(for: option))
                    .font(.system(size: 14))
                    .foregroundColor(Color("AccentColor"))
                    .lineLimit(2)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            
            Spacer()
            
            Image(systemName: voiceIcon(for: option))
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color("AccentColor"))
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(.trailing)
        }
        .background(Color("AccentColor").opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? ColorManager.colorInfos[colorManager.selectedColorIndex].color : Color.clear, lineWidth: 2)
        )
    }
    
    private func voiceDescription(for option: VoiceOption) -> String {
        switch option {
        case .none:
            return "No voice guidance during breathing exercises"
        case .kai:
            return "Calm, soothing masculine voice for focused breathing"
        case .zen:
            return "Peaceful, meditative masculine voice for relaxation"
        case .luma:
            return "Gentle, bright feminine voice for uplifting sessions"
        case .amara:
            return "Soft, nurturing feminine voice for deep relaxation"
        default:
            return ""
        }
    }
    
    private func voiceIcon(for option: VoiceOption) -> String {
        switch option {
        case .none:
            return "speaker.slash"
        case .kai, .zen:
            return "waveform"
        case .luma, .amara:
            return "waveform.and.mic"
        default:
            return "speaker.slash"
        }
    }
}

struct StoryOptionRow: View {
    let option: VoiceOption
    let isPlaying: Bool
    
    @EnvironmentObject var colorManager: ColorManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(option.rawValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("AccentColor"))
                
                Text(storyDescription(for: option))
                    .font(.system(size: 14))
                    .foregroundColor(Color("AccentColor"))
                    .lineLimit(2)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            
            Spacer()
            
            Image(systemName: isPlaying ? "pause.circle" : "play.circle")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color("AccentColor"))
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(.trailing)
        }
        .background(Color("AccentColor").opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isPlaying ? ColorManager.colorInfos[colorManager.selectedColorIndex].color : Color.clear, lineWidth: 2)
        )
    }
    
    private func storyDescription(for option: VoiceOption) -> String {
        switch option {
        case .lumaOneMin:
            return "One minute guided breathing with Luma's voice"
        case .lumaTwoMin:
            return "Two minute guided breathing with Luma's voice"
        case .lumaFiveMin:
            return "Five minute guided breathing with Luma's voice"
        case .kaiOneMin:
            return "One minute guided breathing with Kai's voice"
        case .kaiTwoMin:
            return "Two minute guided breathing with Kai's voice"
        case .kaiFiveMin:
            return "Five minute guided breathing with Kai's voice"
        default:
            return ""
        }
    }
} 
