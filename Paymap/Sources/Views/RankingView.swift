import SwiftUI

struct RankingView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var vm = RankingViewModel()

    private let badgeCatalog: [(id: String, icon: String, color: Color)] = [
        ("firstPost", "star.fill", .yellow),
        ("br10", "flame.fill", .orange),
        ("br50", "bolt.fill", .blue),
        ("brMaster", "crown.fill", .purple),
        ("brExplorer", "map.fill", .green),
    ]

    var body: some View {
        List {
            if vm.isLoading {
                HStack {
                    Spacer()
                    ProgressView(lm.s.loadingLabel)
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else if vm.entries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 48)).foregroundColor(.secondary)
                        Text(lm.s.rankingEmpty).foregroundColor(.secondary)
                    }
                    .padding(.top, 80)
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(vm.entries) { entry in
                    RankingRow(
                        entry: entry,
                        isCurrentUser: entry.uid == authViewModel.userProfile?.uid,
                        badgeCatalog: badgeCatalog,
                        pointsLabel: lm.s.rankingPoints,
                        youLabel: lm.s.rankingYou
                    )
                }
            }
        }
        .listStyle(.plain)
        .refreshable { await vm.fetch() }
        .navigationTitle(lm.s.rankingTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { Task { await vm.fetch() } }
    }
}

// MARK: - Ranking Row
private struct RankingRow: View {
    let entry: RankingEntry
    let isCurrentUser: Bool
    let badgeCatalog: [(id: String, icon: String, color: Color)]
    let pointsLabel: String
    let youLabel: String

    var body: some View {
        HStack(spacing: 12) {
            // Rank number
            Text("\(entry.rank)")
                .font(.title2).bold()
                .foregroundColor(rankColor)
                .frame(width: 36)

            // Medal for top 3
            if entry.rank <= 3 {
                Image(systemName: "medal.fill")
                    .foregroundColor(rankColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.displayName)
                        .font(.subheadline).bold()
                    if isCurrentUser {
                        Text("(\(youLabel))")
                            .font(.caption).foregroundColor(Color.premiumEmerald)
                    }
                }
                // Badges
                if !entry.badges.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(entry.badges.prefix(5), id: \.self) { badgeId in
                            if let b = badgeCatalog.first(where: { $0.id == badgeId }) {
                                Image(systemName: b.icon)
                                    .font(.caption2)
                                    .foregroundColor(b.color)
                            }
                        }
                    }
                }
            }

            Spacer()

            Text("\(entry.points) \(pointsLabel)")
                .font(.subheadline).bold()
                .foregroundColor(Color.premiumEmerald)
        }
        .padding(.vertical, 4)
        .listRowBackground(isCurrentUser ? Color.premiumEmerald.opacity(0.08) : Color.clear)
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .secondary
        }
    }
}

// MARK: - ViewModel
@MainActor
class RankingViewModel: ObservableObject {
    @Published var entries: [RankingEntry] = []
    @Published var isLoading = false
    private let storeService = StoreService()

    func fetch() async {
        guard !isLoading else { return }
        isLoading = true
        do {
            entries = try await storeService.fetchTopUsers(limit: 20)
        } catch {
            // エラー時は既存データを保持
        }
        isLoading = false
    }
}
