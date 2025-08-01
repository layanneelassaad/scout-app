//
//  AgentStoreViewModel.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/31/25.
//

import SwiftUI
import Combine

class AgentStoreViewModel: ObservableObject {
  
    @Published var purchasedAgentIDs: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(purchasedAgentIDs), forKey: "purchasedAgentIDs")
        }
    }
    @Published var showingCheckout = false
    @Published var checkoutURL: URL?
    @Published var isProcessing = false
    @Published var purchaseError: String?
    @Published var downloadingAgents = Set<String>()
    @Published var hasInstalled = Set<String>()
    
    let userId = "demo-user-123" //demo user
    
    init() {
        // Load persisted purchased agents
        let savedIDs = UserDefaults.standard.array(forKey: "purchasedAgentIDs") as? [String] ?? []
        self.purchasedAgentIDs = Set(savedIDs)
    }
    
    func buy(agent: Agent) {
        guard !isProcessing else { return }
        isProcessing = true
        purchaseError = nil
        BackendAPI.createCheckoutSession(agent: agent, userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                switch result {
                case .success(let url):
                    self?.checkoutURL = url
                    self?.showingCheckout = true

                case .failure(let err):
                    self?.purchaseError = err.localizedDescription
                }
            }
        }
    }
    
    func installAgent(_ agent: Agent) {
        // Prevent re-installation if already purchased, downloading, or has installed
        guard !purchasedAgentIDs.contains(agent.id.uuidString) && 
              !downloadingAgents.contains(agent.id.uuidString) &&
              !hasInstalled.contains(agent.id.uuidString) else { return }
        
        downloadingAgents.insert(agent.id.uuidString)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.0...4.0)) {
            DispatchQueue.main.async {
                // Mark as installed first to prevent restart
                self.hasInstalled.insert(agent.id.uuidString)
                self.downloadingAgents.remove(agent.id.uuidString)
                self.purchasedAgentIDs.insert(agent.id.uuidString)
            }
        }
    }

    func handleCallback(url: URL) {
        guard
            url.scheme == "myapp",
            url.host == "purchase-success"
        else { return }

        // For demo: grant all
        allAgents.forEach { purchasedAgentIDs.insert($0.id.uuidString) }
        showingCheckout = false
    }
}
