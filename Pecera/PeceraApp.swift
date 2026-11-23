import SwiftUI

@main
struct PeceraApp: App {
    var body: some Scene { WindowGroup { AquariumView() } }
}

struct Food: Identifiable {
    let id = UUID()
    let x: CGFloat
    let born: Date
}

final class AquariumState: ObservableObject {
    @Published var food: [Food] = []
    @Published var happyUntil = Date.distantPast
}

struct AquariumView: View {
    @AppStorage("aquariumStart") private var start = Date().timeIntervalSince1970
    @AppStorage("lastFed") private var lastFed = 0.0
    @StateObject private var state = AquariumState()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let now = timeline.date
            let hour = Calendar.current.component(.hour, from: now)
            let lamp = hour >= 17 || hour < 6
            let daylightShade = hour < 6 || hour >= 20 ? 0.17 : (hour < 8 || hour >= 17 ? 0.07 : 0.0)
            let days = max(0, Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: start), to: now).day ?? 0)
            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    LinearGradient(colors: lamp ? [Color(red: 0.035, green: 0.12, blue: 0.20), Color(red: 0.05, green: 0.28, blue: 0.31), Color(red: 0.11, green: 0.32, blue: 0.29)] : [Color(red: 0.40, green: 0.78, blue: 0.78), Color(red: 0.16, green: 0.58, blue: 0.61), Color(red: 0.10, green: 0.38, blue: 0.39)], startPoint: .top, endPoint: .bottom)
                    Color.black.opacity(daylightShade)
                    Canvas { context, canvas in
                        drawAquarium(context: &context, size: canvas, time: now.timeIntervalSinceReferenceDate, lamp: lamp, days: days, food: state.food, now: now, happy: now < state.happyUntil)
                    }
                    Color.clear.contentShape(Rectangle()).onTapGesture {
                        state.happyUntil = Date().addingTimeInterval(3)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("MI PECERITA").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(2.5)
                                Text("Un momento de calma.").font(.system(size: 23, weight: .medium, design: .serif))
                            }
                            Spacer()
                            Image(systemName: lamp ? "lightbulb.fill" : "sun.max.fill")
                                .font(.system(size: 16)).foregroundStyle(lamp ? .yellow : .white.opacity(0.85))
                                .padding(12).background(.white.opacity(0.13), in: Circle())
                                .accessibilityLabel(lamp ? "Luz encendida" : "Luz de día")
                        }
                        Spacer()
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("DÍA \(days + 1)").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(2)
                                Text(days == 0 ? "Una nueva amistad" : "Creciendo contigo")
                                    .font(.system(size: 15, weight: .medium, design: .serif))
                            }
                            Spacer()
                            Button {
                                let x = CGFloat.random(in: 0.3...0.7)
                                state.food = (0..<5).map { _ in Food(x: x + CGFloat.random(in: -0.08...0.08), born: now.addingTimeInterval(Double.random(in: 0...0.7))) }
                                lastFed = now.timeIntervalSince1970
                            } label: {
                                Label("Alimentar", systemImage: "sparkles")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 19).padding(.vertical, 14)
                                    .background(.white.opacity(0.22), in: Capsule())
                                    .overlay(Capsule().stroke(.white.opacity(0.28), lineWidth: 1))
                            }.buttonStyle(.plain)
                        }
                    }
                    .foregroundStyle(.white).padding(.horizontal, 26).padding(.top, 18).padding(.bottom, 28)
                }.ignoresSafeArea()
                    .overlay(alignment: .top) { Color.clear.frame(height: geo.safeAreaInsets.top).allowsHitTesting(false) }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
}

