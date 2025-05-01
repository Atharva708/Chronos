import SwiftUI

// MARK: - Theme Model
struct AppTheme: Identifiable {
    let id = UUID()
    let name: String
    let uiAccent: Color
    let background: Color
    let text: Color
    let trophyCost: Int
    let easterEgg: String
    let icon: String
    
    static let defaultTheme = AppTheme(
        name: "Default",
        uiAccent: .blue,
        background: .white,
        text: .black,
        trophyCost: 0,
        easterEgg: "A classic look for your tasks",
        icon: "paintbrush.fill"
    )
    
    static let ocean = AppTheme(
        name: "Ocean",
        uiAccent: .blue,
        background: Color(red: 0.9, green: 0.95, blue: 1.0),
        text: .blue,
        trophyCost: 10,
        easterEgg: "Swipe down three times to see waves",
        icon: "water.waves"
    )
    
    static let forest = AppTheme(
        name: "Forest",
        uiAccent: .green,
        background: Color(red: 0.95, green: 1.0, blue: 0.95),
        text: .green,
        trophyCost: 15,
        easterEgg: "Double tap the background to see leaves",
        icon: "leaf.fill"
    )
    
    static let sunset = AppTheme(
        name: "Sunset",
        uiAccent: .orange,
        background: Color(red: 1.0, green: 0.95, blue: 0.9),
        text: .orange,
        trophyCost: 20,
        easterEgg: "Shake your device to see the sunset",
        icon: "sunset.fill"
    )
    
    static let midnight = AppTheme(
        name: "Midnight",
        uiAccent: .purple,
        background: Color(red: 0.95, green: 0.9, blue: 1.0),
        text: .purple,
        trophyCost: 25,
        easterEgg: "Tap the moon icon three times",
        icon: "moon.stars.fill"
    )
    
    static let aurora = AppTheme(
        name: "Aurora",
        uiAccent: .teal,
        background: Color(red: 0.9, green: 1.0, blue: 0.95),
        text: .teal,
        trophyCost: 30,
        easterEgg: "Swipe left to see the northern lights",
        icon: "sparkles"
    )
    
    static let mountain = AppTheme(
        name: "Mountain",
        uiAccent: .brown,
        background: Color(red: 0.95, green: 0.95, blue: 0.95),
        text: .brown,
        trophyCost: 35,
        easterEgg: "Pinch to see mountain peaks",
        icon: "mountain.2.fill"
    )
    
    static let desert = AppTheme(
        name: "Desert",
        uiAccent: .orange,
        background: Color(red: 1.0, green: 0.95, blue: 0.9),
        text: .orange,
        trophyCost: 40,
        easterEgg: "Long press to see sand dunes",
        icon: "sun.dust.fill"
    )
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.name, forKey: "currentThemeName")
        }
    }
    
    @Published var unlockedThemes: Set<UUID> {
        didSet {
            let themeIds = unlockedThemes.map { $0.uuidString }
            UserDefaults.standard.set(themeIds, forKey: "unlockedThemes")
        }
    }
    
    @Published var isEasterEggActive = false
    
    private init() {
        // Load current theme
        if let savedThemeName = UserDefaults.standard.string(forKey: "currentThemeName"),
           let theme = Self.themeForName(savedThemeName) {
            self.currentTheme = theme
        } else {
            self.currentTheme = AppTheme.defaultTheme
        }
        
        // Load unlocked themes
        if let savedThemeIds = UserDefaults.standard.stringArray(forKey: "unlockedThemes") {
            self.unlockedThemes = Set(savedThemeIds.compactMap { UUID(uuidString: $0) })
        } else {
            self.unlockedThemes = [AppTheme.defaultTheme.id]
        }
    }
    
    private static func themeForName(_ name: String) -> AppTheme? {
        switch name {
        case AppTheme.defaultTheme.name: return AppTheme.defaultTheme
        case AppTheme.ocean.name: return AppTheme.ocean
        case AppTheme.forest.name: return AppTheme.forest
        case AppTheme.sunset.name: return AppTheme.sunset
        case AppTheme.midnight.name: return AppTheme.midnight
        case AppTheme.aurora.name: return AppTheme.aurora
        case AppTheme.mountain.name: return AppTheme.mountain
        case AppTheme.desert.name: return AppTheme.desert
        default: return nil
        }
    }
    
    func unlockTheme(_ theme: AppTheme, trophies: Int) -> Bool {
        guard !unlockedThemes.contains(theme.id) else { return true }
        guard trophies >= theme.trophyCost else { return false }
        
        unlockedThemes.insert(theme.id)
        return true
    }
    
    func applyTheme(_ theme: AppTheme) {
        guard unlockedThemes.contains(theme.id) else { return }
        currentTheme = theme
    }
    
    func triggerEasterEgg() {
        isEasterEggActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isEasterEggActive = false
        }
    }
}

