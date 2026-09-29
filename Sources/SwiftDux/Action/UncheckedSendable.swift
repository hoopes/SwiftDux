import Foundation

/// Carries a value that is not Sendable across an isolation boundary the compiler cannot prove
/// safe. Each use says why it is: the value is handed over once and not touched again from where
/// it came.
@usableFromInline
internal struct UncheckedSendable<Value>: @unchecked Sendable {
  @usableFromInline let value: Value

  @usableFromInline init(_ value: Value) {
    self.value = value
  }
}
