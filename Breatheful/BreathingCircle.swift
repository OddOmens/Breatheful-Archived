import SwiftUI

enum CircleDesign: String, Codable, CaseIterable {
    case stroked = "circleDesign_stroked"
    case strokedGlow = "circleDesign_strokedGlow"
    case expandingRings = "circleDesign_expandingRings"
    case expandingRingsGlow = "circleDesign_expandingRingsGlow"
    case breeze = "circleDesign_breeze"
    case breezeGlow = "circleDesign_breezeGlow"
    case dots = "circleDesign_dots"
    case dotsGlow = "circleDesign_dotsGlow"
    case dashed = "circleDesign_dashed"
    case dashedGlow = "circleDesign_dashedGlow"
    case filled = "circleDesign_filled"
    case filledGlow = "circleDesign_filledGlow"
    case filledGradient = "circleDesign_filledGradient"
    case filledGradientGlow = "circleDesign_filledGradientGlow"
    case verticalMirroredDots = "circleDesign_verticalMirroredDots"
    case horizontalMirroredDots = "circleDesign_horizontalMirroredDots"
    case verticalMirroredLines = "circleDesign_verticalMirroredLines"
    case horizontalMirroredLines = "circleDesign_horizontalMirroredLines"
    case none = "circleDesign_none"



    var localizedName: String {
        NSLocalizedString(self.rawValue, comment: "")
    }
}
struct BreathingCircleView: View {
    let design: CircleDesign
    let color: Color
    let scale: CGFloat
    let size: CGFloat
    
    var body: some View {
        Group {
            switch design {
            case .none:
                Color.clear
                    .frame(width: size, height: size)
                    .scaleEffect(scale)

            case .stroked:
                Circle()
                    .stroke(lineWidth: size/15)
                    .foregroundColor(color)
                    .scaleEffect(scale)
                
            case .strokedGlow:
                Circle()
                    .stroke(lineWidth: size/15)
                    .foregroundColor(color)
                    .blur(radius: size/50)
                    .scaleEffect(scale)
                
            case .expandingRings:
                ZStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(lineWidth: size/30)
                            .foregroundColor(color.opacity(1 - Double(index) * 0.35))
                            .scaleEffect(0.8 + Double(index) * 0.2)
                    }
                }
                .scaleEffect(scale)
                
                
            case .expandingRingsGlow:
                ZStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(lineWidth: size/30)
                            .foregroundColor(color.opacity(1 - Double(index) * 0.35))
                            .scaleEffect(0.8 + Double(index) * 0.2)
                    }
                }
                .blur(radius: size/50)
                .scaleEffect(scale)
                
                
            case .dots:
                ZStack {
                    ForEach(0..<12) { index in
                        Circle()
                            .frame(width: size/30, height: size/30)
                            .offset(x: -size/2)
                            .rotationEffect(.degrees(Double(index) * 30))
                            .foregroundColor(color)
                    }
                }
                .scaleEffect(scale)
                
            case .dotsGlow:
                ZStack {
                    ForEach(0..<12) { index in
                        Circle()
                            .frame(width: size/30, height: size/30)
                            .offset(x: -size/2)
                            .rotationEffect(.degrees(Double(index) * 30))
                            .foregroundColor(color)
                            .blur(radius: size/50)
                    }
                }
                .scaleEffect(scale)
                
            case .dashed:
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: size/15, dash: [5, 14]))
                    .foregroundColor(color)
                    .scaleEffect(scale)
                
            case .dashedGlow:
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: size/15, dash: [5, 14]))
                    .foregroundColor(color)
                    .scaleEffect(scale)
                    .blur(radius: size/50)
                
            case .filled:
                Circle()
                    .fill(color)
                    .scaleEffect(scale)
                
            case .filledGlow:
                Circle()
                    .fill(color)
                    .blur(radius: size/50)
                    .scaleEffect(scale)
                
            case .filledGradient:
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.8), color.opacity(0.2)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(scale)
                
            case .filledGradientGlow:
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.8), color.opacity(0.2)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blur(radius: size/50)
                    .scaleEffect(scale)
                
            case .verticalMirroredDots:
                ZStack {
                    Circle()
                        .frame(width: size/30, height: size/30)
                        .offset(y: -size/2)
                        .foregroundColor(color)
                    Circle()
                        .frame(width: size/30, height: size/30)
                        .offset(y: size/2)
                        .foregroundColor(color)
                }
                .scaleEffect(scale)
                
            case .horizontalMirroredDots:
                ZStack {
                    Circle()
                        .frame(width: size/30, height: size/30)
                        .offset(x: -size/2)
                        .foregroundColor(color)
                    Circle()
                        .frame(width: size/30, height: size/30)
                        .offset(x: size/2)
                        .foregroundColor(color)
                }
                .scaleEffect(scale)
                
            case .verticalMirroredLines:
                ZStack {
                    Rectangle()
                        .frame(width: size/60, height: size/6)
                        .offset(y: -size/2)
                        .foregroundColor(color)
                    Rectangle()
                        .frame(width: size/60, height: size/6)
                        .offset(y: size/2)
                        .foregroundColor(color)
                }
                .scaleEffect(scale)
                
            case .horizontalMirroredLines:
                ZStack {
                    Rectangle()
                        .frame(width: size/6, height: size/60)
                        .offset(x: -size/2)
                        .foregroundColor(color)
                    Rectangle()
                        .frame(width: size/6, height: size/60)
                        .offset(x: size/2)
                        .foregroundColor(color)
                }
                .scaleEffect(scale)
                
            case .breeze:
                Circle()
                    .stroke(lineWidth: size/15)
                    .foregroundColor(color.opacity(scale - 0.5))
                    .scaleEffect(scale)
                
            case .breezeGlow:
                Circle()
                    .stroke(lineWidth: size/15)
                    .foregroundColor(color.opacity(scale - 0.5))
                    .blur(radius: size/50)
                    .scaleEffect(scale)
                

            }

        }
        .frame(width: size, height: size)
    }
}


// RotatingDots.swift
struct RotatingDots: View {
    @State private var rotationAngle: Double = 0
    var scale: CGFloat
    var color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 0, dash: [00, 0]))
                .foregroundColor(color)
                .scaleEffect(scale)
            ForEach(0..<12) { index in
                Circle()
                    .frame(width: 10, height: 10)
                    .offset(x: -180)  // Adjust this value to position the dot along the edge of the circle
                    .rotationEffect(Angle(degrees: Double(index) * 30))
                    .foregroundColor(color)
            }
        }
        .scaleEffect(scale)
    }
}

struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let path = Path { p in
            let width = rect.width
            let height = rect.height
            let midHeight = height / 2
            
            p.move(to: CGPoint(x: 0, y: midHeight))
            
            for x in stride(from: 0, through: width, by: 1) {
                let relativeX = x / width
                let sine = sin(2 * .pi * (relativeX * frequency + phase))
                let y = midHeight + amplitude * sine
                p.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}