func drawAquarium(context: inout GraphicsContext, size: CGSize, time: Double, lamp: Bool, days: Int, food: [Food], now: Date, happy: Bool) {
    let w = size.width, h = size.height
    if lamp {
        var glow = Path(); glow.move(to: CGPoint(x: w * 0.5, y: 0)); glow.addLine(to: CGPoint(x: w * 0.05, y: h * 0.76)); glow.addLine(to: CGPoint(x: w * 0.95, y: h * 0.76)); glow.closeSubpath()
        context.fill(glow, with: .linearGradient(Gradient(colors: [.yellow.opacity(0.16), .clear]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.8)))
    }
    for i in 0..<18 {
        let x = w * CGFloat((Double(i) * 0.173 + 0.05).truncatingRemainder(dividingBy: 1))
        let y = h - CGFloat((time * (12 + Double(i % 3) * 4) + Double(i) * 73).truncatingRemainder(dividingBy: Double(h)))
        let radius = CGFloat(2 + i % 4)
        context.stroke(Path(ellipseIn: CGRect(x: x + CGFloat(sin(time + Double(i))) * 8, y: y, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.22)), lineWidth: 1)
    }
    var floor = Path(); floor.move(to: CGPoint(x: 0, y: h * 0.88)); floor.addQuadCurve(to: CGPoint(x: w, y: h * 0.90), control: CGPoint(x: w * 0.5, y: h * 0.82)); floor.addLine(to: CGPoint(x: w, y: h)); floor.addLine(to: CGPoint(x: 0, y: h)); floor.closeSubpath()
    context.fill(floor, with: .color(Color(red: 0.72, green: 0.70, blue: 0.53).opacity(lamp ? 0.55 : 0.85)))
    for i in 0..<9 {
        let x = w * (CGFloat(i) / 8), height = h * CGFloat(0.08 + Double(i % 3) * 0.035)
        var plant = Path(); plant.move(to: CGPoint(x: x, y: h * 0.91)); plant.addQuadCurve(to: CGPoint(x: x + CGFloat(sin(time * 0.7 + Double(i))) * 9, y: h * 0.91 - height), control: CGPoint(x: x + (i % 2 == 0 ? 20 : -20), y: h * 0.85))
        context.stroke(plant, with: .color(Color(red: 0.10, green: 0.35, blue: 0.27).opacity(0.7)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
    }
    // A small treasure chest rests on the sand.
    context.drawLayer { chest in
        chest.translateBy(x: w * 0.76, y: h * 0.885)
        chest.fill(Path(ellipseIn: CGRect(x: -40, y: 14, width: 80, height: 12)), with: .color(.black.opacity(0.16)))
        let base = Path(roundedRect: CGRect(x: -32, y: -5, width: 64, height: 30), cornerRadius: 5)
        chest.fill(base, with: .color(Color(red: 0.47, green: 0.25, blue: 0.12)))
        chest.stroke(base, with: .color(Color(red: 0.27, green: 0.15, blue: 0.09)), lineWidth: 2)
        var lid = Path(); lid.move(to: CGPoint(x: -32, y: -5)); lid.addQuadCurve(to: CGPoint(x: 32, y: -5), control: CGPoint(x: 0, y: -38)); lid.closeSubpath()
        chest.fill(lid, with: .color(Color(red: 0.62, green: 0.34, blue: 0.15)))
        chest.stroke(lid, with: .color(Color(red: 0.30, green: 0.17, blue: 0.09)), lineWidth: 2)
        for x in [-19.0, 19.0] {
            chest.fill(Path(roundedRect: CGRect(x: x - 2, y: -16, width: 4, height: 39), cornerRadius: 2), with: .color(Color(red: 0.87, green: 0.68, blue: 0.31)))
        }
        chest.fill(Path(roundedRect: CGRect(x: -5, y: -2, width: 10, height: 12), cornerRadius: 2), with: .color(Color(red: 0.98, green: 0.77, blue: 0.33)))
        chest.fill(Path(ellipseIn: CGRect(x: -1.5, y: 1, width: 3, height: 3)), with: .color(.brown))
    }
    // A little plastic diver drifts behind the fish.
    context.drawLayer { diver in
        let dx = w * (0.5 + 0.32 * CGFloat(sin(time * 0.12 + 2)))
        let dy = h * (0.34 + 0.035 * CGFloat(sin(time * 0.5)))
        diver.translateBy(x: dx, y: dy)
        diver.rotate(by: .degrees(-12 + 5 * sin(time * 0.7)))
        diver.fill(Path(roundedRect: CGRect(x: -28, y: -10, width: 23, height: 15), cornerRadius: 5), with: .color(Color(red: 0.78, green: 0.60, blue: 0.28).opacity(0.7)))
        diver.fill(Path(roundedRect: CGRect(x: -19, y: -13, width: 35, height: 23), cornerRadius: 9), with: .color(Color(red: 0.13, green: 0.27, blue: 0.30).opacity(0.8)))
        diver.fill(Path(ellipseIn: CGRect(x: 8, y: -15, width: 25, height: 25)), with: .color(Color(red: 0.85, green: 0.62, blue: 0.35).opacity(0.85)))
        diver.fill(Path(ellipseIn: CGRect(x: 17, y: -10, width: 12, height: 11)), with: .color(Color(red: 0.31, green: 0.65, blue: 0.69).opacity(0.9)))
        for offset in [-1.0, 1.0] {
            var leg = Path(); leg.move(to: CGPoint(x: -15, y: offset * 6)); leg.addLine(to: CGPoint(x: -38, y: offset * (12 + 3 * sin(time * 2))))
            diver.stroke(leg, with: .color(Color(red: 0.12, green: 0.26, blue: 0.29).opacity(0.8)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            var flipper = Path(); flipper.move(to: CGPoint(x: -38, y: offset * (12 + 3 * sin(time * 2)))); flipper.addLine(to: CGPoint(x: -47, y: offset * 15))
            diver.stroke(flipper, with: .color(Color(red: 0.86, green: 0.65, blue: 0.30).opacity(0.8)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
    for pellet in food {
        let age = now.timeIntervalSince(pellet.born)
        if age >= 0 && age < 12 {
            let y = h * 0.18 + CGFloat(age) * h * 0.045
            context.fill(Path(ellipseIn: CGRect(x: pellet.x * w, y: y, width: 5, height: 5)), with: .color(.orange.opacity(age > 10 ? (12 - age) / 2 : 0.9)))
        }
    }
    let phase = time * 0.32
    let x = w * (0.5 + 0.32 * CGFloat(sin(phase)))
    let y = h * (0.48 + 0.13 * CGFloat(sin(phase * 0.67))) + (happy ? CGFloat(sin(time * 8)) * 5 : 0)
    let direction: CGFloat = cos(phase) >= 0 ? 1 : -1
    let scale = min(1.6, 1.0 + CGFloat(days) * 0.015)
    if happy {
        for i in 0..<3 {
            let rise = CGFloat((time * 20 + Double(i) * 18).truncatingRemainder(dividingBy: 55))
            context.draw(Text("♥").font(.system(size: CGFloat(13 + i * 2))).foregroundColor(.pink.opacity(0.85)), at: CGPoint(x: x + CGFloat(i - 1) * 20, y: y - 38 - rise))
        }
    }
    context.drawLayer { layer in
        layer.translateBy(x: x, y: y); layer.scaleBy(x: direction * scale, y: scale)
        var tail = Path(); tail.move(to: CGPoint(x: -35, y: 0)); tail.addQuadCurve(to: CGPoint(x: -71, y: -27), control: CGPoint(x: -57, y: -4)); tail.addQuadCurve(to: CGPoint(x: -71, y: 27), control: CGPoint(x: -62 + CGFloat(sin(time * 5)) * 5, y: 0)); tail.closeSubpath()
        layer.fill(tail, with: .color(Color(red: 0.98, green: 0.48, blue: 0.28).opacity(0.85)))
        layer.fill(Path(ellipseIn: CGRect(x: -46, y: -25, width: 100, height: 50)), with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.78, blue: 0.43), Color(red: 0.95, green: 0.42, blue: 0.25)]), startPoint: CGPoint(x: 0, y: -25), endPoint: CGPoint(x: 0, y: 25)))
        var fin = Path(); fin.move(to: CGPoint(x: -4, y: -20)); fin.addQuadCurve(to: CGPoint(x: 19, y: -23), control: CGPoint(x: 4, y: -40)); fin.closeSubpath(); layer.fill(fin, with: .color(.orange.opacity(0.8)))
        layer.fill(Path(ellipseIn: CGRect(x: 30, y: -10, width: 7, height: 7)), with: .color(Color(red: 0.12, green: 0.20, blue: 0.20)))
        layer.fill(Path(ellipseIn: CGRect(x: 32, y: -9, width: 2, height: 2)), with: .color(.white))
        var gill = Path(); gill.move(to: CGPoint(x: 19, y: -5)); gill.addQuadCurve(to: CGPoint(x: 19, y: 10), control: CGPoint(x: 25, y: 3)); layer.stroke(gill, with: .color(.brown.opacity(0.35)), lineWidth: 1.5)
    }
}
