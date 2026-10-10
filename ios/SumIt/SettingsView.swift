import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var settings = AISettings.shared
    @State private var status: String?
    @State private var testing = false
    @State private var ok = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("hf_…", text: $settings.token)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Link("Create a token on HuggingFace", destination: URL(string: "https://huggingface.co/settings/tokens")!)
                } header: { Text("Access token") } footer: {
                    Text("Use a fine-grained token with the “Make calls to Inference Providers” permission. It is stored in this device's Keychain.")
                }

                Section {
                    TextField("org/model-name", text: $settings.model)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Menu("Suggested models") {
                        ForEach(AISettings.suggestedModels, id: \.self) { m in
                            Button(m) { settings.model = m }
                        }
                    }
                } header: { Text("Model") } footer: {
                    Text("Any chat model served by Inference Providers. Append :fastest or :cheapest to let HuggingFace pick the provider.")
                }

                Section {
                    Button {
                        Task { await test() }
                    } label: {
                        HStack {
                            Text("Test connection")
                            if testing { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(!settings.hasToken || testing)
                    if let status {
                        Label(status, systemImage: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(ok ? .green : .orange)
                    }
                } footer: {
                    Text(settings.hasToken ? "" : "Without a token the app runs in demo mode with sample output.")
                }
            }
            .navigationTitle("Connect AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func test() async {
        testing = true; status = nil
        defer { testing = false }
        do {
            try await LLMSummarizer.ping(token: settings.token.trimmingCharacters(in: .whitespacesAndNewlines),
                                         model: settings.model.trimmingCharacters(in: .whitespacesAndNewlines))
            ok = true; status = "Connected. \(settings.model) responded."
        } catch {
            ok = false; status = error.localizedDescription.capitalized
        }
    }
}
