import SwiftUI
import NotesShared

struct SettingsView: View {

    @EnvironmentObject private var orchestrator: AIOrchestrator

    @State private var providerKind: AIProviderKind = .claude
    @State private var claudeKey: String = KeychainHelper.load(key: AIProviderKind.claude.keychainKey!) ?? ""
    @State private var deepSeekKey: String = KeychainHelper.load(key: AIProviderKind.deepseek.keychainKey!) ?? ""
    @State private var showKeySaved = false

    var body: some View {
        NavigationStack {
            Form {
                // AI settings
                Section {
                    Picker("AI Provider", selection: $providerKind) {
                        ForEach(AIProviderKind.allCases, id: \.self) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    .onChange(of: providerKind) { _, val in
                        orchestrator.selectedProviderKind = val
                    }

                    if providerKind == .claude {
                        apiKeyField(
                            label: "Anthropic API Key",
                            placeholder: "sk-ant-…",
                            text: $claudeKey,
                            keychainKey: "claude_api_key"
                        )
                    } else if providerKind == .deepseek {
                        apiKeyField(
                            label: "DeepSeek API Key",
                            placeholder: "sk-…",
                            text: $deepSeekKey,
                            keychainKey: "deepseek_api_key"
                        )
                    } else {
                        Text("Notes and meetings are summarised entirely on-device. No API key needed.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    }
                } header: {
                    Text("AI Settings")
                } footer: {
                    Text("API keys are stored securely in the iOS Keychain. When offline, the app always falls back to on-device summarisation regardless of provider.")
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
                        Text("Active Provider")
                        Spacer()
                        Text(currentModelLabel)
                            .foregroundStyle(.secondary)
                            .font(.system(.subheadline, design: .monospaced))
                    }
                }

                // Data
                Section("Data") {
                    Button("Clear Claude API Key", role: .destructive) {
                        KeychainHelper.delete(key: "claude_api_key")
                        claudeKey = ""
                    }
                    Button("Clear DeepSeek API Key", role: .destructive) {
                        KeychainHelper.delete(key: "deepseek_api_key")
                        deepSeekKey = ""
                    }
                }
            }
            .navigationTitle("Settings")
            .toast(isPresented: $showKeySaved, message: "API key saved")
            .onAppear { providerKind = orchestrator.selectedProviderKind }
        }
    }

    private var currentModelLabel: String {
        switch providerKind {
        case .claude: return "claude-haiku-4-5"
        case .deepseek: return "deepseek-chat"
        case .onDevice: return "on-device NLP"
        }
    }

    private func apiKeyField(label: String, placeholder: String, text: Binding<String>, keychainKey: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
            SecureField(placeholder, text: text)
                .textContentType(.password)
                .autocorrectionDisabled()
            Button("Save Key") {
                KeychainHelper.save(key: keychainKey, value: text.wrappedValue)
                showKeySaved = true
            }
            .disabled(text.wrappedValue.isEmpty)
        }
        .padding(.vertical, 4)
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
