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
