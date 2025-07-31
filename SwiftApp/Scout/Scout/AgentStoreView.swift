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
        VStack {
            Picker("View:", selection: $selectedView) {
                Text("Installed").tag(0)
                Text("Store").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            SearchBar(text: $searchText)
                .padding(.horizontal)

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
        .navigationTitle("Scout Agent Store")
    
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
    private let columns = [ GridItem(.adaptive(minimum: 180), spacing: 40) ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 40) {
            ForEach(agents) { agent in
                StoreItemView(agent: agent)
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



struct StoreItemView: View {
  @EnvironmentObject var storeVM: AgentStoreViewModel
  let agent: Agent
  @State private var isHovered = false

  var body: some View {
    VStack(spacing: 8) {
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

     
      Text(agent.description)
        .font(.caption)
        .foregroundColor(.secondary)
        .lineLimit(2)
        .multilineTextAlignment(.center)


      if agent.rating > 0 {
        HStack(spacing: 4) {
          Image(systemName: "star.fill").foregroundColor(.yellow)
          Text(String(format: "%.1f", agent.rating))
          Text("(\(agent.reviewCount))")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }


      if storeVM.purchasedAgentIDs.contains(agent.id.uuidString) {
        Text("Purchased")
          .font(.caption).bold()
          .padding(6)
          .background(Color.gray.opacity(0.2))
          .clipShape(Capsule())

      } else {
        Button(action: { storeVM.buy(agent: agent) }) {
          Text(agent.price == 0
               ? "Free"
               : String(format: "Buy for $%.2f", agent.price))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(storeVM.isProcessing)
      }
    }
    .padding()
    .background(isHovered
        ? Color.blue.opacity(0.1)
        : Color(NSColor.windowBackgroundColor))
    .clipShape(RoundedRectangle(cornerRadius: 15))
    .shadow(radius: isHovered ? 8 : 3)
    .scaleEffect(isHovered ? 1.05 : 1.0)
    .animation(.easeInOut(duration: 0.2), value: isHovered)
    .onHover { isHovered = $0 }
    .frame(minWidth: 180)
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
