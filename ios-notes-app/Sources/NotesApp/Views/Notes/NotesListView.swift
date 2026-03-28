import SwiftUI
import SwiftData
import NotesShared

struct NotesListView: View {

    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @State private var searchText = ""
    @State private var filterCategory: NoteCategory?

    private var filtered: [Note] {
        notes.filter { note in
            let matchesSearch = searchText.isEmpty ||
                note.content.localizedCaseInsensitiveContains(searchText) ||
                (note.summary?.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesCategory = filterCategory == nil || note.category == filterCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { note in
                                NavigationLink(destination: NoteDetailView(note: note)) {
                                    NoteCardView(note: note)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(AppColor.background)
            .navigationTitle("Notes")
            .searchable(text: $searchText, prompt: "Search notes…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All") { filterCategory = nil }
                        ForEach(NoteCategory.allCases, id: \.self) { cat in
                            Button {
                                filterCategory = cat
                            } label: {
                                Label(cat.displayName, systemImage: cat.icon)
                            }
                        }
                    } label: {
                        Image(systemName: filterCategory == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 56))
                .foregroundStyle(.quaternary)
            Text("No notes yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Tap + to capture your first note")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
