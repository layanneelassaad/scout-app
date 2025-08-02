//
//  KnowledgeGraphControlPanel.swift
//  Scout
//
//  Created by Alec Alameddine on 8/2/25.
//

import SwiftUI

struct KnowledgeGraphControlPanel: View {
    @State private var isAdvancedEnabled = false
    @State private var showingEnableConfirmation = false
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Knowledge Graph Control Panel")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Manage knowledge graph settings")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            // Advanced Toggle Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Advanced Mode")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Enable advanced knowledge graph features")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isAdvancedEnabled)
                        .disabled(!isAdvancedEnabled)
                        .toggleStyle(SwitchToggleStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                // Enable Button
                if !isAdvancedEnabled {
                    Button("Enable Advanced Mode") {
                        showingEnableConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            
            // Advanced Features (disabled when not enabled)
            VStack(alignment: .leading, spacing: 16) {
                Text("Advanced Features")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    // Feature 1
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(isAdvancedEnabled ? .purple : .gray)
                            .font(.system(size: 16, weight: .medium))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Semantic Search")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isAdvancedEnabled ? .primary : .secondary)
                            Text("Search through your knowledge graph using natural language")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(isAdvancedEnabled ? .secondary : .gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: .constant(false))
                            .disabled(!isAdvancedEnabled)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    
                    // Feature 2
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(isAdvancedEnabled ? .purple : .gray)
                            .font(.system(size: 16, weight: .medium))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Knowledge Connections")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isAdvancedEnabled ? .primary : .secondary)
                            Text("Discover connections between different pieces of knowledge")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(isAdvancedEnabled ? .secondary : .gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: .constant(false))
                            .disabled(!isAdvancedEnabled)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    
                    // Feature 3
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(isAdvancedEnabled ? .purple : .gray)
                            .font(.system(size: 16, weight: .medium))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Learning Analytics")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isAdvancedEnabled ? .primary : .secondary)
                            Text("Track and analyze your knowledge growth patterns")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(isAdvancedEnabled ? .secondary : .gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: .constant(false))
                            .disabled(!isAdvancedEnabled)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                }
            }
        }
        .padding(32)
        .alert("Enable Advanced Knowledge Graph", isPresented: $showingEnableConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Enable") {
                isAdvancedEnabled = true
            }
            Button("Enable for Specific Locations...") {
                showingFilePicker = true
            }
        } message: {
            Text("Are you sure you want to enable advanced knowledge graph features? This will allow the system to access your complete knowledge profile.")
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                // Handle selected folders for specific locations
                isAdvancedEnabled = true
            case .failure(let error):
                print("File picker error: \(error.localizedDescription)")
            }
        }
    }
} 