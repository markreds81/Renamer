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
	
	@FocusedValue(\.world)
	var world: World?
	
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
		.commands {
			CommandGroup(after: .newItem) {
				Button("Select document...") {
					world?.reply = "Hey...!"
					world?.documentUrl = showOpenPanel()
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

public class World: ObservableObject {
	@Published
	var reply: String?
	
	@Published
	var documentUrl: URL?
}

public struct WorldFocusedValueKey: FocusedValueKey {
	public typealias Value = World
}

public extension FocusedValues {
	
	typealias World = WorldFocusedValueKey
	
	var world: World.Value? {
		get { self[World.self] }
		set { self[World.self] = newValue }
	}
}
