import SwiftUI

// MARK: - Codable Color Wrapper
struct CodableColor: Codable {
    var color: Color
    var darkColor: Color?

    enum CodingKeys: String, CodingKey {
        case red, green, blue, opacity
        case darkRed, darkGreen, darkBlue, darkOpacity
    }

    init(color: Color, darkColor: Color? = nil) {
        self.color = color
        self.darkColor = darkColor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let opacity = try container.decode(Double.self, forKey: .opacity)

        self.color = Color(red: red, green: green, blue: blue, opacity: opacity)
        
        if let darkRed = try? container.decode(Double.self, forKey: .darkRed),
           let darkGreen = try? container.decode(Double.self, forKey: .darkGreen),
           let darkBlue = try? container.decode(Double.self, forKey: .darkBlue),
           let darkOpacity = try? container.decode(Double.self, forKey: .darkOpacity) {
            self.darkColor = Color(red: darkRed, green: darkGreen, blue: darkBlue, opacity: darkOpacity)
        }
    }

    func encode(to encoder: Encoder) throws {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        #if canImport(UIKit)
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Double(red), forKey: .red)
        try container.encode(Double(green), forKey: .green)
        try container.encode(Double(blue), forKey: .blue)
        try container.encode(Double(alpha), forKey: .opacity)
        
        if let darkColor = darkColor {
            UIColor(darkColor).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            try container.encode(Double(red), forKey: .darkRed)
            try container.encode(Double(green), forKey: .darkGreen)
            try container.encode(Double(blue), forKey: .darkBlue)
            try container.encode(Double(alpha), forKey: .darkOpacity)
        }
    }
}

// MARK: - Theme Struct
struct Theme: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var primaryColor: CodableColor
    var secondaryColor: CodableColor
    var accentColor: CodableColor
    var price: Int
    var isUnlocked: Bool
    var icon: String
    var isFree: Bool

    var uiPrimary: Color { 
        @Environment(\.colorScheme) var colorScheme
        return colorScheme == .dark ? (primaryColor.darkColor ?? primaryColor.color) : primaryColor.color
    }
    
    var uiSecondary: Color { 
        @Environment(\.colorScheme) var colorScheme
        return colorScheme == .dark ? (secondaryColor.darkColor ?? secondaryColor.color) : secondaryColor.color
    }
    
    var uiAccent: Color { 
        @Environment(\.colorScheme) var colorScheme
        return colorScheme == .dark ? (accentColor.darkColor ?? accentColor.color) : accentColor.color
    }

    static let defaultTheme = Theme(
        name: "Default",
        description: "Classic orange theme",
        primaryColor: CodableColor(color: .orange, darkColor: .orange),
        secondaryColor: CodableColor(color: .pink, darkColor: .pink),
        accentColor: CodableColor(color: .orange, darkColor: .orange),
        price: 0,
        isUnlocked: true,
        icon: "sun.max.fill",
        isFree: true
    )

    static let themes: [Theme] = [
        defaultTheme,
        Theme(
            name: "Ocean",
            description: "Calm blue theme",
            primaryColor: CodableColor(color: .blue, darkColor: .blue),
            secondaryColor: CodableColor(color: .cyan, darkColor: .cyan),
            accentColor: CodableColor(color: .blue, darkColor: .blue),
            price: 100,
            isUnlocked: true,
            icon: "water.waves",
            isFree: true
        ),
        Theme(
            name: "Forest",
            description: "Natural green theme",
            primaryColor: CodableColor(color: .green, darkColor: .green),
            secondaryColor: CodableColor(color: .mint, darkColor: .mint),
            accentColor: CodableColor(color: .green, darkColor: .green),
            price: 200,
            isUnlocked: false,
            icon: "leaf.fill",
            isFree: false
        ),
        Theme(
            name: "Sunset",
            description: "Warm purple theme",
            primaryColor: CodableColor(color: .purple, darkColor: .purple),
            secondaryColor: CodableColor(color: .pink, darkColor: .pink),
            accentColor: CodableColor(color: .purple, darkColor: .purple),
            price: 300,
            isUnlocked: false,
            icon: "sunset.fill",
            isFree: false
        ),
        Theme(
            name: "Midnight",
            description: "Dark night theme",
            primaryColor: CodableColor(color: .black, darkColor: .white),
            secondaryColor: CodableColor(color: .gray, darkColor: .gray),
            accentColor: CodableColor(color: .white, darkColor: .orange),
            price: 400,
            isUnlocked: false,
            icon: "moon.stars.fill",
            isFree: false
        )
    ]
}
