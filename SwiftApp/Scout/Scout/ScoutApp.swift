import SwiftUI

@main
struct ScoutApp: App {
    @StateObject private var storeVM = AgentStoreViewModel()

    init() {
        print("ScoutApp init")
    }

    var body: some Scene {
        WindowGroup {
            AgentStoreView()
                .environmentObject(storeVM)
                .onOpenURL { url in
                    storeVM.handleCallback(url: url)
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Divider()
                Button("Index Directory...") {
                    IndexDirectoryManager.shared.showIndexDirectoryDialog()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }
        }

        Window("File Search", id: "file-search") {
            FileSearchView()
                .frame(minWidth: 600, minHeight: 400)
                .onAppear {
                    print("FileSearchView loaded")
                }
        }
    }
}
