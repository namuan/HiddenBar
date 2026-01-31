//
//  AppActivationManager.swift
//  Hidden Bar
//
//  Created by 上原葉 on 8/4/23.
//  Copyright © 2023 UeharaYou. All rights reserved.
//

import AppKit

class AppActivationManager {
    //static private var activationPolicy: NSApplication.ActivationPolicy = .accessory
    private let updateLock = NSLock()
    
    private static let instance = AppActivationManager()
    
    public static func setup() {
        logInfo("Setting up AppActivationManager", category: "AppActivationManager")
        NotificationCenter.default.addObserver(forName: NotificationNames.prefsChanged, object: nil, queue: Global.mainQueue) {[] (notification) in
            logDebug("Preferences changed notification received", category: "AppActivationManager")
            triggerAdjustment()
        }
        
        // Manually adjusting the bar once
        logInfo("Triggering initial adjustment", category: "AppActivationManager")
        triggerAdjustment()
    }
    
    public static func finishUp() {
        logInfo("AppActivationManager finishing up", category: "AppActivationManager")
    }
    
    private static func triggerAdjustment() {
        adjustAppActivation()
    }
    
    private static func adjustAppActivation() {
        logDebug("Adjusting app activation", category: "AppActivationManager")
        
        //TODO: do not deactivate if preference window is shown
        let lock = instance.updateLock
        lock.lock(before: Date(timeIntervalSinceNow: 1))
        
        let shouldActiveIgnoringOtherApp = !Util.hasFullScreenWindow()
        logDebug("Should activate ignoring other apps: \(shouldActiveIgnoringOtherApp)", category: "AppActivationManager")
        
        let previousActivationPolicy = NSApp.activationPolicy()
        logDebug("Previous activation policy: \(previousActivationPolicy.rawValue)", category: "AppActivationManager")
        
        // Handle Activation Policy
        // First Layer Decision: UI State
        // Querying before storyboard is ready WILL DEADLOCK the app!!!!!!!!!
        if(PreferencesWindowController.isPrefWindowVisible) {
            logInfo("Setting activation policy to .regular (preferences visible)", category: "AppActivationManager")
            NSApp.setActivationPolicy(.regular)
        }
        else {
            // Second Layer Decision: Preference
            switch (PreferenceManager.isUsingFullStatusBar, PreferenceManager.isEditMode, PreferenceManager.statusBarPolicy) {
            case (false, _, _), (true, false, .collapsed):
                logInfo("Setting activation policy to .accessory", category: "AppActivationManager")
                NSApp.setActivationPolicy(.accessory)
            case (true, true, _), (true, _, .partialExpand), (true, _, .fullExpand):
                logInfo("Setting activation policy to .regular (status bar expanded)", category: "AppActivationManager")
                NSApp.setActivationPolicy(.regular)
            }
        }
        
        let newActivationPolicy = NSApp.activationPolicy()
        logDebug("New activation policy: \(newActivationPolicy.rawValue)", category: "AppActivationManager")
        
        // Handle App Activation
        switch (previousActivationPolicy, NSApp.activationPolicy()) {
        case (.accessory, .regular):
            logInfo("Transitioning from .accessory to .regular", category: "AppActivationManager")
            if #available(macOS 14.0, *) {
                if (shouldActiveIgnoringOtherApp && !NSApp.isActive) {
                    logInfo("Activating app (macOS 14+)", category: "AppActivationManager")
                    NSApp.activate()
                }
            }
            else {
                logInfo("Activating app ignoring other apps: \(shouldActiveIgnoringOtherApp)", category: "AppActivationManager")
                NSApp.activate(ignoringOtherApps: shouldActiveIgnoringOtherApp)
            }
        case (.regular, .accessory):
            if (NSApp.isActive) {
                logInfo("Transitioning from .regular to .accessory, deactivating app", category: "AppActivationManager")
                NSApp.deactivate()
            }
        default:
            logDebug("No activation state change needed", category: "AppActivationManager")
            break;
        }
        
        lock.unlock()
    }
}
