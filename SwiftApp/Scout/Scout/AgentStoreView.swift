//
//  AgentStoreView.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import SwiftUI
import Combine

struct AnimatedDownloadIndicator: View {
    @State private var animationProgress: Double = 0
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 20, height: 20)
            
            Circle()
                .trim(from: 0, to: animationProgress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: animationProgress)
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        animateStep()
    }
    
    private func animateStep() {
        // Random progress increment between 0.02 and 0.08
        let progressIncrement = Double.random(in: 0.02...0.08)
        
        withAnimation(.linear(duration: 0.1)) {
            animationProgress += progressIncrement
            // STOP at 1.0 - never restart
            if animationProgress >= 1.0 {
                animationProgress = 1.0
                return // Stop animating completely
            }
        }
        
        // Only continue if not at 1.0
        if animationProgress < 1.0 {
            // Random delay between 0.05 and 0.2 seconds
            let randomDelay = Double.random(in: 0.05...0.2)
            timer = Timer.scheduledTimer(withTimeInterval: randomDelay, repeats: false) { _ in
                animateStep()
            }
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

struct AgentStoreView: View {
    @StateObject private var storeVM = AgentStoreViewModel()
    @Environment(\.openWindow) var openWindow

    @State private var selectedView = 0
    @State private var searchText = ""
    @State private var showingAgentInfo: Agent? = nil
    @State private var showingSettings: Agent? = nil
    @State private var showingStorePage: Agent? = nil
    @State private var navigationState: NavigationState = .main

    private let categories = Category.allCategories
    
    enum NavigationState {
        case main
        case storePage(Agent)
    }
    
    private func agentsForSection(_ sectionIndex: Int) -> [Agent] {
        let category = categories[sectionIndex]
        
        if category.id == "installed" {
            // Show all agents that are purchased/downloading
            return allAgents.filter { agent in
                storeVM.purchasedAgentIDs.contains(agent.id.uuidString) || 
                storeVM.downloadingAgents.contains(agent.id.uuidString)
            }
        } else {
            // Show agents by category
            return allAgents.filter { agent in
                agent.categories.contains { $0.id == category.id }
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar with tabs
            VStack(spacing: 0) {
                // Header in sidebar
                VStack(spacing: 16) {
//                    Text("Scout")
//                        .font(.system(size: 24, weight: .bold, design: .rounded))
//                        .foregroundColor(.primary)
//                        .padding(.top, 20)
                    
                    // Search bar
                    ModernSearchBar(text: $searchText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 19)
                
                Divider()
                    .background(Color.black.opacity(0.3))
                
                // Side tabs
                VStack(spacing: 0) {
                    ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                        SideTabButton(
                            title: category.name,
                            icon: category.icon,
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
            Group {
                switch navigationState {
                case .main:
                    mainContentView
                case .storePage(let agent):
                    StorePage(agent: agent) {
                        navigationState = .main
                    }
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .environmentObject(storeVM)
        .sheet(item: $showingAgentInfo) { agent in
            InfoPage(agent: agent)
        }
        .sheet(item: $showingSettings) { agent in
            SettingsPage(agent: agent)
        }
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
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Content header
            HStack {
                Text(selectedView == 0 ? "Agent Manager" : categories[selectedView].name)
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
                    LazyVStack(spacing: 0) {
                        ForEach(agentsForSection(0).filter {
                            searchText.isEmpty ||
                            $0.name.localizedCaseInsensitiveContains(searchText)
                        }) { agent in
                            InstalledAgentItemView(agent: agent, openWindow: openWindow) {
                                showingAgentInfo = agent
                            } onSettingsTap: {
                                showingSettings = agent
                            }
                            Divider()
                                .background(Color.gray.opacity(0.3))
                        }
                    }
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(agentsForSection(selectedView).filter {
                            searchText.isEmpty ||
                            $0.name.localizedCaseInsensitiveContains(searchText)
                        }) { agent in
                            StoreItemView(agent: agent, onTap: {
                                navigationState = .storePage(agent)
                            })
                            Divider()
                                .background(Color.gray.opacity(0.3))
                        }
                    }
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct SideTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    private var selectedIconColor: Color {
        if !isSelected { return .secondary }
        
        // Find the category and use its selectedColor
        if let category = Category.allCategories.first(where: { $0.name == title }) {
            return category.selectedColor
        }
        
        return .blue // fallback
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(selectedIconColor)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

struct InstalledAgentGridView: View {
    let agents: [Agent]
    let openWindow: OpenWindowAction
    private let columns = [GridItem(.flexible())]

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(agents) { agent in
                InstalledAgentItemView(agent: agent, openWindow: openWindow) {
                    // This closure is passed to InstalledAgentItemView
                    // It will be called when the user taps on the agent item
                    // The parent view (AgentStoreView) will handle updating showingAgentInfo
                    // and potentially opening the info window.
                } onSettingsTap: {
                    // This closure is passed to InstalledAgentItemView
                    // It will be called when the user taps on the settings button
                    // The parent view (AgentStoreView) will handle updating showingSettings
                    // and potentially opening the settings window.
                }
                Divider()
                    .background(Color.gray.opacity(0.3))
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
    }
}

struct AgentGridView: View {
    let agents: [Agent]
    let onTap: (Agent) -> Void
    private let columns = [GridItem(.flexible())]

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(agents) { agent in
                StoreItemView(agent: agent, onTap: {
                    onTap(agent)
                })
                Divider()
                    .background(Color.gray.opacity(0.3))
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
    }
}

struct InstalledAgentItemView: View {
    let agent: Agent
    let openWindow: OpenWindowAction
    let onInfoTap: () -> Void
    let onSettingsTap: () -> Void
    @State private var isHovered = false
    @State private var isEnabled = false // Default to disabled

    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            HStack(spacing: 20) {
                // Icon and Info
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: agent.icon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        Text(agent.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(agent.description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        // Status indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isEnabled ? Color.green : Color.gray)
                                .frame(width: 6, height: 6)
                            Text(isEnabled ? "Active" : "Disabled")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isEnabled ? .green : .secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 16) {
                    // Power Button
                    Button(action: {
                        isEnabled.toggle()
                    }) {
                        Image(systemName: isEnabled ? "power" : "power")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(isEnabled ? .green : .red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(width: 80, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Manage Permissions Button
                    Button(action: {
                        onSettingsTap()
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(width: 80, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Open Button
                    Button(action: {
                        openWindow(id: agent.apiID)
                    }) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(isEnabled ? .blue : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(width: 80, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isEnabled)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isHovered ? Color(NSColor.controlBackgroundColor).opacity(0.8) : Color.clear)
            )
            .onTapGesture {
                onInfoTap()
            }
            .onHover { hovering in
                isHovered = hovering
            }
        }
    }
}

struct StoreItemView: View {
    @EnvironmentObject var storeVM: AgentStoreViewModel
    let agent: Agent
    let onTap: () -> Void
    @State private var isHovered = false
    @State private var showingPermissionsWarning = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: agent.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(agent.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Rating
                if agent.rating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", agent.rating))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text("(\(agent.reviewCount))")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action Button
            if storeVM.downloadingAgents.contains(agent.id.uuidString) {
                HStack(spacing: 6) {
                    AnimatedDownloadIndicator()
                    Text("Installing...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            } else if storeVM.purchasedAgentIDs.contains(agent.id.uuidString) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                    Text("Installed")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
            } else {
                Button(action: { 
                    showingPermissionsWarning = true
                }) {
                    HStack(spacing: 6) {
                        if agent.isFree {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Get")
                                .font(.system(size: 14, weight: .medium))
                        } else {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text(String(format: "$%.2f", agent.price))
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(width: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(storeVM.isProcessing)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? Color(NSColor.controlBackgroundColor).opacity(0.8) : Color.clear)
        )
        .onTapGesture {
            onTap()
        }
        .onHover { isHovered = $0 }
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
                
                Text("The following permissions are required / strongly recommended for best functionality:")
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
                .focusable(false)
                
                Button(agent.isFree ? "Install" : "Buy Agent") {
                    if agent.isFree {
                        // Prevent multiple installations
                        if !storeVM.downloadingAgents.contains(agent.id.uuidString) && 
                           !storeVM.purchasedAgentIDs.contains(agent.id.uuidString) {
                            storeVM.installAgent(agent)
                        }
                    } else {
                        storeVM.buy(agent: agent)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(storeVM.downloadingAgents.contains(agent.id.uuidString))
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
                
                TextField("Search...", text: $text)
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
