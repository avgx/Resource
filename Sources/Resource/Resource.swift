import Foundation

/// Async data state for managers and UI.
///
/// `Failure` must be equatable and displayable.
/// Map raw `Error` values at the layer boundary;
/// otherwise `Resource` cannot stay `Equatable` without hacks such as `String(reflecting:)`
/// (see https://stackoverflow.com/a/76417617/2060780).
public enum Resource<Value: Equatable & Sendable, Failure: Error & Equatable & Sendable>: Equatable & Sendable {

    /// Nothing loaded yet; initial state before the first fetch.
    case idle

    /// First load in flight; no cached value to show.
    case loading

    /// Fresh data on screen; no fetch in progress.
    case available(Value)
    /// Cached value stays visible while a refresh is in flight.
    case refreshing(Value)

    /// Load failed with nothing to show.
    case failed(Failure)
    /// Cached value remains after the last refresh failed.
    case stale(Value, Failure)
}

extension Resource {

    public var value: Value? {
        switch self {
        case .available(let value):
            return value

        case .refreshing(let value):
            return value

        case .stale(let value, _):
            return value

        default:
            return nil
        }
    }
    
    public var isAvailable: Bool {
        value != nil
    }
}

extension Resource {
    
    public var isLoading: Bool {
        switch self {
        case .loading:
            return true
        case .refreshing(_):
            return true
        default:
            return false
        }
    }
}

extension Resource {
    public var failure: Failure? {
        switch self {
        case .failed(let failure):
            return failure

        case .stale(_, let failure):
            return failure

        default:
            return nil
        }
    }
    
    public var isFailed: Bool {
        failure != nil
    }
}

extension Resource where Failure: Equatable & Error & Sendable {
    public func beginLoading() -> Resource<Value, Failure> {
        if let value = value {
            return .refreshing(value)
        }
        return .loading
    }

    public func succeed(_ value: Value) -> Resource<Value, Failure> {
        .available(value)
    }

    public func fail(_ failure: Failure) -> Resource<Value, Failure> {
        if let value = value {
            return .stale(value, failure)
        }
        return .failed(failure)
    }
}
