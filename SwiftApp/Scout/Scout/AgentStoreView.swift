//
//  AgentStoreView.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import SwiftUI

struct AgentStoreView: View {
    @Environment(\.openWindow) var openWindow
    @State private var selectedView = 0
    @State private var searchText = ""

    let agents = allAgents
    // Only show File Search as installed
    let installedAgents = allAgents.filter { $0.name == "File Search" }

    let toolsets = allToolsets

    var body: some View {
            VStack {
                Picker("What do you want to see?", selection: $selectedView) {
                    Text("Installed Agents").tag(0)
                    Text("Store").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                SearchBar(text: $searchText)
                    .padding(.horizontal)

                ScrollView {
                    if selectedView == 0 {
                        InstalledAgentGridView(agents: installedAgents.filter { searchText.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchText) }, openWindow: openWindow)
                    } else {
                        AgentGridView(agents: agents.filter { searchText.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchText) })
                    }
                }
            }
            .navigationTitle("Scout Agent Store")
    }
}

struct InstalledAgentGridView: View {
    let agents: [Agent]
    let openWindow: OpenWindowAction
    private let columns = [GridItem(.adaptive(minimum: 150))]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(agents) { agent in
                InstalledAgentItemView(agent: agent, openWindow: openWindow)
            }
        }
        .padding()
    }
}

struct AgentGridView: View {
    let agents: [Agent]
    private let columns = [GridItem(.adaptive(minimum: 150))]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(agents) { agent in
                StoreItemView(name: agent.name, icon: agent.icon, price: agent.price, rating: agent.rating, reviewCount: agent.reviewCount)
            }
        }
        .padding()
    }
}

struct InstalledAgentItemView: View {
    let agent: Agent
    let openWindow: OpenWindowAction
    @State private var isHovered = false

    var body: some View {
        VStack {
            Image(systemName: agent.icon)
                .font(.system(size: 40, weight: .medium))
                .padding()
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(agent.name)
                .font(.headline)
                .lineLimit(1)
        }
        .padding()
        .background(isHovered ? Color.blue.opacity(0.1) : Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: isHovered ? 8 : 3)
        .scaleEffect(isHovered ? 1.05 : 1.0)
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

struct ToolsetGridView: View {
    let toolsets: [Toolset]
    private let columns = [GridItem(.adaptive(minimum: 150))]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(toolsets) { toolset in
                StoreItemView(name: toolset.name, icon: toolset.icon, price: toolset.price)
            }
        }
        .padding()
    }
}

struct StoreItemView: View {
    var name: String
    var icon: String
    var price: Double
    var rating: Double? = nil
    var reviewCount: Int? = nil

    @State private var isHovered = false

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .medium))
                .padding()
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(name)
                .font(.headline)
                .lineLimit(1)

            if let rating = rating, let reviewCount = reviewCount {
                HStack {
                    Image(systemName: "star.fill").foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                    Text("(\(reviewCount))").font(.caption).foregroundColor(.secondary)
                }
            }

            Text(price == 0.0 ? "Free" : String(format: "$%.2f", price))
                .font(.caption)
                .fontWeight(.bold)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.blue.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding()
        .background(isHovered ? Color.blue.opacity(0.1) : Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: isHovered ? 8 : 3)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            TextField("Search...", text: $text)
                .padding(8)
                .padding(.horizontal, 25)
                .background(Color(NSColor.unemphasizedSelectedContentBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        if !text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
        }
    }
}

struct AgentStoreView_Previews: PreviewProvider {
    static var previews: some View {
        AgentStoreView()
    }
}
