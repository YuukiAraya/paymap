import Foundation

struct L10n {
    // MARK: - Auth
    let appSubtitle: String
    let signInWithGoogle: String

    // MARK: - Tabs
    let tabMap: String
    let tabRegister: String
    let tabMyPage: String

    // MARK: - Map / Bottom Sheet
    let viewDetails: String
    let addInfo: String
    let noPaymentInfo: String
    let paymentAvailable: String
    let photoComingSoon: String
    let openGoogleMaps: String
    let addEditPayment: String
    let closeButton: String
    let storeDetail: String

    // MARK: - Report Sheet
    let reportTitle: String
    let reportSectionHeader: String
    let reportSectionFooter: String
    let submitReport: String
    let reportThanks: String
    let reportThanksBody: String
    let cancelButton: String

    // MARK: - Store Register
    let registerStoreTitle: String
    let storeInfoSection: String
    let storeNamePlaceholder: String
    let storeNameEnPlaceholder: String
    let categoryLabel: String
    let addressPlaceholder: String
    let registerButton: String
    let registeringLabel: String
    let registrationCompleteTitle: String
    func registrationCompleteBody(_ name: String) -> String { registrationCompleteBodyFmt.replacingOccurrences(of: "%@", with: name) }
    let registrationCompleteBodyFmt: String

    // MARK: - Profile
    let myPageTitle: String
    let profileSection: String
    let editProfileLink: String
    let achievementsSection: String
    let contributionPoints: String
    let pointsUnit: String
    let badgesLabel: String
    let registeredStoresSection: String
    let viewRegisteredStores: String
    let rulesLink: String
    let premiumSection: String
    let viewPremiumDetails: String
    let logoutButton: String
    let languageSection: String

    // MARK: - Edit Profile
    let editProfileTitle: String
    let iconSection: String
    let changePhotoDisabled: String
    let nicknameSection: String
    let nicknamePlaceholder: String
    let saveButton: String

    // MARK: - My Stores
    let myStoresTitle: String
    let myStoresEmpty: String
    let loadingLabel: String

    // MARK: - Premium
    let premiumTitle: String
    let premiumUpgrade: String
    let premiumNoAds: String
    let premiumNoAdsDesc: String
    let premiumSearch: String
    let premiumSearchDesc: String
    let premiumOffline: String
    let premiumOfflineDesc: String
    let premiumCustomPin: String
    let premiumCustomPinDesc: String

    // MARK: - Contribution Rules
    let rulesPageTitle: String
    let pointRulesSection: String
    let badgeRulesSection: String
    let notesSection: String
    let note1: String
    let note2: String
    let note3: String

    // MARK: - Point Rules (title / desc / pts label)
    let prNewStore: String;     let prNewStoreDesc: String
    let prFirst: String;        let prFirstDesc: String
    let prReport: String;       let prReportDesc: String
    let prConfirm: String;      let prConfirmDesc: String
    let pointsSuffix: String

    // MARK: - Badge Rules (title / condition)
    let brFirstPost: String;    let brFirstPostCond: String
    let br10: String;           let br10Cond: String
    let br50: String;           let br50Cond: String
    let brMaster: String;       let brMasterCond: String
    let brExplorer: String;     let brExplorerCond: String

    // MARK: - Store Categories
    let catConvenience: String
    let catCafe: String
    let catRestaurant: String
    let catIzakaya: String
    let catFastFood: String
    let catSupermarket: String
    let catDrugStore: String
    let catHotel: String
    let catVending: String
    let catOther: String

    // MARK: - Payment Groups
    let groupCreditCard: String
    let groupQR: String
    let groupIC: String
    let groupOther: String

    // MARK: - Payment Methods (only non-brand names need translation)
    let paymentCashOnly: String

    // MARK: - Misc
    let guestName: String

    // MARK: - Common
    let okButton: String
    let errorTitle: String
    let notesLabel: String
}

