import XCTest
import Combine
@testable import SwiftDux

@MainActor
final class StoreTests: XCTestCase {
  var store: Store<TestSendingState>!
  
  override func setUp() async throws {
    store = Store(state: TestSendingState(text: "initial text"), reducer: TestSendingReducer())
  }
  
  override func tearDown() async throws {
    store = nil
  }
  
  func testInitialStateValue() {
    XCTAssertEqual(store.state.text, "initial text")
  }
  
  func testSendingAction() {
    store.send(TestSendingAction.setText("New text"))
    XCTAssertEqual(store.state.text, "New text")
  }
  
  func testActionPlans() {
    store.send(ActionPlan<TestSendingState> { store in
      Just(TestSendingAction.setText("1234"))
    })
    XCTAssertEqual(store.state.text, "1234")
  }
  
  func testSubscribingToActionPlans() {
    store.send(ActionPlan<TestSendingState> { store in
      Just<Action>(TestSendingAction.setText("1234"))
    })
    XCTAssertEqual(store.state.text, "1234")
  }
  
  func testSubscribingToComplexActionPlans() {
    store.send(ActionPlan<TestSendingState> { store -> AnyPublisher<Action, Never> in
      Just<Int>(store.state.value)
        .eraseToAnyPublisher()
        .map { value -> Int in
          store.send(TestSendingAction.setValue(value + 1))
          return store.state.value
        }
        .map { value -> Int in
          store.send(TestSendingAction.setValue(value + 1))
          return store.state.value
        }
        .map { value -> Action in
          TestSendingAction.setValue(value + 1)
        }
        .eraseToAnyPublisher()
    })
    XCTAssertEqual(store.state.value, 3)
  }

  func testFutureAction() {
    let actionPlan = ActionPlan<TestSendingState> { store in
      Future<Void, Never> { promise in
        store.send(TestSendingAction.setText("test"))
        promise(.success(()))
      }
    }
    
    let cancellable = actionPlan.run(store: store.proxy()).send(to: store)
    XCTAssertEqual(store.state.text, "test")
    cancellable.cancel()
  }

  func testActionPlansEmittingOffTheMainThreadDispatchOnIt() async throws {
    store.send(ActionPlan<TestSendingState> { _ in
      Just<Action>(TestSendingAction.setText("from a background queue"))
        .receive(on: DispatchQueue.global())
    })

    // The action hops to the main queue, which this test holds until it suspends.
    XCTAssertEqual(store.state.text, "initial text")
    for _ in 0..<200 where store.state.text != "from a background queue" {
      try await Task.sleep(nanoseconds: 5_000_000)
    }
    XCTAssertEqual(store.state.text, "from a background queue")
  }

  func testCompositeActionsContinueOnTheMainThreadAfterAnOffMainPlan() async throws {
    store.send(
      ActionPlan<TestSendingState> { _ in
        Just<Action>(TestSendingAction.setText("from a background queue"))
          .receive(on: DispatchQueue.global())
      }
      .then(TestSendingAction.setValue(1))
    )

    for _ in 0..<200 where store.state.value != 1 {
      try await Task.sleep(nanoseconds: 5_000_000)
    }
    XCTAssertEqual(store.state.text, "from a background queue")
    XCTAssertEqual(store.state.value, 1)
  }
}

extension StoreTests {
  
  enum TestSendingAction: Action {
    case setText(String)
    case setValue(Int)
  }
  
  struct TestSendingState: Equatable {
    var text: String
    var value: Int = 0
  }
  
  class TestSendingReducer: Reducer {
    func reduce(state: TestSendingState, action: TestSendingAction) -> TestSendingState {
      var state = state
      switch action {
      case .setText(let text):
        state.text = text
      case .setValue(let value):
        state.value = value
      }
      return state
    }
  }
}
