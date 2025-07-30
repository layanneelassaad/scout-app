//
//  IndexDirectoryManager.swift
//  Scout
//
//  Created by Alec Alameddine on 7/30/25.
//

import Foundation
import SwiftUI
import AppKit

class IndexDirectoryManager: ObservableObject {
    static let shared = IndexDirectoryManager()
    
    @Published var isShowingDialog = false
    @Published var isIndexing = false
    @Published var indexingProgress = ""
    @Published var indexingResult: IndexingResult?
    
    private let apiService = APIService()
    
    private init() {}
    
    func showIndexDirectoryDialog() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a directory to index"
        panel.prompt = "Index Directory"
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.indexDirectory(path: url.path)
            }
        }
    }
    
    func indexDirectory(path: String) {
        isIndexing = true
        indexingProgress = "Starting indexing..."
        
        Task {
            do {
                let result = try await apiService.indexDirectory(path: path)
                await MainActor.run {
                    self.isIndexing = false
                    self.indexingResult = result
                    self.showIndexingResult(result)
                }
            } catch {
                await MainActor.run {
                    self.isIndexing = false
                    self.indexingProgress = "Error: \(error.localizedDescription)"
                    self.showError("Indexing failed", error.localizedDescription)
                }
            }
        }
    }
    
    private func showIndexingResult(_ result: IndexingResult) {
        let alert = NSAlert()
        alert.messageText = "Indexing Complete"
        
        if result.success {
            alert.informativeText = """
            Successfully indexed directory!
            
            Files processed: \(result.filesProcessed)
            Files skipped: \(result.filesSkipped)
            Errors: \(result.totalErrors)
            """
            alert.alertStyle = .informational
        } else {
            alert.informativeText = "Failed to index directory: \(result.error ?? "Unknown error")"
            alert.alertStyle = .critical
        }
        
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showError(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

struct IndexingResult {
    let success: Bool
    let filesProcessed: Int
    let filesSkipped: Int
    let totalErrors: Int
    let error: String?
    
    init(from response: [String: Any]) {
        self.success = response["success"] as? Bool ?? false
        self.filesProcessed = response["files_processed"] as? Int ?? 0
        self.filesSkipped = response["files_skipped"] as? Int ?? 0
        self.totalErrors = response["total_errors"] as? Int ?? 0
        self.error = response["error"] as? String
    }
} 