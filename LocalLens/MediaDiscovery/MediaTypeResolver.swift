import Foundation
import UniformTypeIdentifiers

public struct MediaTypeResolver: Sendable { public init() {}; public func mediaType(for url: URL) -> MediaType? { let ext = url.pathExtension.lowercased(); if ["png","jpg","jpeg","heic","tiff","webp"].contains(ext) { return .image }; if ext == "pdf" { return .pdf }; if ["mp3","m4a","wav","aac"].contains(ext) { return .audio }; if ["mp4","mov","m4v"].contains(ext) { return .video }; return nil } }
