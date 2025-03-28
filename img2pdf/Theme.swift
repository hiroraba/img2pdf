//
//  Theme.swift
//  img2pdf
//
//  Created by 松尾宏規 on 2025/03/27.
//

import Cocoa

struct Theme {
    static let backgroundColor = NSColor(calibratedRed: 39/255, green: 40/255, blue: 34/255, alpha: 1)
    
    static let accentColor = NSColor(calibratedRed: 166/255, green: 226/255, blue: 046/255, alpha: 1)
    
    static let textColor = NSColor(calibratedRed: 248/255, green: 248/255, blue: 242/255, alpha: 1)
    
    static let overlayTextColor = NSColor.lightGray
    
    static let visualEffectViewMaterial: NSVisualEffectView.Material = .sidebar
    
    static let molokaiBackgroundColor = NSColor(calibratedRed: 39/255, green: 40/255, blue: 34/255, alpha: 1.0)
    static let molokaiTextColor = NSColor(calibratedRed: 248/255, green: 248/255, blue: 242/255, alpha: 1.0)

    static let molokaiImportColor = NSColor(calibratedRed: 102/255, green: 217/255, blue: 239/255, alpha: 1.0)
    static let molokaiExportColor = NSColor(calibratedRed: 166/255, green: 226/255, blue: 46/255, alpha: 1.0)
    static let molokaiDeleteColor = NSColor(calibratedRed: 249/255, green: 38/255, blue: 114/255, alpha: 1.0)
}
