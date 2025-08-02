//
//  KnowledgeGraphViewModel.swift
//  Scout
//
//  Created by Alec Alameddine on 8/2/25.
//

import SwiftUI

class KnowledgeGraphViewModel: ObservableObject {
    @Published var isKnowledgeGraphEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isKnowledgeGraphEnabled, forKey: "knowledgeGraphEnabled")
        }
    }
    
    @Published var isAdvancedModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAdvancedModeEnabled, forKey: "advancedModeEnabled")
        }
    }
    
    @Published var isIndexing = false
    @Published var showingEnableConfirmation = false
    @Published var showingIndexingDialog = false
    @Published var showingIndexingComplete = false
    @Published var showingFilePicker = false
    
    init() {
        // Load persistent state from UserDefaults
        self.isKnowledgeGraphEnabled = UserDefaults.standard.bool(forKey: "knowledgeGraphEnabled")
        self.isAdvancedModeEnabled = UserDefaults.standard.bool(forKey: "advancedModeEnabled")
    }
    
    func enableKnowledgeGraph() {
        isIndexing = true
        showingIndexingDialog = true
        
        // Show indexing complete after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showingIndexingDialog = false
            self.showingIndexingComplete = true
            self.isIndexing = false
            self.isKnowledgeGraphEnabled = true
        }
    }
    
    func revokeKnowledgeGraph() {
        isKnowledgeGraphEnabled = false
        isAdvancedModeEnabled = false
    }
} 