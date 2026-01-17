import SwiftUI

struct ServerSettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Server URL", text: $authManager.baseURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .foregroundStyle(Theme.Colors.text)
                } header: {
                    Text("Connection")
                } footer: {
                    Text("Enter the URL of your NanoChat server")
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .listRowBackground(Theme.Colors.sectionBackground)

                Section {
                    Text("The server URL should point to your NanoChat backend instance")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                } header: {
                    Text("Help")
                }
                .listRowBackground(Theme.Colors.sectionBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.backgroundStart)
            .navigationTitle("Server Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        authManager.saveCredentials()
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.accent)
                }
            }
        }
    }
}

#Preview {
    @MainActor func preview() -> some View {
        ServerSettingsView()
            .environmentObject(AuthenticationManager())
    }
    return preview()
}
