//
//  ScoutApp.swift
//  Scout
//
//  Created by Layanne El Assaad on 7/28/25.
//

import SwiftUI
@main
struct ScoutApp: App {
    init() {
        print("✅ ScoutApp init")
    }
    
    var body: some Scene {
        WindowGroup {
            AgentStoreView()
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    print("✅ AgentStoreView loaded")
                }
        }
        
        Window("File Search", id: "file-search") {
            FileSearchView()
                .frame(minWidth: 600, minHeight: 400)
                .onAppear {
                    print("✅ FileSearchView loaded")
                }
        }
    }
}
