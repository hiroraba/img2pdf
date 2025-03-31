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
    private let fileService: FileServiceProtocol
    
    init(useCase: ConvertImagesToPDFUseCase = ConvertImagesToPDFUseCase(),
    fileService: FileServiceProtocol = FileServiceImpl()) {
        self.convertImagesToPDFUseCase = useCase
        self.fileService = fileService
    }
    
    func importFiles() {
        fileService.selectFiles {[weak self] urls in
            guard let self = self else { return }
            var currentFiles = self.fileURLs.value
            currentFiles.append(contentsOf: urls)
            self.fileURLs.accept(currentFiles)
        }
    }
    
    func exportPDF() {
        let currentFiles = fileURLs.value
        guard !currentFiles.isEmpty else { return }
        
        let sortedFiles = currentFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
        isProcessiojnng.accept(true)

        fileService.saveFile(defaultName: "output.pdf") {[weak self] outputURL in
            guard let self = self, let url = outputURL else {
                self?.isProcessiojnng.accept(false)
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
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
        }
    }
    
    func deleteSelectedFiles(at indices: IndexSet) {
        var files = fileURLs.value
        indices.sorted(by: >).forEach { files.remove(at: $0) }
        fileURLs.accept(files)
    }
}
