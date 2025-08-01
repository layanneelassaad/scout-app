//
//  Agent.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import Foundation

struct Agent: Identifiable, Hashable {
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
    var categories: [Category]
    var requiredPermissions: [String]
    var recommendedPermissions: [String]
    var infoPage: InfoPageContent?
    var permissionsPage: PermissionsPage?

    var isFree: Bool {
        return price == 0.0
    }
    
    // Hashable conformance using the id property
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Agent, rhs: Agent) -> Bool {
        return lhs.id == rhs.id
    }
}
