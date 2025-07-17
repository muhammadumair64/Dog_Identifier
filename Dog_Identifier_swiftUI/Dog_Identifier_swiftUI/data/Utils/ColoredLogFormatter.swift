//
//  ColoredLogFormatter.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 15/01/2025.
//


import CocoaLumberjack

class ColoredLogFormatter: NSObject, DDLogFormatter {
    func format(message logMessage: DDLogMessage) -> String? {
        let level: String
       

        switch logMessage.flag {
        case .error:
            level = "🔴☠️💥 [ERROR]"
          
        case .warning:
            level = "🟠💀⚠️ [WARN]"
          
        case .info:
            level = "🔵👉 [INFO]"
            
        case .debug:
            level = "🟢👉 [DEBUG]"
       
        case .verbose:
            level = "⚪️👉 [VERBOSE]"
        default:
            level = "⚫️👉 [DEFAULT]"
        }

        let message = logMessage.message
        
        return "\(level): \(message)"
    }
}



