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
    var timezone: String = TimeZone.current.identifier
    var privacyMode: Bool = false
    var contextMemoryEnabled: Bool = false
    var persistentMemoryEnabled: Bool = false
    var youtubeTranscriptsEnabled: Bool = false
    var webScrapingEnabled: Bool = false
    var mcpEnabled: Bool = false
    var followUpQuestionsEnabled: Bool = true
    var suggestedPromptsEnabled: Bool = true
    var karakeepUrl: String = ""
    var karakeepApiKey: String = ""
    var titleModelId: String = ""
    var titleProviderId: String = ""
    var followUpModelId: String = ""
    var followUpProviderId: String = ""
    var titleModelProviders: [ProviderInfo] = []
    var followUpModelProviders: [ProviderInfo] = []
    var titleSupportsProviderSelection: Bool = false
    var followUpSupportsProviderSelection: Bool = false

    func loadSettings() async {
        isLoading = true
        error = nil

        do {
            let loadedSettings = try await api.getUserSettings()
            settings = loadedSettings

            // Update local state
            timezone = loadedSettings.timezone
            privacyMode = loadedSettings.privacyMode
            contextMemoryEnabled = loadedSettings.contextMemoryEnabled
            persistentMemoryEnabled = loadedSettings.persistentMemoryEnabled
            youtubeTranscriptsEnabled = loadedSettings.youtubeTranscriptsEnabled
            webScrapingEnabled = loadedSettings.webScrapingEnabled
            mcpEnabled = loadedSettings.mcpEnabled
            followUpQuestionsEnabled = loadedSettings.followUpQuestionsEnabled
            suggestedPromptsEnabled = loadedSettings.suggestedPromptsEnabled
            karakeepUrl = loadedSettings.karakeepUrl ?? ""
            karakeepApiKey = loadedSettings.karakeepApiKey ?? ""
            titleModelId = loadedSettings.titleModelId ?? ""
            titleProviderId = loadedSettings.titleProviderId ?? ""
            followUpModelId = loadedSettings.followUpModelId ?? ""
            followUpProviderId = loadedSettings.followUpProviderId ?? ""
            await refreshTitleProviders()
            await refreshFollowUpProviders()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func updatePrivacyMode(_ value: Bool) async {
        privacyMode = value
        await updateSetting(privacyMode: value)
    }

    func updateTimezone(_ value: String) async {
        timezone = value
        await updateSetting(timezone: value)
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

    func updateSuggestedPromptsEnabled(_ value: Bool) async {
        suggestedPromptsEnabled = value
        await updateSetting(suggestedPromptsEnabled: value)
    }

    func updateTitleModelId(_ value: String) async {
        titleModelId = value
        if value.isEmpty {
            titleProviderId = ""
        }
        await updateSetting(
            titleModelId: value.isEmpty ? nil : value,
            titleProviderId: value.isEmpty ? "" : nil
        )
        await refreshTitleProviders()
    }

    func updateFollowUpModelId(_ value: String) async {
        followUpModelId = value
        if value.isEmpty {
            followUpProviderId = ""
        }
        await updateSetting(
            followUpModelId: value.isEmpty ? nil : value,
            followUpProviderId: value.isEmpty ? "" : nil
        )
        await refreshFollowUpProviders()
    }

    func updateTitleProviderId(_ value: String) async {
        titleProviderId = value
        await updateSetting(titleProviderId: value)
    }

    func updateFollowUpProviderId(_ value: String) async {
        followUpProviderId = value
        await updateSetting(followUpProviderId: value)
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
        timezone: String? = nil,
        privacyMode: Bool? = nil,
        contextMemoryEnabled: Bool? = nil,
        persistentMemoryEnabled: Bool? = nil,
        youtubeTranscriptsEnabled: Bool? = nil,
        webScrapingEnabled: Bool? = nil,
        mcpEnabled: Bool? = nil,
        followUpQuestionsEnabled: Bool? = nil,
        suggestedPromptsEnabled: Bool? = nil,
        karakeepUrl: String? = nil,
        karakeepApiKey: String? = nil,
        theme: String? = nil,
        titleModelId: String? = nil,
        titleProviderId: String? = nil,
        followUpModelId: String? = nil,
        followUpProviderId: String? = nil
    ) async {
        isUpdating = true
        error = nil

        // Store previous state for potential rollback
        let previousTimezone = self.timezone
        let previousPrivacyMode = self.privacyMode
        let previousContextMemoryEnabled = self.contextMemoryEnabled
        let previousPersistentMemoryEnabled = self.persistentMemoryEnabled
        let previousYoutubeTranscriptsEnabled = self.youtubeTranscriptsEnabled
        let previousWebScrapingEnabled = self.webScrapingEnabled
        let previousMcpEnabled = self.mcpEnabled
        let previousFollowUpQuestionsEnabled = self.followUpQuestionsEnabled
        let previousSuggestedPromptsEnabled = self.suggestedPromptsEnabled
        let previousKarakeepUrl = self.karakeepUrl
        let previousKarakeepApiKey = self.karakeepApiKey
        let previousTitleModelId = self.titleModelId
        let previousTitleProviderId = self.titleProviderId
        let previousFollowUpModelId = self.followUpModelId
        let previousFollowUpProviderId = self.followUpProviderId

        do {
            let updatedSettings = try await api.updateUserSettings(
                timezone: timezone,
                privacyMode: privacyMode,
                contextMemoryEnabled: contextMemoryEnabled,
                persistentMemoryEnabled: persistentMemoryEnabled,
                youtubeTranscriptsEnabled: youtubeTranscriptsEnabled,
                webScrapingEnabled: webScrapingEnabled,
                mcpEnabled: mcpEnabled,
                followUpQuestionsEnabled: followUpQuestionsEnabled,
                suggestedPromptsEnabled: suggestedPromptsEnabled,
                karakeepUrl: karakeepUrl,
                karakeepApiKey: karakeepApiKey,
                theme: theme,
                titleModelId: titleModelId,
                titleProviderId: titleProviderId,
                followUpModelId: followUpModelId,
                followUpProviderId: followUpProviderId
            )
            settings = updatedSettings
        } catch {
            self.error = error.localizedDescription

            // Revert local state on error
            self.timezone = previousTimezone
            self.privacyMode = previousPrivacyMode
            self.contextMemoryEnabled = previousContextMemoryEnabled
            self.persistentMemoryEnabled = previousPersistentMemoryEnabled
            self.youtubeTranscriptsEnabled = previousYoutubeTranscriptsEnabled
            self.webScrapingEnabled = previousWebScrapingEnabled
            self.mcpEnabled = previousMcpEnabled
            self.followUpQuestionsEnabled = previousFollowUpQuestionsEnabled
            self.suggestedPromptsEnabled = previousSuggestedPromptsEnabled
            self.karakeepUrl = previousKarakeepUrl
            self.karakeepApiKey = previousKarakeepApiKey
            self.titleModelId = previousTitleModelId
            self.titleProviderId = previousTitleProviderId
            self.followUpModelId = previousFollowUpModelId
            self.followUpProviderId = previousFollowUpProviderId
        }

        isUpdating = false
    }

    private func refreshTitleProviders() async {
        guard !titleModelId.isEmpty else {
            titleSupportsProviderSelection = false
            titleModelProviders = []
            return
        }

        do {
            let response = try await api.fetchModelProviders(modelId: titleModelId)
            titleSupportsProviderSelection = response.supportsProviderSelection
            titleModelProviders = response.providers.filter { $0.available }

            if !titleSupportsProviderSelection && !titleProviderId.isEmpty {
                titleProviderId = ""
                await updateSetting(titleProviderId: "")
            }

            if titleSupportsProviderSelection,
                !titleProviderId.isEmpty,
                !titleModelProviders.contains(where: { $0.provider == titleProviderId })
            {
                titleProviderId = ""
                await updateSetting(titleProviderId: "")
            }
        } catch {
            titleSupportsProviderSelection = false
            titleModelProviders = []
        }
    }

    private func refreshFollowUpProviders() async {
        guard !followUpModelId.isEmpty else {
            followUpSupportsProviderSelection = false
            followUpModelProviders = []
            return
        }

        do {
            let response = try await api.fetchModelProviders(modelId: followUpModelId)
            followUpSupportsProviderSelection = response.supportsProviderSelection
            followUpModelProviders = response.providers.filter { $0.available }

            if !followUpSupportsProviderSelection && !followUpProviderId.isEmpty {
                followUpProviderId = ""
                await updateSetting(followUpProviderId: "")
            }

            if followUpSupportsProviderSelection,
                !followUpProviderId.isEmpty,
                !followUpModelProviders.contains(where: { $0.provider == followUpProviderId })
            {
                followUpProviderId = ""
                await updateSetting(followUpProviderId: "")
            }
        } catch {
            followUpSupportsProviderSelection = false
            followUpModelProviders = []
        }
    }
}
