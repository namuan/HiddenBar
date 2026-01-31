//
//  main.swift
//  Hidden Bar
//
//  Created by 上原葉 on 5/16/23.
//  Copyright © 2023 Dwarves Foundation. All rights reserved.
//

import AppKit

@main struct MyApp {
    
    static func main () -> Void {
        // Initialize logger early
        logInfo("========================================", category: "Startup")
        logInfo("Hidden Bar starting up", category: "Startup")
        logInfo("macOS version: \(ProcessInfo.processInfo.operatingSystemVersionString)", category: "Startup")
        logInfo("Bundle version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")", category: "Startup")
        logInfo("Bundle identifier: \(Bundle.main.bundleIdentifier ?? "unknown")", category: "Startup")
        
        // Check for duplicated instances (in case of "open -n" command or other circumstances).
        let otherRunningInstances = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == Global.mainAppId && $0 != NSRunningApplication.current
        }
        let isAppAlreadyRunning = !otherRunningInstances.isEmpty
        
        if (isAppAlreadyRunning) {
            let pids = otherRunningInstances.map{$0.processIdentifier}
            logWarning("Program already running with PIDs: \(pids). Exiting.", category: "Startup")
            NSLog("Program already running: \(pids).")
        }
        else {
            // Register user default
            logInfo("Registering user defaults", category: "Startup")
            PreferenceManager.setDefault()
            
            // Load main entry for NSApp
            logInfo("Launching NSApplication", category: "Startup")
            NSLog("App started.")
            let ret_val = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
            logInfo("App exited with return code: \(ret_val)", category: "Shutdown")
            NSLog("App exited with exit code: \(ret_val).")
            
            // Flush logs before exit
            Logger.shared.flush()
        }
        return
    }
}
