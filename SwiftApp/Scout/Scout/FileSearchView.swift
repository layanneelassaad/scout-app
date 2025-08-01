//
//  FileSearchView.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import SwiftUI
import Foundation

struct FileSearchView: View {
    @StateObject private var viewModel = FileSearchViewModel()
    @State private var showingSettings = false
    @State private var developerViewEnabled = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("File Search")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Search through your indexed files and content")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Settings Button
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Settings")
                    
                    // Connection Status (only show if developer view is enabled)
                    if developerViewEnabled {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(viewModel.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(viewModel.connectionStatus)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // Search Bar
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("Search for files, content, or topics...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .regular))
                            .onSubmit {
                                viewModel.performSearch()
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
                    
                    if viewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.8, anchor: .center)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Status Panels (only show if developer view is enabled)
            if developerViewEnabled {
                VStack(spacing: 16) {
                    // Command Status
                    StatusPanel(
                        title: "Command Status",
                        isExpanded: $viewModel.isCommandStatusExpanded,
                        content: viewModel.commandStatus,
                        currentCommand: viewModel.commandStatus.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.last ?? "Ready"
                    )
                    
                    // Raw SSE Data
                    StatusPanel(
                        title: "Raw SSE Data",
                        isExpanded: .constant(false),
                        content: viewModel.rawSSEData,
                        currentCommand: nil
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
            }
            
            // Files List
            VStack(spacing: 12) {
                HStack {
                    Text("Files (\(viewModel.files.count))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                if viewModel.files.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.secondary)
                        Text("No files found")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("Try searching for files or content")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.files) { file in
                                ModernFileRowView(file: file)
                                    .onTapGesture { viewModel.openFile(file) }
                                    .contextMenu {
                                        Button("Open") { viewModel.openFile(file) }
                                        Button("Reveal in Finder") { viewModel.revealInFinder(file) }
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingSettings) {
            SettingsView(developerViewEnabled: $developerViewEnabled)
        }
    }
}

struct StatusPanel: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: String
    let currentCommand: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if currentCommand != nil {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if isExpanded || currentCommand == nil {
                ScrollView {
                    Text(content)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .foregroundColor(title == "Raw SSE Data" ? .green : .primary)
                }
                .frame(height: 120)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
            } else {
                Text(currentCommand ?? "")
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
    }
}

struct ModernFileRowView: View {
    let file: FileInfo
    
    var body: some View {
        HStack(spacing: 12) {
            // File Icon
            Image(systemName: getFileIcon(for: file.path))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            // File Info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.path)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    if let type = file.type {
                        Text(type)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.2))
                            )
                            .foregroundColor(.blue)
                    }
                    
                    if let description = file.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 11, weight: .regular))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Score
            if let score = file.score {
                Text(String(format: "%.0f%%", score * 100))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.green.opacity(0.2))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func getFileIcon(for path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext"
        case "txt", "md": return "doc.text"
        case "jpg", "jpeg", "png", "gif": return "photo"
        case "mp4", "mov", "avi": return "video"
        case "mp3", "wav", "aac": return "music.note"
        case "zip", "rar", "7z": return "archivebox"
        default: return "doc"
        }
    }
}

struct FileSearchView_Previews: PreviewProvider {
    static var previews: some View {
        FileSearchView()
    }
}

struct SettingsView: View {
    @Binding var developerViewEnabled: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Developer View", isOn: $developerViewEnabled)
                    .font(.system(size: 14, weight: .medium))
                    .toggleStyle(SwitchToggleStyle())
                
                Text("Show connection status, command status, and raw data stream as the search agent traverses your knowledge graph.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(width: 400, height: 200)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
