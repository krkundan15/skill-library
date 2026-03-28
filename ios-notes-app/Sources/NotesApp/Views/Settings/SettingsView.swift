import SwiftUI
import NotesShared

struct SettingsView: View {

    @State private var apiKey: String = KeychainHelper.load(key: "claude_api_key") ?? ""
    @State private var useClaudeWhenOnline: Bool = UserDefaults.standard.bool(forKey: "useClaudeWhenOnline")
    @State private var showKeySaved = false

    var body: some View {
        NavigationStack {
            Form {
                // AI settings
                Section {
                    Toggle("Use Claude AI when online", isOn: $useClaudeWhenOnline)
                        .onChange(of: useClaudeWhenOnline) { _, val in
                            UserDefaults.standard.set(val, forKey: "useClaudeWhenOnline")
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Anthropic API Key")
                            .font(.subheadline)
                        SecureField("sk-ant-…", text: $apiKey)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                        Button("Save Key") {
                            KeychainHelper.save(key: "claude_api_key", value: apiKey)
                            showKeySaved = true
                        }
                        .disabled(apiKey.isEmpty)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("AI Settings")
                } footer: {
                    Text("Your API key is stored securely in the iOS Keychain. Get one at console.anthropic.com")
                        .font(.caption)
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("AI Model")
                        Spacer()
                        Text("claude-haiku-4-5")
                            .foregroundStyle(.secondary)
                            .font(.system(.subheadline, design: .monospaced))
                    }
                }

                // Data
                Section("Data") {
                    Button("Clear Saved API Key", role: .destructive) {
                        KeychainHelper.delete(key: "claude_api_key")
                        apiKey = ""
                    }
                }
            }
            .navigationTitle("Settings")
            .toast(isPresented: $showKeySaved, message: "API key saved")
        }
    }
}

// MARK: - Simple toast modifier

extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        self.overlay(alignment: .bottom) {
            if isPresented.wrappedValue {
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.darkGray))
                    .clipShape(Capsule())
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { isPresented.wrappedValue = false }
                        }
                    }
            }
        }
        .animation(.spring(), value: isPresented.wrappedValue)
    }
}
