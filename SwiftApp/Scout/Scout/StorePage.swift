//
//  StorePage.swift
//  Scout
//
//  Created by Alec Alameddine on 8/1/25
//

import SwiftUI

struct StorePage: View {
    let agent: Agent
    let onDismiss: () -> Void
    @EnvironmentObject var storeVM: AgentStoreViewModel
    @State private var showingPermissionsWarning = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: {
                    onDismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Placeholder for balance
                Color.clear
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Icon and Title with Price
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
                            
                            // Price or Purchase Status
                            HStack(spacing: 8) {
                                if storeVM.purchasedAgentIDs.contains(agent.id.uuidString) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.green)
                                        Text("Purchased")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    if agent.isFree {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.down.circle.fill")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.blue)
                                            Text("Free")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.blue)
                                        }
                                    } else {
                                        HStack(spacing: 6) {
                                            Image(systemName: "cart.fill")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.blue)
                                            Text(String(format: "$%.2f", agent.price))
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                
                                // Rating
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", agent.rating))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("(\(agent.reviewCount))")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Purchase Button
                    let isDownloading = storeVM.downloadingAgents.contains(agent.id.uuidString)
                    let isPurchased = storeVM.purchasedAgentIDs.contains(agent.id.uuidString)
                    let hasInstalled = storeVM.hasInstalled.contains(agent.id.uuidString)
                    
                    if !isPurchased {
                        Button(action: {
                            if agent.requiredPermissions.isEmpty && agent.recommendedPermissions.isEmpty {
                                // No permissions needed, install directly
                                storeVM.installAgent(agent)
                            } else {
                                // Show permissions warning
                                showingPermissionsWarning = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                if isDownloading && !hasInstalled {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Installing...")
                                        .font(.system(size: 18, weight: .semibold))
                                } else if agent.isFree {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Get")
                                        .font(.system(size: 18, weight: .semibold))
                                } else {
                                    Image(systemName: "cart.fill")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Buy for $\(String(format: "%.2f", agent.price))")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(storeVM.isProcessing || isDownloading)
                    } else {
                        // Show installed status
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                            Text("Installed")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
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
                                    Text("No permissions required")
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
                                    Text("No permissions recommended")
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
                    
                    // Reviews Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reviews")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // Mock reviews
                        VStack(spacing: 12) {
                            ReviewCard(
                                author: "Sarah M.",
                                rating: 5,
                                date: "2 days ago",
                                comment: "This agent is incredible! Found my lost document in seconds."
                            )
                            
                            ReviewCard(
                                author: "Mike R.",
                                rating: 4,
                                date: "1 week ago",
                                comment: "Really useful for finding old emails and files. Works exactly as advertised."
                            )
                            
                            ReviewCard(
                                author: "Alex K.",
                                rating: 5,
                                date: "2 weeks ago",
                                comment: "Game changer for file organization. Natural language search is amazing."
                            )
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingPermissionsWarning) {
            PermissionsWarningView(agent: agent)
        }
    }
}

struct ReviewCard: View {
    let author: String
    let rating: Int
    let date: String
    let comment: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(author)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(date)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < rating ? "star.fill" : "star")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.yellow)
                }
            }
            
            Text(comment)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.primary)
                .lineLimit(nil)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
} 