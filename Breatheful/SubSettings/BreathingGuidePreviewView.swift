import SwiftUI
import CoreData
import CloudKit

class CircleStyleManager: ObservableObject {
    static let shared = CircleStyleManager()
    
    @Published var designs: [CircleDesign] = CircleDesign.allCases
    @Published var currentDesign: CircleDesign = .stroked
    
    init() {
        if let savedDesign = UserDefaults.standard.string(forKey: "selectedCircleDesign"),
           let design = CircleDesign(rawValue: savedDesign) {
            currentDesign = design
        }
    }
}

struct BreathingGuidePreview: View {
    let design: CircleDesign
    let color: Color
    let isSelected: Bool
    
    let previewSize: CGFloat = 120
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            BreathingCircleView(
                design: design,
                color: color,
                scale: isAnimating ? 0.8 : 0.5,
                size: previewSize
            )
            
            Text(design.localizedName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("AccentColor"))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? color.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? color : Color.clear, lineWidth: 2)
        )
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct BreathingGuidePreviewView: View {
    @StateObject private var styleManager = CircleStyleManager.shared
    @ObservedObject var colorManager: ColorManager
    @Environment(\.presentationMode) var presentationMode
    let colorInfos: [ColorInfo]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Select Your Breathing Guide Style")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AccentColor"))
                    .padding(.top)
                
                Text("Choose how your breathing guide will look during exercises")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 20) {
                    ForEach(styleManager.designs, id: \.self) { design in
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            styleManager.currentDesign = design
                            UserDefaults.standard.set(design.rawValue, forKey: "selectedCircleDesign")
                        } label: {
                            BreathingGuidePreview(
                                design: design,
                                color: colorInfos[colorManager.selectedColorIndex].color,
                                isSelected: styleManager.currentDesign == design
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .navigationBarTitle("Guide Style", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                presentationMode.wrappedValue.dismiss()
            }) {
                Image("arrow-left")
                    .renderingMode(.template)
                    .foregroundColor(Color("AccentColor"))
            }
        )
    }
}

