//
//  APIService.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import Foundation
import Combine


// MARK: - API Data Models

private struct MakeSessionResponse: Decodable { let log_id: String }
private struct EventPayload:      Decodable { let command: String?; let args: [String: String]?; let result: CommandResult? }
private struct CommandResult:     Decodable {
    let entity: String?; let type: String?; let description: String?; let score: Double?; let properties: [String: String]?
    enum CodingKeys: String, CodingKey { case entity, type, description, score, properties }
}




// The 'result' field in a command_result event can be a string or a structured object.
// This enum handles decoding for either case.


// MARK: - Data Models





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
    private var session: URLSession!; private var sseTask: URLSessionDataTask?
    private var dataBuffer = Data()
    

    override init() {
            super.init()
            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }

    // MARK: - Main Search Function
    func performSearch(query: String) {
        searchResults.removeAll()
        Task {
          do {
            connectionStatus.send("Creating session…")
            guard let id = try await makeSession() else {
              connectionStatus.send("Failed to get session")
              isConnected.send(false)
              return
            }
            connectionStatus.send("Session created")
            connectToSSE(sessionId: id)
            try await sendSearchQuery(sessionId: id, query: query)
            isConnected.send(true)
          } catch {
            connectionStatus.send("Search error: \(error)")
            isConnected.send(false)
            isSearching.send(false)
          }
        }
      }

    // MARK: - Networking Steps

    private func makeSession() async throws -> String? {
      let url = URL(string: "\(baseURL)/makesession/kg2?api_key=<YOUR_KEY>")!
      let (data, resp) = try await URLSession.shared.data(from: url)
      guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return nil }
      return try JSONDecoder().decode(MakeSessionResponse.self, from: data).log_id
    }

    private func connectToSSE(sessionId: String) {
       let url = URL(string: "\(baseURL)/chat/\(sessionId)/events?api_key=<YOUR_KEY>")!
       sseTask = session.dataTask(with: url)
       sseTask?.resume()
       connectionStatus.send("Connected to SSE")
     }
    
    
    private func sendSearchQuery(sessionId: String, query: String) async throws {
       let url = URL(string: "\(baseURL)/chat/\(sessionId)/send?api_key=<YOUR_KEY>")!
       var req = URLRequest(url: url)
       req.httpMethod = "POST"
       req.setValue("application/json", forHTTPHeaderField: "Content-Type")
       req.httpBody = try JSONEncoder().encode([["type":"text","text":query]])
       let (_, resp) = try await URLSession.shared.data(for: req)
       guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
         throw URLError(.badServerResponse)
       }
     }
    
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let chunk = String(decoding: data, as: UTF8.self)
        print("===== SSE RAW CHUNK =====\n\(chunk)\n========================")
        dataBuffer.append(data)
        processBuffer()
    }
    
    private func processBuffer() {
        let sep = "\n\n".data(using: .utf8)!
        while let range = dataBuffer.range(of: sep) {
            let msgData = dataBuffer.subdata(in: 0..<range.lowerBound)
            dataBuffer.removeSubrange(0..<range.upperBound)
            if let msg = String(data: msgData, encoding: .utf8) {
                parseSSEMessage(msg)
            }
        }
    }
    
    private func parseSSEMessage(_ msg: String) {
           print("===== PARSING SSE MESSAGE =====\n\(msg)\n===============================")
           var eventName = "message"
           var payload = ""
           for line in msg.split(whereSeparator: \.isNewline) {
               if line.hasPrefix("event:") {
                   eventName = String(line.dropFirst("event:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
               }
               if line.hasPrefix("data:") {
                   let dataPart = String(line.dropFirst("data:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                   payload += dataPart
               }
           }
           print("[APIService] parsed eventName = \(eventName)")
           print("[APIService] parsed payload = \(payload)")
           guard !payload.isEmpty, let d = payload.data(using: .utf8) else {
               print("[APIService] ⚠️ payload empty or invalid UTF-8")
               return
           }
           do {
               let ev = try JSONDecoder().decode(EventPayload.self, from: d)
               print("[APIService] ✅ decoded EventPayload: \(ev)")
               processParsedEvent(name: eventName, payload: ev)
           } catch {
               print("[APIService] ❌ JSON-decode error: \(error)\npayload: \(payload)")
               currentCommand.send("JSON-decode error: \(error)")
           }
       }
    
    private func processParsedEvent(name: String, payload: EventPayload) {
      DispatchQueue.main.async {
        switch name {
          case "partial_command","running_command":
            if let cmd = payload.command {
              if let args = payload.args, !args.isEmpty {
                let a = args.map { "\($0)=\($1)" }.joined(separator: ", ")
                self.currentCommand.send("\(cmd): \(a)")
              } else {
                self.currentCommand.send(cmd)
              }
            }
          case "command_result":
            if let r = payload.result, let e = r.entity, let t = r.type {
              let fi = FileInfo(path:e, score:r.score, type:t, description:r.description, properties: r.properties )
              self.searchResults.append(fi)
              self.newFile.send(fi)
              self.currentCommand.send("Found: \(e)")
            }
          case "search_complete","finished_chat":
            self.isSearching.send(false)
            self.searchDidComplete.send()
            self.connectionStatus.send("Done: \(self.searchResults.count) results")
          default: break
        }
      }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
          self.isConnected.send(false)
          self.isSearching.send(false)
          if let u = error as? URLError, u.code == .cancelled {
            self.connectionStatus.send("Disconnected")
          } else if let e = error {
            self.connectionStatus.send("SSE error: \(e.localizedDescription)")
          } else {
            self.connectionStatus.send("Disconnected")
          }
        }
      }
    
    func fetchEntitiesByType(_ type: String) async throws -> KGListResponse {
       let url = URL(string: "\(baseURL)/api/kg/entities-by-type/\(type)?api_key=<YOUR_KEY>")!
       let (data, resp) = try await URLSession.shared.data(from: url)
       guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
         throw URLError(.badServerResponse)
       }
       return try JSONDecoder().decode(KGListResponse.self, from: data)
     }
    
    
    func disconnect() {
        sseTask?.cancel()
        isConnected.send(false)
        connectionStatus.send("Disconnected")
    }

    // MARK: - URLSessionDataDelegate (for SSE)


   

   
   
   
    
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