// MARK: - Easter Egg Effects
struct EasterEggEffect: View {
    let theme: AppTheme
    @Binding var isActive: Bool
    
    var body: some View {
        Group {
            switch theme.name {
            case "Ocean":
                WaveEffect(isActive: isActive)
            case "Forest":
                LeafEffect(isActive: isActive)
            case "Sunset":
                SunsetEffect(isActive: isActive)
            case "Midnight":
                StarEffect(isActive: isActive)
            default:
                EmptyView()
            }
        }
    }
}

struct WaveEffect: View {
    let isActive: Bool
    
    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                guard isActive else { return }
                
                var path = Path()
                let midY = size.height * 0.5
                
                path.move(to: CGPoint(x: 0, y: midY))
                path.addCurve(
                    to: CGPoint(x: size.width, y: midY),
                    control1: CGPoint(x: size.width * 0.25, y: size.height * 0.25),
                    control2: CGPoint(x: size.width * 0.75, y: size.height * 0.75)
                )
                
                context.stroke(path, with: .color(Color.blue.opacity(0.3)), lineWidth: 2)
            }
        }
    }
}

struct LeafEffect: View {
    let isActive: Bool
    @State private var leaves: [Leaf] = []
    
    struct Leaf: Identifiable {
        let id = UUID()
        var position: CGPoint
        var rotation: Double
        var scale: Double
    }
    
    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                guard isActive else { return }
                
                if leaves.isEmpty {
                    leaves = (0..<10).map { _ in
                        Leaf(
                            position: CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height)),
                            rotation: .random(in: 0...360),
                            scale: .random(in: 0.5...1.0)
                        )
                    }
                }
                
                for leaf in leaves {
                    var leafContext = context
                    let transform = CGAffineTransform(translationX: leaf.position.x, y: leaf.position.y)
                        .rotated(by: CGFloat(leaf.rotation * .pi / 180))
                        .scaledBy(x: leaf.scale, y: leaf.scale)
                    
                    leafContext.transform = transform
                    
                    let path = Path { p in
                        p.move(to: .zero)
                        p.addLine(to: CGPoint(x: 10, y: 0))
                        p.addLine(to: CGPoint(x: 5, y: 15))
                        p.closeSubpath()
                    }
                    
                    leafContext.fill(path, with: .color(Color.green.opacity(0.3)))
                }
            }
        }
    }
}

struct SunsetEffect: View {
    let isActive: Bool
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard isActive else { return }
                
                let timeNow = timeline.date.timeIntervalSinceReferenceDate
                let angle = timeNow.remainder(dividingBy: 2)
                
                let gradient = Gradient(colors: [.orange, .pink, .purple])
                let startPoint = CGPoint(x: 0, y: 0)
                let endPoint = CGPoint(
                    x: size.width * (0.5 + 0.5 * cos(angle)),
                    y: size.height * (0.5 + 0.5 * sin(angle))
                )
                
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(gradient, startPoint: startPoint, endPoint: endPoint)
                )
            }
        }
    }
}

struct StarEffect: View {
    let isActive: Bool
    @State private var stars: [Star] = []
    
    struct Star: Identifiable {
        let id = UUID()
        var position: CGPoint
        var brightness: Double
    }
    
    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                guard isActive else { return }
                
                if stars.isEmpty {
                    stars = (0..<20).map { _ in
                        Star(
                            position: CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height)),
                            brightness: .random(in: 0.3...1.0)
                        )
                    }
                }
                
                for star in stars {
                    let rect = CGRect(x: star.position.x - 1.5, y: star.position.y - 1.5, width: 3, height: 3)
                    context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(star.brightness)))
                }
            }
        }
    }
} 