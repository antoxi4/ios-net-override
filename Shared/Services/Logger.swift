//
//  Log.swift
//  Vault
//
//  Created by Anton Yashyn on 09.08.2025.
//

import Foundation

struct Logger {
    static func info(
        _ message: Any,
        fileID: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
#if DEBUG
        print("INFO: [\(fileID):\(line)] \(function) – \(message)")
#endif
        
    }
    
    static func deinitMessage(fileID: String = #fileID,) {
#if DEBUG
        print("DEINIT: [\(fileID)]")
#endif
    }
    
    static func error(
        _ message: Any,
        fileID: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        print("ERROR: [\(fileID):\(line)] \(function) – \(message)")
    }
}
