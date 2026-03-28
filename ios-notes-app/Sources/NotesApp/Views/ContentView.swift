import SwiftUI
import NotesShared

struct ContentView: View {

    @State private var showCapture = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                NotesListView()
                    .tabItem { Label("Notes", systemImage: "note.text") }
                    .tag(0)

                PlanningView()
                    .tabItem { Label("Plan", systemImage: "calendar") }
                    .tag(1)

                ActionItemsView()
                    .tabItem { Label("Actions", systemImage: "checkmark.circle") }
                    .tag(2)

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
                    .tag(3)
            }

            // Floating Action Button
            Button {
                showCapture = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 80) // above tab bar
        }
        .sheet(isPresented: $showCapture) {
            QuickCaptureView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openQuickCapture)) { _ in
            showCapture = true
        }
    }
}
