//
//  Category.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import Foundation
import SwiftUI

struct Category: Identifiable {
    let id: String
    let name: String
    let icon: String
    let selectedColor: Color
    let description: String
    
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