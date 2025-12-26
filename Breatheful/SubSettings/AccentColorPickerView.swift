import SwiftUI

struct AccentColorPickerView: View {
    @ObservedObject var colorManager: ColorManager
    @Environment(\.presentationMode) var presentationMode
    let colorInfos: [ColorInfo]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Select Your Accent Color")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AccentColor"))
                    .padding(.top)
                
                Text("Choose the accent color for your app interface")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 20) {
                    ForEach(colorInfos.indices, id: \.self) { index in
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            colorManager.selectedColorIndex = index
                        } label: {
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colorInfos[index].color)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(colorManager.selectedColorIndex == index ? Color("AccentColor") : Color.clear, lineWidth: 3)
                                    )
                                    .shadow(color: colorInfos[index].color.opacity(0.3), radius: colorManager.selectedColorIndex == index ? 8 : 4)
                                
                                Text(colorInfos[index].name)
                                    .font(.caption)
                                    .foregroundColor(Color("AccentColor"))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                        }
                        .scaleEffect(colorManager.selectedColorIndex == index ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: colorManager.selectedColorIndex)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .navigationBarTitle("Accent Color", displayMode: .inline)
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