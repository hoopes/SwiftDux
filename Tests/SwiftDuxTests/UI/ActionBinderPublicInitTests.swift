import XCTest
// Deliberately not @testable: this file compiles only while ActionBinder's initializer is public.
import SwiftDux

@MainActor
final class ActionBinderPublicInitTests: XCTestCase {

  func testABinderCanBeMadeOutsideTheModule() {
    let store = Store(state: ActionBinderTests.TestState(), reducer: ActionBinderTests.TestReducer())
    let binder = ActionBinder(actionDispatcher: store)
    var binding = binder.bind(store.state.name) {
      ActionBinderTests.TestAction.setName($0)
    }
    binding.wrappedValue = "from a public binder"
    XCTAssertEqual(store.state.name, "from a public binder")
  }
}
