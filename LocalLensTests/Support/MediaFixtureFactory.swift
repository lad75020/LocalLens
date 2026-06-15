import AppKit
import AVFoundation
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

    static func writeWAV(named name: String = "tone.wav", durationSeconds: Double = 1.0, sampleRate: Int = 8_000, in root: URL) throws -> URL {
        let frameCount = max(1, Int(durationSeconds * Double(sampleRate)))
        var data = Data()
        func appendString(_ string: String) { data.append(contentsOf: string.data(using: .ascii)!) }
        func appendUInt32(_ value: UInt32) { var little = value.littleEndian; data.append(Data(bytes: &little, count: 4)) }
        func appendUInt16(_ value: UInt16) { var little = value.littleEndian; data.append(Data(bytes: &little, count: 2)) }
        let byteRate = sampleRate * 2
        let dataByteCount = frameCount * 2
        appendString("RIFF")
        appendUInt32(UInt32(36 + dataByteCount))
        appendString("WAVE")
        appendString("fmt ")
        appendUInt32(16)
        appendUInt16(1)
        appendUInt16(1)
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(byteRate))
        appendUInt16(2)
        appendUInt16(16)
        appendString("data")
        appendUInt32(UInt32(dataByteCount))
        data.append(Data(repeating: 0, count: dataByteCount))
        let url = root.appendingPathComponent(name)
        try data.write(to: url)
        return url
    }

    static func writeCorruptMedia(named name: String = "corrupt.wav", in root: URL) throws -> URL {
        let url = root.appendingPathComponent(name)
        try Data("not a media file".utf8).write(to: url)
        return url
    }

    static func writeVideo(named name: String = "clip.mov", durationSeconds: Double = 1.0, frameCount: Int = 3, in root: URL) async throws -> URL {
        let url = root.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: url)
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 320,
            AVVideoHeightKey: 180
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: 320,
            kCVPixelBufferHeightKey as String: 180
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attributes)
        guard writer.canAdd(input) else { throw XCTSkip("Unable to add video writer input") }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? XCTSkip("Unable to start video writer") }
        writer.startSession(atSourceTime: .zero)
        let frameDuration = durationSeconds / Double(max(1, frameCount))
        for frame in 0..<frameCount {
            while !input.isReadyForMoreMediaData { try await Task.sleep(nanoseconds: 1_000_000) }
            guard let buffer = makePixelBuffer(width: 320, height: 180, frame: frame) else { throw XCTSkip("Unable to make pixel buffer") }
            let time = CMTime(seconds: Double(frame) * frameDuration, preferredTimescale: 600)
            guard adaptor.append(buffer, withPresentationTime: time) else { throw writer.error ?? XCTSkip("Unable to append video frame") }
        }
        input.markAsFinished()
        await writer.finishWriting()
        if writer.status != .completed { throw writer.error ?? XCTSkip("Unable to finish video writer") }
        return url
    }

    private static func makePixelBuffer(width: Int, height: Int, frame: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, nil, &pixelBuffer)
        guard let pixelBuffer else { return nil }
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let color: UInt32 = frame.isMultiple(of: 2) ? 0xFF3366CC : 0xFF66CC33
        for y in 0..<height {
            let row = base.advanced(by: y * bytesPerRow).assumingMemoryBound(to: UInt32.self)
            for x in 0..<width { row[x] = color.bigEndian }
        }
        return pixelBuffer
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
