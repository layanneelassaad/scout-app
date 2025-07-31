import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Scout Knowledge Graph Search")
                .font(.title2)
                .padding(.top)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.messages.indices, id: \.self) { index in
                            Text(viewModel.messages[index])
                                .font(.system(.body, design: .monospaced))
                                .padding(10)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(8)
                                .id(index)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.count - 1, anchor: .bottom)
                    }
                }
            }

            Divider()

            Button("Start Listening") {
             
                viewModel.connectToEventStream(sessionID: "a58badca-997c-49a6-a9ba-81c62c316c2d")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(minWidth: 600, minHeight: 600)
        .padding()
    }
}
