rm # Hidden Bar Logging System

## Overview

Hidden Bar now includes a comprehensive logging system to help diagnose issues and understand application behavior.

## Log File Location

Logs are stored in:
```
~/Library/Application Support/HiddenBar/Logs/HiddenBar.log
```

## Log Levels

The logging system supports five log levels:

1. **DEBUG** - Detailed diagnostic information for debugging
2. **INFO** - General informational messages about application state
3. **WARNING** - Warning messages about potential issues
4. **ERROR** - Error messages for recoverable problems
5. **CRITICAL** - Critical errors that may affect application functionality

## Log Destinations

Logs are written to three destinations simultaneously:

1. **File Logs** - Written to `~/Library/Application Support/HiddenBar/Logs/HiddenBar.log`
2. **Console Logs** - Visible via `NSLog` in Xcode console
3. **Unified Logging** - macOS unified logging system (viewable in Console.app)

## Log Rotation

- Logs automatically rotate when they reach **10 MB**
- Up to **5 archived logs** are kept with timestamps
- Older archived logs are automatically deleted
- Archive format: `HiddenBar-2026-01-31T17-30-00Z.log`

## Viewing Logs

### Quick Method - Log Viewer Script

Double-click `view-logs.command` in Finder or run:
```bash
./view-logs.command
```

This interactive script provides:
- Real-time log viewing
- Search functionality
- Filter by errors/warnings
- List all log files
- Open logs in TextEdit or Finder
- Access to Console.app

### Manual Methods

**View in real-time:**
```bash
tail -f ~/Library/Application\ Support/HiddenBar/Logs/HiddenBar.log
```

**View last 100 lines:**
```bash
tail -n 100 ~/Library/Application\ Support/HiddenBar/Logs/HiddenBar.log
```

**Search for errors:**
```bash
grep ERROR ~/Library/Application\ Support/HiddenBar/Logs/HiddenBar.log
```

**View in Console.app:**
1. Open `/Applications/Utilities/Console.app`
2. Search for: `process:"Hidden Bar"`
3. Or filter by: `subsystem:com.hiddenbar`

## What's Logged

### Application Lifecycle
- Application startup and shutdown
- Component initialization (managers, controllers)
- Version and system information

### User Actions
- Menu bar button clicks (left, right, with modifiers)
- Hotkey triggers
- Preference changes
- Context menu interactions
- Edit mode toggles

### Status Bar Management
- Separator position validation
- Status bar policy changes (collapsed, partial, full expand)
- Auto-collapse timer events
- Separator adjustments

### Preferences
- All preference reads and writes
- Global hotkey configuration
- Auto-hide settings
- Launch at login changes

### Application State
- Activation policy changes
- Full-screen window detection
- Edit mode state changes

### Errors and Warnings
- Invalid separator positions
- Missing preferences
- Window detection failures
- Timer issues

## Log Format

Each log entry includes:
```
[YYYY-MM-DD HH:MM:SS.mmm] [LEVEL] [Category] [File:Line] FunctionName - Message
```

Example:
```
[2026-01-31 17:47:23.456] [INFO] [StatusBarManager] [StatusBarManager.swift:92] setup() - Setting up StatusBarManager
```

## Categories

Logs are organized by category for easier filtering:

- **Startup** - Application launch
- **Shutdown** - Application termination
- **AppDelegate** - Main app delegate events
- **StatusBarManager** - Status bar operations
- **HotKeyManager** - Keyboard shortcut handling
- **PreferenceManager** - Preference management
- **AppActivationManager** - App activation states
- **ContextMenuManager** - Context menu operations
- **Util** - Utility functions
- **Logger** - Logging system itself

## Using Logs for Troubleshooting

### Issue: App won't start
```bash
grep -i "startup\|error\|critical" ~/Library/Application\ Support/HiddenBar/Logs/HiddenBar.log
```

### Issue: Hotkey not working
```bash
grep -i "hotkey" ~/Library/Application\ Support/HiddenBar/Logs/HiddenBar.log
```

### Issue: Status bar not hiding/showing
```bash
grep -i "statusbar\|separator\|policy" ~/Library/Application\ Support/HiddenBar/Logs/HiddenBar.log
```

### Issue: Preferences not saving
```bash
grep -i "preference" ~/Library/Application\ Support/HiddenBar/Logs/HiddenBar.log
```

## Programmatic Logging

Developers can use the logging system in code:

```swift
// Using convenience functions
logDebug("Detailed debug message", category: "MyCategory")
logInfo("Informational message", category: "MyCategory")
logWarning("Warning message", category: "MyCategory")
logError("Error message", category: "MyCategory")
logCritical("Critical error", category: "MyCategory")

// Or use the Logger directly
Logger.shared.log("Custom message", level: .info, category: "MyCategory")
```

File, function, and line information are automatically captured.

## Privacy

Logs are stored locally on your Mac and are never transmitted anywhere. They may contain:
- Application state information
- Keyboard shortcut configurations
- Timestamps of user actions
- Error messages

No personal data or identifiable information is logged.

## Clearing Logs

To clear all logs:
```bash
rm -rf ~/Library/Application\ Support/HiddenBar/Logs/*.log
```

Or use the log viewer script option 8.

## Performance

The logging system is designed to be efficient:
- Asynchronous file writing (doesn't block the main thread)
- Automatic log rotation prevents unlimited growth
- File operations use a dedicated queue
- Minimal impact on app performance
