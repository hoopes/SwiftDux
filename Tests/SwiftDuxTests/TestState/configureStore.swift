import Foundation
import SwiftDux

@MainActor func configureStore(state: AppState = AppState.defaultState) -> Store<AppState> {
  Store(state: state, reducer: TodoListsReducer() + TodosReducer())
}
