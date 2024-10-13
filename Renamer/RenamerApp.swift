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
				
				Button("Rename") {
					NotificationCenter.default.post(name: .performRenameNotification, object: nil)
				}
				.keyboardShortcut("r")
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

extension Notification.Name {
	static let performRenameNotification = Notification.Name("PerformRenameNotification")
}

extension URL {
	var attributes: [FileAttributeKey : Any]? {
		do {
			return try FileManager.default.attributesOfItem(atPath: path)
		} catch let error as NSError {
			print("FileAttribute error: \(error)")
		}
		return nil
	}
	
	var fileSize: UInt64 {
		return attributes?[.size] as? UInt64 ?? UInt64(0)
	}
	
	var fileSizeString: String {
		return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
	}
	
	var creationDate: Date? {
		return attributes?[.creationDate] as? Date
	}
}
