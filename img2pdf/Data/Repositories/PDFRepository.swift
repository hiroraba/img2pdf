//
//  PDFRepository.swift
//  img2pdf
//
//  Created by 松尾宏規 on 2025/03/29.
//

import Foundation
import PDFKit
import Cocoa

public class PDFRepository {
    
    // swiftlint:disable:next function_body_length
    func createPDF(fileURLs: [URL], outputURL: URL) -> Bool {
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
        return true 
    }
    
    private func preprocessImage(image: NSImage) -> NSImage? {
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
}
