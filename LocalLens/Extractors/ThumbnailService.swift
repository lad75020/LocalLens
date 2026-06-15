import AppKit
import Foundation
import ImageIO
import PDFKit
import UniformTypeIdentifiers

public struct ThumbnailService: Sendable {
    public let maxDimension: Int

    public init(maxDimension: Int = BuildConfiguration.thumbnailMaxDimension) {
        self.maxDimension = max(64, maxDimension)
    }

    public func generateThumbnail(
        for sourceURL: URL,
        assetID: UUID,
        mediaType: MediaType,
        cachePaths: CachePaths
    ) async throws -> ThumbnailResult {
        do {
            try FileManager.default.createDirectory(
                at: cachePaths.thumbnails(for: assetID).deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let image: CGImage
            switch mediaType {
            case .image:
                image = try makeImageThumbnail(from: sourceURL)
            case .pdf:
                image = try makePDFThumbnail(from: sourceURL)
            case .audio, .video, .office:
                throw ExtractionFailure.failed(
                    category: .unsupportedMedia,
                    retryability: .ignore,
                    safeMessage: "Thumbnail generation for this media type is not part of the image/PDF stage."
                )
            }

            let destinationURL = cachePaths.thumbnails(for: assetID)
            try writePNG(image, to: destinationURL)
            let byteCount = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? NSNumber)?.intValue ?? 0
            return ThumbnailResult(
                assetID: assetID,
                thumbnailURL: destinationURL,
                pixelWidth: image.width,
                pixelHeight: image.height,
                byteCount: byteCount
            )
        } catch let failure as ExtractionFailure {
            throw failure
        } catch {
            throw ExtractionFailure.map(error, defaultCategory: .corruptedMedia)
        }
    }

    private func makeImageThumbnail(from url: URL) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw ExtractionFailure.failed(category: .corruptedMedia, retryability: .notRetryable, safeMessage: "Image could not be decoded.")
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ExtractionFailure.failed(category: .corruptedMedia, retryability: .notRetryable, safeMessage: "Image thumbnail could not be generated.")
        }
        return thumbnail
    }

    private func makePDFThumbnail(from url: URL) throws -> CGImage {
        guard let document = PDFDocument(url: url) else {
            throw ExtractionFailure.failed(category: .corruptedMedia, retryability: .notRetryable, safeMessage: "PDF could not be opened.")
        }
        guard !document.isLocked else {
            throw ExtractionFailure.failed(category: .passwordProtectedPDF, retryability: .notRetryable, safeMessage: "Password-protected PDFs are skipped until the user unlocks them outside LocalLens.")
        }
        guard let page = document.page(at: 0) else {
            throw ExtractionFailure.failed(category: .corruptedMedia, retryability: .notRetryable, safeMessage: "PDF has no readable pages.")
        }
        let bounds = page.bounds(for: .mediaBox)
        let longest = max(bounds.width, bounds.height)
        let scale = longest > 0 ? min(CGFloat(maxDimension) / longest, 1) : 1
        let size = CGSize(width: max(1, bounds.width * scale), height: max(1, bounds.height * scale))
        let nsImage = page.thumbnail(of: size, for: .mediaBox)
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ExtractionFailure.failed(category: .corruptedMedia, retryability: .retry, safeMessage: "PDF thumbnail could not be rendered.")
        }
        return cgImage
    }

    private func writePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw ExtractionFailure.failed(category: .storageFull, retryability: .retry, safeMessage: "Thumbnail cache could not be opened for writing.")
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ExtractionFailure.failed(category: .storageFull, retryability: .retry, safeMessage: "Thumbnail cache write failed.")
        }
    }
}
