import Foundation
import Combine

struct ChatEvent: Codable {
    let type: String
    let entity: String
    let description: String
}

class ChatViewModel: ObservableObject {
    @Published var messages: [String] = []
    @Published var isConnected = false

    private var sseClient: SSEClient?
    private var cancellables = Set<AnyCancellable>()

    func connectToEventStream(sessionID: String) {
        print("Connecting to event stream...")

        sseClient = SSEClient()
        sseClient?.onEvent = { [weak self] event in
            print("Event: \(event.entity): \(event.description)")
            self?.messages.append(" \(event.entity): \(event.description)")
        }

        sseClient?.connect(sessionID: sessionID)
        
        // Subscribe to connection status from SSEClient if it has one
        // For now, we'll set it manually since SSEClient doesn't expose isConnected
        isConnected = true
    }

    func stopListening() {
        sseClient?.disconnect()
        isConnected = false
    }
}
