//
//  ViewController.swift
//  Img2pdf
//
//  Created by 松尾宏規 on 2025/03/26.
//

import Cocoa
import PDFKit

class ViewController: NSViewController {

    let dragDropView: DragDropView = {
        let view = DragDropView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let exportButton: NSButton = {
        let button = NSButton(title: "Export", target: nil, action: #selector(exportPDF))
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let importButton: NSButton = {
        let button = NSButton(title: "Import", target: nil, action: #selector(importFiles))
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let buttonStackView: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .centerY
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
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("FileColumn"))
        column.title = "画像ファイル"
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    let tableScrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        return scrollView
    }()

    var fileURLs: [URL] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func loadView() {
        self.view = NSView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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

        // ここでは、tableScrollView は特に固定の高さは与えず、contentStackView 内で残りのスペースを埋めるようにします。

        // テーブルビューの delegate と dataSource の設定
        tableView.delegate = self
        tableView.dataSource = self

        // ボタンのターゲット設定
        importButton.target = self
        exportButton.target = self
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

    func createPDF(fileURLs: [URL], outputURL: URL) {
        let pdfDocument = PDFKit.PDFDocument()
        for (index, fileURL) in fileURLs.enumerated() {

            guard let originalImage = NSImage(contentsOf: fileURL) else { continue }

            let processedImage = preprocessImage(image: originalImage) ?? originalImage
            guard let cgImage = processedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }

            let imageWidth = CGFloat(cgImage.width)
            let imageHeight = CGFloat(cgImage.height)
            let pageRect = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)

            let data = NSMutableData()
            guard let consumer = CGDataConsumer(data: data as CFMutableData) else { continue }
            var mediaBox = pageRect
            guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { continue }

            context.beginPDFPage(nil)
            context.draw(cgImage, in: pageRect)
            context.endPDFPage()
            context.closePDF()

            if let tempDoc = PDFDocument(data: data as Data), let pdfPage = tempDoc.page(at: 0) {
                pdfDocument.insert(pdfPage, at: index)
            }
        }
        pdfDocument.write(to: outputURL)
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
        let identifier = NSUserInterfaceItemIdentifier("FileCell")
        var cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = identifier
            let textField = NSTextField(labelWithString: fileURL.lastPathComponent)
            textField.translatesAutoresizingMaskIntoConstraints = false
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
