public import SwiftUI


public struct TodoItemRow: View {
  private let item: TodoItem
  private let onToggle: @MainActor @Sendable (Date) -> Void
  
  public var body: some View {
    HStack {
      Button(action: onToggle) {
        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
          .foregroundColor(item.isCompleted ? .green : .gray)
      }
      
      Button(action: {
        Task { @MainActor [weak self] in
          self?.onToggle(Date())
        }
      }) {
        Image(systemName: "trash")
      }
    }
  }
}
