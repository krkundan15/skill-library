import SwiftUI
import SwiftData
import NotesShared

struct ActionItemsView: View {

    @Query(sort: \ActionItem.createdAt, order: .reverse) private var allItems: [ActionItem]

    private var today: [ActionItem]    { allItems.filter { $0.bucket == .today } }
    private var upcoming: [ActionItem] { allItems.filter { $0.bucket == .upcoming } }
    private var done: [ActionItem]     { allItems.filter { $0.bucket == .done } }

    var body: some View {
        NavigationStack {
            Group {
                if allItems.isEmpty {
                    emptyState
                } else {
                    List {
                        if !today.isEmpty {
                            Section("Today") {
                                ForEach(today) { ActionItemRowView(item: $0) }
                            }
                        }
                        if !upcoming.isEmpty {
                            Section("Upcoming") {
                                ForEach(upcoming) { ActionItemRowView(item: $0) }
                            }
                        }
                        if !done.isEmpty {
                            Section("Done") {
                                ForEach(done) { ActionItemRowView(item: $0) }
                                    .opacity(0.6)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Actions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Progress indicator
                    let total = allItems.count
                    let completed = done.count
                    if total > 0 {
                        Text("\(completed)/\(total)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(.quaternary)
            Text("No action items yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Action items are extracted automatically\nwhen you save a note")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
