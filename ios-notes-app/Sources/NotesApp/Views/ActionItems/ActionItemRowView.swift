import SwiftUI
import SwiftData
import NotesShared

struct ActionItemRowView: View {

    @Bindable var item: ActionItem
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 10) {
            Button {
                item.isCompleted.toggle()
                try? modelContext.save()
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isCompleted ? AppColor.completedAction : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .foregroundStyle(item.isCompleted ? .secondary : AppColor.primaryText)
                    .strikethrough(item.isCompleted, color: .secondary)

                if let due = item.dueDate {
                    Text("Due \(DateFormatters.relative(due))")
                        .font(.caption)
                        .foregroundStyle(item.isCompleted ? .tertiary : AppColor.pendingAction)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
