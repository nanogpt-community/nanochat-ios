import SwiftUI

struct ModelInfoView: View {
    let model: UserModel

    @State private var info: ModelInfoResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    private let api = NanoChatAPI.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        headerCard

                        if isLoading {
                            loadingCard
                        } else if let errorMessage {
                            errorCard(message: errorMessage)
                        } else if let info {
                            detailsView(info)
                        } else {
                            errorCard(message: "No details available.")
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Model Info")
            .navigationBarTitleDisplayMode(.inline)
            .liquidGlassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.text)
                }
            }
            .task {
                await loadInfo()
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            if let iconUrl = info?.model.iconUrl,
                let url = URL(string: iconUrl)
            {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderIcon
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                    case .failure:
                        placeholderIcon
                    @unknown default:
                        placeholderIcon
                    }
                }
            } else {
                placeholderIcon
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.text)

                Text(model.modelId)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .glassCard()
    }

    private var loadingCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ProgressView()
                .tint(Theme.Colors.secondary)
            Text("Loading model details...")
                .font(.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func errorCard(message: String) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(message)
                .font(.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            Button("Retry") {
                Task { await loadInfo(forceReload: true) }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func detailsView(_ info: ModelInfoResponse) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            if let description = info.model.description, !description.isEmpty {
                section(title: "Description") {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.text)
                }
            }

            if info.benchmarks.available, info.benchmarks.llm != nil || info.benchmarks.image != nil
            {
                section(title: "Benchmarks") {
                    VStack(spacing: Theme.Spacing.sm) {
                        if let llm = info.benchmarks.llm {
                            benchmarkRow(
                                label: "Intelligence", value: formatScore(llm.intelligence),
                                color: .blue)
                            benchmarkRow(
                                label: "Coding", value: formatScore(llm.coding), color: .green)
                            benchmarkRow(
                                label: "Math", value: formatScore(llm.math), color: .purple)

                            if let speed = llm.speedTokensPerSecond {
                                Divider().overlay(Theme.Colors.glassBorder)
                                benchmarkRow(
                                    label: "Speed",
                                    value: "\(Int(speed.rounded())) tok/s",
                                    color: .yellow,
                                    icon: "bolt.fill"
                                )
                            }
                        }

                        if let image = info.benchmarks.image {
                            benchmarkRow(
                                label: "ELO Rating", value: formatNumber(image.elo), color: .blue)
                            benchmarkRow(
                                label: "Rank", value: image.rank.map { "#\($0)" } ?? "-",
                                color: .orange)
                        }

                        if let sourceUrl = info.benchmarks.sourceUrl,
                            let url = URL(string: sourceUrl)
                        {
                            Link(destination: url) {
                                HStack(spacing: 4) {
                                    Text("Data from Artificial Analysis")
                                    Image(systemName: "arrow.up.right")
                                }
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    }
                }
            }

            section(title: "Features") {
                let caps = info.model.capabilities
                HStack(spacing: Theme.Spacing.sm) {
                    ModelCapabilityBadge(capability: .vision, isEnabled: caps?.vision == true)
                    ModelCapabilityBadge(capability: .reasoning, isEnabled: caps?.reasoning == true)
                    ModelCapabilityBadge(capability: .images, isEnabled: caps?.images == true)
                    ModelCapabilityBadge(capability: .video, isEnabled: caps?.video == true)

                    if caps?.vision != true && caps?.reasoning != true && caps?.images != true
                        && caps?.video != true
                    {
                        Text("No special features")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }

            section(title: "Provider & Context") {
                HStack(alignment: .top, spacing: Theme.Spacing.lg) {
                    infoColumn(title: "Provider", value: providerName(info.model.ownedBy))
                    infoColumn(
                        title: "Context", value: "\(formatNumber(info.model.contextLength)) tokens")
                }
            }

            section(title: "Max Output & Added") {
                HStack(alignment: .top, spacing: Theme.Spacing.lg) {
                    infoColumn(
                        title: "Max Output",
                        value: "\(formatNumber(info.model.maxOutputTokens)) tokens")
                    infoColumn(title: "Added", value: formatDate(info.model.created))
                }
            }

            if let pricing = info.model.pricing {
                section(title: "Pricing") {
                    VStack(spacing: Theme.Spacing.sm) {
                        if pricing.prompt != nil {
                            infoRow(
                                label: "Input", value: "\(formatPrice(pricing.prompt)) / 1M tokens")
                        }
                        if pricing.completion != nil {
                            infoRow(
                                label: "Output",
                                value: "\(formatPrice(pricing.completion)) / 1M tokens")
                        }
                        if let estimate = info.model.costEstimate {
                            Divider().overlay(Theme.Colors.glassBorder)
                            infoRow(
                                label: "Est. per message", value: String(format: "$%.4f", estimate),
                                valueColor: Theme.Colors.success)
                        }
                    }
                }
            }

            if let subscription = info.model.subscription {
                section(title: "Subscription") {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(
                            systemName: subscription.included
                                ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundStyle(
                            subscription.included ? Theme.Colors.success : Theme.Colors.warning)
                        Text(
                            subscription.note?.isEmpty == false
                                ? subscription.note!
                                : (subscription.included
                                    ? "Included in subscription" : "Not included")
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            subscription.included ? Theme.Colors.success : Theme.Colors.warning)
                        Spacer()
                    }
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        (subscription.included ? Theme.Colors.success : Theme.Colors.warning)
                            .opacity(0.15)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                }
            }
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content)
        -> some View
    {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.leading, Theme.Spacing.xs)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                content()
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
    }

    private func benchmarkRow(label: String, value: String, color: Color, icon: String? = nil)
        -> some View
    {
        HStack {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(color)
        }
    }

    private func infoRow(label: String, value: String, valueColor: Color = Theme.Colors.text)
        -> some View
    {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(valueColor)
        }
    }

    private func infoColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var placeholderIcon: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
            .fill(Theme.Colors.glassBackground)
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.Colors.textTertiary)
            )
    }

    private var displayName: String {
        info?.model.name ?? model.name ?? model.modelId
    }

    private func providerName(_ ownedBy: String?) -> String {
        guard let ownedBy, !ownedBy.isEmpty else { return "Unknown" }
        return
            ownedBy
            .replacingOccurrences(of: "organization-owner", with: "Third Party")
            .split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    private func formatNumber(_ number: Double?) -> String {
        guard let number else { return "-" }
        if number >= 1_000_000 { return String(format: "%.1fM", number / 1_000_000) }
        if number >= 1_000 { return String(format: "%.0fK", number / 1_000) }
        return String(format: "%.0f", number)
    }

    private func formatNumber(_ number: Int?) -> String {
        guard let number else { return "-" }
        return formatNumber(Double(number))
    }

    private func formatScore(_ score: Double?) -> String {
        guard let score else { return "-" }
        return String(format: "%.1f", score)
    }

    private func formatDate(_ timestamp: Double?) -> String {
        guard let timestamp, timestamp > 0 else { return "-" }
        let date = Date(timeIntervalSince1970: timestamp)
        return Self.dateFormatter.string(from: date)
    }

    private func formatPrice(_ price: String?) -> String {
        guard let price, let value = Double(price) else { return "-" }
        if value == 0 { return "Free" }
        return String(format: "$%.2f", value)
    }

    @MainActor
    private func loadInfo(forceReload: Bool = false) async {
        if info != nil && !forceReload { return }
        isLoading = true
        errorMessage = nil
        do {
            info = try await api.fetchModelInfo(modelId: model.modelId)
        } catch {
            errorMessage = "Failed to load model details."
        }
        isLoading = false
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

#Preview {
    ModelInfoView(
        model: UserModel(
            modelId: "zai-org/glm-4.7",
            provider: "nanogpt",
            enabled: true,
            pinned: false,
            name: "GLM 4.7",
            description: "A next-gen GLM model with strong reasoning.",
            capabilities: ModelCapabilities(
                vision: true, reasoning: true, images: false, video: false),
            costEstimate: 0.001,
            subscriptionIncluded: true,
            resolutions: nil,
            additionalParams: nil,
            maxImages: nil,
            defaultSettings: nil
        ))
}
