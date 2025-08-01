//
//  Agent.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import Foundation

struct Agent: Identifiable, Codable {
    let id: UUID
    let apiID: String
    var name: String
    var description: String
    var icon: String 
    var price: Double
    var rating: Double
    var reviewCount: Int
    var requiredToolsetIDs: [UUID]
    var dependentAgentIDs: [UUID]
    var categories: [String]
    var requiredPermissions: [String]
    var recommendedPermissions: [String]

    var isFree: Bool {
        return price == 0.0
    }
}
