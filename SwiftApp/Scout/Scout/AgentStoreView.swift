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
    private let installedAgents = allAgents.filter { $0.name == "File Search" }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scout Agent Store")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Discover and install powerful AI agents")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // View Picker
                Picker("View:", selection: $selectedView) {
                    Text("Installed").tag(0)
                    Text("Store").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
                
                // Search Bar
                ModernSearchBar(text: $searchText)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Content
            ScrollView {
                if selectedView == 0 {
                    InstalledAgentGridView(
                        agents: installedAgents
                            .filter {
                                searchText.isEmpty ||
                                $0.name.localizedCaseInsensitiveContains(searchText)
                            },
                        openWindow: openWindow
                    )
                } else {
                    AgentGridView(
                        agents: agents
                            .filter {
                                searchText.isEmpty ||
                                $0.name.localizedCaseInsensitiveContains(searchText)
                            }
                    )
                }
            }
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

struct InstalledAgentGridView: View {
    let agents: [Agent]
    let openWindow: OpenWindowAction
    private let columns = [GridItem(.adaptive(minimum: 200))]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ForEach(agents) { agent in
                InstalledAgentItemView(agent: agent, openWindow: openWindow)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

struct AgentGridView: View {
    let agents: [Agent]
    private let columns = [ GridItem(.adaptive(minimum: 220), spacing: 24) ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ForEach(agents) { agent in
                StoreItemView(agent: agent)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

struct InstalledAgentItemView: View {
    let agent: Agent
    let openWindow: OpenWindowAction
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
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
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isHovered ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: isHovered ? .blue.opacity(0.2) : .black.opacity(0.05), radius: isHovered ? 12 : 4, x: 0, y: isHovered ? 6 : 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if agent.name == "File Search" {
                openWindow(id: "file-search")
            }
        }
    }
}

struct StoreItemView: View {
    @EnvironmentObject var storeVM: AgentStoreViewModel
    let agent: Agent
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
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
            
            // Action Button
            if storeVM.purchasedAgentIDs.contains(agent.id.uuidString) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Purchased")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.2))
                )
            } else {
                Button(action: { storeVM.buy(agent: agent) }) {
                    HStack(spacing: 6) {
                        if agent.price == 0 {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Free")
                                .font(.system(size: 13, weight: .medium))
                        } else {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text(String(format: "$%.2f", agent.price))
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
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
                        .stroke(isHovered ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: isHovered ? .blue.opacity(0.2) : .black.opacity(0.05), radius: isHovered ? 12 : 4, x: 0, y: isHovered ? 6 : 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
        .frame(minWidth: 220)
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
