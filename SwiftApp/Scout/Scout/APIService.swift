//
//  APIService.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import Foundation
import Combine

// MARK: - API Data Models

// For parsing the response from /makesession/kg2
struct MakeSessionResponse: Decodable {
    let log_id: String
}

// A helper to decode any JSON value (String, Int, Double, Bool)
// and convert it to a String for display.
enum JSONValue: Decodable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported JSON type"))
        }
    }

    var description: String {
        switch self {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return String(b)
        case .array(let a):
            return "[" + a.map { $0.description }.joined(separator: ", ") + "]"
        case .object(let o):
            return "{" + o.map { "\($0.key): \($0.value.description)" }.joined(separator: ", ") + "}"
        }
    }
}

// The 'result' field in a command_result event can be a string or a structured object.
// This enum handles decoding for either case.
enum CommandResultValue: Decodable {
    case string(String)
    case structured(CommandResult)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let val = try? container.decode(CommandResult.self) {
            self = .structured(val)
            return
        }
        if let val = try? container.decode(String.self) {
            self = .string(val)
            return
        }
        throw DecodingError.typeMismatch(CommandResultValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Result is not a String or a CommandResult object"))
    }
}

// MARK: - Data Models

struct EventPayload: Decodable {
    let command: String?
    let args: [String: String]?
    let result: CommandResult?
}

struct CommandResult: Decodable {
    let entity: String?
    let type: String?
    let description: String?
    let score: Double?
    let properties: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case entity, type, description, score, properties
    }
}


// MARK: - API Service

final class APIService: NSObject, URLSessionDataDelegate {

    // MARK: - Published Properties
    @Published var isConnected = CurrentValueSubject<Bool, Never>(false)
    @Published var connectionStatus = CurrentValueSubject<String, Never>("Disconnected")
    @Published var currentCommand = CurrentValueSubject<String, Never>("")
    @Published var newFile = PassthroughSubject<FileInfo, Never>()
    @Published var searchDidComplete = PassthroughSubject<Void, Never>()
    @Published var isSearching = CurrentValueSubject<Bool, Never>(false)
    @Published var searchResults: [FileInfo] = []
    @Published var rawSSEData = CurrentValueSubject<String, Never>("")

    // MARK: - Private Properties
    private let baseURL = "http://127.0.0.1:8020"
    private var session: URLSession!
    private var sseTask: URLSessionDataTask?
    private var dataBuffer = Data()

