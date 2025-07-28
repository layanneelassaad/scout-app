//
//  Toolset.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import Foundation

struct Toolset: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var icon: String // SF Symbol name or asset name
    var price: Double

    var isFree: Bool {
        return price == 0.0
    }
}
