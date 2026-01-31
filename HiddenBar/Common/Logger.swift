//
//  Logger.swift
//  Hidden Bar
//
//  Created for comprehensive application logging
//

import Foundation
import os.log

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

class Logger {
    static let shared = Logger()
    
    private let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.hiddenbar", category: "HiddenBar")
    private let fileManager = FileManager.default
    private let logFileName = "HiddenBar.log"
    private var logFileURL: URL?
    private let dateFormatter: DateFormatter
    private let logQueue = DispatchQueue(label: "com.hiddenbar.logger", qos: .utility)
    private var logFileHandle: FileHandle?
    
    // Maximum log file size (10 MB)
    private let maxLogFileSize: UInt64 = 10 * 1024 * 1024
    // Maximum number of archived log files
    private let maxArchivedLogs = 5
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        setupLogFile()
        log("Logger initialized. Log file: \(logFileURL?.path ?? "unknown")", level: .info, category: "Logger")
    }
    
    private func setupLogFile() {
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            NSLog("Failed to get Application Support directory")
            return
        }
        
        let logsDirectory = appSupportURL.appendingPathComponent("HiddenBar/Logs", isDirectory: true)
        
        // Create logs directory if it doesn't exist
        do {
            try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("Failed to create logs directory: \(error)")
            return
        }
        
        logFileURL = logsDirectory.appendingPathComponent(logFileName)
        
        // Create log file if it doesn't exist
        if !fileManager.fileExists(atPath: logFileURL!.path) {
            fileManager.createFile(atPath: logFileURL!.path, contents: nil, attributes: nil)
        }
        
        // Open file handle for writing
        do {
            logFileHandle = try FileHandle(forWritingTo: logFileURL!)
            try logFileHandle?.seekToEnd()
        } catch {
            NSLog("Failed to open log file: \(error)")
        }
        
        // Check if log rotation is needed
        rotateLogsIfNeeded()
    }
    
    private func rotateLogsIfNeeded() {
        guard let logFileURL = logFileURL else { return }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: logFileURL.path)
            if let fileSize = attributes[.size] as? UInt64, fileSize > maxLogFileSize {
                rotateLogFile()
            }
        } catch {
            NSLog("Failed to check log file size: \(error)")
        }
    }
    
    private func rotateLogFile() {
        guard let logFileURL = logFileURL else { return }
        
        // Close current file handle
        try? logFileHandle?.close()
        
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let archiveURL = logFileURL.deletingLastPathComponent()
            .appendingPathComponent("HiddenBar-\(timestamp).log")
        
        do {
            try fileManager.moveItem(at: logFileURL, to: archiveURL)
            
            // Create new log file
            fileManager.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
            logFileHandle = try FileHandle(forWritingTo: logFileURL)
            
            // Clean up old logs
            cleanupOldLogs()
        } catch {
            NSLog("Failed to rotate log file: \(error)")
        }
    }
    
    private func cleanupOldLogs() {
        guard let logsDirectory = logFileURL?.deletingLastPathComponent() else { return }
        
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
                .filter { $0.lastPathComponent.hasPrefix("HiddenBar-") && $0.pathExtension == "log" }
                .sorted { (url1, url2) -> Bool in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }
            
            // Remove oldest logs beyond the limit
            if logFiles.count > maxArchivedLogs {
                for logFile in logFiles.dropFirst(maxArchivedLogs) {
                    try? fileManager.removeItem(at: logFile)
                }
            }
        } catch {
            NSLog("Failed to cleanup old logs: \(error)")
        }
    }
    
    func log(_ message: String, level: LogLevel = .info, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(category)] [\(fileName):\(line)] \(function) - \(message)"
        
        // Log to unified logging system
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        
        // Log to console (NSLog)
        NSLog("[%@] [%@] %@", level.rawValue, category, message)
        
        // Write to file asynchronously
        logQueue.async { [weak self] in
            guard let self = self, let logFileHandle = self.logFileHandle else { return }
            
            if let data = (logMessage + "\n").data(using: .utf8) {
                do {
                    try logFileHandle.write(contentsOf: data)
                    
                    // Check if rotation is needed after writing
                    self.rotateLogsIfNeeded()
                } catch {
                    NSLog("Failed to write to log file: \(error)")
                }
            }
        }
    }
    
    func debug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }
    
    // Flush logs to disk immediately
    func flush() {
        logQueue.sync {
            try? logFileHandle?.synchronize()
        }
    }
    
    // Get log file URL
    func getLogFileURL() -> URL? {
        return logFileURL
    }
    
    // Get logs directory URL
    func getLogsDirectoryURL() -> URL? {
        return logFileURL?.deletingLastPathComponent()
    }
    
    deinit {
        flush()
        try? logFileHandle?.close()
    }
}

// Convenience global functions
func logDebug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, category: category, file: file, function: function, line: line)
}

func logInfo(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, category: category, file: file, function: function, line: line)
}

func logWarning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, category: category, file: file, function: function, line: line)
}

func logError(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, category: category, file: file, function: function, line: line)
}

func logCritical(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.critical(message, category: category, file: file, function: function, line: line)
}
