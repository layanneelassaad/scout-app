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

    var body: some View {
        VStack(spacing: 0) {
            // Search input
            HStack {
                TextField("Search for files, content, or topics...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        viewModel.performSearch()
                    }
                
                if viewModel.isSearching {
                    ProgressView()
                        .scaleEffect(0.5, anchor: .center)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Connection status
            HStack {
                Image(systemName: viewModel.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(viewModel.isConnected ? .green : .red)
                Text(viewModel.connectionStatus)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Command status (expandable)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Command Status")
                        .font(.subheadline.bold())
                    Spacer()
                    Button(action: { viewModel.isCommandStatusExpanded.toggle() }) {
                        Image(systemName: viewModel.isCommandStatusExpanded ? "chevron.up" : "chevron.down")
                    }
                }
                
                if viewModel.isCommandStatusExpanded {
                    ScrollView {
                        Text(viewModel.commandStatus)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(height: 200)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                } else {
                    Text(viewModel.currentCommand)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
            }
            .padding()
            
            // Raw SSE Data
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Raw SSE Data")
                        .font(.subheadline.bold())
                    Spacer()
                }
                
                ScrollView {
                    Text(viewModel.rawSSEData)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .foregroundColor(.green)
                }
                .frame(height: 100)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            }
            .padding()
            
            Divider()
            
            // Files list
            VStack {
                Text("Files count: \(viewModel.files.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                List(viewModel.files) { file in
                    FileRowView(file: file)
                        .onTapGesture { viewModel.openFile(file) }
                        .contextMenu {
                            Button("Open") { viewModel.openFile(file) }
                            Button("Reveal in Finder") { viewModel.revealInFinder(file) }
                        }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Scout File Search")
    }
}

struct FileRowView: View {
    let file: FileInfo
    
    var body: some View {
        HStack {
            Image(systemName: "doc")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.path)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack {
                    if let type = file.type {
                        Text("Type: \(type)")
                    }
                    if let description = file.description, !description.isEmpty {
                        Text("Description: \(description)")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let score = file.score {
                Text(String(format: "%.0f%%", score * 100))
                    .font(.body.monospacedDigit())
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FileSearchView_Previews: PreviewProvider {
    static var previews: some View {
        FileSearchView()
    }
}