// MARK: - Japanese
extension L10n {
    static let japanese = L10n(
        appSubtitle: "決済手段をシェアして、\nみんなでマップを作ろう！",
        signInWithGoogle: "Googleでサインイン",
        tabMap: "マップ",
        tabRegister: "店舗登録",
        tabMyPage: "マイページ",
        viewDetails: "詳細・写真",
        addInfo: "情報を追加",
        noPaymentInfo: "まだ情報がありません。最初の報告者になりましょう！",
        paymentAvailable: "現在有効な決済手段",
        photoComingSoon: "外観写真は準備中です",
        openGoogleMaps: "Google マップで開く",
        addEditPayment: "決済情報を追加・修正する",
        closeButton: "閉じる",
        storeDetail: "店舗詳細",
        reportTitle: "情報の申請",
        reportSectionHeader: "この店舗で使える決済手段を選択してください",
        reportSectionFooter: "全体の80%以上が「使える」と報告した手段のみ有効化されます。",
        submitReport: "報告を送信する",
        reportThanks: "報告ありがとうございます",
        reportThanksBody: "承認ステータスが更新されました。",
        cancelButton: "キャンセル",
        registerStoreTitle: "店舗を登録",
        storeInfoSection: "店舗情報",
        storeNamePlaceholder: "店舗名（例：セブンイレブン 渋谷店）",
        storeNameEnPlaceholder: "英語名（例：7-Eleven Shibuya）",
        categoryLabel: "カテゴリ",
        addressPlaceholder: "住所（任意）",
        registerButton: "店舗を登録する",
        registeringLabel: "登録中…",
        registrationCompleteTitle: "登録完了",
        registrationCompleteBodyFmt: "「%@」を登録しました。情報のご提供ありがとうございます！",
        myPageTitle: "マイページ",
        profileSection: "プロフィール",
        editProfileLink: "プロフィールを編集",
        achievementsSection: "実績・インセンティブ",
        contributionPoints: "貢献ポイント",
        pointsUnit: "pt",
        badgesLabel: "獲得バッジ",
        registeredStoresSection: "登録した店舗",
        viewRegisteredStores: "登録した店舗一覧",
        rulesLink: "貢献ポイントの獲得ルールを見る",
        premiumSection: "プレミアムプラン",
        viewPremiumDetails: "プレミアム機能の詳細を見る",
        logoutButton: "ログアウト",
        languageSection: "言語 / Language",
        editProfileTitle: "プロフィール編集",
        iconSection: "アイコン",
        changePhotoDisabled: "写真を変更（準備中）",
        nicknameSection: "ニックネーム",
        nicknamePlaceholder: "ニックネームを入力",
        saveButton: "保存",
        myStoresTitle: "登録した店舗",
        myStoresEmpty: "まだ登録した店舗がありません",
        loadingLabel: "読み込み中…",
        premiumTitle: "PayMap Premium",
        premiumUpgrade: "月額 300円でアップグレード",
        premiumNoAds: "広告非表示",
        premiumNoAdsDesc: "マップや店舗詳細画面の広告がすべて非表示になります。",
        premiumSearch: "高度な絞り込み検索",
        premiumSearchDesc: "「PayPayが使える × 深夜営業」など条件を組み合わせた検索が可能に。",
        premiumOffline: "オフラインマップ",
        premiumOfflineDesc: "電波の届かない地下の店舗でも決済手段を確認できます。",
        premiumCustomPin: "オリジナルマップピン",
        premiumCustomPinDesc: "あなたのマップピンを特別なデザインにカスタマイズできます。",
        rulesPageTitle: "貢献ポイントの仕組み",
        pointRulesSection: "ポイント獲得ルール",
        badgeRulesSection: "バッジ獲得条件",
        notesSection: "注意事項",
        note1: "• 1店舗につき1回のみポイントを獲得できます。",
        note2: "• 虚偽の情報登録が確認された場合、ポイントは取り消されます。",
        note3: "• ポイントはランキング表示のみに使用されます（現金化不可）。",
        prNewStore: "新規店舗の登録",      prNewStoreDesc: "まだ未登録の店舗を初めて追加する",
        prFirst: "ファーストディスカバリー", prFirstDesc: "その店舗の決済手段を最初に報告する",
        prReport: "決済手段の報告",         prReportDesc: "既存店舗の決済手段を追加・修正する",
        prConfirm: "確認ボーナス",          prConfirmDesc: "すでに登録済みの情報が正確と確認する",
        pointsSuffix: "pt",
        brFirstPost: "初投稿",     brFirstPostCond: "初めて情報を登録する",
        br10: "10件達成",          br10Cond: "10件の情報を登録する",
        br50: "50件達成",          br50Cond: "50件の情報を登録する",
        brMaster: "決済マスター",  brMasterCond: "合計200ptを獲得する",
        brExplorer: "探検家",      brExplorerCond: "5つの異なるカテゴリを登録",
        catConvenience: "コンビニ",
        catCafe: "カフェ",
        catRestaurant: "レストラン",
        catIzakaya: "居酒屋",
        catFastFood: "ファストフード",
        catSupermarket: "スーパー",
        catDrugStore: "ドラッグストア",
        catHotel: "ホテル",
        catVending: "自動販売機",
        catOther: "その他",
        groupCreditCard: "クレジットカード",
        groupQR: "QRコード決済",
        groupIC: "電子マネー・IC",
        groupOther: "その他",
        paymentCashOnly: "現金のみ",
        guestName: "ゲスト",
        okButton: "OK",
        errorTitle: "エラー",
        notesLabel: "注意事項"
    )
}

