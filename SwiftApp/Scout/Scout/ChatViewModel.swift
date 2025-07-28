import Foundation
import Combine

struct ChatEvent: Codable {
    let type: String
    let entity: String
    let description: String
}
class ChatViewModel: ObservableObject {
    @Published var messages: [String] = []

    private var sseClient: SSEClient?

    func connectToEventStream(sessionID: String) {
        print("🔌 Connecting to event stream...")

        sseClient = SSEClient()
        sseClient?.onEvent = { [weak self] event in
            print("📥 Event: \(event.entity): \(event.description)")
            self?.messages.append("📥 \(event.entity): \(event.description)")
        }

        sseClient?.connect(sessionID: sessionID)
    }

    func stopListening() {
        sseClient?.disconnect()
    }
}
