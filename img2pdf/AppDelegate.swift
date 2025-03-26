//
//  AppDelegate.swift
//  img2pdf
//
//  Created by 松尾宏規 on 2025/03/26.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let windowSize = NSRect(x: 0, y: 0, width: 400, height: 200)
        window = NSWindow(contentRect: windowSize, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.center()
        window.title = "Img2pdf"
        
        let viewController = ViewController()
        window.contentViewController = viewController
        window.makeKeyAndOrderFront(nil)
    }


}

