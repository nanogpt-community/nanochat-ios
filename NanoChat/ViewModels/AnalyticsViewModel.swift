import Foundation

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var stats: [ModelPerformanceStat] = []
    @Published var insights: AnalyticsInsights?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = NanoChatAPI.shared

    func loadAnalytics(recalculate: Bool = true) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await api.getAnalytics(recalculate: recalculate)
            stats = response.stats
            insights = response.insights
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
