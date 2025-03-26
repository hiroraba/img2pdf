//
//  ViewController.swift
//  Img2pdf
//
//  Created by 松尾宏規 on 2025/03/26.
//

import Cocoa
import PDFKit

class ViewController: NSViewController {
    let dragDropView = DragDropView(frame: NSRect(x: 20, y: 100, width: 760, height: 400))

    let exportButton: NSButton = {
        let button = NSButton(title: "Export", target: nil, action: #selector(exportPDF))
        button.bezelStyle = .rounded
        return button
    }()

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(dragDropView)

        exportButton.frame = NSRect(x: 20, y: 20, width: 100, height: 40)
        exportButton.target = self
        view.addSubview(exportButton)
    }

    @objc func exportPDF() {
        let fileURLs = dragDropView.fileURLs

        let sortedFileURLs = fileURLs.sorted { (url1, url2) -> Bool in
            url1.lastPathComponent.localizedStandardCompare(url2.lastPathComponent) == .orderedAscending
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "output.pdf"
        savePanel.begin(completionHandler: { (response) in
            if response == .OK, let url = savePanel.url {
                self.createPDF(fileURLs: sortedFileURLs, outputURL: url)
            }
        })
    }

    func createPDF(fileURLs: [URL], outputURL: URL) {
        let pdfDocument = PDFKit.PDFDocument()
        for (index, fileURL) in fileURLs.enumerated() {
            if let image = NSImage(contentsOf: fileURL) {
                let pdfPage = PDFPage(image: image)
                pdfDocument.insert(pdfPage!, at: index)
            }
        }
        pdfDocument.write(to: outputURL)
    }
}
