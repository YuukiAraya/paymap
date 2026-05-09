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
    let changePhoto: String
    let storePhotoSection: String
    let addPhoto: String
    let uploadingPhoto: String
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
    let premiumRestorePurchases: String
    let premiumPurchasing: String
    let premiumActive: String
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
    let catBar: String
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

    // MARK: - Points / Badges
    let pointsEarnedFmt: String

    // MARK: - Errors
    let errorNotAuthenticated: String
    let errorDatabasePrefix: String

    // MARK: - Payment Methods (only non-brand names need translation)
    let paymentCashOnly: String
    let paymentCashAlso: String

    // MARK: - Email Change
    let emailSection: String
    let emailPlaceholder: String
    let emailChangeSuccess: String

    // MARK: - Misc
    let guestName: String

    // MARK: - Common
    let okButton: String
    let errorTitle: String
    let notesLabel: String

    // MARK: - Facilities (WiFi / Power)
    let facilitiesSection: String
    let hasWifiLabel: String
    let hasPowerLabel: String
    let facilityYes: String
    let facilityNo: String
    let facilityUnknown: String

    // MARK: - Map Filter
    let filterTitle: String
    let filterByPayment: String
    let filterByCategory: String
    let filterByFacility: String
    let filterWifi: String
    let filterPower: String
    let clearFilters: String
    let applyFilters: String
    let filterActive: String
    let filterNoResults: String
    let filterAllCategories: String
    let advancedFilterPremium: String
    let filterFavoritesOnly: String

    // MARK: - Map Search
    let searchPlaceholder: String

    // MARK: - Long Press Register
    let longPressHint: String
    let registerHereTitle: String
    let registerHereButton: String
    let cancelPinButton: String

    // MARK: - Address Picker (Map Confirmation)
    let addressRequired: String
    let confirmOnMapButton: String
    let addressPickerTitle: String
    let dragToAdjust: String
    let confirmLocationButton: String
    let geocodingInProgress: String
    let geocodeFailedError: String

    // MARK: - Ranking
    let rankingTitle: String
    let rankingSection: String
    let rankingEmpty: String
    let rankingYou: String
    let rankingPoints: String

    // MARK: - Favorites
    let favoritesTitle: String
    let favoritesEmpty: String
    let addFavorite: String
    let removeFavorite: String
    let favoritesSection: String
    let favoritesRequiresPremium: String

    // MARK: - Offline Mode
    let offlineModeLabel: String
    let showingCachedData: String

    // MARK: - Store Detail Facilities Display
    let wifiAvailable: String
    let powerAvailable: String
    let wifiUnavailable: String
    let powerUnavailable: String

    // MARK: - Delete Store
    let deleteStore: String
    let deleteStoreConfirmTitle: String
    let deleteStoreConfirmBody: String
    let cannotDeleteTitle: String
    let cannotDeleteBody: String

    // MARK: - Error Report (誤り報告)
    let reportErrorTitle: String
    let reportErrorSelectReason: String
    let reportErrorDuplicate: String
    let reportErrorNotExist: String
    let reportErrorWrongInfo: String
    let reportErrorOther: String
    let reportErrorSubmit: String
    let reportErrorThanksTitle: String
    let reportErrorThanksBody: String
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
        changePhoto: "写真を変更",
        storePhotoSection: "店舗写真",
        addPhoto: "写真を追加",
        uploadingPhoto: "アップロード中…",
        nicknameSection: "ニックネーム",
        nicknamePlaceholder: "ニックネームを入力",
        saveButton: "保存",
        myStoresTitle: "登録した店舗",
        myStoresEmpty: "まだ登録した店舗がありません",
        loadingLabel: "読み込み中…",
        premiumTitle: "PayMap Premium",
        premiumUpgrade: "月額 300円でアップグレード",
        premiumRestorePurchases: "購入を復元",
        premiumPurchasing: "購入中…",
        premiumActive: "プレミアム有効中 ✓",
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
        catBar: "バー",
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
        pointsEarnedFmt: "+%d pt獲得！",
        errorNotAuthenticated: "ログインが必要です",
        errorDatabasePrefix: "データベースエラー: ",
        paymentCashOnly: "現金のみ",
        paymentCashAlso: "現金も可能",
        emailSection: "メールアドレス",
        emailPlaceholder: "新しいメールアドレス",
        emailChangeSuccess: "メールアドレスを変更しました",
        guestName: "ゲスト",
        okButton: "OK",
        errorTitle: "エラー",
        notesLabel: "注意事項",
        facilitiesSection: "設備情報",
        hasWifiLabel: "フリーWiFi",
        hasPowerLabel: "電源あり（利用可）",
        facilityYes: "あり",
        facilityNo: "なし",
        facilityUnknown: "不明",
        filterTitle: "フィルター",
        filterByPayment: "決済手段で絞り込む",
        filterByCategory: "カテゴリで絞り込む",
        filterByFacility: "設備で絞り込む",
        filterWifi: "フリーWiFiあり",
        filterPower: "電源あり",
        clearFilters: "フィルターをクリア",
        applyFilters: "適用",
        filterActive: "フィルター適用中",
        filterNoResults: "条件に合う店舗がありません",
        filterAllCategories: "すべてのカテゴリ",
        advancedFilterPremium: "高度な絞り込みはプレミアム会員限定です",
        filterFavoritesOnly: "お気に入りのみ表示",
        searchPlaceholder: "店舗名・住所で検索",
        longPressHint: "長押しで店舗を登録できます",
        registerHereTitle: "この場所に店舗を登録",
        registerHereButton: "ここに登録する",
        cancelPinButton: "キャンセル",
        addressRequired: "住所（必須）",
        confirmOnMapButton: "地図で位置を確認・調整",
        addressPickerTitle: "位置を確認",
        dragToAdjust: "ピンをドラッグして位置を調整してください",
        confirmLocationButton: "この位置で確定",
        geocodingInProgress: "住所を検索中…",
        geocodeFailedError: "住所から位置を取得できませんでした",
        rankingTitle: "貢献度ランキング",
        rankingSection: "ランキング",
        rankingEmpty: "まだランキングデータがありません",
        rankingYou: "あなた",
        rankingPoints: "pt",
        favoritesTitle: "お気に入り",
        favoritesEmpty: "お気に入りの店舗がまだありません",
        addFavorite: "お気に入りに追加",
        removeFavorite: "お気に入りから削除",
        favoritesSection: "お気に入り店舗",
        favoritesRequiresPremium: "お気に入り機能はプレミアム会員限定です",
        offlineModeLabel: "オフラインモード",
        showingCachedData: "キャッシュされたデータを表示中",
        wifiAvailable: "フリーWiFi あり",
        powerAvailable: "電源 利用可",
        wifiUnavailable: "フリーWiFi なし",
        powerUnavailable: "電源 なし",
        deleteStore: "店舗を削除",
        deleteStoreConfirmTitle: "この店舗を削除しますか？",
        deleteStoreConfirmBody: "削除すると元に戻せません。",
        cannotDeleteTitle: "削除できません",
        cannotDeleteBody: "他のユーザーが情報を追加しているため削除できません。「誤り報告」で通報してください。",
        reportErrorTitle: "誤り報告",
        reportErrorSelectReason: "報告理由を選択してください",
        reportErrorDuplicate: "重複した店舗",
        reportErrorNotExist: "存在しない店舗",
        reportErrorWrongInfo: "情報が間違っている",
        reportErrorOther: "その他",
        reportErrorSubmit: "報告する",
        reportErrorThanksTitle: "報告を受け付けました",
        reportErrorThanksBody: "ご報告ありがとうございます。3件以上の報告で管理者がレビューします。"
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
        changePhoto: "Change Photo",
        storePhotoSection: "Store Photo",
        addPhoto: "Add Photo",
        uploadingPhoto: "Uploading…",
        nicknameSection: "Nickname",
        nicknamePlaceholder: "Enter a nickname",
        saveButton: "Save",
        myStoresTitle: "My Registered Stores",
        myStoresEmpty: "You haven't registered any stores yet.",
        loadingLabel: "Loading…",
        premiumTitle: "PayMap Premium",
        premiumUpgrade: "Upgrade for ¥300 / month",
        premiumRestorePurchases: "Restore Purchases",
        premiumPurchasing: "Purchasing…",
        premiumActive: "Premium Active ✓",
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
        catIzakaya: "Izakaya",
        catBar: "Bar",
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
        pointsEarnedFmt: "+%d pts earned!",
        errorNotAuthenticated: "Please sign in to continue.",
        errorDatabasePrefix: "Database error: ",
        paymentCashOnly: "Cash only",
        paymentCashAlso: "Cash also accepted",
        emailSection: "Email Address",
        emailPlaceholder: "New email address",
        emailChangeSuccess: "Email address updated",
        guestName: "Guest",
        okButton: "OK",
        errorTitle: "Error",
        notesLabel: "Notes",
        facilitiesSection: "Facilities",
        hasWifiLabel: "Free WiFi",
        hasPowerLabel: "Power Outlets Available",
        facilityYes: "Available",
        facilityNo: "Not Available",
        facilityUnknown: "Unknown",
        filterTitle: "Filter",
        filterByPayment: "Filter by Payment",
        filterByCategory: "Filter by Category",
        filterByFacility: "Filter by Facility",
        filterWifi: "Free WiFi",
        filterPower: "Power Outlets",
        clearFilters: "Clear Filters",
        applyFilters: "Apply",
        filterActive: "Filter Active",
        filterNoResults: "No stores match your filters",
        filterAllCategories: "All Categories",
        advancedFilterPremium: "Advanced filters require Premium",
        filterFavoritesOnly: "Favorites Only",
        searchPlaceholder: "Search by name or address",
        longPressHint: "Long-press on the map to register a store",
        registerHereTitle: "Register Store Here",
        registerHereButton: "Register Here",
        cancelPinButton: "Cancel",
        addressRequired: "Address (required)",
        confirmOnMapButton: "Confirm on Map",
        addressPickerTitle: "Confirm Location",
        dragToAdjust: "Drag the map to adjust the pin position",
        confirmLocationButton: "Confirm This Location",
        geocodingInProgress: "Searching address…",
        geocodeFailedError: "Could not find location for this address",
        rankingTitle: "Contribution Ranking",
        rankingSection: "Ranking",
        rankingEmpty: "No ranking data yet",
        rankingYou: "You",
        rankingPoints: "pts",
        favoritesTitle: "Favorites",
        favoritesEmpty: "No favorite stores yet",
        addFavorite: "Add to Favorites",
        removeFavorite: "Remove from Favorites",
        favoritesSection: "Favorite Stores",
        favoritesRequiresPremium: "Favorites require Premium",
        offlineModeLabel: "Offline Mode",
        showingCachedData: "Showing cached data",
        wifiAvailable: "Free WiFi Available",
        powerAvailable: "Power Outlets Available",
        wifiUnavailable: "No Free WiFi",
        powerUnavailable: "No Power Outlets",
        deleteStore: "Delete Store",
        deleteStoreConfirmTitle: "Delete This Store?",
        deleteStoreConfirmBody: "This action cannot be undone.",
        cannotDeleteTitle: "Cannot Delete",
        cannotDeleteBody: "Other users have added information to this store. Please use 'Report Error' instead.",
        reportErrorTitle: "Report Error",
        reportErrorSelectReason: "Select a reason",
        reportErrorDuplicate: "Duplicate store",
        reportErrorNotExist: "Store does not exist",
        reportErrorWrongInfo: "Incorrect information",
        reportErrorOther: "Other",
        reportErrorSubmit: "Submit",
        reportErrorThanksTitle: "Report Submitted",
        reportErrorThanksBody: "Thank you for your report. Our team will review it after 3+ reports."
    )
}
