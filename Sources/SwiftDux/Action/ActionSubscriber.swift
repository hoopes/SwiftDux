import Combine
import Foundation

/// Subscribes to a publisher of actions, and sends them to an action dispatcher.
final internal class ActionSubscriber: Subscriber {

  typealias ReceivedCompletion = () -> Void

  private let actionDispatcher: ActionDispatcher
  private var subscription: Subscription? = nil {
    willSet {
      guard let subscription = subscription else { return }
      subscription.cancel()
    }
  }

  internal init(actionDispatcher: ActionDispatcher) {
    self.actionDispatcher = actionDispatcher
  }

  public func receive(subscription: Subscription) {
    self.subscription = subscription
    subscription.request(.max(1))
  }

  public func receive(_ input: Action) -> Subscribers.Demand {
    // The store is isolated to the main actor, but a plan's publisher can emit anywhere. On the
    // main thread the action is dispatched synchronously, as it always was; from anywhere else
    // it hops to the main queue rather than racing the store.
    let delivery = Delivery(actionDispatcher: actionDispatcher, action: input)
    if Thread.isMainThread {
      MainActor.assumeIsolated { delivery.dispatch() }
    } else {
      DispatchQueue.main.async { MainActor.assumeIsolated { delivery.dispatch() } }
    }
    return .max(1)
  }

  public func receive(completion: Subscribers.Completion<Never>) {
    subscription = nil
  }

  public func cancel() {
    subscription?.cancel()
    subscription = nil
  }
}

/// Carries an action from the thread a publisher emitted it on to the main actor. It is handed
/// over once and never touched from the emitting thread again, which is what makes the unchecked
/// conformance sound.
private struct Delivery: @unchecked Sendable {
  let actionDispatcher: ActionDispatcher
  let action: Action

  @MainActor func dispatch() {
    actionDispatcher(action)
  }
}

extension Publisher where Output == Action, Failure == Never {

  /// Subscribe to a publisher of actions, and send the results to an action dispatcher.
  ///
  /// - Parameter actionDispatcher: The ActionDispatcher
  /// - Returns: A cancellable to unsubscribe.
  public func send(to actionDispatcher: ActionDispatcher) -> AnyCancellable {
    let subscriber = ActionSubscriber(actionDispatcher: actionDispatcher)

    self.subscribe(subscriber)
    return AnyCancellable { subscriber.cancel() }
  }
}
