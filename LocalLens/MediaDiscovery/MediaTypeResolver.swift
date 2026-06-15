import Foundation
import UniformTypeIdentifiers

public struct ResolvedMediaType: Equatable, Sendable {
    public let mediaType: MediaType
    public let contentTypeIdentifier: String

    public init(mediaType: MediaType, contentTypeIdentifier: String) {
        self.mediaType = mediaType
        self.contentTypeIdentifier = contentTypeIdentifier
    }
}

public struct MediaTypeResolver: Sendable {
    private let extensionMap: [String: ResolvedMediaType]

    public init() {
        self.extensionMap = [
            "png": .init(mediaType: .image, contentTypeIdentifier: UTType.png.identifier),
            "jpg": .init(mediaType: .image, contentTypeIdentifier: UTType.jpeg.identifier),
            "jpeg": .init(mediaType: .image, contentTypeIdentifier: UTType.jpeg.identifier),
            "heic": .init(mediaType: .image, contentTypeIdentifier: UTType.heic.identifier),
            "tif": .init(mediaType: .image, contentTypeIdentifier: UTType.tiff.identifier),
            "tiff": .init(mediaType: .image, contentTypeIdentifier: UTType.tiff.identifier),
            "webp": .init(mediaType: .image, contentTypeIdentifier: UTType(filenameExtension: "webp")?.identifier ?? "org.webmproject.webp"),
            "pdf": .init(mediaType: .pdf, contentTypeIdentifier: UTType.pdf.identifier),
            "mp3": .init(mediaType: .audio, contentTypeIdentifier: UTType.mp3.identifier),
            "m4a": .init(mediaType: .audio, contentTypeIdentifier: UTType.mpeg4Audio.identifier),
            "wav": .init(mediaType: .audio, contentTypeIdentifier: UTType.wav.identifier),
            "aac": .init(mediaType: .audio, contentTypeIdentifier: UTType(filenameExtension: "aac")?.identifier ?? "public.aac-audio"),
            "mp4": .init(mediaType: .video, contentTypeIdentifier: UTType.mpeg4Movie.identifier),
            "mov": .init(mediaType: .video, contentTypeIdentifier: UTType.quickTimeMovie.identifier),
            "m4v": .init(mediaType: .video, contentTypeIdentifier: UTType(filenameExtension: "m4v")?.identifier ?? "com.apple.m4v-video"),
            "pptx": .init(mediaType: .office, contentTypeIdentifier: UTType(filenameExtension: "pptx")?.identifier ?? "org.openxmlformats.presentationml.presentation"),
            "docx": .init(mediaType: .office, contentTypeIdentifier: UTType(filenameExtension: "docx")?.identifier ?? "org.openxmlformats.wordprocessingml.document"),
            "xlsx": .init(mediaType: .office, contentTypeIdentifier: UTType(filenameExtension: "xlsx")?.identifier ?? "org.openxmlformats.spreadsheetml.sheet")
        ]
    }

    public func resolve(_ url: URL) -> ResolvedMediaType? {
        extensionMap[url.pathExtension.lowercased()]
    }

    public func mediaType(for url: URL) -> MediaType? {
        resolve(url)?.mediaType
    }

    public func contentTypeIdentifier(for url: URL) -> String? {
        resolve(url)?.contentTypeIdentifier
    }

    public func officeKind(for url: URL) -> OfficeDocumentKind? {
        OfficeDocumentKind(rawValue: url.pathExtension.lowercased())
    }
}