// MARK: - English
extension L10n {
    static let english = L10n(
        appSubtitle: "Share payment methods\nand build a map together!",
        signInWithGoogle: "Sign in with Google",
        tabMap: "Map",
        tabRegister: "Add Store",
        tabMyPage: "My Page",
        viewDetails: "Details & Photos",
        addInfo: "Add Info",
        noPaymentInfo: "No info yet. Be the first to report!",
        paymentAvailable: "Accepted Payment Methods",
        photoComingSoon: "Store photo coming soon",
        openGoogleMaps: "Open in Google Maps",
        addEditPayment: "Add / Edit Payment Info",
        closeButton: "Close",
        storeDetail: "Store Details",
        reportTitle: "Submit Report",
        reportSectionHeader: "Select accepted payment methods for this store",
        reportSectionFooter: "A method is activated when 80% or more of reports say it's accepted.",
        submitReport: "Submit Report",
        reportThanks: "Thank you for your report!",
        reportThanksBody: "Approval status has been updated.",
        cancelButton: "Cancel",
        registerStoreTitle: "Add a Store",
        storeInfoSection: "Store Information",
        storeNamePlaceholder: "Store name (e.g. 7-Eleven Shibuya)",
        storeNameEnPlaceholder: "English name (e.g. 7-Eleven Shibuya)",
        categoryLabel: "Category",
        addressPlaceholder: "Address (optional)",
        registerButton: "Register Store",
        registeringLabel: "Registering…",
        registrationCompleteTitle: "Store Added!",
        registrationCompleteBodyFmt: "\"%@\" has been registered. Thank you for contributing!",
        myPageTitle: "My Page",
        profileSection: "Profile",
        editProfileLink: "Edit Profile",
        achievementsSection: "Achievements",
        contributionPoints: "Contribution Points",
        pointsUnit: "pts",
        badgesLabel: "Badges Earned",
        registeredStoresSection: "My Registered Stores",
        viewRegisteredStores: "View My Stores",
        rulesLink: "How to Earn Contribution Points",
        premiumSection: "Premium Plan",
        viewPremiumDetails: "View Premium Features",
        logoutButton: "Log Out",
        languageSection: "言語 / Language",
        editProfileTitle: "Edit Profile",
        iconSection: "Icon",
        changePhotoDisabled: "Change Photo (coming soon)",
        nicknameSection: "Nickname",
        nicknamePlaceholder: "Enter a nickname",
        saveButton: "Save",
        myStoresTitle: "My Registered Stores",
        myStoresEmpty: "You haven't registered any stores yet.",
        loadingLabel: "Loading…",
        premiumTitle: "PayMap Premium",
        premiumUpgrade: "Upgrade for ¥300 / month",
        premiumNoAds: "Ad-Free",
        premiumNoAdsDesc: "Remove all ads from the map and store detail screens.",
        premiumSearch: "Advanced Search",
        premiumSearchDesc: "Search with multiple filters like 'PayPay accepted × Late night open'.",
        premiumOffline: "Offline Maps",
        premiumOfflineDesc: "Check payment info even underground without signal.",
        premiumCustomPin: "Custom Map Pins",
        premiumCustomPinDesc: "Customize your map pin with unique designs.",
        rulesPageTitle: "How Contribution Points Work",
        pointRulesSection: "Point Earning Rules",
        badgeRulesSection: "Badge Conditions",
        notesSection: "Notes",
        note1: "• Points can be earned once per store.",
        note2: "• Points will be revoked if false information is confirmed.",
        note3: "• Points are used for rankings only (non-transferable).",
        prNewStore: "Register New Store",    prNewStoreDesc: "Add a store not yet in the database",
        prFirst: "First Discovery",         prFirstDesc: "First to report payment methods for a store",
        prReport: "Payment Report",         prReportDesc: "Add or correct payment methods for a store",
        prConfirm: "Confirmation Bonus",    prConfirmDesc: "Confirm that existing information is still accurate",
        pointsSuffix: "pts",
        brFirstPost: "First Post",  brFirstPostCond: "Register information for the first time",
        br10: "10 Reports",         br10Cond: "Register 10 pieces of information",
        br50: "50 Reports",         br50Cond: "Register 50 pieces of information",
        brMaster: "Pay Master",     brMasterCond: "Earn a total of 200 pts",
        brExplorer: "Explorer",     brExplorerCond: "Register 5 different store categories",
        catConvenience: "Convenience Store",
        catCafe: "Café",
        catRestaurant: "Restaurant",
        catIzakaya: "Izakaya (Bar)",
        catFastFood: "Fast Food",
        catSupermarket: "Supermarket",
        catDrugStore: "Drug Store",
        catHotel: "Hotel",
        catVending: "Vending Machine",
        catOther: "Other",
        groupCreditCard: "Credit Cards",
        groupQR: "QR Code Payment",
        groupIC: "IC / E-Money",
        groupOther: "Other",
        paymentCashOnly: "Cash only",
        guestName: "Guest",
        okButton: "OK",
        errorTitle: "Error",
        notesLabel: "Notes"
    )
}
