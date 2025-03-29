//
//  MainViewModels.swift
//  img2pdf
//
//  Created by 松尾宏規 on 2025/03/29.
//

import Foundation
import RxSwift
import RxCocoa
import AppKit

class MainViewModel {
    let fileURLs = BehaviorRelay<[URL]>(value: [])
    
    let isProcessiojnng = BehaviorRelay<Bool>(value: false)
    
    private let disposeBag = DisposeBag()
    private let convertImagesToPDFUseCase: ConvertImagesToPDFUseCase
    
    init(useCase: ConvertImagesToPDFUseCase = ConvertImagesToPDFUseCase()) {
        self.convertImagesToPDFUseCase = useCase
    }
    
    func importFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png]
        panel.allowsMultipleSelection = true
        panel.begin { [weak self] result in
            if result == .abort { return }
            var currentFiles = self?.fileURLs.value ?? []
            currentFiles.append(contentsOf: panel.urls)
            self?.fileURLs.accept(currentFiles)
        }
    }
    
    func exportPDF() {
        let currentFiles = fileURLs.value
        guard !currentFiles.isEmpty else { return }
        
        let sortedFiles = currentFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "output.pdf"
        isProcessiojnng.accept(true)
        
        savePanel.begin { [weak self] result in
            guard let self = self else { return }
            if result == .OK, let url = savePanel.url {
                DispatchQueue.global().async {
                    let success = self.convertImagesToPDFUseCase.execute(with: sortedFiles, outputURL: url)
                    DispatchQueue.main.async {
                        self.isProcessiojnng.accept(false)
                        if success {
                            self.fileURLs.accept([])
                        } else {
                            NSAlert().alertStyle = .warning
                            NSAlert().runModal()
                        }
                    }
                }
            } else {
                self.isProcessiojnng.accept(false)
            }
        }
    }
    
    func deleteSelectedFiles(at indices: IndexSet) {
        var files = fileURLs.value
        indices.sorted(by: >).forEach { files.remove(at: $0) }
        fileURLs.accept(files)
    }
}
