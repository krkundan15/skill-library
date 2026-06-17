import SwiftUI
import NotesShared

struct ContentView: View {

    @State private var showCapture = false
    @State private var showMeeting = false
    @State private var fabExpanded = false
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

            fabStack
        }
        .sheet(isPresented: $showCapture) {
            QuickCaptureView()
        }
        .sheet(isPresented: $showMeeting) {
            MeetingCaptureView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openQuickCapture)) { _ in
            showCapture = true
        }
    }

    @ViewBuilder
    private var fabStack: some View {
        VStack(alignment: .trailing, spacing: 16) {
            if fabExpanded {
                fabOption(title: "New Meeting", systemImage: "mic.fill") {
                    fabExpanded = false
                    showMeeting = true
                }
                fabOption(title: "Quick Note", systemImage: "square.and.pencil") {
                    fabExpanded = false
                    showCapture = true
                }
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    fabExpanded.toggle()
                }
            } label: {
                Image(systemName: fabExpanded ? "xmark" : "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 80) // above tab bar
    }

    private func fabOption(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppColor.cardBackground)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
}
