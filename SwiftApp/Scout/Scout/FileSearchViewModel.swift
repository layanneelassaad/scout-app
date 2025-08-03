// FileSearchViewModel.swift
// Scout

import SwiftUI
import AppKit
import Combine

enum SearchMode {
    case content, files
}

@MainActor
final class FileSearchViewModel: ObservableObject {
    // MARK: - Published State
    @Published var searchText = ""
    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    @Published var commandStatus = ""
    @Published var currentCommand = "Ready. Enter a search query."
    @Published var files = [FileInfo]()               // for content‐mode chunks
    @Published var kgFileEntities = [KGFileEntity]()  // for files‐mode results
    @Published var isSearching = false
    @Published var rawSSEData = ""
    @Published var searchMode: SearchMode = .content
    @Published var isCommandStatusExpanded = false
    @Published var fileAccessBookmarks: [(url: URL, data: Data)] = []
    
    // MARK: - Private
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    private var matchingSourceFiles = Set<String>()   // collect source_file paths
    private let bookmarksKey = "enabledFileBookmarks"
    
   
    
    init() {
        print("[VM] init – binding to APIService")
        setupBindings()
        loadFileBookmarks()
    }
    
    private func loadFileBookmarks() {
        guard let dataArray = UserDefaults.standard.array(forKey: bookmarksKey) as? [Data]
        else { return }
        var resolved: [(URL, Data)] = []
        for data in dataArray{
            var stale = false
            do {
                let url = try URL(
                    resolvingBookmarkData: data,
                    options: [.withSecurityScope],
                    bookmarkDataIsStale: &stale
                )
                if url.startAccessingSecurityScopedResource() {
                    resolved.append((url, data))
                }
                
            } catch{
                print("[VM] failed to resolve bookmark:", error)
            }
        }
        self.fileAccessBookmarks = resolved
    }
    
    private func setupBindings() {
        // Connection status
        apiService.isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)
        
        apiService.connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                print("[VM] connectionStatus = \(status)")
                self.connectionStatus = status
                self.commandStatus += "\(Date()): \(status)\n"
            }
            .store(in: &cancellables)
        
        apiService.currentCommand
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cmd in
                guard let self = self else { return }
                print("[VM] currentCommand = \(cmd)")
                self.currentCommand = cmd
                self.commandStatus += "\(Date()): \(cmd)\n"
            }
            .store(in: &cancellables)
        
        // New chunk/file from SSE
        apiService.newFile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chunk in
                guard let self = self else { return }
                switch self.searchMode {
                case .content:
                    print("[VM] 📥 newFile chunk in content mode: \(chunk.path)")
                    self.files.append(chunk)
                case .files:
                    if let fileName = chunk.properties?["file_name"] {
                        
                        self.matchingSourceFiles.insert(fileName)
                    }
                }
            }
            .store(in: &cancellables)
        
        // On search completion
        apiService.searchDidComplete
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                print("[VM] 🔍 searchDidComplete – isSearching=false")
                self.isSearching = false
                
                Task {
                    do {
                        print("[VM] 📡 fetching all File entities from KG")
                        let resp = try await self.apiService.fetchEntitiesByType("File")
                        let hits = resp.results.filter { fe in
                            guard
                                let rawName = fe.properties?["file_name"],
                                case let .string(name) = rawName
                            else { return false }
                            return self.matchingSourceFiles.contains(name)
                        }
                        print("[VM] 🎯 filtered KGFileEntities count: \(hits.count)")
                        await MainActor.run { self.kgFileEntities = hits }
                    } catch {
                        print("[VM] ❌ fetchEntitiesByType error: \(error)")
                    }
                }
            }
            .store(in: &cancellables)
        
        // Raw SSE data dump
        apiService.rawSSEData
            .receive(on: DispatchQueue.main)
            .assign(to: &$rawSSEData)
    }
    
    // MARK: - Search
    func performSearch() {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        print("[VM] performSearch called with query: “\(q)”")
        guard !q.isEmpty else {
            print("[VM] 🛑 empty query – clearing all")
            files.removeAll()
            kgFileEntities.removeAll()
            currentCommand = "Please enter a search query."
            return
        }
        matchingSourceFiles.removeAll()
        files.removeAll()
        kgFileEntities.removeAll()
        isSearching = true
        commandStatus = ""
        currentCommand = "Searching for “\(q)”…"
        apiService.performSearch(query: q)
    }
    func fetchKGFiles(matching query: String) {
        print("[VM] fetchKGFiles(matching: “\(query)”)")
        Task {
            do {
                let resp = try await apiService.fetchEntitiesByType("File")
                let q = query.lowercased()
                let filtered = resp.results.filter { ent in
                    // 1️⃣ match against the entity name
                    let entityMatch = ent.entity.lowercased().contains(q)
                    
                    // 2️⃣ match against the "file_name" property *only* if it's a JSONValue.string
                    let fileNameMatch: Bool = {
                        guard
                            let raw = ent.properties?["file_name"],
                            case let .string(fn) = raw
                        else { return false }
                        return fn.lowercased().contains(q)
                    }()
                    
                    return entityMatch || fileNameMatch
                }
                print("[VM] fetchKGFiles → filtered: \(filtered.count) items")
                await MainActor.run { self.kgFileEntities = filtered }
            } catch {
                print("[VM] ❌ fetchKGFiles error: \(error)")
            }
        }
    }
    
    // MARK: - File Actions
    func openFile(_ file: FileInfo) {
        let url = URL(fileURLWithPath: file.path).standardizedFileURL
        openURL(url)

    }
    
    func revealInFinder(_ file: FileInfo) {
        let url = URL(fileURLWithPath: file.path).standardizedFileURL
        openURL(url)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    func setFileAccessBookmarks(_ bookmarks: [(URL, Data)]) {
        self.fileAccessBookmarks = bookmarks
    }
    
    func openKGFile(at path: String) {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        openURL(url)
    }
    private func openURL(_ url: URL) {
        if let (root, _) = fileAccessBookmarks.first(
            where: { url.path.hasPrefix($0.url.path) }
        ){
            _ = root.startAccessingSecurityScopedResource()
        }
        NSWorkspace.shared.open(url)
    }
}
