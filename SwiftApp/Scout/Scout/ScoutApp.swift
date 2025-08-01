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
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
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
                .frame(minWidth: 800, minHeight: 600)
                .preferredColorScheme(.dark)
                .onAppear {
                    print("FileSearchView loaded")
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
