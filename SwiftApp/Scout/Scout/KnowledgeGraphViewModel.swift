//
//  KnowledgeGraphViewModel.swift
//  Scout
//
//  Created by Alec Alameddine on 8/2/25.
//

import SwiftUI
struct FileBookmark: Identifiable {
  let id = UUID()
  let url: URL
  let data: Data
}

@MainActor
class KnowledgeGraphViewModel: ObservableObject {
    @Published var enabledFileBookmarks: [FileBookmark] = []
    
    private let bookmarksKey = "enabledFileBookmarks"
    
    @Published var isKnowledgeGraphEnabled: Bool {
        didSet { UserDefaults.standard.set(isKnowledgeGraphEnabled, forKey: "knowledgeGraphEnabled") }
    }
    @Published var isAdvancedModeEnabled: Bool {
        didSet { UserDefaults.standard.set(isAdvancedModeEnabled, forKey: "advancedModeEnabled") }
    }
    @Published var isGraphVisualizerEnabled: Bool {
        didSet { UserDefaults.standard.set(isGraphVisualizerEnabled, forKey: "graphVisualizerEnabled") }
    }
    
    @Published var isIndexing = false
    @Published var showingEnableConfirmation = false
    @Published var showingIndexingDialog = false
    @Published var showingIndexingComplete = false
    @Published var showingFilePicker = false
    @Published var showingVisualization = false
    
    init() {
        let defaults = UserDefaults.standard
        // Check if each key exists in UserDefaults (first time vs existing user)
        self.isKnowledgeGraphEnabled = defaults.bool(forKey: "knowledgeGraphEnabled")
        
        let hasAdvancedModeBeenSet = UserDefaults.standard.object(forKey: "advancedModeEnabled") != nil
        let hasGraphVisualizerBeenSet = UserDefaults.standard.object(forKey: "graphVisualizerEnabled") != nil
        
        // Load persistent state from UserDefaults, default to false for new users
        
        self.isAdvancedModeEnabled = hasAdvancedModeBeenSet ? UserDefaults.standard.bool(forKey: "advancedModeEnabled") : false
        self.isGraphVisualizerEnabled = hasGraphVisualizerBeenSet ? UserDefaults.standard.bool(forKey: "graphVisualizerEnabled") : false
        
        loadBookmarks()
        
        
    }
    
    
    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: "knowledgeGraphEnabled")
        UserDefaults.standard.removeObject(forKey: "advancedModeEnabled")
        UserDefaults.standard.removeObject(forKey: "graphVisualizerEnabled")
        
        self.isKnowledgeGraphEnabled = false
        self.isAdvancedModeEnabled = false
        self.isGraphVisualizerEnabled = false
    }
    
    func enableKnowledgeGraph() {
        isIndexing = true
        showingIndexingDialog = true
        
        // Show indexing complete after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showingIndexingDialog = false
            self.showingIndexingComplete = true
            self.isIndexing = false
            self.isKnowledgeGraphEnabled = true
        }
    }
    
    func revokeKnowledgeGraph() {
        isKnowledgeGraphEnabled = false
        isAdvancedModeEnabled = false
    }
    private func loadBookmarks() {
        guard let dataArray = UserDefaults.standard.array(forKey: bookmarksKey) as? [Data] else { return }
        for data in dataArray {
            do {
                var stale = false
                let url = try URL(
                    resolvingBookmarkData: data,
                    options: [.withSecurityScope],
                    bookmarkDataIsStale: &stale
                )
                if url.startAccessingSecurityScopedResource() {
                    enabledFileBookmarks.append(FileBookmark(url: url, data: data))
                }
            } catch {
                print("[KGVM] Failed to resolve bookmark: \(error)")
            }
        }
    }
    
    
    func addEnabledURLs(_ urls: [URL]) {
        var stored = UserDefaults.standard.array(forKey: bookmarksKey) as? [Data] ?? []
        for url in urls {
            do {
                let bookmark = try url.bookmarkData(
                    options: [.withSecurityScope],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                guard !stored.contains(bookmark) else { continue }
                stored.append(bookmark)
                UserDefaults.standard.set(stored, forKey: bookmarksKey)

                var stale = false
                let resolved = try URL(
                    resolvingBookmarkData: bookmark,
                    options: [.withSecurityScope],
                    bookmarkDataIsStale: &stale
                )
                if resolved.startAccessingSecurityScopedResource() {
                    enabledFileBookmarks.append(FileBookmark(url: resolved, data: bookmark))
                }
            } catch {
                print("[KGVM] Bookmark error for URL \(url): \(error)")
            }
        }
    }
    func store(bookmarkData data: Data, for url: URL) {
      var stored = UserDefaults.standard.array(forKey: bookmarksKey) as? [Data] ?? []
      guard !stored.contains(data) else { return }
      stored.append(data)
      UserDefaults.standard.set(stored, forKey: bookmarksKey)

      // Keep the live bookmark so the UI can show it immediately:
      enabledFileBookmarks.append(FileBookmark(url: url, data: data))
    }
    
    func removeBookmark(_ bookmark: FileBookmark) {
            // 1️⃣ Stop the security-scoped session
            bookmark.url.stopAccessingSecurityScopedResource()

            // 2️⃣ Remove its data from UserDefaults
            var stored = UserDefaults.standard.array(forKey: bookmarksKey) as? [Data] ?? []
            if let idx = stored.firstIndex(of: bookmark.data) {
                stored.remove(at: idx)
                UserDefaults.standard.set(stored, forKey: bookmarksKey)
            }

            // 3️⃣ Update our published array
            if let vmIdx = enabledFileBookmarks.firstIndex(where: { $0.id == bookmark.id }) {
                enabledFileBookmarks.remove(at: vmIdx)
            }
        }
    
}
