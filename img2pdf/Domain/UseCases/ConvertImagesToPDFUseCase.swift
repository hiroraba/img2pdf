//
//  ConvertImagesToPDFUseCase.swift
//  img2pdf
//
//  Created by 松尾宏規 on 2025/03/29.
//

import Foundation

class ConvertImagesToPDFUseCase {
    private let pdfRepository: PDFRepository
    init(pdfRepository: PDFRepository = PDFRepository()) {
        self.pdfRepository = pdfRepository
    }
    
    func execute(with fileURLs: [URL], outputURL: URL) -> Bool {
        return pdfRepository.createPDF(fileURLs: fileURLs, outputURL: outputURL)
    }
}
