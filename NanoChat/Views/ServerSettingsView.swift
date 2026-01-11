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
                } header: {
                    Text("Connection")
                } footer: {
                    Text("Enter the URL of your NanoChat server")
                }

                Section {
                    Text("The server URL should point to your NanoChat backend instance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Help")
                }
            }
            .navigationTitle("Server Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        authManager.saveCredentials()
                        dismiss()
                    }
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
