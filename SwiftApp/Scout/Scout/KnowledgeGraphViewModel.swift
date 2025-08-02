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
    
    @Published var isGraphVisualizerEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isGraphVisualizerEnabled, forKey: "graphVisualizerEnabled")
        }
    }
    
    @Published var isIndexing = false
    @Published var showingEnableConfirmation = false
    @Published var showingIndexingDialog = false
    @Published var showingIndexingComplete = false
    @Published var showingFilePicker = false
    @Published var showingVisualization = false
    
    init() {
        // Check if each key exists in UserDefaults (first time vs existing user)
        let hasKnowledgeGraphBeenSet = UserDefaults.standard.object(forKey: "knowledgeGraphEnabled") != nil
        let hasAdvancedModeBeenSet = UserDefaults.standard.object(forKey: "advancedModeEnabled") != nil
        let hasGraphVisualizerBeenSet = UserDefaults.standard.object(forKey: "graphVisualizerEnabled") != nil
        
        // Load persistent state from UserDefaults, default to false for new users
        self.isKnowledgeGraphEnabled = hasKnowledgeGraphBeenSet ? UserDefaults.standard.bool(forKey: "knowledgeGraphEnabled") : false
        self.isAdvancedModeEnabled = hasAdvancedModeBeenSet ? UserDefaults.standard.bool(forKey: "advancedModeEnabled") : false
        self.isGraphVisualizerEnabled = hasGraphVisualizerBeenSet ? UserDefaults.standard.bool(forKey: "graphVisualizerEnabled") : false
    }
    
    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: "knowledgeGraphEnabled")
        UserDefaults.standard.removeObject(forKey: "advancedModeEnabled")
        UserDefaults.standard.removeObject(forKey: "graphVisualizerEnabled")
        
        self.isKnowledgeGraphEnabled = false
        self.isAdvancedModeEnabled = false
        self.isGraphVisualizerEnabled = false
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