    override init() {
        super.init()
        // Using a delegate-based session to handle the SSE stream
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    // MARK: - Main Search Function
    func performSearch(query: String) {
        print("🔍 [APIService] Starting search for: '\(query)'")
        // Clear previous search results
        searchResults.removeAll()
        Task {
            do {
                connectionStatus.send("Creating session...")
                print("🔍 [APIService] Creating session...")
                
                // 1. Create a session
                guard let sessionId = try await makeSession() else {
                    print("❌ [APIService] Failed to create session")
                    connectionStatus.send("Error: Could not create session")
                    isConnected.send(false)
                    return
                }
                print("✅ [APIService] Session created: \(sessionId)")
                connectionStatus.send("Session created successfully")

                // 2. Connect to the SSE events endpoint
                print("🔍 [APIService] Connecting to SSE events...")
                connectToSSE(sessionId: sessionId)

                // 3. Send the search query
                print("🔍 [APIService] Sending search query...")
                try await sendSearchQuery(sessionId: sessionId, query: query)
                
                print("✅ [APIService] Search query sent successfully")
                isConnected.send(true)

            } catch {
                print("❌ [APIService] Search failed: \(error.localizedDescription)")
                connectionStatus.send("Search failed: \(error.localizedDescription)")
                isConnected.send(false)
            }
        }
    }

    // MARK: - Networking Steps

    private func makeSession() async throws -> String? {
        print("🔍 [APIService] Making session request...")
        guard let url = URL(string: "\(baseURL)/makesession/kg2?api_key=3d453a5f-1bd8-4d92-b8b8-f4bae99ccda4") else { 
            print("❌ [APIService] Invalid session URL")
            connectionStatus.send("Error: Invalid session URL")
            return nil 
        }
        
        print("🔍 [APIService] Requesting session from: \(url)")
        let (data, httpResponse) = try await URLSession.shared.data(from: url)
        
        // Check for successful HTTP response
        guard let httpResponse = httpResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("❌ [APIService] Backend returned status \(httpResponse)")
            connectionStatus.send("Error: Backend returned status \(httpResponse)")
            return nil
        }
        
        print("✅ [APIService] Session response received, status: \(httpResponse.statusCode)")
        print("🔍 [APIService] Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        let sessionResponse = try JSONDecoder().decode(MakeSessionResponse.self, from: data)
        print("✅ [APIService] Session decoded successfully: \(sessionResponse.log_id)")
        return sessionResponse.log_id
    }

    private func connectToSSE(sessionId: String) {
        print("🔍 [APIService] Connecting to SSE with session: \(sessionId)")
        guard let url = URL(string: "\(baseURL)/chat/\(sessionId)/events?api_key=3d453a5f-1bd8-4d92-b8b8-f4bae99ccda4") else { 
            print("❌ [APIService] Invalid SSE URL")
            connectionStatus.send("Error: Invalid SSE URL")
            isConnected.send(false)
            return 
        }
        print("🔍 [APIService] SSE URL: \(url)")
        sseTask = session.dataTask(with: url)
        sseTask?.resume()
        print("✅ [APIService] SSE task started")
        connectionStatus.send("Connected to event stream")
    }

    private func sendSearchQuery(sessionId: String, query: String) async throws {
        print("🔍 [APIService] Sending search query: '\(query)' to session: \(sessionId)")
        guard let url = URL(string: "\(baseURL)/chat/\(sessionId)/send?api_key=3d453a5f-1bd8-4d92-b8b8-f4bae99ccda4") else { 
            print("❌ [APIService] Invalid search query URL")
            return 
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // The backend expects a JSON array with a single text object
        let body = [["type": "text", "text": query]]
        request.httpBody = try JSONEncoder().encode(body)
        
        print("🔍 [APIService] Search request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for successful HTTP response
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("❌ [APIService] Search query failed with status: \(response)")
            throw URLError(.badServerResponse)
        }
        print("✅ [APIService] Search query sent successfully, status: \(httpResponse.statusCode)")
        print("🔍 [APIService] Search response: \(String(data: data, encoding: .utf8) ?? "nil")")
    }
    
    func disconnect() {
        sseTask?.cancel()
        isConnected.send(false)
    }

    // MARK: - URLSessionDataDelegate (for SSE)

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let rawData = String(data: data, encoding: .utf8) ?? "nil"
        print("🔍 [APIService] Received SSE data: \(rawData)")
        
        // Check if this is a command_result event before sending to UI
        if rawData.contains("event: command_result") {
            DispatchQueue.main.async {
                self.rawSSEData.send(rawData)
            }
        }
        
        dataBuffer.append(data)
        processBuffer()
    }

    private func processBuffer() {
        // SSE messages are separated by double newlines.
        // The server uses CRLF line endings, so the separator is `\r\n\r\n`.
        let separator = "\r\n\r\n".data(using: .utf8)!
        while let range = dataBuffer.range(of: separator) {
            let messageData = dataBuffer.subdata(in: 0..<range.lowerBound)
            dataBuffer.removeSubrange(0..<range.upperBound)

            if let messageString = String(data: messageData, encoding: .utf8) {
                print("🔍 [APIService] Processing SSE message: \(messageString)")
                parseSSEMessage(messageString)
            }
        }
    }

    private func parseSSEMessage(_ messageString: String) {
        print("🔍 [APIService] Parsing SSE message: \(messageString)")
        var eventName = "message" // Default event type per SSE spec
        var dataContent = ""

        // Split message into lines, handling both \n and \r\n
        let lines = messageString.split(whereSeparator: \.isNewline)
        for line in lines {
            if line.hasPrefix("event:") {
                eventName = String(line.dropFirst(6).trimmingCharacters(in: .whitespaces))
                print("🔍 [APIService] Event type: \(eventName)")
            } else if line.hasPrefix("data:") {
                // Append data, removing the prefix. A single event can have multiple data lines.
                dataContent += String(line.dropFirst(5).trimmingCharacters(in: .whitespaces))
            }
        }
        
        print("🔍 [APIService] Event: \(eventName), Data: \(dataContent)")
      
        guard !dataContent.isEmpty, let jsonData = dataContent.data(using: .utf8) else {
            print("❌ [APIService] Empty data content or invalid encoding")
            return
        }
        
        do {
            let payload = try JSONDecoder().decode(EventPayload.self, from: jsonData)
            print("✅ [APIService] Successfully decoded event payload")
            processParsedEvent(name: eventName, payload: payload)
        } catch {
            print("❌ [APIService] SSE JSON Decode Error: \(error.localizedDescription) for data: \(dataContent)")
            currentCommand.send("SSE JSON Decode Error: \(error.localizedDescription) for data: \(dataContent)")
        }
    }

    private func processParsedEvent(name: String, payload: EventPayload) {
        print("🔍 [APIService] Processing parsed event: \(name)")
        print("🔍 [APIService] Event payload: \(payload)")
        DispatchQueue.main.async {
            switch name {
            case "partial_command", "running_command": // Handle both potential event names
                print("🔍 [APIService] Processing command event")
                if let command = payload.command {
                    if let args = payload.args, !args.isEmpty {
                        let argsString = args.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                        print("🔍 [APIService] Command with args: \(command): \(argsString)")
                        self.currentCommand.send("\(command): \(argsString)")
                    } else {
                        print("🔍 [APIService] Command without args: \(command)")
                        self.currentCommand.send(command)
                    }
                }
                
            case "command_result":
                print("🔍 [APIService] Processing command_result event")
                if let result = payload.result {
                    print("🔍 [APIService] Command result: \(result)")
                    
                    // Handle search results - the backend sends results in the 'result' field
                    if let entity = result.entity, let type = result.type {
                        print("🔍 [APIService] Found search result: \(entity) (\(type))")
                        
                        // Create FileInfo from the search result
                        let fileInfo = FileInfo(
                            path: entity,
                            score: result.score,
                            type: type,
                            description: result.description
                        )
                        
                        print("✅ [APIService] Adding search result: \(fileInfo)")
                        self.newFile.send(fileInfo)
                    }
                }
                
            case "search_complete", "finished_chat":
                print("🔍 [APIService] Processing search_complete/finished_chat event")
                self.isSearching.send(false)
                self.searchDidComplete.send()
                self.connectionStatus.send("Search completed with \(self.searchResults.count) results")
                
            default:
                print("🔍 [APIService] Unknown event type: \(name)")
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            self.isConnected.send(false)

            // If the error is a cancellation, it's an expected part of the disconnect flow.
            // We don't need to show a user-facing message.
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }

            // For other actual errors, report them.
            if let error = error {
                self.connectionStatus.send("SSE Error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Directory Indexing
    
    func indexDirectory(path: String) async throws -> IndexingResult {
        print("🔍 [APIService] Indexing directory: \(path)")
        
        guard let url = URL(string: "\(baseURL)/api/kg/index-directory") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["path": path]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ [APIService] Indexing failed with status: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        
        print("✅ [APIService] Indexing response: \(json)")
        return IndexingResult(from: json)
    }
}
