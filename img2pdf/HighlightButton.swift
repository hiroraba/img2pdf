//
//  HighlightButton.swift
//  img2pdf
//
//  Created by 松尾宏規 on 2025/03/28.
//

import Cocoa

class HighlightButton: NSButton {
    private var originalBackgroundColor: CGColor?
    
    override func updateLayer() {
        super.updateLayer()
        
        if originalBackgroundColor == nil {
            originalBackgroundColor = layer?.backgroundColor
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if originalBackgroundColor == nil, let bg = layer?.backgroundColor {
            originalBackgroundColor = bg
        }
        
        if let currentColor = layer?.backgroundColor, let nsColor = NSColor(cgColor: currentColor) {
            layer?.backgroundColor = nsColor.darker(by: 20).cgColor
        }
        
        super.mouseDown(with: event)
        layer?.backgroundColor = originalBackgroundColor
    }
}

extension NSColor {
    func darker(by percentage: Int = 20) -> NSColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let newBrightness = max(brightness - CGFloat(percentage) / 100, 0)
        return NSColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
    }
}
