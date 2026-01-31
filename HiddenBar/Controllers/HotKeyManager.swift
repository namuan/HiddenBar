//
//  HotKeyManager.swift
//  Hidden Bar
//
//  Created by 上原葉 on 5/24/23.
//  Copyright © 2023 Dwarves Foundation. All rights reserved.
//

import Foundation
import HotKey

class HotKeyManager {
    static var hotKey: HotKey? {
        didSet {
            guard let hotKey = hotKey else {
                logWarning("HotKey cleared", category: "HotKeyManager")
                return
            }
            
            logInfo("HotKey registered: \(hotKey.keyCombo)", category: "HotKeyManager")
            
            hotKey.keyDownHandler = { [] in
                logDebug("HotKey triggered, current policy: \(PreferenceManager.statusBarPolicy)", category: "HotKeyManager")
                switch (PreferenceManager.statusBarPolicy) {
                case (.collapsed):
                    logInfo("Expanding status bar via hotkey", category: "HotKeyManager")
                    PreferenceManager.statusBarPolicy = .partialExpand
                default:
                    logInfo("Collapsing status bar via hotkey", category: "HotKeyManager")
                    PreferenceManager.statusBarPolicy = .collapsed
                }
            }
        }
    }
        
    public static func setup() {
        logInfo("Setting up HotKeyManager", category: "HotKeyManager")
        guard let globalKey = PreferenceManager.globalKey else {
            logWarning("No global key configured", category: "HotKeyManager")
            return
        }
        logInfo("Configuring hotkey with keyCode: \(globalKey.keyCode), modifiers: \(globalKey.carbonFlags)", category: "HotKeyManager")
        hotKey = HotKey(keyCombo: KeyCombo(carbonKeyCode: globalKey.keyCode, carbonModifiers: globalKey.carbonFlags))
    }
    
    public static func finishUp() {
        logInfo("HotKeyManager finishing up", category: "HotKeyManager")
        if hotKey != nil {
            logInfo("Clearing hotkey", category: "HotKeyManager")
            hotKey = nil
        }
    }
}
