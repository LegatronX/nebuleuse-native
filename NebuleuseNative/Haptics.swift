import UIKit

/// Le Taptic Engine : la raison d'être de cette version native.
final class Haptics {
    static let shared = Haptics()

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notification.prepare()
    }

    func lightExplosion() {
        light.impactOccurred(intensity: 0.8)
        light.prepare()
    }

    func heavyExplosion() {
        heavy.impactOccurred(intensity: 1.0)
        // double frappe : le "thud" d'un gros boss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.medium.impactOccurred(intensity: 0.9)
            self?.heavy.prepare()
            self?.medium.prepare()
        }
    }

    func errorBuzz() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }

    func mediumTap() {
        medium.impactOccurred()
        medium.prepare()
    }
}
