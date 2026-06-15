import Foundation

public actor IndexProgressStore { public private(set) var snapshot = IndexProgressSnapshot(); public init() {}; public func publish(_ snapshot: IndexProgressSnapshot) { self.snapshot = snapshot } }
