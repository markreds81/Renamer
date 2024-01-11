//
//  RenamerApp.swift
//  Renamer
//
//  Created by Marco on 10/01/24.
//

import SwiftUI

@main
struct RenamerApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self)
	var appDelegate
    
	let appState = AppState()
	
    var body: some Scene {
        Window("Renamer", id: "main") {
            ContentView().environmentObject(appState)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Select document...") {
                    appState.documentUrl = showOpenPanel()
                }
                .keyboardShortcut("o")
            }
        }
    }
	
	func showOpenPanel() -> URL? {
		let openPanel = NSOpenPanel()
		let response = openPanel.runModal()
		return response == .OK ? openPanel.url : nil
	}
}

class AppDelegate: NSObject, NSApplicationDelegate {    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

class AppState: ObservableObject {
	@Published
	var documentUrl: URL?
}
