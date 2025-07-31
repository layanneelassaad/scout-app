//
//  FileSearchViewModel.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import SwiftUI
import AppKit
import Combine

// MARK: - Data Model

struct FileInfo: Decodable, Identifiable, Hashable {
    var id: String { path }
    let path: String
    let score: Double?
    let type: String?
    let description: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
        lhs.path == rhs.path
    }
    
    enum CodingKeys: String, CodingKey {
        case path, score, type, description
    }
}

// MARK: - View Model

@MainActor
final class FileSearchViewModel: ObservableObject {

    // MARK: - Published State
    @Published var searchText = ""
    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    @Published var commandStatus = ""
    @Published var currentCommand = "Ready. Enter a search query."
    @Published var files = [FileInfo]()
    @Published var isCommandStatusExpanded = false
    @Published var isSearching = false
    @Published var rawSSEData = ""

    // MARK: - Private Properties
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to updates from the APIService
        setupBindings()
    }

    private func setupBindings() {
        apiService.isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)

        apiService.connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.connectionStatus = status
                self?.commandStatus += "\(Date().formatted(date: .omitted, time: .standard)): \(status)\n"
            }
            .store(in: &cancellables)

        apiService.currentCommand
            .receive(on: DispatchQueue.main)
            .sink { [weak self] command in
                self?.currentCommand = command
                self?.commandStatus += "\(Date().formatted(date: .omitted, time: .standard)): \(command)\n"
            }
            .store(in: &cancellables)

        apiService.newFile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] file in
              
                self?.files.append(file)
               
            }
            .store(in: &cancellables)

        apiService.searchDidComplete
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isSearching = false
            }
            .store(in: &cancellables)
            
        apiService.rawSSEData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rawData in
                self?.rawSSEData = rawData
            }
            .store(in: &cancellables)
    }

    // MARK: - Search
    func performSearch() {
        guard !searchText.isEmpty else {
            files.removeAll()
            currentCommand = "Please enter a search query."
            return
        }

        isSearching = true
        files.removeAll()
        commandStatus = ""
        currentCommand = "Initiating search for: \(searchText)..."
        
        apiService.performSearch(query: searchText)
    }

    // MARK: - File Actions
    func openFile(_ file: FileInfo) {
        currentCommand = "Opening: \(file.path)"
        commandStatus += "\(Date().formatted(date: .omitted, time: .standard)): Opening: \(file.path)\n"
        #if canImport(AppKit)
        NSWorkspace.shared.open(URL(fileURLWithPath: file.path))
        #endif
    }

    func revealInFinder(_ file: FileInfo) {
        #if canImport(AppKit)
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: file.path)])
        #endif
    }
}
