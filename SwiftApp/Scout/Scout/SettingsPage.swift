//
//  SettingsPage.swift
//  Scout
//
//  Created by Alec Alameddine on 8/1/25
//

import SwiftUI

struct PermissionsPage {
    let requiredPermissions: [Permission]
    let recommendedPermissions: [Permission]
    
    static let searchAgent = PermissionsPage(
        requiredPermissions: [
            Permission(name: "Full Disk Access", description: "Required to search through your files", icon: "folder.fill")
        ],
        recommendedPermissions: [
            Permission(name: "Mail Access", description: "Search through your emails", icon: "envelope.fill"),
            Permission(name: "Calendar Access", description: "Find files related to calendar events", icon: "calendar"),
            Permission(name: "Contacts Access", description: "Search files by contact names", icon: "person.fill")
        ]
    )
}

struct Permission {
    let name: String
    let description: String
    let icon: String
}

struct SettingsPage: View {
    let agent: Agent
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("\(agent.name) Settings")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Placeholder for balance
                Color.clear
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Tab Picker
            Picker("", selection: $selectedTab) {
                Text("Permissions").tag(0)
                Text("Other Settings").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Content
            ScrollView {
                if selectedTab == 0 {
                    PermissionsView(agent: agent)
                } else {
                    OtherSettingsView(agent: agent)
                }
            }
        }
        .frame(width: 500, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct PermissionsView: View {
    let agent: Agent
    @State private var showingKnowledgeGraphConfirmation = false
    @State private var showingFilePicker = false
    @State private var grantedPermissions: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Required Permissions
            let validRequiredPermissions = agent.requiredPermissions.filter { !$0.isEmpty }
            let ungrantedRequiredPermissions = validRequiredPermissions.filter { permission in
                // Check if the permission is granted, accounting for name changes
                if permission == "Limited Disk Access (Select Specific Folders)" {
                    return !grantedPermissions.contains("Limited Disk Access")
                } else {
                    return !grantedPermissions.contains(permission)
                }
            }
            
            if !ungrantedRequiredPermissions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Required Permissions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ForEach(ungrantedRequiredPermissions, id: \.self) { permission in
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(permission)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Required for \(agent.name) to function properly")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Grant") {
                                if permission == "Limited Disk Access (Select Specific Folders)" {
                                    showingFilePicker = true
                                } else {
                                    grantedPermissions.insert(permission)
                                }
                            }
                            .buttonStyle(.borderedProminent)
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
            } else if validRequiredPermissions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Required Permissions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("No permissions required")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                }
            }
            
            // Recommended Permissions
            let ungrantedRecommendedPermissions = agent.recommendedPermissions.filter { !grantedPermissions.contains($0) }
            
            if !ungrantedRecommendedPermissions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommended Permissions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ForEach(ungrantedRecommendedPermissions, id: \.self) { permission in
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 14, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(permission)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                Text(permission == "Knowledge Graph" ? "Recommended for semantic search" : "Recommended for full functionality")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Grant") {
                                if permission == "Knowledge Graph" {
                                    showingKnowledgeGraphConfirmation = true
                                } else {
                                    grantedPermissions.insert(permission)
                                }
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
            } else if agent.recommendedPermissions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommended Permissions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("No permissions recommended")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                }
            }
            
            // Granted Permissions
            if !grantedPermissions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Granted Permissions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ForEach(Array(grantedPermissions), id: \.self) { permission in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 14, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(permission)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Permission granted")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                if permission == "Limited Disk Access" {
                                    Button("Manage") {
                                        // TODO: Show details of selected folders
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .foregroundColor(.blue)
                                }
                                
                                Button("Revoke") {
                                    grantedPermissions.remove(permission)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .foregroundColor(.red)
                            }
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
        .padding(20)
        .alert("Knowledge Graph Access", isPresented: $showingKnowledgeGraphConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Allow") {
                grantedPermissions.insert("Knowledge Graph")
            }
            Button("Allow Specific Permissions...") {
                // TODO: Handle specific knowledge graph access
            }
        } message: {
            Text("Are you sure you want to allow this agent to access your complete knowledge profile?")
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                // Handle selected folders
                grantedPermissions.insert("Limited Disk Access")
            case .failure(let error):
                print("File picker error: \(error.localizedDescription)")
            }
        }
    }
}

struct OtherSettingsView: View {
    let agent: Agent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Other Settings")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Additional settings for \(agent.name) will appear here.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
        }
        .padding(20)
    }
} 
