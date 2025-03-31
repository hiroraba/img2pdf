//
//  PDFRepositoryProtocols.swift
//  img2pdf
//
//  Created by 松尾宏規 on 2025/03/31.
//

import Foundation

protocol PDFRepositoryProtocols {
    func createPDF(from fileURLs: [URL], outputURL: URL) -> Bool
}
