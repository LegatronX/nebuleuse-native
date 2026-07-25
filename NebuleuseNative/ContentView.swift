import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var playing = false
    @State private var scene = GameScene()

    var body: some View {
        ZStack {
            if playing {
                SpriteView(scene: scene, preferredFramesPerSecond: 120)
                    .ignoresSafeArea()
                    .onAppear { scene.startGame() }
            } else {
                menu
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    private var menu: some View {
        ZStack {
            Image("bg-nebula")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.45))
            VStack(spacing: 18) {
                Spacer()
                Text("NÉBULEUSE\nPROTOCOL IV")
                    .font(.system(size: 40, weight: .ultraLight, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 18)
                Text("ÉDITION NATIVE · v0.1")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(.cyan.opacity(0.8))
                Spacer()
                Button {
                    Haptics.shared.mediumTap()
                    playing = true
                } label: {
                    Text("JOUER")
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .tracking(6)
                        .padding(.horizontal, 56)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                                .shadow(color: .cyan.opacity(0.7), radius: 16)
                        )
                        .foregroundStyle(.black)
                }
                Text("Glissez pour piloter · tir automatique\nRessentez chaque explosion")
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 8)
                Spacer().frame(height: 40)
            }
        }
    }
}
