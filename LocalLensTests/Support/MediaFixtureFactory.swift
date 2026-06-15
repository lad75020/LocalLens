import AppKit
import CoreGraphics
import CoreText
import Foundation
import PDFKit
import XCTest
@testable import LocalLens

enum MediaFixtureFactory {
    static func tempRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    static func writePNG(named name: String = "screenshot-text.png", text: String = "LocalLens OCR", size: CGSize = CGSize(width: 900, height: 500), in root: URL) throws -> URL {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 64, weight: .bold),
            .foregroundColor: NSColor.black
        ]
        text.draw(at: CGPoint(x: 60, y: size.height / 2 - 40), withAttributes: attributes)
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else {
            throw XCTSkip("Unable to create PNG fixture")
        }
        let url = root.appendingPathComponent(name)
        try data.write(to: url)
        return url
    }

    static func writePDF(named name: String = "fixture.pdf", pages: [String], in root: URL) throws -> URL {
        let data = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw XCTSkip("Unable to create PDF context")
        }
        for text in pages {
            context.beginPDFPage(nil)
            let attributed = NSAttributedString(
                string: text,
                attributes: [.font: CTFontCreateWithName("Helvetica" as CFString, 28, nil)]
            )
            let framesetter = CTFramesetterCreateWithAttributedString(attributed)
            let path = CGMutablePath()
            path.addRect(CGRect(x: 72, y: 360, width: 468, height: 180))
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributed.length), path, nil)
            CTFrameDraw(frame, context)
            context.endPDFPage()
        }
        context.closePDF()
        let url = root.appendingPathComponent(name)
        guard data.write(to: url, atomically: true) else { throw XCTSkip("Unable to write PDF fixture") }
        return url
    }

    static func writeImageOnlyPDF(named name: String = "image-only.pdf", text: String = "Image-only OCR fallback text", in root: URL) throws -> URL {
        let pdf = PDFDocument()
        let pageImage = NSImage(size: CGSize(width: 612, height: 792))
        pageImage.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 612, height: 792)).fill()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: NSColor.black
        ]
        text.draw(in: NSRect(x: 72, y: 360, width: 468, height: 160), withAttributes: attributes)
        pageImage.unlockFocus()
        guard let page = PDFPage(image: pageImage) else { throw XCTSkip("Unable to create image-only PDF page") }
        pdf.insert(page, at: 0)
        let url = root.appendingPathComponent(name)
        guard pdf.write(to: url) else { throw XCTSkip("Unable to write image-only PDF fixture") }
        return url
    }

    static func writeLockedPDF(named name: String = "locked.pdf", in root: URL) throws -> URL {
        let source = try writePDF(named: "source-\(name)", pages: ["Locked LocalLens PDF"], in: root)
        guard let pdf = PDFDocument(url: source) else { throw XCTSkip("Unable to read source PDF") }
        let url = root.appendingPathComponent(name)
        let options: [PDFDocumentWriteOption: Any] = [
            .userPasswordOption: "secret",
            .ownerPasswordOption: "owner"
        ]
        guard pdf.write(to: url, withOptions: options) else { throw XCTSkip("Unable to write locked PDF") }
        return url
    }

    static func asset(id: UUID = UUID(), folderID: UUID = UUID(), filename: String, mediaType: MediaType) -> MediaAsset {
        MediaAsset(
            id: id,
            watchedFolderID: folderID,
            fileIdentity: "identity-\(id.uuidString)",
            pathRelativeToFolder: filename,
            pathHash: "hash-\(filename)",
            filename: filename,
            mediaType: mediaType,
            contentType: mediaType == .pdf ? "com.adobe.pdf" : "public.png",
            sizeBytes: 1,
            createdAtFile: nil,
            modifiedAtFile: nil,
            indexedFileSignature: "sig-\(filename)",
            dimensions: nil,
            durationSeconds: nil,
            pageCount: nil,
            thumbnailState: .queued,
            indexState: .queued,
            lastIndexedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
