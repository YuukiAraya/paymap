import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("プロフィール")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.userProfile?.displayName ?? "Guest")
                                .font(.headline)
                            Text(authViewModel.userProfile?.email ?? "No Email")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("実績・インセンティブ")) {
                    HStack {
                        Text("貢献ポイント")
                        Spacer()
                        Text("\(authViewModel.userProfile?.totalContributions ?? 0) pt")
                            .bold()
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("獲得バッジ")
                            .font(.subheadline)
                        
                        HStack(spacing: 16) {
                            BadgeView(icon: "star.fill", title: "初投稿", color: .yellow)
                            BadgeView(icon: "flame.fill", title: "10件達成", color: .orange)
                            BadgeView(icon: "crown.fill", title: "決済マスター", color: .gray) // Locked
                                .opacity(0.4)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("プレミアムプラン")) {
                    NavigationLink(destination: PremiumFeatureView()) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("プレミアム機能の詳細を見る")
                                .foregroundColor(.purple)
                                .bold()
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Text("ログアウト")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("マイページ")
        }
    }
}

struct BadgeView: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(height: 30)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
        }
    }
}

struct PremiumFeatureView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.yellow)
                    .padding(.top, 40)
                
                Text("PayMap Premium")
                    .font(.largeTitle)
                    .bold()
                
                VStack(alignment: .leading, spacing: 20) {
                    PremiumFeatureRow(icon: "eye.slash", title: "広告非表示", description: "マップや店舗詳細画面の広告がすべて非表示になります。")
                    PremiumFeatureRow(icon: "line.3.horizontal.decrease.circle", title: "高度な絞り込み検索", description: "「PayPayが使える × 深夜営業」など、条件を組み合わせた検索が可能に。")
                    PremiumFeatureRow(icon: "map.fill", title: "オフラインマップ", description: "電波の届かない地下の店舗でも決済手段を確認できます。")
                    PremiumFeatureRow(icon: "mappin.circle", title: "オリジナルマップピン", description: "あなたのマップピンを特別なデザインにカスタマイズできます。")
                }
                .padding()
                
                Spacer(minLength: 40)
                
                Button(action: { print("Upgrade tapped") }) {
                    Text("月額 300円でアップグレード")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("プレミアムプラン")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
