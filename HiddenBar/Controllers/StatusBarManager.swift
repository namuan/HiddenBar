//
//  StatusBarManager.swift
//  vanillaClone
//
//  Created by Thanh Nguyen on 1/30/19.
//  Copyright © 2019 Dwarves Foundation. All rights reserved.
//

import AppKit

enum StatusBarPolicy:Int {
    case  collapsed = 0, fullExpand = 1, partialExpand = 2
}

class StatusBarManager {

    enum StatusBarValidity {
        case invalid; case onStartUp; case valid
    }
    
    private let masterToggle = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let primarySeprator = NSStatusBar.system.statusItem(withLength: 0)
    private let secondarySeprator = NSStatusBar.system.statusItem(withLength: 0)
    private let updateLock = NSLock()
    private var autoCollapseTimer: Timer? = nil
    
    private static let hiddenSepratorLength: CGFloat =  0
    private static let normalSepratorLength: CGFloat =  10
    private static let expandedSeperatorLength: CGFloat = 10000

    private static let instance = StatusBarManager()

    public static func setup() {
        logInfo("Setting up StatusBarManager", category: "StatusBarManager")
        _ = instance

        NotificationCenter.default.addObserver(forName: NotificationNames.prefsChanged, object: nil, queue: Global.mainQueue) { [] _ in
            logDebug("Preferences changed notification received", category: "StatusBarManager")
            triggerAdjustment()
        }

        // Manually adjusting the bar once
        logInfo("Triggering initial adjustment", category: "StatusBarManager")
        triggerAdjustment()
    }

    public static func areSeperatorPositionValid () -> StatusBarValidity {
        guard
            let toggleButtonX = instance.masterToggle.button?.getOrigin?.x,
            let primarySepratorX = instance.primarySeprator.button?.getOrigin?.x,
            let secondarySepratorX = instance.secondarySeprator.button?.getOrigin?.x
        else {return .invalid}
        
        // all x will be all equal if applicationDidFinishLaunching have not returned, so we have to try again
        if toggleButtonX == primarySepratorX && primarySepratorX == secondarySepratorX {return .onStartUp}
        
        if Global.isUsingLTRTypeSystem {
            return (toggleButtonX > primarySepratorX && primarySepratorX > secondarySepratorX) ? .valid : .invalid
        } else {
            return (toggleButtonX < primarySepratorX && primarySepratorX < secondarySepratorX) ? .valid : .invalid
        }
    }

    @objc private func toggleButtonPressed(sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent {
            
            let isOptionKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.option)
            let isControlKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.control)
            
            logDebug("Toggle button pressed - eventType: \(event.type.rawValue), option: \(isOptionKeyPressed), control: \(isControlKeyPressed)", category: "StatusBarManager")
            
