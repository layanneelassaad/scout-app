//
//  Category.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import Foundation
import SwiftUI

struct Category: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let selectedColor: Color
    let description: String
    
    // Custom coding keys to handle Color
    private enum CodingKeys: String, CodingKey {
        case id, name, icon, selectedColorName, description
    }
    
    init(id: String, name: String, icon: String, selectedColor: Color, description: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.selectedColor = selectedColor
        self.description = description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        description = try container.decode(String.self, forKey: .description)
        
        let colorName = try container.decode(String.self, forKey: .selectedColorName)
        selectedColor = Category.colorFromName(colorName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(description, forKey: .description)
        try container.encode(Category.nameFromColor(selectedColor), forKey: .selectedColorName)
    }
    
    private static func colorFromName(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "yellow": return .yellow
        case "brown": return .brown
        case "blue": return .blue
        case "pink": return .pink
        case "orange": return .orange
        default: return .blue
        }
    }
    
    private static func nameFromColor(_ color: Color) -> String {
        switch color {
        case .green: return "green"
        case .yellow: return "yellow"
        case .brown: return "brown"
        case .blue: return "blue"
        case .pink: return "pink"
        case .orange: return "orange"
        default: return "blue"
        }
    }
    
    static let installed = Category(
        id: "installed",
        name: "Installed Scouts",
        icon: "square.and.arrow.down.fill",
        selectedColor: .blue,
        description: "Your installed agents"
    )
    
    static let madeByScout = Category(
        id: "made_by_scout",
        name: "Made by Scout",
        icon: "checkmark.seal.fill",
        selectedColor: .green,
        description: "Official Scout agents"
    )
    
    static let discover = Category(
        id: "discover",
        name: "Discover",
        icon: "sparkles",
        selectedColor: .yellow,
        description: "Discover new agents"
    )
    
    static let productivity = Category(
        id: "productivity",
        name: "Productivity",
        icon: "bolt.fill",
        selectedColor: .yellow,
        description: "Boost your productivity"
    )
    
    static let development = Category(
        id: "development",
        name: "Development",
        icon: "hammer.fill",
        selectedColor: .brown,
        description: "Development tools"
    )
    
    static let utilities = Category(
        id: "utilities",
        name: "Utilities",
        icon: "wrench.and.screwdriver.fill",
        selectedColor: .brown,
        description: "Utility tools"
    )
    
    static let allCategories = [installed, madeByScout, discover, productivity, development, utilities]
} 