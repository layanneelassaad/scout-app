//
//  AgentStoreViewModel.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/31/25.
//

import SwiftUI
import Combine

class AgentStoreViewModel: ObservableObject {
  
    @Published var purchasedAgentIDs = Set<String>()
    @Published var showingCheckout = false
    @Published var checkoutURL: URL?
    @Published var isProcessing = false
    @Published var purchaseError: String?
    let userId = "demo-user-123" //demo user
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
