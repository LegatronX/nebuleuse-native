import SpriteKit
import UIKit

final class GameScene: SKScene {

    // MARK: - État
    private var playing = false
    private var gameOver = false
    private var score = 0
    private var hull = 3
    private var kills = 0
    private var fireCd: TimeInterval = 0
    private var spawnT: TimeInterval = 1.2
    private var lastUpdate: TimeInterval = 0
    private var elapsed: TimeInterval = 0

    // MARK: - Nœuds
    private let world = SKNode()
    private var player: SKShapeNode!
    private var scoreLabel: SKLabelNode!
    private var hullLabel: SKLabelNode!
    private var messageLabel: SKLabelNode?
    private var bullets: [SKShapeNode] = []
    private var enemies: [Enemy] = []

    private struct Enemy {
        let node: SKShapeNode
        var hp: Int
        let kind: Kind
        var t: TimeInterval = 0
        let baseX: CGFloat
        enum Kind { case drone, zig, tank }
    }

    // MARK: - Cycle de vie
    override func didMove(to view: SKView) {
        backgroundColor = .black
        scaleMode = .resizeFill
        addChild(world)
        setupBackground()
        setupStars()
        setupPlayer()
        setupHUD()
    }

    override var size: CGSize {
        didSet { if size != oldValue { layoutForSize() } }
    }

    private func layoutForSize() {
        scoreLabel?.position = CGPoint(x: size.width / 2, y: size.height - 60)
        hullLabel?.position = CGPoint(x: size.width / 2, y: 34)
        player?.position.y = size.height * 0.16
    }

    // MARK: - Setup
    private func setupBackground() {
        let tex = SKTexture(imageNamed: "bg-nebula")
        let bg = SKSpriteNode(texture: tex)
        let scale = max(size.width / tex.size().width, size.height / tex.size().height)
        bg.setScale(scale)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -100
        bg.alpha = 0.85
        world.addChild(bg)
        let veil = SKSpriteNode(color: .black, size: size)
        veil.alpha = 0.35
        veil.position = CGPoint(x: size.width / 2, y: size.height / 2)
        veil.zPosition = -99
        world.addChild(veil)
    }

    private func setupStars() {
        let stars = SKEmitterNode()
        stars.particleBirthRate = 8
        stars.particleLifetime = 6
        stars.particleSpeed = 30
        stars.particleSpeedRange = 40
        stars.emissionAngle = -.pi / 2
        stars.emissionAngleRange = 0.2
        stars.particleSize = CGSize(width: 2, height: 2)
        stars.particleColor = .white
        stars.particleAlpha = 0.7
        stars.particleColorSequence = nil
        stars.particlePositionRange = CGVector(dx: size.width, dy: 0)
        stars.position = CGPoint(x: size.width / 2, y: size.height + 10)
        stars.particleZPosition = -50
        stars.advanceSimulationTime(6)
        world.addChild(stars)
    }

