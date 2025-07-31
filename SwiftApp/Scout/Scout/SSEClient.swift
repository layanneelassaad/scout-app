//
//  SSEClient.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import Foundation
import Combine

final class SSEClient: NSObject, ObservableObject, URLSessionDataDelegate {
    private var session: URLSession!
    private var task: URLSessionDataTask?
    private var buffer = ""
    var onEvent: ((ChatEvent) -> Void)?

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func connect(sessionID: String) {
        let apiKey = "3d453a5f-1bd8-4d92-b8b8-f4bae99ccda4"
        guard let url = URL(string: "http://127.0.0.1:8020/chat/\(sessionID)/events?api_key=\(apiKey)") else {
         
            return
        }

        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")


        task = session.dataTask(with: request)
        task?.resume()
    }

    func disconnect() {
     
        task?.cancel()
        task = nil
    }

   
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let text = String(data: data, encoding: .utf8) {
            buffer += text
            processBuffer()
        }
    }

    private func processBuffer() {
        let events = buffer.components(separatedBy: "\n\n")
        for eventBlock in events {
            let lines = eventBlock.components(separatedBy: "\n")
            for line in lines {
                if line.starts(with: "data: ") {
                    let jsonString = line.replacingOccurrences(of: "data: ", with: "")
                   
                    
                    if let jsonData = jsonString.data(using: .utf8),
                       let event = try? JSONDecoder().decode(ChatEvent.self, from: jsonData) {
                        DispatchQueue.main.async {
                            self.onEvent?(event)
                        }
                    }
                }
            }
        }

        buffer = ""
    }

}
