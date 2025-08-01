//
//  AgentStoreView.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import SwiftUI


struct AgentStoreView: View {
    @EnvironmentObject var storeVM: AgentStoreViewModel
    @Environment(\.openWindow) var openWindow

    @State private var selectedView = 0
    @State private var searchText = ""

    private let agents = allAgents
    
    // App Store-style sections
    private let sections = [
        ("Installed Scouts", "checkmark.circle.fill", 0),
        ("Made by Scout", "sparkles", 1),
        ("Discover", "sparkles", 2),
        ("Productivity", "bolt.fill", 3),
        ("Development", "hammer.fill", 4),
        ("Utilities", "wrench.and.screwdriver.fill", 5)
    ]
    
    private func agentsForSection(_ sectionIndex: Int) -> [Agent] {
        let sectionName = sections[sectionIndex].0.lowercased()
        let categoryMap = [
            "installed scouts": "installed",
            "made by scout": "made by scout",
            "discover": "discover", 
            "productivity": "productivity",
            "development": "development",
            "utilities": "utilities"
        ]
        
        let targetCategory = categoryMap[sectionName] ?? ""
        
        return agents.filter { agent in
            agent.categories.contains(targetCategory)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar with tabs
            VStack(spacing: 0) {
                // Header in sidebar
                VStack(spacing: 16) {
                    Text("Scout")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    // Search bar
                    ModernSearchBar(text: $searchText)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Side tabs
                VStack(spacing: 0) {
                    ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                        SideTabButton(
                            title: section.0,
                            icon: section.1,
                            isSelected: selectedView == index
                        ) {
                            selectedView = index
                        }
                    }
                }
                
                Spacer()
            }
            .frame(width: 250)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Main content area
            VStack(spacing: 0) {
                // Content header
                HStack {
                    Text(sections[selectedView].0)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Content
                ScrollView {
                    if selectedView == 0 {
                        InstalledAgentGridView(
                            agents: agentsForSection(0)
                                .filter {
                                    searchText.isEmpty ||
                                    $0.name.localizedCaseInsensitiveContains(searchText)
                                },
                            openWindow: openWindow
                        )
                    } else {
                        AgentGridView(
                            agents: agentsForSection(selectedView)
                                .filter {
                                    searchText.isEmpty ||
                                    $0.name.localizedCaseInsensitiveContains(searchText)
                                }
                        )
                    }
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $storeVM.showingCheckout) {
            if let url = storeVM.checkoutURL {
                ZStack(alignment: .topTrailing) {
                  
                    CheckoutWebView(url: url)
                        .frame(minWidth: 600, minHeight: 800)

                 
                    Button(action: {
                        storeVM.showingCheckout = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                    .help("Close checkout")
                }
            } else {
                Text("Unable to load checkout.")
                    .padding()
            }
        }
    }
}

struct SideTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 20, alignment: .leading)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InstalledAgentGridView: View {
    let agents: [Agent]
    let openWindow: OpenWindowAction
    private let columns = [GridItem(.adaptive(minimum: 240))]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(agents) { agent in
                InstalledAgentItemView(agent: agent, openWindow: openWindow)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
    }
}

struct AgentGridView: View {
    let agents: [Agent]
    private let columns = [ GridItem(.adaptive(minimum: 260), spacing: 20) ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(agents) { agent in
                StoreItemView(agent: agent)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
    }
}

struct InstalledAgentItemView: View {
    let agent: Agent
    let openWindow: OpenWindowAction
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 16) {
            // Enhanced Icon with gradient background
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
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Content with better spacing
            VStack(spacing: 6) {
                Text(agent.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(agent.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isHovered ? Color.blue.opacity(0.4) : Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: isHovered ? .blue.opacity(0.3) : .black.opacity(0.08), radius: isHovered ? 16 : 6, x: 0, y: isHovered ? 8 : 3)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            openWindow(id: agent.apiID)
        }
    }
}

struct StoreItemView: View {
    @EnvironmentObject var storeVM: AgentStoreViewModel
    let agent: Agent
    @State private var isHovered = false
    @State private var showingPermissionsWarning = false

    var body: some View {
        VStack(spacing: 16) {
            // Enhanced Icon
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
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Content
            VStack(spacing: 8) {
                Text(agent.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(agent.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Enhanced Rating
                if agent.rating > 0 {
                    HStack(spacing: 6) {
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.yellow.opacity(0.1))
                    )
                }
            }
            
            // Enhanced Action Button
            if storeVM.purchasedAgentIDs.contains(agent.id.uuidString) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Installed")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.2))
                )
            } else {
                Button(action: { 
                    showingPermissionsWarning = true
                }) {
                    HStack(spacing: 8) {
                        if agent.isFree {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Get")
                                .font(.system(size: 14, weight: .medium))
                        } else {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text(String(format: "$%.2f", agent.price))
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(storeVM.isProcessing)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isHovered ? Color.blue.opacity(0.4) : Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: isHovered ? .blue.opacity(0.3) : .black.opacity(0.08), radius: isHovered ? 16 : 6, x: 0, y: isHovered ? 8 : 3)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isHovered)
        .onHover { isHovered = $0 }
        .frame(minWidth: 260)
        .sheet(isPresented: $showingPermissionsWarning) {
            PermissionsWarningView(agent: agent)
        }
    }
}

struct PermissionsWarningView: View {
    let agent: Agent
    @EnvironmentObject var storeVM: AgentStoreViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("WARNING")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.red)
                
                Text("The following permissions are required and the following are strongly recommended for top functionality:")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            
            // Required Permissions
            VStack(alignment: .leading, spacing: 12) {
                Text("Required Permissions:")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.red)
                
                ForEach(agent.requiredPermissions, id: \.self) { permission in
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(permission)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Recommended Permissions
            VStack(alignment: .leading, spacing: 12) {
                Text("Recommended Permissions:")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.orange)
                
                ForEach(agent.recommendedPermissions, id: \.self) { permission in
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text(permission)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Action Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button(agent.isFree ? "Install" : "Buy Agent") {
                    storeVM.buy(agent: agent)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(width: 500, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ModernSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search agents...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .regular))
                
                if !text.isEmpty {
                    Button(action: {
                        self.text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct AgentStoreView_Previews: PreviewProvider {
    static var previews: some View {
        AgentStoreView()
    }
}
