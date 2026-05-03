import SwiftUI

struct ContributionRulesView: View {
    @EnvironmentObject var lm: LanguageManager

    var body: some View {
        List {
            Section(header: Text(lm.s.pointRulesSection)) {
                ForEach(PointRule.all(l10n: lm.s)) { rule in
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
                        Text("+\(rule.points) \(lm.s.pointsSuffix)")
                            .font(.headline).bold()
                            .foregroundColor(Color.premiumEmerald)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section(header: Text(lm.s.badgeRulesSection)) {
                ForEach(BadgeRule.all(l10n: lm.s)) { rule in
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

            Section(header: Text(lm.s.notesSection)) {
                Text(lm.s.note1)
                Text(lm.s.note2)
                Text(lm.s.note3)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .navigationTitle(lm.s.rulesPageTitle)
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

    static func all(l10n: L10n) -> [PointRule] {
        [
            PointRule(title: l10n.prNewStore,  description: l10n.prNewStoreDesc, points: 30, icon: "plus.circle.fill",      color: .blue),
            PointRule(title: l10n.prFirst,     description: l10n.prFirstDesc,    points: 20, icon: "star.fill",             color: .yellow),
            PointRule(title: l10n.prReport,    description: l10n.prReportDesc,   points: 10, icon: "checkmark.circle.fill", color: .green),
            PointRule(title: l10n.prConfirm,   description: l10n.prConfirmDesc,  points: 3,  icon: "hand.thumbsup.fill",    color: .orange),
        ]
    }
}

struct BadgeRule: Identifiable {
    let id = UUID()
    let title: String
    let condition: String
    let icon: String
    let color: Color

    static func all(l10n: L10n) -> [BadgeRule] {
        [
            BadgeRule(title: l10n.brFirstPost, condition: l10n.brFirstPostCond, icon: "star.fill",   color: .yellow),
            BadgeRule(title: l10n.br10,        condition: l10n.br10Cond,        icon: "flame.fill",  color: .orange),
            BadgeRule(title: l10n.br50,        condition: l10n.br50Cond,        icon: "bolt.fill",   color: .red),
            BadgeRule(title: l10n.brMaster,    condition: l10n.brMasterCond,    icon: "crown.fill",  color: .purple),
            BadgeRule(title: l10n.brExplorer,  condition: l10n.brExplorerCond,  icon: "map.fill",    color: .teal),
        ]
    }
}
