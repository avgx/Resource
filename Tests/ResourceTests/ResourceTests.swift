import Testing
@testable import Resource

enum TestError: Error, Equatable {
    case boom
}

typealias TestResource = Resource<String, TestError>

let sampleValue = "value"
let updatedValue = "updated"
let sampleFailure = TestError.boom

@Test(arguments: [
    (TestResource.idle, nil as String?),
    (.loading, nil),
    (.available(sampleValue), sampleValue),
    (.refreshing(sampleValue), sampleValue),
    (.failed(sampleFailure), nil),
    (.stale(sampleValue, sampleFailure), sampleValue),
])
func value(for resource: TestResource, expected: String?) {
    #expect(resource.value == expected)
}

@Test(arguments: [
    (TestResource.idle, false),
    (.loading, false),
    (.available(sampleValue), true),
    (.refreshing(sampleValue), true),
    (.failed(sampleFailure), false),
    (.stale(sampleValue, sampleFailure), true),
])
func isAvailable(for resource: TestResource, expected: Bool) {
    #expect(resource.isAvailable == expected)
}

@Test(arguments: [
    (TestResource.idle, false),
    (.loading, true),
    (.available(sampleValue), false),
    (.refreshing(sampleValue), true),
    (.failed(sampleFailure), false),
    (.stale(sampleValue, sampleFailure), false),
])
func isLoading(for resource: TestResource, expected: Bool) {
    #expect(resource.isLoading == expected)
}

@Test(arguments: [
    (TestResource.idle, nil as TestError?),
    (.loading, nil),
    (.available(sampleValue), nil),
    (.refreshing(sampleValue), nil),
    (.failed(sampleFailure), sampleFailure),
    (.stale(sampleValue, sampleFailure), sampleFailure),
])
func failure(for resource: TestResource, expected: TestError?) {
    #expect(resource.failure == expected)
}

@Test(arguments: [
    (TestResource.idle, false),
    (.loading, false),
    (.available(sampleValue), false),
    (.refreshing(sampleValue), false),
    (.failed(sampleFailure), true),
    (.stale(sampleValue, sampleFailure), true),
])
func isFailed(for resource: TestResource, expected: Bool) {
    #expect(resource.isFailed == expected)
}

@Test func equatableSameState() {
    #expect(TestResource.available(sampleValue) == .available(sampleValue))
    #expect(TestResource.stale(sampleValue, sampleFailure) == .stale(sampleValue, sampleFailure))
}

@Test func equatableDifferentAssociatedValues() {
    #expect(TestResource.available(sampleValue) != .available(updatedValue))
    #expect(TestResource.failed(sampleFailure) != .stale(sampleValue, sampleFailure))
}

@Test func equatableDifferentCasesWithSameValue() {
    #expect(TestResource.available(sampleValue) != .refreshing(sampleValue))
    #expect(TestResource.available(sampleValue) != .stale(sampleValue, sampleFailure))
}

// MARK: - beginLoading Tests

@Test func beginLoadingFromIdle() {
    let resource = TestResource.idle
    let result = resource.beginLoading()
    
    #expect(result == TestResource.loading)
    #expect(result.value == nil)
    #expect(result.isLoading == true)
    #expect(result.isAvailable == false)
}

@Test func beginLoadingFromLoading() {
    let resource = TestResource.loading
    let result = resource.beginLoading()
    
    #expect(result == TestResource.loading)
    #expect(result.value == nil)
    #expect(result.isLoading == true)
    #expect(result.isAvailable == false)
}

@Test func beginLoadingFromAvailable() {
    let resource = TestResource.available(sampleValue)
    let result = resource.beginLoading()
    
    #expect(result == TestResource.refreshing(sampleValue))
    #expect(result.value == sampleValue)
    #expect(result.isLoading == true)
    #expect(result.isAvailable == true)
}

@Test func beginLoadingFromRefreshing() {
    let resource = TestResource.refreshing(sampleValue)
    let result = resource.beginLoading()
    
    // Refreshing should keep the same value but remain in refreshing state
    #expect(result == TestResource.refreshing(sampleValue))
    #expect(result.value == sampleValue)
    #expect(result.isLoading == true)
    #expect(result.isAvailable == true)
}

@Test func beginLoadingFromFailed() {
    let resource = TestResource.failed(sampleFailure)
    let result = resource.beginLoading()
    
    // Failed state has no cached value, so should go to loading
    #expect(result == TestResource.loading)
    #expect(result.value == nil)
    #expect(result.isLoading == true)
    #expect(result.isAvailable == false)
    #expect(result.failure == nil)
}

@Test func beginLoadingFromStale() {
    let resource = TestResource.stale(sampleValue, sampleFailure)
    let result = resource.beginLoading()
    
    // Stale has cached value, so should go to refreshing with same value
    #expect(result == TestResource.refreshing(sampleValue))
    #expect(result.value == sampleValue)
    #expect(result.isLoading == true)
    #expect(result.isAvailable == true)
    #expect(result.failure == nil) // Failure should be cleared during refresh
}

@Test func beginLoadingSequence() {
    // Test a realistic sequence: stale -> refreshing -> available
    var resource = TestResource.stale(sampleValue, sampleFailure)
    #expect(resource.failure == sampleFailure)
    
    // Begin refresh
    resource = resource.beginLoading()
    #expect(resource == TestResource.refreshing(sampleValue))
    #expect(resource.failure == nil)
    #expect(resource.isLoading == true)
    
    // Succeed the refresh
    resource = resource.succeed(updatedValue)
    #expect(resource == TestResource.available(updatedValue))
    #expect(resource.isLoading == false)
    #expect(resource.value == updatedValue)
}

@Test(arguments: [
    (TestResource.idle, false, true, false),      // idle -> loading
    (TestResource.loading, false, true, false),   // loading -> loading
    (TestResource.available(sampleValue), true, true, true),   // available -> refreshing
    (TestResource.refreshing(sampleValue), true, true, true),  // refreshing -> refreshing
    (TestResource.failed(sampleFailure), false, true, false),  // failed -> loading
    (TestResource.stale(sampleValue, sampleFailure), true, true, true), // stale -> refreshing
])
func beginLoadingTransitions(
    from resource: TestResource,
    expectedHasValue: Bool,
    expectedIsLoading: Bool,
    expectedIsAvailable: Bool
) {
    let result = resource.beginLoading()
    
    #expect(result.isLoading == expectedIsLoading)
    #expect(result.isAvailable == expectedIsAvailable)
    
    if expectedHasValue {
        #expect(result.value != nil)
    } else {
        #expect(result.value == nil)
    }
}

@Test func beginLoadingPreservesValueSemantics() {
    let customValue = "custom"
    let customFailure = TestError.boom
    
    let testCases: [TestResource] = [
        .idle,
        .loading,
        .available(customValue),
        .refreshing(customValue),
        .failed(customFailure),
        .stale(customValue, customFailure)
    ]
    
    for resource in testCases {
        let result = resource.beginLoading()
        
        // Check that beginLoading is not changing value when need to save it
        if case .available(let value) = resource,
           case .refreshing(let newValue) = result {
            #expect(value == newValue)
        } else if case .refreshing(let value) = resource,
                  case .refreshing(let newValue) = result {
            #expect(value == newValue)
        } else if case .stale(let value, _) = resource,
                  case .refreshing(let newValue) = result {
            #expect(value == newValue)
        }
    }
}
