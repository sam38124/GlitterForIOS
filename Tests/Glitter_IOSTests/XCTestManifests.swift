import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Glitter_IOSTests.allTests),
    ]
}
#endif
