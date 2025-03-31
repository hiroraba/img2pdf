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
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.setContentSize(NSSize(width: 480, height: 320))
                window.center()
            }
        }
    }
}
