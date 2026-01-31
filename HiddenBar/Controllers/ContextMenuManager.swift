//
//  ContextMenuManager.swift
//  Hidden Bar
//
//  Created by 上原葉 on 5/21/23.
//  Copyright © 2023 Dwarves Foundation. All rights reserved.
//

import AppKit

class ContextMenuManager {
    class ContextMenuDelegate:NSObject, NSMenuDelegate {
        func confinementRect(for menu: NSMenu, on screen: NSScreen?) -> NSRect {
            guard let lscreen = screen else { return NSZeroRect }
            return lscreen.visibleFrame
        }
    }
    private static let delegate = ContextMenuDelegate()
    private static let instance = ContextMenuManager()
    private let contextMenu: NSMenu
    private let prefButton: NSMenuItem
    private let editToggle: NSMenuItem
    private let quitButton: NSMenuItem
    private let seperator1 = NSMenuItem.separator()
    private let seperator2 = NSMenuItem.separator()
    private init() {
        logInfo("Initializing ContextMenuManager", category: "ContextMenuManager")
        
        let menu = NSMenu()
        
        let nPrefButton = NSMenuItem(title: "Preferences...".localized, action: #selector(showPreference), keyEquivalent: ",")
        nPrefButton.tag = 0
        
        
        let nEditToggle = NSMenuItem(title: "Edit Mode".localized, action: #selector(toggleEdit), keyEquivalent: "e")
        nEditToggle.tag = 1
        
        let nQuitButton = NSMenuItem(title: "Quit".localized, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        nQuitButton.tag = 2
        
        contextMenu = menu
        prefButton = nPrefButton
        editToggle = nEditToggle
        quitButton = nQuitButton
        
        logInfo("ContextMenuManager initialized", category: "ContextMenuManager")
    }
    
    private func updateMenu() {
        let editMode = PreferenceManager.isEditMode
        editToggle.state = editMode ? .on : .off
        logDebug("Menu updated, edit mode: \(editMode)", category: "ContextMenuManager")
    }
    
    public static func setup() {
        logInfo("Setting up ContextMenuManager", category: "ContextMenuManager")
        instance.prefButton.target = instance
        instance.editToggle.target = instance
        instance.contextMenu.addItem(instance.prefButton)
        instance.contextMenu.addItem(instance.seperator1)
        instance.contextMenu.addItem(instance.editToggle)
        instance.contextMenu.addItem(instance.seperator2)
        instance.contextMenu.addItem(instance.quitButton)
        
        instance.contextMenu.delegate = delegate
        
        NotificationCenter.default.addObserver(forName: NotificationNames.prefsChanged, object: nil, queue: nil) {[] _ in
            logDebug("Preferences changed, updating context menu", category: "ContextMenuManager")
            instance.updateMenu()
        }
        instance.updateMenu()
        logInfo("ContextMenuManager setup complete", category: "ContextMenuManager")
    }
    
    public static func finishUp() {
        logInfo("ContextMenuManager finishing up", category: "ContextMenuManager")
    }
    
    public static func showContextMenu(_ sender: NSStatusBarButton) {
        logInfo("Showing context menu", category: "ContextMenuManager")
        instance.contextMenu.popUp(positioning: nil, at: .init(x: sender.bounds.minX, y: sender.bounds.minY), in: sender)
    }
    
    @objc func showPreference() {
        logInfo("Preferences menu item selected", category: "ContextMenuManager")
        PreferencesWindowController.showPrefWindow()
    }
    @objc func toggleEdit() {
        let newEditMode = !PreferenceManager.isEditMode
        logInfo("Toggling edit mode to: \(newEditMode)", category: "ContextMenuManager")
        PreferenceManager.isEditMode = newEditMode
    }

    
}

