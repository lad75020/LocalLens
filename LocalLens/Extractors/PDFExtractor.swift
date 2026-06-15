import AppKit
import Foundation
import PDFKit
import Vision

public struct PDFExtractor: ExtractorService, Sendable {
    public let maxOCRPages: Int

    public init(maxOCRPages: Int = 12) {
        self.maxOCRPages = max(1, maxOCRPages)
    }

    public func extract(from url: URL) async throws -> PDFExtractionResult {
        do {
            guard let document = PDFDocument(url: url) else {
                throw ExtractionFailure.failed(category: .corruptedMedia, retryability: .notRetryable, safeMessage: "PDF could not be opened.")
            }
            guard !document.isLocked else {
                throw ExtractionFailure.failed(category: .passwordProtectedPDF, retryability: .notRetryable, safeMessage: "Password-protected PDFs are skipped until unlocked outside LocalLens.")
            }

            let pageCount = document.pageCount
            guard pageCount > 0 else {
                throw ExtractionFailure.failed(category: .corruptedMedia, retryability: .notRetryable, safeMessage: "PDF has no readable pages.")
            }

            var pages: [PageExtraction] = []
            for index in 0..<pageCount {
                guard let page = document.page(at: index) else {
                    pages.append(PageExtraction(pageNumber: index + 1, selectableText: "", ocrText: "", failureCategory: .corruptedMedia))
                    continue
                }

                let selectable = (page.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                var ocrText = ""
                var failure: FailureCategory?
                if selectable.isEmpty, index < maxOCRPages {
                    do {
                        let image = try render(page: page)
                        ocrText = await recognizeText(in: image).map(\.text).joined(separator: "\n")
                    } catch {
                        failure = ExtractionFailure.map(error, defaultCategory: .corruptedMedia).category
                    }
                }
                pages.append(PageExtraction(pageNumber: index + 1, selectableText: selectable, ocrText: ocrText, failureCategory: failure))
            }

            let hasText = pages.contains { !$0.combinedText.isEmpty }
            return PDFExtractionResult(pageCount: pageCount, pages: pages, failureCategory: hasText ? nil : .unknownRedacted)
        } catch let failure as ExtractionFailure {
            throw failure
        } catch {
            throw ExtractionFailure.map(error, defaultCategory: .corruptedMedia)
        }
    }

    private func render(page: PDFPage) throws -> CGImage {
        let bounds = page.bounds(for: .mediaBox)
        let longest = max(bounds.width, bounds.height)
        let scale = longest > 0 ? min(1536 / longest, 2) : 1
        let size = CGSize(width: max(1, bounds.width * scale), height: max(1, bounds.height * scale))
        let image = page.thumbnail(of: size, for: .mediaBox)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ExtractionFailure.failed(category: .corruptedMedia, retryability: .retry, safeMessage: "PDF page could not be rendered for OCR.")
        }
        return cgImage
    }

    private func recognizeText(in image: CGImage) async -> [RecognizedText] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                    let observations = (request.results ?? [])
                        .compactMap { observation -> RecognizedText? in
                            guard let candidate = observation.topCandidates(1).first else { return nil }
                            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { return nil }
                            return RecognizedText(text: text, confidence: Double(candidate.confidence), pageNumber: nil)
                        }
                    continuation.resume(returning: observations)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }
}
