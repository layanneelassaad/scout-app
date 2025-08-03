//
//  KnowledgeGraphControlPanel.swift
//  Scout
//
//  Created by Alec Alameddine on 8/2/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct KnowledgeGraphControlPanel: View {
    @StateObject private var viewModel = KnowledgeGraphViewModel()
    
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
                    
                    if viewModel.isKnowledgeGraphEnabled && !viewModel.isIndexing {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 20, weight: .medium))
                            
                            Button("Revoke") {
                                viewModel.revokeKnowledgeGraph()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .foregroundColor(.red)
                        }
                    } else if viewModel.isIndexing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            Text("Indexing...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    } else {
                        Button("Enable") {
                            viewModel.showingEnableConfirmation = true
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
                
                // Visualize Button (only shown when Graph Visualizer is enabled and KG is enabled)
                if viewModel.isGraphVisualizerEnabled && viewModel.isKnowledgeGraphEnabled && !viewModel.isIndexing {
                    HStack {
                        Spacer()
                        
                        Button("Visualize") {
                            viewModel.showingVisualization = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
            if !viewModel.enabledFileBookmarks.isEmpty {
              VStack(alignment: .leading, spacing: 12) {
                Text("Files/Folders Enabled:")
                  .font(.system(size: 18, weight: .semibold))

                  ForEach(viewModel.enabledFileBookmarks) { bookmark in
                        ZStack(alignment: .topLeading) {
                          // ✖️ remove-button
                          Button {
                            viewModel.removeBookmark(bookmark)
                          } label: {
                            Image(systemName: "xmark.circle.fill")
                              .font(.system(size: 14))
                              .foregroundColor(.secondary)
                          }
                          .buttonStyle(PlainButtonStyle())
                          .padding(4)

                          // 📂 the main open-item button
                          Button {
                            guard bookmark.url.startAccessingSecurityScopedResource() else { return }
                            NSWorkspace.shared.open(bookmark.url)
                          } label: {
                            HStack {
                              Image(systemName: bookmark.url.hasDirectoryPath ? "folder.fill" : "doc.fill")
                              VStack(alignment: .leading) {
                                Text(bookmark.url.lastPathComponent)
                                  .fontWeight(.medium)
                                Text(bookmark.url.path)
                                  .font(.caption2)
                                  .foregroundColor(.secondary)
                                  .lineLimit(1)
                                  .truncationMode(.middle)
                              }
                              Spacer()
                              Image(systemName: "arrow.up.right.square")
                            }
                            .padding(8)
                            .background(
                              RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                            )
                          }
                          .buttonStyle(PlainButtonStyle())
                          .padding(.leading, 24) // make room for the “x”
                        }
                      }
                  Button {
                        viewModel.showingFilePicker = true
                      } label: {
                        HStack {
                          Image(systemName: "plus.circle.fill")
                          Text("Add More…")
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.1)))
                        .overlay(
                          RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 1)
                        )
                      }
                      .buttonStyle(PlainButtonStyle())
                      .padding(.top, 4)
                    }
              .padding(.horizontal)
            }


            
            // Knowledge Graph Settings (only shown when enabled)
            if viewModel.isKnowledgeGraphEnabled && !viewModel.isIndexing {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Knowledge Graph Settings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        // Advanced Mode Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Advanced Mode")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Enable Advanced Mode, giving you more granular control over your knowledge graph")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.isAdvancedModeEnabled)
                                .toggleStyle(SwitchToggleStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Graph Visualizer
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Graph Visualizer")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Visualize your knowledge graph connections")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.isGraphVisualizerEnabled)
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Semantic Search")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(viewModel.isAdvancedModeEnabled ? .primary : .secondary)
                                Text("Search through your knowledge graph using natural language")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(viewModel.isAdvancedModeEnabled ? .secondary : .gray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: .constant(false))
                                .disabled(!viewModel.isAdvancedModeEnabled)
                                .toggleStyle(SwitchToggleStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Knowledge Connections
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Knowledge Connections")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(viewModel.isAdvancedModeEnabled ? .primary : .secondary)
                                Text("Discover connections between different pieces of knowledge")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(viewModel.isAdvancedModeEnabled ? .secondary : .gray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: .constant(false))
                                .disabled(!viewModel.isAdvancedModeEnabled)
                                .toggleStyle(SwitchToggleStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Learning Analytics
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Learning Analytics")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(viewModel.isAdvancedModeEnabled ? .primary : .secondary)
                                Text("Track and analyze your knowledge growth patterns")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(viewModel.isAdvancedModeEnabled ? .secondary : .gray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: .constant(false))
                                .disabled(!viewModel.isAdvancedModeEnabled)
                                .toggleStyle(SwitchToggleStyle())
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
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        // Google Drive
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Google Drive")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Google Drive connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Gmail
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gmail")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Gmail connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Slack
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Slack")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Slack connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Notion
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notion")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Notion connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Linear
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Linear")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Linear connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Jira
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Jira")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Jira connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        
                        // Git
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Git")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Connect") {
                                // TODO: Handle Git connection
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(true)
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
        .alert("Enable Knowledge Graph", isPresented: $viewModel.showingEnableConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Enable") {
        
                viewModel.enableKnowledgeGraph()
            }
            Button("Enable for Specific Locations...") {
                viewModel.showingFilePicker = true
            }
        } message: {
            Text("Are you sure you want to enable your knowledge graph? This will allow the system to access your complete knowledge profile.")
        }
        .alert("Indexing Files", isPresented: $viewModel.showingIndexingDialog) {
            // No buttons for this alert
        } message: {
            Text("Knowledge graph is currently indexing your files. This may take a while.")
        }
        .alert("Indexing Complete", isPresented: $viewModel.showingIndexingComplete) {
            Button("OK") { }
        } message: {
            Text("Your personal profile is ready!")
        }
        .sheet(isPresented: $viewModel.showingVisualization) {
            VisualizationView()
        }
        .fileImporter(
          isPresented: $viewModel.showingFilePicker,
          allowedContentTypes: [UTType.folder, UTType.item],
          allowsMultipleSelection: true
        ) { result in
          switch result {
          case .success(let urls):
            for url in urls {
              // 1️⃣ Immediately start access—while the sandbox grant is still valid
              guard url.startAccessingSecurityScopedResource() else {
                print("[KGCP] Could not start access for \(url)")
                continue
              }

              // 2️⃣ Create & store the security-scoped bookmark right here
              do {
                let data = try url.bookmarkData(
                  options: [.withSecurityScope],
                  includingResourceValuesForKeys: nil,
                  relativeTo: nil
                )
                viewModel.store(bookmarkData: data, for: url)
              } catch {
                print("[KGCP] Bookmark creation error for \(url): \(error)")
              }
            }

            // 3️⃣ Now that at least one folder/file is bookmarked, enable the KG
            viewModel.enableKnowledgeGraph()

          case .failure(let error):
            print("[KGCP] File picker error: \(error)")
          }
        }
    }
}

struct VisualizationView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Text("Knowledge Graph Visualization")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Color.clear.frame(width: 60, height: 1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Image
            ScrollView([.horizontal, .vertical]) {
                Image("kg_visualization_dot")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(20)
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
