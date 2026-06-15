import Foundation
import SQLite3

public enum LocalLensDatabaseError: Error, Equatable, Sendable {
    case openFailed(String)
    case migrationFailed(String)
    case executionFailed(String)
    case corruptionDetected(String)
}

public enum SQLiteValue: Equatable, Sendable {
    case null
    case integer(Int64)
    case real(Double)
    case text(String)
    case data(Data)

    public var stringValue: String? {
        if case let .text(value) = self { return value }
        return nil
    }

    public var intValue: Int? {
        if case let .integer(value) = self { return Int(value) }
        return nil
    }

    public var int64Value: Int64? {
        if case let .integer(value) = self { return value }
        return nil
    }

    public var doubleValue: Double? {
        switch self {
        case let .real(value): return value
        case let .integer(value): return Double(value)
        default: return nil
        }
    }

    public var dataValue: Data? {
        if case let .data(value) = self { return value }
        return nil
    }
}

public struct SQLiteRow: Sendable, Equatable {
    private let values: [String: SQLiteValue]

    public init(values: [String: SQLiteValue]) {
        self.values = values
    }

    public subscript(_ key: String) -> SQLiteValue { values[key] ?? .null }
}

private final class SQLiteHandle: @unchecked Sendable {
    var raw: OpaquePointer?
    init(_ raw: OpaquePointer?) { self.raw = raw }
    deinit { if let raw { sqlite3_close(raw) } }
}

public actor LocalLensDatabase {
    private let handle: SQLiteHandle
    public let databaseURL: URL
    public let cacheRootURL: URL

    public init(databaseURL: URL? = nil, cacheRootURL: URL? = nil) throws {
        let support = try Self.defaultApplicationSupportURL()
        self.databaseURL = databaseURL ?? support.appendingPathComponent("LocalLens.sqlite")
        self.cacheRootURL = cacheRootURL ?? support.appendingPathComponent("Caches", isDirectory: true)
        try FileManager.default.createDirectory(at: self.databaseURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: self.cacheRootURL, withIntermediateDirectories: true)
        var opened: OpaquePointer?
        guard sqlite3_open_v2(self.databaseURL.path, &opened, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            let message = opened.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            if let opened { sqlite3_close(opened) }
            throw LocalLensDatabaseError.openFailed(message)
        }
        self.handle = SQLiteHandle(opened)
    }

    public static func defaultApplicationSupportURL() throws -> URL {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return base.appendingPathComponent("LocalLens", isDirectory: true)
    }

    public func migrate() throws {
        for sql in MigrationV1.statements { try execute(sql) }
    }

    public func execute(_ sql: String) throws {
        guard let db = handle.raw else { throw LocalLensDatabaseError.openFailed("database closed") }
        var error: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &error) == SQLITE_OK else {
            let message = error.map { String(cString: $0) } ?? String(cString: sqlite3_errmsg(db))
            sqlite3_free(error)
            if message.localizedCaseInsensitiveContains("malformed") { throw LocalLensDatabaseError.corruptionDetected(message) }
            throw LocalLensDatabaseError.executionFailed(message)
        }
    }

    public func execute(_ sql: String, bindings: [SQLiteValue]) throws {
        guard let db = handle.raw else { throw LocalLensDatabaseError.openFailed("database closed") }
        let statement = try prepare(sql, db: db)
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)
        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE else { throw LocalLensDatabaseError.executionFailed(String(cString: sqlite3_errmsg(db))) }
    }

    public func query(_ sql: String, bindings: [SQLiteValue] = []) throws -> [SQLiteRow] {
        guard let db = handle.raw else { throw LocalLensDatabaseError.openFailed("database closed") }
        let statement = try prepare(sql, db: db)
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)
        var rows: [SQLiteRow] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { break }
            guard result == SQLITE_ROW else { throw LocalLensDatabaseError.executionFailed(String(cString: sqlite3_errmsg(db))) }
            rows.append(readRow(from: statement))
        }
        return rows
    }

    public func scalarInt(_ sql: String) throws -> Int {
        try scalarInt(sql, bindings: [])
    }

    public func scalarInt(_ sql: String, bindings: [SQLiteValue]) throws -> Int {
        guard let row = try query(sql, bindings: bindings).first else { return 0 }
        return row["count"].intValue ?? row["COUNT(*)"].intValue ?? 0
    }

    public func withTransaction<T: Sendable>(_ operation: @Sendable () throws -> T) throws -> T {
        try execute("BEGIN IMMEDIATE TRANSACTION;")
        do {
            let value = try operation()
            try execute("COMMIT;")
            return value
        } catch {
            try? execute("ROLLBACK;")
            throw error
        }
    }

    private func prepare(_ sql: String, db: OpaquePointer) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw LocalLensDatabaseError.executionFailed(String(cString: sqlite3_errmsg(db)))
        }
        return statement
    }

    private func bind(_ values: [SQLiteValue], to statement: OpaquePointer?) throws {
        for (index, value) in values.enumerated() {
            let position = Int32(index + 1)
            let result: Int32
            switch value {
            case .null:
                result = sqlite3_bind_null(statement, position)
            case let .integer(value):
                result = sqlite3_bind_int64(statement, position, value)
            case let .real(value):
                result = sqlite3_bind_double(statement, position, value)
            case let .text(value):
                result = sqlite3_bind_text(statement, position, value, -1, SQLITE_TRANSIENT)
            case let .data(value):
                result = value.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, position, bytes.baseAddress, Int32(value.count), SQLITE_TRANSIENT)
                }
            }
            guard result == SQLITE_OK else { throw LocalLensDatabaseError.executionFailed("SQLite bind failed at position \(position)") }
        }
    }

    private func readRow(from statement: OpaquePointer?) -> SQLiteRow {
        let columnCount = sqlite3_column_count(statement)
        var values: [String: SQLiteValue] = [:]
        for index in 0..<columnCount {
            let name = String(cString: sqlite3_column_name(statement, index))
            switch sqlite3_column_type(statement, index) {
            case SQLITE_INTEGER:
                values[name] = .integer(sqlite3_column_int64(statement, index))
            case SQLITE_FLOAT:
                values[name] = .real(sqlite3_column_double(statement, index))
            case SQLITE_TEXT:
                values[name] = .text(String(cString: sqlite3_column_text(statement, index)))
            case SQLITE_BLOB:
                let bytes = sqlite3_column_blob(statement, index)
                let count = Int(sqlite3_column_bytes(statement, index))
                values[name] = .data(Data(bytes: bytes!, count: count))
            default:
                values[name] = .null
            }
        }
        return SQLiteRow(values: values)
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
