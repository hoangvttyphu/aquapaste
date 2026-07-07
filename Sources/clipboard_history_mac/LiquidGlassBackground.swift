import SwiftUI

struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)

            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.20).opacity(0.88),
                    Color(red: 0.10, green: 0.16, blue: 0.28).opacity(0.78),
                    Color(red: 0.08, green: 0.10, blue: 0.18).opacity(0.84),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.30),
                            Color.white.opacity(0.02),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: -180, y: -150)
                .blur(radius: 18)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.26),
                            Color.purple.opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: 220, y: 180)
                .blur(radius: 26)

            VStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.28),
                        Color.white.opacity(0.03),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 110)
                .blur(radius: 10)

                Spacer()
            }
        }
    }
}

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
    }
}
