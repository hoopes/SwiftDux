import XCTest
import Combine
import Dispatch
import SwiftDux
@testable import SwiftDuxExtras

@MainActor
final class PrintActionMiddlewareTests: XCTestCase {
  
  override func setUp() async throws {
  }
  
  func testPrintAction() {
    var log = [String]()
    let store = Store(
      state: TestState(),
      reducer: TestReducer(),
      middleware: PrintActionMiddleware(printer: { log.append($0) })
    )
    store.send(TestAction.actionB)
    XCTAssertEqual(log, ["prepare", "actionB"])
  }
}

extension PrintActionMiddlewareTests {
  
  enum TestAction: Action, Equatable {
    case actionA
    case actionB
  }
  
  struct TestState: Equatable {
    var test: String = ""
  }
  
  class TestReducer: Reducer {
    func reduce(state: TestState, action: TestAction) -> TestState {
      state
    }
  }
}
