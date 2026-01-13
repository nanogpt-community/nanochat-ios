import SwiftUI

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var sortOption: SortOption = .uses
    @State private var sortDirection: SortDirection = .desc

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Colors.primary.opacity(0.12), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 320
                    )
                )
                .frame(width: 380, height: 380)
                .offset(x: 140, y: -120)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if viewModel.isLoading && viewModel.stats.isEmpty {
                        LoadingCard()
                    } else if let error = viewModel.errorMessage, viewModel.stats.isEmpty {
                        ErrorCard(message: error) {
                            Task { await viewModel.loadAnalytics(recalculate: true) }
                        }
                    } else if !hasStats {
                        EmptyStateCard()
                    } else {
                        summarySection
                        insightsSection
                        sortControls
                        modelStatsSection
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .liquidGlassNavigationBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.shared.tap()
                    Task { await viewModel.loadAnalytics(recalculate: true) }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Theme.Colors.text)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Theme.Colors.text)
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.loadAnalytics(recalculate: true)
        }
        .refreshable {
            await viewModel.loadAnalytics(recalculate: true)
        }
    }

    private var hasStats: Bool {
        viewModel.stats.contains { $0.totalMessages > 0 }
    }

    private var summarySection: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md
        ) {
            StatCard(
                title: "Total Messages",
                value: formatCount(viewModel.insights?.totalMessages ?? 0),
                systemImage: "message.fill"
            )

            StatCard(
                title: "Total Cost",
                value: formatCurrency(viewModel.insights?.totalCost),
                systemImage: "dollarsign.circle.fill"
            )

            StatCard(
                title: "Avg Rating",
                value: formatRating(viewModel.insights?.avgRating),
                systemImage: "star.fill"
            )
        }
    }

    private var insightsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            if let mostUsed = viewModel.insights?.mostUsedModel {
                InsightCard(
                    title: "Most Used Model",
                    detail:
                        "\(mostUsed.modelId) with \(formatCount(mostUsed.totalMessages)) messages"
                )
            }

            if let bestRated = viewModel.insights?.bestRatedModel,
                let avgRating = bestRated.avgRating
            {
                InsightCard(
                    title: "Best Rated Model",
                    detail: "\(bestRated.modelId) with \(String(format: "%.2f", avgRating)) rating"
                )
            }

            if let mostCost = viewModel.insights?.mostCostEffective {
                let avgCost =
                    mostCost.totalMessages > 0
                    ? mostCost.totalCost / Double(mostCost.totalMessages)
                    : 0
                InsightCard(
                    title: "Most Cost Effective",
                    detail:
                        "\(mostCost.modelId) at \(formatCurrency(avgCost, decimals: 6)) per message"
                )
            }

            if let fastest = viewModel.insights?.fastestModel {
                let speed = tokensPerSecond(fastest)
                InsightCard(
                    title: "Fastest Model",
                    detail:
                        "\(fastest.modelId) at \(String(format: "%.1f", speed)) tokens per second"
                )
            }
        }
    }

    private var sortControls: some View {
        GlassCard(cornerRadius: Theme.CornerRadius.lg, padding: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                Menu {
                    ForEach(SortOption.allCases) { option in
                        Button {
                            sortOption = option
                        } label: {
                            Text(option.title)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Sort: \(sortOption.title)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.text)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                Spacer()

                Button {
                    sortDirection.toggle()
                } label: {
                    Image(systemName: sortDirection.systemImage)
                        .foregroundStyle(Theme.Colors.text)
                }
            }
        }
    }

    private var modelStatsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(sortedStats) { stat in
                ModelStatCard(
                    stat: stat,
                    avgCost: averageCost(stat),
                    thumbsSummary: thumbsSummary(stat),
                    speed: speedSummary(stat),
                    categories: topCategories(stat)
                )
            }
        }
    }

    private var sortedStats: [ModelPerformanceStat] {
        let stats = viewModel.stats.filter { $0.totalMessages > 0 }
        return stats.sorted { a, b in
            switch sortOption {
            case .model:
                if sortDirection == .asc {
                    return a.modelId.localizedCaseInsensitiveCompare(b.modelId) == .orderedAscending
                } else {
                    return a.modelId.localizedCaseInsensitiveCompare(b.modelId)
                        == .orderedDescending
                }
            case .rating:
                return compare(a.avgRating ?? 0, b.avgRating ?? 0)
            case .uses:
                return compare(Double(a.totalMessages), Double(b.totalMessages))
            case .cost:
                let aCost = a.totalMessages > 0 ? a.totalCost / Double(a.totalMessages) : 0
                let bCost = b.totalMessages > 0 ? b.totalCost / Double(b.totalMessages) : 0
                return compare(aCost, bCost)
            case .thumbs:
                let aTotal = a.thumbsUpCount + a.thumbsDownCount
                let bTotal = b.thumbsUpCount + b.thumbsDownCount
                let aRatio = aTotal > 0 ? Double(a.thumbsUpCount) / Double(aTotal) : 0
                let bRatio = bTotal > 0 ? Double(b.thumbsUpCount) / Double(bTotal) : 0
                return compare(aRatio, bRatio)
            case .speed:
                return compare(tokensPerSecond(a), tokensPerSecond(b))
            }
        }
    }

    private func compare(_ a: Double, _ b: Double) -> Bool {
        sortDirection == .asc ? a < b : a > b
    }

    private func formatCount(_ value: Int) -> String {
        value.formatted()
    }

    private func formatCurrency(_ value: Double?, decimals: Int = 2) -> String {
        guard let value, !value.isNaN else { return "N/A" }
        return String(format: "$%.\(decimals)f", value)
    }

    private func formatRating(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        return String(format: "%.2f", value)
    }

    private func tokensPerSecond(_ stat: ModelPerformanceStat) -> Double {
        guard let tokens = stat.avgTokens,
            let responseTime = stat.avgResponseTime,
            responseTime > 0
        else {
            return 0
        }
        return tokens / (responseTime / 1000)
    }

    private func averageCost(_ stat: ModelPerformanceStat) -> String {
        guard stat.totalMessages > 0 else { return "N/A" }
        let avgCost = stat.totalCost / Double(stat.totalMessages)
        return formatCurrency(avgCost, decimals: 6)
    }

    private func thumbsSummary(_ stat: ModelPerformanceStat) -> String {
        let total = stat.thumbsUpCount + stat.thumbsDownCount
        guard total > 0 else { return "N/A" }
        let ratio = Double(stat.thumbsUpCount) / Double(total) * 100
        return "\(stat.thumbsUpCount) up / \(stat.thumbsDownCount) down (\(Int(ratio))%)"
    }

    private func speedSummary(_ stat: ModelPerformanceStat) -> String {
        let speed = tokensPerSecond(stat)
        if speed <= 0 { return "N/A" }
        return String(format: "%.1f t/s", speed)
    }

    private func topCategories(_ stat: ModelPerformanceStat) -> [CategoryStat] {
        let categories: [CategoryStat] = [
            CategoryStat(
                name: "Accurate", count: stat.accurateCount, icon: "checkmark.circle.fill",
                color: Theme.Colors.success),
            CategoryStat(
                name: "Helpful", count: stat.helpfulCount, icon: "hand.thumbsup.fill",
                color: Theme.Colors.accent),
            CategoryStat(
                name: "Creative", count: stat.creativeCount, icon: "sparkles",
                color: Theme.Colors.primary),
            CategoryStat(
                name: "Fast", count: stat.fastCount, icon: "bolt.fill", color: Theme.Colors.warning),
            CategoryStat(
                name: "Cost-effective", count: stat.costEffectiveCount,
                icon: "dollarsign.circle.fill", color: Theme.Colors.secondary),
        ]

        return
            categories
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
            .prefix(3)
            .map { $0 }
    }
}

