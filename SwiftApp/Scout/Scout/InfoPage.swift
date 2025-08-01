//
//  InfoPage.swift
//  Scout
//
//  Created by Alec Alameddine on 8/1/25
//

import SwiftUI

struct InfoPageContent {
    let title: String
    let subtitle: String
    let description: String
    let features: [String]
    let examples: [String]
    
    static let searchAgent = InfoPageContent(
        title: "Search Agent",
        subtitle: "Find anything on your computer in seconds",
        description: "Have you ever spent ages digging for an old file you emailed years ago? How about a document you downloaded during a meeting a while back? Using pure language queries like “2nd to last file I sent John about college recommendations” or “contract I downloaded during a meeting with acme corp”, Search Agent will surface any file you want. \n\nWhat's more, search agent can also find information for you from any of your files, emals, or other integrations. You can ask a question like “what did I write about in my meeting with acme corp last year” and search agent will instantly surface that information",
        features: [
            "Natural language queries",
            "Find files by content and context",
            "Search across emails and integrations",
            "Instant information retrieval"
        ],
        examples: [
            "\"2nd to last file I sent John about college recommendations\"",
            "\"contract I downloaded during a meeting with acme corp\"",
            "\"what did I write about in my meeting with acme corp last year\""
        ]
    )
}

struct InfoPage: View {
    let agent: Agent
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var storeVM: AgentStoreViewModel
    @State private var showingStorePage = false
    
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
                
                Text(agent.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Store Button
                Button(action: {
                    showingStorePage = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Store")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Icon and Title
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: agent.icon)
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(agent.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(agent.description)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                    }
                    
                    // Detailed Description
                    if let infoPage = agent.infoPage {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(infoPage.description)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                            
                            // Features
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Key Features")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                ForEach(infoPage.features, id: \.self) { feature in
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 14, weight: .medium))
                                        Text(feature)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            
                            // Examples
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Example Queries")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                ForEach(infoPage.examples, id: \.self) { example in
                                    HStack(spacing: 8) {
                                        Image(systemName: "quote.opening")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 12, weight: .medium))
                                        Text(example)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Permissions Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Permissions")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            // Required Permissions
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Required")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                if agent.requiredPermissions.isEmpty || (agent.requiredPermissions.count == 1 && agent.requiredPermissions[0].isEmpty) {
                                    Text("None required")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(agent.requiredPermissions.filter { !$0.isEmpty }, id: \.self) { permission in
                                        HStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 12, weight: .medium))
                                            Text(permission)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            
                            // Recommended Permissions
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Recommended")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                if agent.recommendedPermissions.isEmpty {
                                    Text("None recommended")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(agent.recommendedPermissions, id: \.self) { permission in
                                        HStack(spacing: 8) {
                                            Image(systemName: "info.circle.fill")
                                                .foregroundColor(.orange)
                                                .font(.system(size: 12, weight: .medium))
                                            Text(permission)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                    }
                                }
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
                .padding(20)
            }
        }
        .frame(width: 600, height: 700)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingStorePage) {
            StorePage(agent: agent)
        }
    }
} 
