//
//  ViewController.swift
//  Img2pdf
//
//  Created by 松尾宏規 on 2025/03/26.
//

import Cocoa
import PDFKit

class ViewController: NSViewController {
    
    let backgroundView: NSVisualEffectView = {
        let view = NSVisualEffectView()
        view.material = Theme.visualEffectViewMaterial
        view.blendingMode = .behindWindow
        view.state = .active
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let dragDropView: DragDropView = {
        let view = DragDropView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.cornerRadius = 10
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.separatorColor.cgColor
        return view
    }()

    let exportButton: NSButton = {
        let button = NSButton(title: "Export", target: nil, action: #selector(exportPDF))
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        button.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        button.contentTintColor = Theme.accentColor
        return button
    }()

    let importButton: NSButton = {
        let button = NSButton(title: "Import", target: nil, action: #selector(importFiles))
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        button.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        button.contentTintColor = Theme.accentColor
        return button
    }()

    let buttonStackView: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .centerY
        stackView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return stackView
    }()

    let contentStackView: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    let tableView: NSTableView = {
        let tableView = NSTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.rowHeight = 40
        tableView.font = NSFont.systemFont(ofSize: 13)
        tableView.backgroundColor = NSColor.clear
        
        tableView.headerView?.isHidden = true
        return tableView
    }()

    let tableScrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        
        scrollView.wantsLayer = true
        scrollView.layer?.borderWidth = 1
        scrollView.layer?.borderColor = NSColor.separatorColor.cgColor
        
        scrollView.backgroundColor = Theme.backgroundColor
        return scrollView
    }()
    
    let emptyListOverlay: NSTextField = {
        let label = NSTextField(labelWithString: "image files will be displayed here")
        label.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = Theme.overlayTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.isHidden = false
        return label
    }()

    var fileURLs: [URL] = [] {
        didSet {
            tableView.reloadData()
            emptyListOverlay.isHidden = !fileURLs.isEmpty
            tableView.headerView?.isHidden = fileURLs.isEmpty
        }
    }

    override func loadView() {
        self.view = NSView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // ドラッグ＆ドロップのデリゲート設定
        dragDropView.delegate = self
        view.addSubview(dragDropView)

        // dragDropView をウィンドウ全体にフィットさせる
        NSLayoutConstraint.activate([
            dragDropView.topAnchor.constraint(equalTo: view.topAnchor),
            dragDropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dragDropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dragDropView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // テーブルビューをスクロールビューにセット
        tableScrollView.documentView = tableView
        
        let clipView = tableScrollView.contentView
        clipView.addSubview(emptyListOverlay)
        NSLayoutConstraint.activate([
            emptyListOverlay.centerXAnchor.constraint(equalTo: clipView.centerXAnchor),
            emptyListOverlay.centerYAnchor.constraint(equalTo: clipView.centerYAnchor)
        ])

        // ボタンスタックに Import と Export ボタンを追加
        buttonStackView.addArrangedSubview(importButton)
        buttonStackView.addArrangedSubview(exportButton)
        // ボタンスタックの高さは固定（例：40pt）
        buttonStackView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // コンテンツスタックにテーブルビューとボタンスタックを追加
        contentStackView.addArrangedSubview(tableScrollView)
        contentStackView.addArrangedSubview(buttonStackView)
        view.addSubview(contentStackView)

        // コンテンツスタックをウィンドウ全体にマージン付きで配置
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
        let indexColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("IndexColumn"))
        indexColumn.title = "No."
        indexColumn.width = 50
        
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        nameColumn.title = "Name"
        nameColumn.width = 200
        
        let dateColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("DateColumn"))
        dateColumn.title = "Date"
        dateColumn.width = 150
        
        tableView.addTableColumn(indexColumn)
        tableView.addTableColumn(nameColumn)
        tableView.addTableColumn(dateColumn)
        
        tableView.delegate = self
        tableView.dataSource = self

        importButton.target = self
        exportButton.target = self
    }

    @objc func exportPDF() {
        let fileURLs = dragDropView.fileURLs

        guard !fileURLs.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "error"
            alert.informativeText = "image files are empty"
            alert.runModal()
            return
        }

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

    @objc func importFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png]
        panel.allowsMultipleSelection = true
        panel.begin { (result) in
            if result == .OK {
                self.fileURLs.append(contentsOf: panel.urls)
            }
        }
    }

    func preprocessImage(image: NSImage) -> NSImage? {
        guard let tiffData = image.tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else {
            return nil
        }

        guard let filter = CIFilter(name: "CIColorControls") else {
            return nil
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(1.5, forKey: kCIInputContrastKey)
        filter.setValue(0.0, forKey: kCIInputBrightnessKey)
        filter.setValue(1.0, forKey: kCIInputSaturationKey)

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let rep = NSCIImageRep(ciImage: outputImage)
        let processedImage = NSImage(size: rep.size)
        processedImage.addRepresentation(rep)
        return processedImage
    }

    // swiftlint:disable:next function_body_length
    func createPDF(fileURLs: [URL], outputURL: URL) {
        let pdfDocument = PDFDocument()
        let targetDPI: CGFloat = 300.0
        let pointsPerInch: CGFloat = 72.0

        print("Creating PDF at \(fileURLs.count) pages to \(outputURL)")

        for (index, fileURL) in fileURLs.enumerated() {
            print("Processing file: \(fileURL)")
            guard let originalImage = NSImage(contentsOf: fileURL) else {
                print("Failed to load image from \(fileURL)")
                continue
            }

            // 前処理適用（失敗した場合は元画像）
            let processedImage = preprocessImage(image: originalImage) ?? originalImage

            var proposedRect = NSRect(origin: .zero, size: processedImage.size)
            guard let cgImage = processedImage.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
                print("Failed to convert processed image to CGImage for \(fileURL)")
                continue
            }

            let pixelWidth = CGFloat(cgImage.width)
            let pixelHeight = CGFloat(cgImage.height)
            let pageWidth = pixelWidth * pointsPerInch / targetDPI
            let pageHeight = pixelHeight * pointsPerInch / targetDPI
            let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
            print("Page rect: \(pageRect)")

            let data = NSMutableData()
            guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
                print("Failed to create CGDataConsumer")
                continue
            }
            var mediaBox = pageRect
            guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
                print("Failed to create CGContext")
                continue
            }

            context.beginPDFPage(nil)
            context.interpolationQuality = .high

            let scaleFactor = pointsPerInch / targetDPI
            context.scaleBy(x: scaleFactor, y: scaleFactor)

            let imageRect = CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight)
            context.draw(cgImage, in: imageRect)

            context.endPDFPage()
            context.closePDF()

            if let tempDoc = PDFDocument(data: data as Data), let pdfPage = tempDoc.page(at: 0) {
                pdfDocument.insert(pdfPage, at: index)
                print("Inserted PDF page for \(fileURL)")
            } else {
                print("Failed to extract PDF page from temporary document for \(fileURL)")
            }
        }

        if pdfDocument.pageCount > 0 {
            if pdfDocument.write(to: outputURL) {
                print("PDF successfully written to \(outputURL)")
            } else {
                print("Failed to write PDF to \(outputURL)")
            }
        } else {
            print("No PDF pages were created.")
        }
    }
}

extension ViewController: DragDropViewDelegate {
    func dragDropView(_ view: DragDropView, didUpdateFileURLs fileURLs: [URL]) {
        self.fileURLs = fileURLs
        tableView.reloadData()
    }
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fileURLs.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let fileURL = fileURLs[row]
        var cellIdentifier: String = ""
        var text: String = ""
  
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier("IndexColumn") {
            cellIdentifier = "IndexCell"
            text = "\(row + 1)"
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier("NameColumn") {
            cellIdentifier = "NameCell"
            text = fileURL.lastPathComponent
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier("DateColumn") {
            cellIdentifier = "DateCell"
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let date = attributes[.creationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                text = formatter.string(from: date)
            } else {
                text = "Unknown"
            }
        }
        
        // swiftlint:disable:next line_length
        var cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier), owner: self) as? NSTableCellView
        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = NSUserInterfaceItemIdentifier(cellIdentifier)
            let textField = NSTextField(labelWithString: text)
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.font = NSFont.systemFont(ofSize: 14)
            textField.textColor = Theme.textColor
            cell?.addSubview(textField)
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 5),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -5),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
            cell?.textField = textField
        } else {
            cell?.textField?.stringValue = fileURL.lastPathComponent
        }
        return cell
    }
}