private enum SortOption: String, CaseIterable, Identifiable {
    case uses
    case rating
    case cost
    case thumbs
    case speed
    case model

    var id: String { rawValue }

    var title: String {
        switch self {
        case .uses:
            return "Uses"
        case .rating:
            return "Rating"
        case .cost:
            return "Avg Cost"
        case .thumbs:
            return "Thumbs Up"
        case .speed:
            return "Speed"
        case .model:
            return "Model"
        }
    }
}

private enum SortDirection {
    case asc
    case desc

    mutating func toggle() {
        self = self == .asc ? .desc : .asc
    }

    var systemImage: String {
        switch self {
        case .asc:
            return "arrow.up"
        case .desc:
            return "arrow.down"
        }
    }
}

private struct CategoryStat: Hashable {
    let name: String
    let count: Int
    let icon: String
    let color: Color
}

private struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        GlassCard(cornerRadius: Theme.CornerRadius.lg, padding: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text(value)
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.text)
                }

                Spacer()

                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }
}

private struct InsightCard: View {
    let title: String
    let detail: String

    var body: some View {
        GlassCard(cornerRadius: Theme.CornerRadius.lg, padding: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.text)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ModelStatCard: View {
    let stat: ModelPerformanceStat
    let avgCost: String
    let thumbsSummary: String
    let speed: String
    let categories: [CategoryStat]

    var body: some View {
        GlassCard(cornerRadius: Theme.CornerRadius.lg, padding: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stat.modelId)
                            .font(.headline)
                            .foregroundStyle(Theme.Colors.text)
                        Text(stat.provider)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Spacer()

                    if let rating = stat.avgRating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.warning)
                            Text(String(format: "%.2f", rating))
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.text)
                        }
                    } else {
                        Text("N/A")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                Divider()
                    .overlay(Theme.Colors.glassBorder)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: Theme.Spacing.sm
                ) {
                    MetricCell(title: "Uses", value: stat.totalMessages.formatted())
                    MetricCell(title: "Avg Cost", value: avgCost)
                    MetricCell(title: "Thumbs", value: thumbsSummary)
                    MetricCell(title: "Speed", value: speed)
                    MetricCell(title: "Errors", value: "\(stat.errorCount)")
                }

                if !categories.isEmpty {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 90), spacing: Theme.Spacing.sm)],
                        spacing: Theme.Spacing.sm
                    ) {
                        ForEach(categories, id: \.name) { category in
                            CategoryBadge(category: category)
                        }
                    }
                }
            }
        }
    }
}

private struct MetricCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.textTertiary)
            Text(value)
                .font(.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private struct CategoryBadge: View {
    let category: CategoryStat

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)
            Text(category.name)
                .font(.caption2)
            Text("\(category.count)")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .foregroundStyle(category.color)
        .background(Theme.Colors.glassBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(category.color.opacity(0.5), lineWidth: 1)
        )
    }
}

private struct LoadingCard: View {
    var body: some View {
        GlassCard(cornerRadius: Theme.CornerRadius.lg, padding: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                    .tint(Theme.Colors.primary)
                Text("Loading analytics...")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct ErrorCard: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        GlassCard(cornerRadius: Theme.CornerRadius.lg, padding: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.error)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    HapticManager.shared.tap()
                    retry()
                }
                .buttonStyle(LiquidGlassButtonStyle(style: .destructive))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct EmptyStateCard: View {
    var body: some View {
        GlassCard(cornerRadius: Theme.CornerRadius.lg, padding: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "chart.bar")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text("No Data Yet")
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.text)
                Text("Start chatting to see analytics here.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    NavigationStack {
        AnalyticsView()
    }
    .preferredColorScheme(.dark)
}
