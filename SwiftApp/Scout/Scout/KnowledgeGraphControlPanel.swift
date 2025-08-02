//
//  KnowledgeGraphControlPanel.swift
//  Scout
//
//  Created by Alec Alameddine on 8/2/25.
//

import SwiftUI

struct KnowledgeGraphControlPanel: View {
    @State private var isKnowledgeGraphEnabled = false
    @State private var isAdvancedModeEnabled = false
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
            
            // Knowledge Graph Enable Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Knowledge Graph")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Enable your personal knowledge graph")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isKnowledgeGraphEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20, weight: .medium))
                    } else {
                        Button("Enable") {
                            showingEnableConfirmation = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
            
            // Knowledge Graph Settings (only shown when enabled)
            if isKnowledgeGraphEnabled {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Knowledge Graph Settings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        // Advanced Mode Toggle
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                                .font(.system(size: 16, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Advanced Mode")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Enable advanced knowledge graph features")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isAdvancedModeEnabled)
                                .toggleStyle(SwitchToggleStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Semantic Search
                        HStack {
                            Image(systemName: "magnifyingglass.circle")
                                .foregroundColor(isAdvancedModeEnabled ? .purple : .gray)
                                .font(.system(size: 16, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Semantic Search")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isAdvancedModeEnabled ? .primary : .secondary)
                                Text("Search through your knowledge graph using natural language")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(isAdvancedModeEnabled ? .secondary : .gray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: .constant(false))
                                .disabled(!isAdvancedModeEnabled)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Knowledge Connections
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(isAdvancedModeEnabled ? .purple : .gray)
                                .font(.system(size: 16, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Knowledge Connections")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isAdvancedModeEnabled ? .primary : .secondary)
                                Text("Discover connections between different pieces of knowledge")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(isAdvancedModeEnabled ? .secondary : .gray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: .constant(false))
                                .disabled(!isAdvancedModeEnabled)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Learning Analytics
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(isAdvancedModeEnabled ? .purple : .gray)
                                .font(.system(size: 16, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Learning Analytics")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isAdvancedModeEnabled ? .primary : .secondary)
                                Text("Track and analyze your knowledge growth patterns")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(isAdvancedModeEnabled ? .secondary : .gray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: .constant(false))
                                .disabled(!isAdvancedModeEnabled)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                    }
                }
                
                // Integrations Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Integrations")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        // Google Drive
                        HStack {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Google Drive")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Sync documents and files from Google Drive")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Google Drive connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Gmail
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 16, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gmail")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Import emails and conversations")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Gmail connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Slack
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(.purple)
                                .font(.system(size: 16, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Slack")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Import messages and conversations")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Slack connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Notion
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notion")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Import notes and documents")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Notion connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Linear
                        HStack {
                            Image(systemName: "list.bullet.clipboard.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linear")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Import issues and project data")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Linear connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Jira
                        HStack {
                            Image(systemName: "ticket.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Jira")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Import issues and project management data")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Jira connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Git
                        HStack {
                            Image(systemName: "git.branch")
                                .foregroundColor(.orange)
                                .font(.system(size: 16, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Git")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Import code repositories and commits")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Git connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
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
        }
        .padding(32)
        .alert("Enable Knowledge Graph", isPresented: $showingEnableConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Enable") {
                isKnowledgeGraphEnabled = true
            }
            Button("Enable for Specific Locations...") {
                showingFilePicker = true
            }
        } message: {
            Text("Are you sure you want to enable your knowledge graph? This will allow the system to access your complete knowledge profile.")
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                // Handle selected folders for specific locations
                isKnowledgeGraphEnabled = true
            case .failure(let error):
                print("File picker error: \(error.localizedDescription)")
            }
        }
    }
} 