            switch (event.type, isOptionKeyPressed, isControlKeyPressed) {
            case (NSEvent.EventType.leftMouseUp, false, false):
                logInfo("Left click: toggling between collapsed and partial expand", category: "StatusBarManager")
                if (PreferenceManager.statusBarPolicy != .collapsed) {PreferenceManager.statusBarPolicy  = .collapsed}
                else {PreferenceManager.statusBarPolicy = .partialExpand}
                PreferenceManager.isEditMode = false
            case (NSEvent.EventType.leftMouseUp, true, false):
                logInfo("Option+Left click: toggling between collapsed and full expand", category: "StatusBarManager")
                if (PreferenceManager.statusBarPolicy != .collapsed) {PreferenceManager.statusBarPolicy  = .collapsed}
                else {PreferenceManager.statusBarPolicy = .fullExpand}
                PreferenceManager.isEditMode = false
            case (NSEvent.EventType.rightMouseUp, _, _):
                fallthrough
            case (NSEvent.EventType.leftMouseUp, _, true):
                logInfo("Right click or Control+Left click: showing context menu", category: "StatusBarManager")
                ContextMenuManager.showContextMenu(sender)
            default:
                logDebug("Unhandled event type", category: "StatusBarManager")
                break
            }
        }
    }

    private init() {
        logInfo("Initializing StatusBarManager", category: "StatusBarManager")
        
        if let button = masterToggle.button {
            button.image = AssetManager.expandImage
            logDebug("Master toggle button configured", category: "StatusBarManager")
        }
        
        if let button = primarySeprator.button {
            button.image = AssetManager.seperatorImage
            logDebug("Primary separator configured", category: "StatusBarManager")
        }
        
        if let button = secondarySeprator.button {
            button.image = AssetManager.seperatorImage
            button.appearsDisabled = true
            logDebug("Secondary separator configured", category: "StatusBarManager")
        }
        masterToggle.autosaveName = "hiddenbar_masterToggle";
        primarySeprator.autosaveName = "hiddenbar_primarySeprator";
        logInfo("Setting up StatusBarManager", category: "StatusBarManager")
        
        let masterToggle = self.masterToggle,
        primarySeprator = self.primarySeprator,
        secondarySeprator = self.secondarySeprator
        
        if let button = masterToggle.button {
            button.target = self
            button.action = #selector(toggleButtonPressed(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            logDebug("Master toggle actions configured", category: "StatusBarManager")
        }
        // This won't work: blocking action to be sent.
        //let menu = StatusBarMenuManager.getContextMenu()
        //masterToggle.menu = menu
        
        masterToggle.isVisible = true
        primarySeprator.isVisible = true
        secondarySeprator.isVisible = true
        logInfo("Status bar items made visible", category: "StatusBarManager")
    }
    
    public static func finishUp() {
        logInfo("StatusBarManager finishing up", category: "StatusBarManager")
        
        // Manually adjusting the bar once
        triggerAdjustment()
    }
    
    private static func triggerAdjustment() {
        let validity = areSeperatorPositionValid()
        logDebug("Triggering adjustment, separator position validity: \(validity)", category: "StatusBarManager")
        
        switch validity {
        case .onStartUp:
            logWarning("Separators not ready yet (on startup), scheduling retry in 1s", category: "StatusBarManager")
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                // retry on more time after 1s
                logDebug("Retrying separator adjustment after startup delay", category: "StatusBarManager")
                NotificationCenter.default.post(Notification(name: NotificationNames.prefsChanged, object: PreferenceManager.isAutoStart))
            }
            fallthrough
        case .valid:
            logDebug("Separator positions valid, adjusting status bar", category: "StatusBarManager")
            resetAutoCollapseTimer()
            adjustStatusBar()
        case .invalid:
            logError("Separator positions invalid, resetting", category: "StatusBarManager")
            resetSeperator()
        }
    }
    
    private static func resetSeperator () {
        logWarning("Resetting separators to default state", category: "StatusBarManager")
        let masterToggle = instance.masterToggle,
            primarySeprator = instance.primarySeprator,
            secondarySeprator = instance.secondarySeprator,
            lock = instance.updateLock
        lock.lock(before: Date(timeIntervalSinceNow: 1))
        primarySeprator.length = StatusBarManager.normalSepratorLength
        secondarySeprator.length = StatusBarManager.normalSepratorLength
        masterToggle.button?.image = AssetManager.collapseImage
        masterToggle.button?.title = "Invalid".localized
        lock.unlock()
        logWarning("Separators reset complete", category: "StatusBarManager")
    }
    
    private static func resetAutoCollapseTimer () {
        let lock = instance.updateLock
        do {
            lock.lock(before: Date(timeIntervalSinceNow: 1))
            defer {lock.unlock()}
            
            instance.autoCollapseTimer?.invalidate()
            
            switch (PreferenceManager.isAutoHide, PreferenceManager.isEditMode, PreferenceManager.statusBarPolicy) {
            case (false, _, _), (_, true, _), (_, _, .collapsed):
                logDebug("Auto-collapse timer not needed (autoHide=\(PreferenceManager.isAutoHide), editMode=\(PreferenceManager.isEditMode), policy=\(PreferenceManager.statusBarPolicy))", category: "StatusBarManager")
                return
            default:
                break
            }
            let interval = PreferenceManager.numberOfSecondForAutoHide
            logInfo("Setting auto-collapse timer for \(interval) seconds", category: "StatusBarManager")
            let timer = Timer(timeInterval: TimeInterval(interval), repeats: false) {
                [] (timer:Timer) in
                logInfo("Auto-collapse timer triggered, collapsing status bar", category: "StatusBarManager")
                PreferenceManager.statusBarPolicy = .collapsed
                return
            }
            Global.runLoop.add(timer, forMode: .common)
            instance.autoCollapseTimer = timer
        }
    }
    
    private static func adjustStatusBar () {
        let masterToggle = instance.masterToggle,
            primarySeprator = instance.primarySeprator,
            secondarySeprator = instance.secondarySeprator,
            lock = instance.updateLock
        
        lock.lock(before: Date(timeIntervalSinceNow: 1))
        
        if PreferenceManager.isEditMode {
            logInfo("Adjusting status bar for EDIT mode", category: "StatusBarManager")
            primarySeprator.length = StatusBarManager.normalSepratorLength
            //primarySeprator.isVisible = true
            secondarySeprator.length = StatusBarManager.normalSepratorLength
            //secondarySeprator.isVisible = true
            masterToggle.button?.image = AssetManager.collapseImage
            masterToggle.button?.title = "Edit".localized
            
        }
        else {
            let policy = PreferenceManager.statusBarPolicy
            logInfo("Adjusting status bar for policy: \(policy)", category: "StatusBarManager")
            
            switch policy {
            case .fullExpand:
                logDebug("Setting full expand state", category: "StatusBarManager")
                primarySeprator.length = StatusBarManager.hiddenSepratorLength
                //primarySeprator.isVisible = false
                secondarySeprator.length = StatusBarManager.hiddenSepratorLength
                //secondarySeprator.isVisible = false
                masterToggle.button?.image = AssetManager.collapseImage
                masterToggle.button?.title = ""
                
            case .partialExpand:
                logDebug("Setting partial expand state", category: "StatusBarManager")
                primarySeprator.length = StatusBarManager.hiddenSepratorLength
                //primarySeprator.isVisible = false
                secondarySeprator.length = StatusBarManager.expandedSeperatorLength
                //secondarySeprator.isVisible = true
                masterToggle.button?.image = AssetManager.collapseImage
                masterToggle.button?.title = ""
                
            case .collapsed:
                logDebug("Setting collapsed state", category: "StatusBarManager")
                primarySeprator.length = StatusBarManager.expandedSeperatorLength
                //primarySeprator.isVisible = true
                secondarySeprator.length = StatusBarManager.expandedSeperatorLength
                //secondarySeprator.isVisible = true
                masterToggle.button?.image = AssetManager.expandImage
                masterToggle.button?.title = ""
                
            }
        }
        lock.unlock()
    }
}
