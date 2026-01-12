import Foundation
import SwiftUI

@MainActor
@Observable
final class AccountSettingsViewModel {
    private let api = NanoChatAPI.shared

    var settings: UserSettings?
    var isLoading = false
    var error: String?
    var isUpdating = false

    // Local state for settings that haven't been saved yet
    var privacyMode: Bool = false
    var contextMemoryEnabled: Bool = false
    var persistentMemoryEnabled: Bool = false
    var youtubeTranscriptsEnabled: Bool = false
    var webScrapingEnabled: Bool = false
    var mcpEnabled: Bool = false
    var followUpQuestionsEnabled: Bool = true
    var karakeepUrl: String = ""
    var karakeepApiKey: String = ""
    var titleModelId: String = ""
    var followUpModelId: String = ""

    func loadSettings() async {
        isLoading = true
        error = nil

        do {
            let loadedSettings = try await api.getUserSettings()
            settings = loadedSettings

            // Update local state
            privacyMode = loadedSettings.privacyMode
            contextMemoryEnabled = loadedSettings.contextMemoryEnabled
            persistentMemoryEnabled = loadedSettings.persistentMemoryEnabled
            youtubeTranscriptsEnabled = loadedSettings.youtubeTranscriptsEnabled
            webScrapingEnabled = loadedSettings.webScrapingEnabled
            mcpEnabled = loadedSettings.mcpEnabled
            followUpQuestionsEnabled = loadedSettings.followUpQuestionsEnabled
            karakeepUrl = loadedSettings.karakeepUrl ?? ""
            karakeepApiKey = loadedSettings.karakeepApiKey ?? ""
            titleModelId = loadedSettings.titleModelId ?? ""
            followUpModelId = loadedSettings.followUpModelId ?? ""
        } catch {
            self.error = error.localizedDescription
            print("Failed to load user settings: \(error)")
        }

        isLoading = false
    }

    func updatePrivacyMode(_ value: Bool) async {
        privacyMode = value
        await updateSetting(privacyMode: value)
    }

    func updateContextMemoryEnabled(_ value: Bool) async {
        contextMemoryEnabled = value
        await updateSetting(contextMemoryEnabled: value)
    }

    func updatePersistentMemoryEnabled(_ value: Bool) async {
        persistentMemoryEnabled = value
        await updateSetting(persistentMemoryEnabled: value)
    }

    func updateYoutubeTranscriptsEnabled(_ value: Bool) async {
        youtubeTranscriptsEnabled = value
        await updateSetting(youtubeTranscriptsEnabled: value)
    }

    func updateWebScrapingEnabled(_ value: Bool) async {
        webScrapingEnabled = value
        await updateSetting(webScrapingEnabled: value)
    }

    func updateMcpEnabled(_ value: Bool) async {
        mcpEnabled = value
        await updateSetting(mcpEnabled: value)
    }

    func updateFollowUpQuestionsEnabled(_ value: Bool) async {
        followUpQuestionsEnabled = value
        await updateSetting(followUpQuestionsEnabled: value)
    }

    func updateTitleModelId(_ value: String) async {
        titleModelId = value
        await updateSetting(titleModelId: value.isEmpty ? nil : value)
    }

    func updateFollowUpModelId(_ value: String) async {
        followUpModelId = value
        await updateSetting(followUpModelId: value.isEmpty ? nil : value)
    }

    func updateKarakeepSettings(url: String, apiKey: String) async {
        karakeepUrl = url
        karakeepApiKey = apiKey
        await updateSetting(
            karakeepUrl: url.isEmpty ? nil : url,
            karakeepApiKey: apiKey.isEmpty ? nil : apiKey
        )
    }

    private func updateSetting(
        privacyMode: Bool? = nil,
        contextMemoryEnabled: Bool? = nil,
        persistentMemoryEnabled: Bool? = nil,
        youtubeTranscriptsEnabled: Bool? = nil,
        webScrapingEnabled: Bool? = nil,
        mcpEnabled: Bool? = nil,
        followUpQuestionsEnabled: Bool? = nil,
        karakeepUrl: String? = nil,
        karakeepApiKey: String? = nil,
        theme: String? = nil,
        titleModelId: String? = nil,
        followUpModelId: String? = nil
    ) async {
        isUpdating = true
        error = nil

        // Store previous state for potential rollback
        let previousPrivacyMode = self.privacyMode
        let previousContextMemoryEnabled = self.contextMemoryEnabled
        let previousPersistentMemoryEnabled = self.persistentMemoryEnabled
        let previousYoutubeTranscriptsEnabled = self.youtubeTranscriptsEnabled
        let previousWebScrapingEnabled = self.webScrapingEnabled
        let previousMcpEnabled = self.mcpEnabled
        let previousFollowUpQuestionsEnabled = self.followUpQuestionsEnabled
        let previousKarakeepUrl = self.karakeepUrl
        let previousKarakeepApiKey = self.karakeepApiKey
        let previousTitleModelId = self.titleModelId
        let previousFollowUpModelId = self.followUpModelId

        do {
            let updatedSettings = try await api.updateUserSettings(
                privacyMode: privacyMode,
                contextMemoryEnabled: contextMemoryEnabled,
                persistentMemoryEnabled: persistentMemoryEnabled,
                youtubeTranscriptsEnabled: youtubeTranscriptsEnabled,
                webScrapingEnabled: webScrapingEnabled,
                mcpEnabled: mcpEnabled,
                followUpQuestionsEnabled: followUpQuestionsEnabled,
                karakeepUrl: karakeepUrl,
                karakeepApiKey: karakeepApiKey,
                theme: theme,
                titleModelId: titleModelId,
                followUpModelId: followUpModelId
            )
            settings = updatedSettings
        } catch {
            self.error = error.localizedDescription
            print("Failed to update user settings: \(error)")

            // Revert local state on error
            self.privacyMode = previousPrivacyMode
            self.contextMemoryEnabled = previousContextMemoryEnabled
            self.persistentMemoryEnabled = previousPersistentMemoryEnabled
            self.youtubeTranscriptsEnabled = previousYoutubeTranscriptsEnabled
            self.webScrapingEnabled = previousWebScrapingEnabled
            self.mcpEnabled = previousMcpEnabled
            self.followUpQuestionsEnabled = previousFollowUpQuestionsEnabled
            self.karakeepUrl = previousKarakeepUrl
            self.karakeepApiKey = previousKarakeepApiKey
            self.titleModelId = previousTitleModelId
            self.followUpModelId = previousFollowUpModelId
        }

        isUpdating = false
    }
}
