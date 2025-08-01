//
//  APIService.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import Foundation
import Combine

// MARK: - API Data Models


struct MakeSessionResponse: Decodable {
    let log_id: String
}


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
       
        
        searchResults.removeAll()
        Task {
            do {
                connectionStatus.send("Creating session...")
              
                
         
                guard let sessionId = try await makeSession() else {
                  
                    connectionStatus.send("Error: Could not create session")
                    isConnected.send(false)
                    return
                }
             
                connectionStatus.send("Session created successfully")

         
                connectToSSE(sessionId: sessionId)

              
                try await sendSearchQuery(sessionId: sessionId, query: query)
                
            
                isConnected.send(true)

            } catch {
       
                connectionStatus.send("Search failed: \(error.localizedDescription)")
                isConnected.send(false)
            }
        }
    }

    // MARK: - Networking Steps

    private func makeSession() async throws -> String? {
       
        guard let url = URL(string: "\(baseURL)/makesession/kg2?api_key=3d453a5f-1bd8-4d92-b8b8-f4bae99ccda4") else { 
      
            connectionStatus.send("Error: Invalid session URL")
            return nil 
        }
        
    
        let (data, httpResponse) = try await URLSession.shared.data(from: url)
        
        // Check for successful HTTP response
        guard let httpResponse = httpResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
           
            connectionStatus.send("Error: Backend returned status \(httpResponse)")
            return nil
        }
        
       
        
        let sessionResponse = try JSONDecoder().decode(MakeSessionResponse.self, from: data)
   
        return sessionResponse.log_id
    }

    private func connectToSSE(sessionId: String) {
       
        guard let url = URL(string: "\(baseURL)/chat/\(sessionId)/events?api_key=3d453a5f-1bd8-4d92-b8b8-f4bae99ccda4") else { 
           
            connectionStatus.send("Error: Invalid SSE URL")
            isConnected.send(false)
            return 
        }

        sseTask = session.dataTask(with: url)
        sseTask?.resume()

        connectionStatus.send("Connected to event stream")
    }

    private func sendSearchQuery(sessionId: String, query: String) async throws {
       
        guard let url = URL(string: "\(baseURL)/chat/\(sessionId)/send?api_key=3d453a5f-1bd8-4d92-b8b8-f4bae99ccda4") else { 
            
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
    
        let body = [["type": "text", "text": query]]
        request.httpBody = try JSONEncoder().encode(body)
        
      
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for successful HTTP response
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
         
            throw URLError(.badServerResponse)
        }
      
    }
    
    func disconnect() {
        sseTask?.cancel()
        isConnected.send(false)
        connectionStatus.send("Disconnected")
    }

    // MARK: - URLSessionDataDelegate (for SSE)

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let rawData = String(data: data, encoding: .utf8) ?? "nil"
       
        
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
               
                parseSSEMessage(messageString)
            }
        }
    }

    private func parseSSEMessage(_ messageString: String) {
   
        var eventName = "message" // Default event type per SSE spec
        var dataContent = ""

        // Split message into lines, handling both \n and \r\n
        let lines = messageString.split(whereSeparator: \.isNewline)
        for line in lines {
            if line.hasPrefix("event:") {
                eventName = String(line.dropFirst(6).trimmingCharacters(in: .whitespaces))
               
            } else if line.hasPrefix("data:") {
                // Append data, removing the prefix. A single event can have multiple data lines.
                dataContent += String(line.dropFirst(5).trimmingCharacters(in: .whitespaces))
            }
        }
        
    
      
        guard !dataContent.isEmpty, let jsonData = dataContent.data(using: .utf8) else {
           
            return
        }
        
        do {
            let payload = try JSONDecoder().decode(EventPayload.self, from: jsonData)
            
            processParsedEvent(name: eventName, payload: payload)
        } catch {
          
            currentCommand.send("SSE JSON Decode Error: \(error.localizedDescription) for data: \(dataContent)")
        }
    }

    private func processParsedEvent(name: String, payload: EventPayload) {
       
        DispatchQueue.main.async {
            switch name {
            case "partial_command", "running_command": // Handle both potential event names
               
                if let command = payload.command {
                    if let args = payload.args, !args.isEmpty {
                        let argsString = args.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                       
                        self.currentCommand.send("\(command): \(argsString)")
                    } else {
                   
                        self.currentCommand.send(command)
                    }
                }
                
            case "command_result":
       
                if let result = payload.result {
                 
                    
                    // Handle search results - the backend sends results in the 'result' field
                    if let entity = result.entity, let type = result.type {
                     
                        
                        // Create FileInfo from the search result
                        let fileInfo = FileInfo(
                            path: entity,
                            score: result.score,
                            type: type,
                            description: result.description
                        )
                        
                     
                        self.newFile.send(fileInfo)
                        
                        // Update current command to show that results are being found
                        self.currentCommand.send("Found: \(entity)")
                    }
                }
                
            case "search_complete", "finished_chat":
             
                self.isSearching.send(false)
                self.searchDidComplete.send()
                self.connectionStatus.send("Search completed with \(self.searchResults.count) results")
                
            default:
                print("[APIService] Unknown event type: \(name)")
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            self.isConnected.send(false)

            // If the error is a cancellation, it's an expected part of the disconnect flow.
            // We don't need to show a user-facing message.
            if let urlError = error as? URLError, urlError.code == .cancelled {
                self.connectionStatus.send("Disconnected")
                return
            }

            // For other actual errors, report them.
            if let error = error {
                self.connectionStatus.send("SSE Error: \(error.localizedDescription)")
            } else {
                self.connectionStatus.send("Disconnected")
            }
        }
    }
    
    // MARK: - Directory Indexing
    
    func indexDirectory(path: String) async throws -> IndexingResult {
       
        
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
            
            throw URLError(.badServerResponse)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        
        return IndexingResult(from: json)
    }
}
