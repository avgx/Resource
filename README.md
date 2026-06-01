# Resource

Most apps track async data with separate flags — `value?`, `isLoading`, `error?` — and eventually end up in impossible combinations: data and an error at once, or loading with no way to tell first load from refresh. `Resource` is a single finite-state enum: one case at a time, six cases total, `Equatable` and `Sendable`.

```swift
public enum Resource<Value, Failure>
where Value: Equatable & Sendable, Failure: Error & Equatable & Sendable {
    case idle
    case loading
    case available(Value)
    case refreshing(Value)
    case failed(Failure)
    case stale(Value, Failure)
}
```

Use it as public state on a manager; map transport errors into `Failure` at the boundary.

```swift
@MainActor
final class ItemsManager: ObservableObject {
        @Published public private(set) var items: Resource<[Item], AppError> = .idle

    func load() async {
        items = .loading
        do {
            items = .available(try await http.fetch())
        } catch {
            items = .failed(AppError(from: error))
        }
    }

    func refresh() async {
        guard let current = items.value else { return }
        items = .refreshing(current)
        do {
            items = .available(try await http.fetch())
        } catch {
            items = .stale(current, AppError(from: error))
        }
    }
}
```

## Transitions

No cached data:

```
.idle
.loading
.failed(error)
```

Cached data:

```
.available(value)
.refreshing(value)
.stale(value, error)
```

Typical flow:

```
.idle
↓
.loading
↓
.available(value)
↓
.refreshing(value)
↓
.available(updatedValue)
or
.stale(value, error)
```

Secondary paths: 
`.loading → .failed` on first load; 
`.failed → .loading` on retry; 
`.stale → .refreshing` on retry with cache.

## Install

```swift
.package(url: "https://github.com/avgx/Resource.git", from: "1.0.0")
```

```bash
swift build
swift test
```

Full write-up: [Resource: one enum for async data state](https://avgx.github.io/blog/http-resource/).
