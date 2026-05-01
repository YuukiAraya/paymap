import SwiftUI

struct ContributionRulesView: View {
    var body: some View {
        List {
            Section(header: Text("ポイント獲得ルール")) {
                ForEach(PointRule.all) { rule in
                    HStack(spacing: 16) {
                        Image(systemName: rule.icon)
                            .foregroundColor(rule.color)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.title)
                                .font(.subheadline).bold()
                            Text(rule.description)
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("+\(rule.points) pt")
                            .font(.headline).bold()
                            .foregroundColor(Color.premiumEmerald)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section(header: Text("バッジ獲得条件")) {
                ForEach(BadgeRule.all) { rule in
                    HStack(spacing: 16) {
                        Image(systemName: rule.icon)
                            .foregroundColor(rule.color)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.title)
                                .font(.subheadline).bold()
                            Text(rule.condition)
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section(header: Text("注意事項")) {
                Text("• 1店舗につき1回のみポイントを獲得できます。")
                Text("• 虚偽の情報登録が確認された場合、ポイントは取り消されます。")
                Text("• ポイントはランキング表示のみに使用されます（現金化不可）。")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .navigationTitle("貢献ポイントの仕組み")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data

struct PointRule: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let points: Int
    let icon: String
    let color: Color

    static let all: [PointRule] = [
        PointRule(title: "新規店舗の登録",
                  description: "まだ未登録の店舗を初めて追加する",
                  points: 30, icon: "plus.circle.fill", color: .blue),
        PointRule(title: "ファーストディスカバリー",
                  description: "その店舗の決済手段を最初に報告する",
                  points: 20, icon: "star.fill", color: .yellow),
        PointRule(title: "決済手段の報告",
                  description: "既存店舗の決済手段を追加・修正する",
                  points: 10, icon: "checkmark.circle.fill", color: .green),
        PointRule(title: "確認ボーナス",
                  description: "すでに登録済みの情報が正確と確認する",
                  points: 3, icon: "hand.thumbsup.fill", color: .orange),
    ]
}

struct BadgeRule: Identifiable {
    let id = UUID()
    let title: String
    let condition: String
    let icon: String
    let color: Color

    static let all: [BadgeRule] = [
        BadgeRule(title: "初投稿",       condition: "初めて情報を登録する",      icon: "star.fill",   color: .yellow),
        BadgeRule(title: "10件達成",     condition: "10件の情報を登録する",       icon: "flame.fill",  color: .orange),
        BadgeRule(title: "50件達成",     condition: "50件の情報を登録する",       icon: "bolt.fill",   color: .red),
        BadgeRule(title: "決済マスター", condition: "合計200ptを獲得する",        icon: "crown.fill",  color: .purple),
        BadgeRule(title: "探検家",       condition: "5つの異なるカテゴリを登録", icon: "map.fill",    color: .teal),
    ]
}
