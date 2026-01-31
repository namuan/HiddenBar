//
//  AppDelegate.swift
//  vanillaClone
//
//  Created by Thanh Nguyen on 1/24/19.
//  Copyright © 2019 Dwarves Foundation. All rights reserved.
//

import AppKit
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate{
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        logInfo("========================================", category: "AppDelegate")
        logInfo("Application did finish launching", category: "AppDelegate")
        
        logInfo("Setting up ContextMenuManager", category: "AppDelegate")
        ContextMenuManager.setup()
        
        logInfo("Setting up StatusBarManager", category: "AppDelegate")
        StatusBarManager.setup()
        
        logInfo("Setting up HotKeyManager", category: "AppDelegate")
        HotKeyManager.setup()
        
        logInfo("Setting up AppActivationManager", category: "AppDelegate")
        AppActivationManager.setup()
        
        logInfo("Application launch complete", category: "AppDelegate")
        NSLog("App launched.")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        logInfo("Application reopen requested, hasVisibleWindows: \(flag)", category: "AppDelegate")
        PreferencesWindowController.showPrefWindow()
        NSLog("App Reopened.")
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        logInfo("========================================", category: "AppDelegate")
        logInfo("Application will terminate", category: "AppDelegate")
        NSLog("App shutting down.")
        
        logInfo("Finishing AppActivationManager", category: "AppDelegate")
        AppActivationManager.finishUp()
        
        logInfo("Finishing HotKeyManager", category: "AppDelegate")
        HotKeyManager.finishUp()
        
        logInfo("Finishing StatusBarManager", category: "AppDelegate")
        StatusBarManager.finishUp()
        
        logInfo("Finishing ContextMenuManager", category: "AppDelegate")
        ContextMenuManager.finishUp()
        
        logInfo("Application shutdown complete", category: "AppDelegate")
        Logger.shared.flush()
    }
   
}

 
