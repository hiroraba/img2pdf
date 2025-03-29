//
//  ViewController.swift
//  Img2pdf
//
//  Created by 松尾宏規 on 2025/03/26.
//

import Cocoa
import RxSwift
import RxCocoa

class ViewController: NSViewController {
    
    private var viewModel = MainViewModel()
    private let disposeBag = DisposeBag()
    
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
        return view
    }()

    private let importButton = HighlightButton(originalBackgroundColor: Theme.molokaiImportColor, title: "📂 Import")
    private let exportButton = HighlightButton(originalBackgroundColor: Theme.molokaiExportColor, title: "📤 Export")
    private let deleteButton = HighlightButton(originalBackgroundColor: Theme.molokaiDeleteColor, title: "🗑 Delete")

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
        
        tableView.allowsMultipleSelection = true
        return tableView
    }()

    let tableScrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        
        scrollView.wantsLayer = true
        scrollView.layer?.borderWidth = 1
        scrollView.layer?.borderColor = Theme.accentColor.cgColor
        
        scrollView.backgroundColor = Theme.molokaiBackgroundColor
        return scrollView
    }()
    
    let emptyListOverlay: NSTextField = {
        let label = NSTextField(labelWithString: "image files will be displayed here")
        label.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = Theme.overlayTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.isHidden = false
        return label
    }()
    
    let progressIndicator: NSProgressIndicator = {
        let progress = NSProgressIndicator()
        progress.style = .spinning
        progress.controlSize = .regular
        progress.isDisplayedWhenStopped = false
        progress.isHidden = false
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()

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
        
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = Theme.molokaiBackgroundColor.cgColor
               
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
        buttonStackView.addArrangedSubview(deleteButton)
        
        // ボタンスタックの高さは固定（例：40pt）
        buttonStackView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // コンテンツスタックにテーブルビューとボタンスタックを追加
        contentStackView.addArrangedSubview(tableScrollView)
        contentStackView.addArrangedSubview(buttonStackView)
        view.addSubview(contentStackView)
        
        view.addSubview(progressIndicator)
        NSLayoutConstraint.activate([
            progressIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressIndicator.widthAnchor.constraint(equalToConstant: 32),
            progressIndicator.heightAnchor.constraint(equalToConstant: 32)
        ])

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
        
        self.deleteButton.isEnabled = false
        self.deleteButton.alphaValue = 0.5
        
        bindViewModel()
    }
    
    private func bindViewModel() {
        importButton.rx.tap.bind { [weak self] in
            self?.viewModel.importFiles()
        }.disposed(by: disposeBag)
        
        exportButton.rx.tap.bind { [weak self] in
            self?.viewModel.exportPDF()
        }.disposed(by: disposeBag)
        
        deleteButton.rx.tap.bind { [weak self] in
            let selected = self?.tableView.selectedRowIndexes ?? []
            self?.viewModel.deleteSelectedFiles(at: selected)
        }.disposed(by: disposeBag)
        
        viewModel.fileURLs.observe(on: MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.tableView.reloadData()
            emptyListOverlay.isHidden = !self.viewModel.fileURLs.value.isEmpty
            tableView.headerView?.isHidden = self.viewModel.fileURLs.value.isEmpty
        }).disposed(by: disposeBag)
        
        viewModel.isProcessiojnng.observe(on: MainScheduler.instance).subscribe(onNext: { [weak self] isProcessing in
            if isProcessing {
                self?.progressIndicator.startAnimation(self)
                self?.progressIndicator.isHidden = false
            } else {
                self?.progressIndicator.stopAnimation(self)
                self?.progressIndicator.isHidden = true
            }
        }).disposed(by: disposeBag)
    }
}

extension ViewController: DragDropViewDelegate {
    func dragDropView(_ view: DragDropView, didUpdateFileURLs fileURLs: [URL]) {
        viewModel.fileURLs.accept(fileURLs)
    }
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return viewModel.fileURLs.value.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let fileURL = viewModel.fileURLs.value[row]
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
                formatter.timeStyle = .medium
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
            cell?.textField?.stringValue = text
        }
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let hasSelection = !tableView.selectedRowIndexes.isEmpty
        deleteButton.isEnabled = hasSelection
        deleteButton.alphaValue = hasSelection ? 1.0 : 0.5
    }
}
