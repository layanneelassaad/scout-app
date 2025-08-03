import SwiftUI

// MARK: - Shared Icon Helper

private func fileIcon(forExt ext: String) -> String {
    switch ext.lowercased() {
    case "pdf":                return "doc.richtext"
    case "txt", "md":          return "doc.text"
    case "jpg", "jpeg", "png", "gif": return "photo"
    case "mp4", "mov", "avi":  return "video"
    case "mp3", "wav", "aac":  return "music.note"
    case "zip", "rar", "7z":   return "archivebox"
    default:                   return "doc"
    }
}

// MARK: - Content (SSE) Row

struct ModernFileRowView: View {
    let file: FileInfo
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: fileIcon(forExt: (file.path as NSString).pathExtension))
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(file.path)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 8) {
                    if let type = file.type {
                        Text(type)
                            .font(.system(size: 11, weight: .medium))
                            .padding(4)
                            .background(Capsule().fill(Color.blue.opacity(0.2)))
                    }
                    if let desc = file.description {
                        Text(desc)
                            .font(.system(size: 11))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            if let score = file.score {
                Text(String(format: "%.0f%%", score * 100))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.green.opacity(0.2)))
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
    }
}

// MARK: - KG Entity Row
struct KGFileRowView: View {
    let file: KGFileEntity

    // Helpers
    private var fileName: String {
        file.properties?["file_name"]?.stringValue
            ?? file.entity.replacingOccurrences(of: "File:", with: "")
    }
    private var createdDate: String? {
        file.properties?["created_date"]?.stringValue
            .flatMap { ISO8601DateFormatter().date(from: $0) }
            .map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none) }
    }
    private var fileType: String? {
        file.properties?["file_extension"]?.stringValue
    }
    private var fileSize: String? {
        file.properties?["file_size"]?.stringValue
    }
    private var fullPath: String? {
        file.properties?["full_path"]?.stringValue
    }
    private var directoryName: String? {
        if let path = fullPath {
            return URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 1) File name
            HStack(spacing: 12) {
                Image(systemName: fileIcon(forExt: fileType ?? ""))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)

                Text(fileName)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(1)

                Spacer()
            }

            // 2) Found in…
            if let dir = directoryName {
                Text("Found in: \(dir)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 3) Metadata rows
            VStack(alignment: .leading, spacing: 4) {
                if let date = createdDate {
                    HStack {
                        Text("Date created:")
                            .fontWeight(.medium)
                        Text(date)
                    }
                    .font(.caption)
                }
                if let type = fileType {
                    HStack {
                        Text("File type:")
                            .fontWeight(.medium)
                        Text(type)
                    }
                    .font(.caption)
                }
                if let size = fileSize {
                    HStack {
                        Text("File size:")
                            .fontWeight(.medium)
                        Text(size)
                    }
                    .font(.caption)
                }
                if let path = fullPath {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("File path:")
                            .fontWeight(.medium)
                        Text(path)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }

        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - Status Panel

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
                        .foregroundColor(title == "Raw Stream" ? .green : .primary)
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

// MARK: - Content List View

struct ContentFileListView: View {
    @ObservedObject var viewModel: FileSearchViewModel

    // Filter out any ::chunk_ entries
    private var visibleFiles: [FileInfo] {
        viewModel.files.filter { !$0.path.contains("::chunk_") }
    }

    var body: some View {
        VStack(spacing: 20) {                      // ↑ a bit more breathing room
            HStack {
                // renamed for content‐mode
                Text("Results (\(visibleFiles.count))")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal)

            if visibleFiles.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.secondary)
                    Text("No results")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Try adjusting your query")
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {         // ↑ more vertical spacing
                        ForEach(visibleFiles) { file in
                            ModernFileRowView(file: file)
                                .onTapGesture { viewModel.openFile(file) }
                                .contextMenu {
                                    Button("Open") { viewModel.openFile(file) }
                                    Button("Reveal in Finder") { viewModel.revealInFinder(file) }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Binding var developerViewEnabled: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {                // ↑ extra spacing
            HStack {
                Text("Settings")
                    .font(.system(size: 22, weight: .bold))
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }

            Divider()

            // purple-tinted developer‐mode toggle
            Toggle(isOn: $developerViewEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Developer View")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Show low-level connection status & raw stream")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .purple))
            .padding(.horizontal)

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 400, minHeight: 240)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding()
    }
}

// MARK: - Main View

struct FileSearchView: View {
    @StateObject private var viewModel = FileSearchViewModel()
    @State private var showingSettings = false
    @State private var developerViewEnabled = false

    var body: some View {
        VStack(spacing: 0) {
            // --- Header & Search Bar ---
            VStack(spacing: 16) {                           // ↑ extra top/between spacing
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("File Scout")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Search through your indexed files and content")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if developerViewEnabled {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(viewModel.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(viewModel.connectionStatus)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
                    }
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search files, content, topics…", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .onSubmit { viewModel.performSearch() }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))

                    if viewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()
                .background(Color.gray.opacity(0.3))

            // --- Developer Panels (if enabled) ---
            if developerViewEnabled {
                VStack(spacing: 20) {
                    StatusPanel(
                        title: "Command Status",
                        isExpanded: $viewModel.isCommandStatusExpanded,
                        content: viewModel.commandStatus,
                        currentCommand: viewModel.currentCommand
                    )
                    StatusPanel(
                        title: "Raw Stream",
                        isExpanded: .constant(false),
                        content: viewModel.rawSSEData,
                        currentCommand: nil
                    )
                }
                .padding()
                Divider().background(Color.gray.opacity(0.3))
            }

            // --- Mode Picker ---
            Picker("", selection: $viewModel.searchMode) {
                Text("Content").tag(SearchMode.content)
                Text("Files").tag(SearchMode.files)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)           // ↑ extra vertical padding

            // --- Results Pane ---
            Group {
                if viewModel.searchMode == .content {
                    ContentFileListView(viewModel: viewModel)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.kgFileEntities) { fe in
                                KGFileRowView(file: fe)
                                    .onTapGesture {
                                        if let raw = fe.properties?["full_path"],
                                           case let .string(path) = raw {
                                            viewModel.openKGFile(at: path)
                                        }
                                    }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .animation(.easeInOut, value: viewModel.searchMode)
        }
        .background(Color(NSColor.windowBackgroundColor).ignoresSafeArea())
        .sheet(isPresented: $showingSettings) {
            SettingsView(developerViewEnabled: $developerViewEnabled)
        }
        .onAppear { print("[View] FileSearchView appeared") }
    }
}

struct FileSearchView_Previews: PreviewProvider {
    static var previews: some View {
        FileSearchView()
    }
}
