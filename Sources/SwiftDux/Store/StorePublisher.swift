import Combine
import Foundation

/// Publishes state changes from the store.
// Sendable so a store's changes can be observed from any task. Its only state is the subject,
// a constant, and Combine's subjects synchronize their own subscribers and sends.
public final class StorePublisher: Publisher, @unchecked Sendable {
  public typealias Failure = Never
  public typealias Output = Void
  private let subject = PassthroughSubject<Void, Never>()

  public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, S.Input == Void {
    subject.receive(subscriber: subscriber)
  }

  internal func send() {
    subject.send()
  }
}
