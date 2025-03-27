//
//  DragDropView.swift
//  Img2pdf
//
//  Created by 松尾宏規 on 2025/03/26.
//

import Cocoa

protocol DragDropViewDelegate: AnyObject {
    func dragDropView(_ view: DragDropView, didUpdateFileURLs fileURLs: [URL])
}

class DragDropView: NSView {

    weak var delegate: DragDropViewDelegate?

    var fileURLs: [URL] = [] {
        didSet {
            delegate?.dragDropView(self, didUpdateFileURLs: fileURLs)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
        layer?.backgroundColor = NSColor.lightGray.cgColor
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if containsPNGFile(draggingInfo: sender) {
            layer?.borderWidth = 3
            layer?.borderColor = NSColor.blue.cgColor
            return .copy
        }
        return []
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        layer?.borderWidth = 0
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        layer?.borderWidth = 0
        let pasteboard = sender.draggingPasteboard
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in urls where url.pathExtension == "png" {
                fileURLs.append(url)
            }
            return true
        }
        return false
    }

    func containsPNGFile(draggingInfo: NSDraggingInfo) -> Bool {
        let pasteboard = draggingInfo.draggingPasteboard
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            return urls.contains { $0.pathExtension == "png" }
        }
        return false
    }
}
