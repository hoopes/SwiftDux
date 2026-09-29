import Combine
import Foundation

/// Combines multiple actions into a chained, composite action. It guarantees the dispatch order of each action.
public struct CompositeAction: RunnableAction {

  @usableFromInline
  internal var actions: [Action] = []

  /// Create a composite action.
  ///
  /// - Parameter actions: An array of actions to chain.
  @usableFromInline internal init(_ actions: [Action] = []) {
    self.actions = actions
  }

  // Each action starts when the one before it completes, which can be on any thread, so this is
  // explicitly nonisolated: otherwise it, and the closure below, would inherit the main actor from
  // the requirement it satisfies, and trap off it. The actions touch the store, so each is started
  // on the main actor - synchronously when the previous one completed on the main thread, as it
  // always did, and on the main queue otherwise.
  nonisolated public func run<T>(store: StoreProxy<T>) -> AnyPublisher<Action, Never> {
    actions
      .publisher
      .flatMap(maxPublishers: .max(1)) { action -> AnyPublisher<Action, Never> in
        let action = UncheckedSendable(action)
        guard Thread.isMainThread else {
          return Just(())
            .receive(on: DispatchQueue.main)
            .flatMap { _ in Self.start(action, forStore: store) }
            .eraseToAnyPublisher()
        }
        return Self.start(action, forStore: store)
      }
      .eraseToAnyPublisher()
  }

  private static func start<T>(_ action: UncheckedSendable<Action>, forStore store: StoreProxy<T>) -> AnyPublisher<Action, Never> {
    MainActor.assumeIsolated { UncheckedSendable(run(action: action.value, forStore: store)) }.value
  }

  @MainActor private static func run<T>(action: Action, forStore store: StoreProxy<T>) -> AnyPublisher<Action, Never> {
    if let action = action as? RunnableAction {
      return action.run(store: store)
    }
    return Just(action).eraseToAnyPublisher()
  }
}

/// Chain two actions together as a composite type.
///
/// - Parameters:
///   - lhs: The first action.
///   - rhs: The next action.
/// - Returns: A composite action.
@inlinable public func + (lhs: Action, rhs: Action) -> CompositeAction {
  if var lhs = lhs as? CompositeAction {
    lhs.actions.append(rhs)
    return lhs
  }
  return CompositeAction([lhs, rhs])
}
