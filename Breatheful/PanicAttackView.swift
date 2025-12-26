import SwiftUI
import UIKit

enum GroundingStep: Int, CaseIterable {
    case introduction = 0
    case see5 = 1
    case touch4 = 2
    case hear3 = 3
    case smell2 = 4
    case taste1 = 5
    case breathing = 6
    
    var title: String {
        switch self {
        case .introduction:
            return "Panic Attack Support".localized
        case .see5:
            return "5 Things You Can See".localized
        case .touch4:
            return "4 Things You Can Touch".localized
        case .hear3:
            return "3 Things You Can Hear".localized
        case .smell2:
            return "2 Things You Can Smell".localized
        case .taste1:
            return "1 Thing You Can Taste".localized
        case .breathing:
            return "Calming Breaths".localized
        }
    }
    
    var instruction: String {
        switch self {
        case .introduction:
            return "We're going to walk through a grounding exercise to help you through this moment. Tap 'Begin' when you're ready.".localized
        case .see5:
            return "Look around you. Name 5 things you can see right now.".localized
        case .touch4:
            return "Find 4 things you can physically touch or feel.".localized
        case .hear3:
            return "Listen carefully. What are 3 sounds you can hear?".localized
        case .smell2:
            return "Try to notice 2 things you can smell right now.".localized
        case .taste1:
            return "Focus on 1 thing you can taste or imagine tasting.".localized
        case .breathing:
            return "Now let's focus on your breathing. Breathe in for 4, hold for 2, out for 6.".localized
        }
    }
    
    var buttonText: String {
        switch self {
        case .introduction:
            return "Begin".localized
        case .breathing:
            return "I'm Feeling Better".localized
        default:
            return "Continue".localized
        }
    }
    
    var imageName: String {
        switch self {
        case .introduction:
            return "heart"
        case .see5:
            return "eye"
        case .touch4:
            return "cusHand"
        case .hear3:
            return "cusEar"
        case .smell2:
            return "cusNose"
        case .taste1:
            return "cusMouth"
        case .breathing:
            return "cusWind"
        }
    }
    
    var systemImageFallback: String {
        switch self {
        case .introduction:
            return "heart.circle.fill"
        case .see5:
            return "eye.fill"
        case .touch4:
            return "hand.raised.fill"
        case .hear3:
            return "ear.fill"
        case .smell2:
            return "nose.fill"
        case .taste1:
            return "mouth.fill"
        case .breathing:
            return "lungs.fill"
        }
    }
}

struct PanicAttackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @State private var currentStep: GroundingStep = .introduction
    @StateObject private var breathingSettings = AnimationSettings()
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var circleOptionManager: CircleOptionManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // Add callback for returning to main view
    let onReturn: () -> Void
    
    // Haptic feedback generator
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    // Special breathing pattern for panic: 4-1-6-0
    private let panicBreathingMode = BreathingMode(
        id: 999,
        name: "Calm Panic",
        description: "Extended exhale to activate the parasympathetic nervous system",
        iconName: "cusWind",
        inhaleTime: 4.0,
        inhaleHoldTime: 2.0,
        exhaleTime: 6.0,
        exhaleHoldTime: 1.0
    )
    
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
    
    var circleColor: Color {
        return ColorManager.colorInfos[colorManager.selectedColorIndex].color
    }
    
    func dismissView() {
        onReturn()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if currentStep == .breathing {
                // Breathing circle screen
                breathingView
            } else {
                // Grounding instruction screen
                groundingInstructionView
            }
        }
        .onAppear {
            // Prepare feedback generator
            feedbackGenerator.prepare()
        }
        .onDisappear {
            // Stop the breathing cycle when leaving
            if currentStep == .breathing {
                breathingSettings.stopBreathingCycle()
            }
        }
    }
    
    // Breathing view shown at the final step
    private var breathingView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 60) // Push content down
            
            // Header
            Text(currentStep.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("AccentColor"))
                .padding(.top, 30)
            
            Spacer()
            
            // Breathing circle
            ZStack {
                // Use the user's custom circle design
                BreathingCircleView(
                    design: CircleStyleManager.shared.currentDesign,
                    color: circleColor,
                    scale: breathingSettings.scale,
                    size: 300
                )
                
                VStack {
                    Text(breathingSettings.currentPhase.text)
                        .font(.system(size: 24, weight: .bold))
                        .padding(.bottom, 4)
                        .foregroundColor(computedForegroundColor)
                    
                    Text(String(format: "%02d".localized, Int(breathingSettings.remainingTime)))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(computedForegroundColor)
                }
                .padding()
            }
            .onAppear {
                // Apply special breathing pattern
                breathingSettings.currentMode = panicBreathingMode
                breathingSettings.startBreathingCycle()
                
                // Prepare feedback generator
                feedbackGenerator.prepare()
            }
            
            Spacer()
            
            // Complete button
            Button(action: {
                feedbackGenerator.notificationOccurred(.success)
                dismissView()
            }) {
                Text(currentStep.buttonText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(circleColor)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                }
            .padding(.bottom, 30)
        }
    }
    
    // Grounding instruction view shown for steps 0-5
    private var groundingInstructionView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40) // Push content down
            
            // Image at top
            imageForCurrentStep
                .padding(.top, 20)
            
            // Header
            Text(currentStep.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("AccentColor"))
                .padding(.top, 20)
            
            // Instruction text with reduced spacing
            Text(currentStep.instruction)
                .font(.system(size: 20))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 10)
                .foregroundColor(Color("AccentColor"))
            
            Spacer()
            
            // Progress dots
            if currentStep != .introduction {
                HStack(spacing: 8) {
                    ForEach(GroundingStep.allCases.dropLast(), id: \.rawValue) { step in
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue ? circleColor : circleColor.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
            }
            
            // Navigation buttons
            VStack(spacing: 16) {
                Button(action: {
                    // Advance to next step
                    feedbackGenerator.notificationOccurred(.success)
                    currentStep = GroundingStep(rawValue: currentStep.rawValue + 1) ?? .breathing

                }) {
                    Text(currentStep.buttonText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(circleColor)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                }
                
                // Back button
                Button(action: {
                    feedbackGenerator.notificationOccurred(.warning)
                    if currentStep == .introduction {
                        dismissView()
                    } else {
                        currentStep = GroundingStep(rawValue: currentStep.rawValue - 1) ?? .introduction
                    }
                }) {
                    Text(currentStep == .introduction ? "Return to Breathing".localized : "Back".localized)
                        .font(.system(size: 16))
                        .foregroundColor(Color("AccentColor"))
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    // Custom image view using app's custom images
    private var imageForCurrentStep: some View {
        Image(systemName: currentStep.systemImageFallback)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(Color("AccentColor"))
            .frame(width: 120, height: 120)
    }
}

// Preview
struct PanicAttackView_Previews: PreviewProvider {
    static var previews: some View {
        PanicAttackView(onReturn: {})
            .environmentObject(ColorManager())
            .environmentObject(CircleOptionManager())
            .environmentObject(ThemeManager())
    }
} 
