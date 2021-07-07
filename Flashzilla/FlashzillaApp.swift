//
//  FlashzillaApp.swift
//  Flashzilla
//
//  Created by Russell Gordon on 2021-07-04.
//

import SwiftUI

@main
struct FlashzillaApp: App {
    
    // Access the data store
    @StateObject var dataStore = Cards()
    
    // Access global app state
    @StateObject var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(appState)
        }
    }
}
