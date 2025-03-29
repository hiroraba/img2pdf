//
//  HighlightButton.swift
//  img2pdf
//
//  Created by 松尾宏規 on 2025/03/28.
//

import Cocoa

class HighlightButton: NSButton {
    private var originalBackgroundColor: CGColor?
    
    init(originalBackgroundColor: CGColor? = nil, title: String) {
        super.init(frame: .zero)
        self.title = title
        self.originalBackgroundColor = originalBackgroundColor
        self.wantsLayer = true
        self.bezelStyle = .rounded
        self.isBordered = false
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.layer?.cornerRadius = 8
        self.layer?.backgroundColor = originalBackgroundColor
        self.contentTintColor = Theme.molokaiTextColor
        self.font = .systemFont(ofSize: 16, weight: .medium)
        
        self.heightAnchor.constraint(equalToConstant: 44).isActive = true
        self.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
