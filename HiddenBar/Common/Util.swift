//
//  Util.swift
//  vanillaClone
//
//  Created by Thanh Nguyen on 1/29/19.
//  Copyright © 2019 Dwarves Foundation. All rights reserved.
//

import AppKit
import Foundation
//import ServiceManagement



class Util {
    
    static func hasFullScreenWindow() -> Bool
    {
        logDebug("Checking for fullscreen windows", category: "Util")
        
        // TODO: A better method detecting active full screen windows to prevent glitching
        guard let windows = CGWindowListCopyWindowInfo(CGWindowListOption(rawValue: CGWindowListOption.optionOnScreenOnly.rawValue | CGWindowListOption.excludeDesktopElements.rawValue), kCGNullWindowID) else {
            logWarning("Failed to get window list", category: "Util")
            return false
        }
        
        guard let screenFrame = NSScreen.main?.frame else {
            logWarning("Failed to get main screen frame", category: "Util")
            return false
        }

        for window in windows as NSArray
        {
            guard let winInfo = window as? NSDictionary, let frameInfo = winInfo["kCGWindowBounds"] as? NSDictionary else { continue }
            
            if frameInfo["Height"] as? CGFloat == screenFrame.height, frameInfo["Width"] as? CGFloat == screenFrame.width,
               frameInfo["X"] as? CGFloat == 0, frameInfo["Y"] as? CGFloat == 0,
               winInfo["kCGWindowOwnerName"] as? String != "Dock"
            {
                let ownerName = winInfo["kCGWindowOwnerName"] as? String ?? "unknown"
                logInfo("Found fullscreen window: \(ownerName)", category: "Util")
#if DEBUG
                NSLog("Found full screen window: \(winInfo)")
#endif
                return true
            }
        }
        
        logDebug("No fullscreen window found", category: "Util")
#if DEBUG
                NSLog("No full screen window Found.")
#endif
        return false
    }
}
