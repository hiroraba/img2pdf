//
//  FileService.swift
//  img2pdf
//
//  Created by 松尾宏規 on 2025/03/31.
//

import Cocoa

protocol FileServiceProtocol {
    func selectFiles(completion: @escaping ([URL]) -> Void)
    func saveFile(defaultName: String, completion: @escaping (URL?) -> Void)
}

class FileServiceImpl: FileServiceProtocol {
    func selectFiles(completion: @escaping ([URL]) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png]
        panel.begin { result in
            completion(result == .OK ? panel.urls : [])
        }
    }
    
    func saveFile(defaultName: String, completion: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = defaultName
        panel.begin { result in
            completion(result == .OK  ? panel.url : nil)
        }
    }
}