    private func setupPlayer() {
        let ship = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 18))
        path.addLine(to: CGPoint(x: 14, y: -12))
        path.addLine(to: CGPoint(x: 0, y: -5))
        path.addLine(to: CGPoint(x: -14, y: -12))
        path.closeSubpath()
        ship.path = path
        ship.fillColor = UIColor(red: 0.3, green: 0.9, blue: 1, alpha: 1)
        ship.strokeColor = .white
        ship.lineWidth = 1.5
        ship.glowWidth = 4
        ship.position = CGPoint(x: size.width / 2, y: size.height * 0.16)
        ship.zPosition = 10
        world.addChild(ship)
        player = ship

        // traînée moteur
        let trail = SKEmitterNode()
        trail.particleBirthRate = 30
        trail.particleLifetime = 0.35
        trail.particleSpeed = 60
        trail.emissionAngle = -.pi / 2
        trail.emissionAngleRange = 0.3
        trail.particleSize = CGSize(width: 4, height: 4)
        trail.particleColor = UIColor(red: 0.4, green: 0.8, blue: 1, alpha: 1)
        trail.particleAlpha = 0.6
        trail.particleAlphaSpeed = -1.8
        trail.position = CGPoint(x: 0, y: -12)
        ship.addChild(trail)
    }

    private func setupHUD() {
        scoreLabel = SKLabelNode(text: "0")
        scoreLabel.fontName = "Menlo-Bold"
        scoreLabel.fontSize = 22
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 60)
        scoreLabel.zPosition = 100
        addChild(scoreLabel)

        hullLabel = SKLabelNode(text: "♥♥♥")
        hullLabel.fontName = "Menlo"
        hullLabel.fontSize = 18
        hullLabel.fontColor = UIColor(red: 1, green: 0.4, blue: 0.5, alpha: 1)
        hullLabel.position = CGPoint(x: size.width / 2, y: 34)
        hullLabel.zPosition = 100
        addChild(hullLabel)
    }

    // MARK: - Démarrage
    func startGame() {
        playing = true
        gameOver = false
        score = 0
        hull = 3
        kills = 0
        elapsed = 0
        fireCd = 0
        spawnT = 1.2
        for b in bullets { b.removeFromParent() }
        bullets.removeAll()
        for e in enemies { e.node.removeFromParent() }
        enemies.removeAll()
        messageLabel?.removeFromParent()
        messageLabel = nil
        player.isHidden = false
        player.position = CGPoint(x: size.width / 2, y: size.height * 0.16)
        updateHUD()
        AudioManager.shared.playMusic()
    }

    // MARK: - Tactile
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameOver {
            Haptics.shared.mediumTap()
            startGame()
            return
        }
        guard playing, let t = touches.first else { return }
        movePlayer(to: t.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard playing, !gameOver, let t = touches.first else { return }
        movePlayer(to: t.location(in: self))
    }

    private func movePlayer(to p: CGPoint) {
        let clampedX = min(max(p.x, 24), size.width - 24)
        player.position.x = clampedX
    }

    // MARK: - Boucle
    override func update(_ currentTime: TimeInterval) {
        guard playing, !gameOver else { lastUpdate = currentTime; return }
        var dt = currentTime - lastUpdate
        lastUpdate = currentTime
        if dt > 0.05 { dt = 0.05 }
        elapsed += dt

        updateFiring(dt)
        updateSpawning(dt)
        updateBullets(dt)
        updateEnemies(dt)
        updateCollisions()
    }

    private func updateFiring(_ dt: TimeInterval) {
        fireCd -= dt
        if fireCd <= 0 {
            fireCd = 0.22
            fireBullet(at: CGPoint(x: player.position.x - 6, y: player.position.y + 16))
            fireBullet(at: CGPoint(x: player.position.x + 6, y: player.position.y + 16))
        }
    }

    private func fireBullet(at p: CGPoint) {
        let b = SKShapeNode(circleOfRadius: 3)
        b.fillColor = .cyan
        b.strokeColor = .clear
        b.glowWidth = 3
        b.position = p
        b.zPosition = 5
        world.addChild(b)
        bullets.append(b)
    }

    private func updateBullets(_ dt: TimeInterval) {
        let speed: CGFloat = 760
        for b in bullets { b.position.y += speed * dt }
        let off = bullets.filter { $0.position.y > size.height + 20 }
        for b in off { b.removeFromParent() }
        bullets.removeAll { $0.position.y > size.height + 20 }
    }

    private func updateSpawning(_ dt: TimeInterval) {
        spawnT -= dt
        if spawnT > 0 { return }
        // la cadence monte avec le score : la tension grimpe
        spawnT = max(0.5, 1.3 - Double(kills) * 0.02)
        let roll = Int.random(in: 0..<10)
        if kills > 6 && roll < 3 { spawnEnemy(.tank) }
        else if roll < 5 { spawnEnemy(.zig) }
        else { spawnEnemy(.drone) }
    }

    private func spawnEnemy(_ kind: Enemy.Kind) {
        let x = CGFloat.random(in: 40...(size.width - 40))
        let node: SKShapeNode
        var hp: Int
        switch kind {
        case .drone:
            node = SKShapeNode(circleOfRadius: 11)
            node.fillColor = UIColor(red: 1, green: 0.5, blue: 0.4, alpha: 1)
            hp = 3
        case .zig:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: -12))
            path.addLine(to: CGPoint(x: 10, y: 8))
            path.addLine(to: CGPoint(x: -10, y: 8))
            path.closeSubpath()
            node = SKShapeNode(path: path)
            node.fillColor = UIColor(red: 0.9, green: 0.4, blue: 1, alpha: 1)
            hp = 5
        case .tank:
            node = SKShapeNode(rectOf: CGSize(width: 30, height: 30), cornerRadius: 6)
            node.fillColor = UIColor(red: 1, green: 0.7, blue: 0.2, alpha: 1)
            hp = 12
        }
        node.strokeColor = .white
        node.lineWidth = 1
        node.glowWidth = 2
        node.position = CGPoint(x: x, y: size.height + 30)
        node.zPosition = 8
        world.addChild(node)
        enemies.append(Enemy(node: node, hp: hp, kind: kind, baseX: x))
    }

    private func updateEnemies(_ dt: TimeInterval) {
        var toRemove: [Int] = []
        for i in enemies.indices {
            var e = enemies[i]
            e.t += dt
            let speed: CGFloat = e.kind == .tank ? 60 : e.kind == .zig ? 130 : 170
            e.node.position.y -= speed * dt
            if e.kind == .zig {
                e.node.position.x = e.baseX + sin(e.t * 3) * 60
            }
            enemies[i] = e
            if e.node.position.y < -40 {
                e.node.removeFromParent()
                toRemove.append(i)
            }
        }
        for i in toRemove.reversed() { enemies.remove(at: i) }
    }

    private func updateCollisions() {
        // balles ↔ ennemis
        var deadBullets: [SKShapeNode] = []
        var deadEnemies: [Int] = []
        for b in bullets {
            for (i, e) in enemies.enumerated() {
                let d = hypot(e.node.position.x - b.position.x, e.node.position.y - b.position.y)
                if d < 22 {
                    deadBullets.append(b)
                    var hit = e
                    hit.hp -= 1
                    enemies[i] = hit
                    if hit.hp <= 0 { deadEnemies.append(i) }
                    break
                }
            }
        }
        for b in deadBullets {
            b.removeFromParent()
            bullets.removeAll { $0 === b }
        }
        for i in deadEnemies.sorted().reversed() {
            killEnemy(at: i)
        }
        // ennemis ↔ joueur
        var rammed: [Int] = []
        for (i, e) in enemies.enumerated() {
            let d = hypot(e.node.position.x - player.position.x, e.node.position.y - player.position.y)
            if d < 26 { rammed.append(i) }
        }
        for i in rammed.sorted().reversed() {
            let pos = enemies[i].node.position
            enemies[i].node.removeFromParent()
            enemies.remove(at: i)
            explosion(at: pos, big: false)
            damagePlayer()
        }
    }

    private func killEnemy(at index: Int) {
        let e = enemies[index]
        let pos = e.node.position
        e.node.removeFromParent()
        enemies.remove(at: index)
        kills += 1
        score += e.kind == .tank ? 300 : e.kind == .zig ? 150 : 100
        explosion(at: pos, big: e.kind == .tank)
        updateHUD()
    }

    private func damagePlayer() {
        hull -= 1
        Haptics.shared.errorBuzz()
        flashRed()
        updateHUD()
        if hull <= 0 {
            gameOver = true
            playing = false
            explosion(at: player.position, big: true)
            player.isHidden = true
            showGameOver()
        }
    }

    // MARK: - Effets
    private func explosion(at p: CGPoint, big: Bool) {
        let boom = SKEmitterNode()
        boom.particleBirthRate = 400
        boom.numParticlesToEmit = big ? 60 : 24
        boom.particleLifetime = big ? 0.8 : 0.45
        boom.particleSpeed = big ? 220 : 140
        boom.particleSpeedRange = 80
        boom.emissionAngleRange = .pi * 2
        boom.particleSize = CGSize(width: big ? 7 : 5, height: big ? 7 : 5)
        boom.particleColor = UIColor(red: 1, green: 0.7, blue: 0.3, alpha: 1)
        boom.particleAlpha = 1
        boom.particleAlphaSpeed = -2
        boom.position = p
        boom.zPosition = 50
        world.addChild(boom)
        boom.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.removeFromParent()
        ]))
        // haptique : c'est ici que le natif parle
        if big {
            Haptics.shared.heavyExplosion()
            shakeWorld(intensity: 8)
        } else {
            Haptics.shared.lightExplosion()
            shakeWorld(intensity: 3)
        }
    }

    private func shakeWorld(intensity: CGFloat) {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: intensity, y: -intensity, duration: 0.03),
            SKAction.moveBy(x: -intensity * 2, y: intensity * 2, duration: 0.05),
            SKAction.moveBy(x: intensity, y: -intensity, duration: 0.03)
        ])
        world.run(shake)
    }

    private func flashRed() {
        let flash = SKSpriteNode(color: UIColor.red.withAlphaComponent(0.35), size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 200
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }

    private func showGameOver() {
        let msg = SKLabelNode(text: "SIGNAL PERDU")
        msg.fontName = "Menlo-Bold"
        msg.fontSize = 30
        msg.fontColor = .white
        msg.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        msg.zPosition = 300
        addChild(msg)
        let sub = SKLabelNode(text: "Score : \(score) — touchez pour rejouer")
        sub.fontName = "Menlo"
        sub.fontSize = 14
        sub.fontColor = .cyan
        sub.position = CGPoint(x: size.width / 2, y: size.height * 0.55 - 40)
        sub.zPosition = 300
        addChild(sub)
        messageLabel = msg
    }

    private func updateHUD() {
        scoreLabel.text = "\(score)"
        hullLabel.text = String(repeating: "♥", count: max(hull, 0))
    }
}
