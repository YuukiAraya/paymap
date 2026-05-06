import SwiftUI

// 誤り報告シート（マップ詳細・マイページ登録一覧 共通）
struct StoreErrorReportView: View {
    let store: Store
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var lm: LanguageManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: ErrorReason? = nil
    @State private var isSubmitting = false
    @State private var showingThanks = false
    @State private var reportCount = 0

    enum ErrorReason: String, CaseIterable, Identifiable {
        case duplicate  = "duplicate"
        case notExist   = "not_exist"
        case wrongInfo  = "wrong_info"
        case other      = "other"

        var id: String { rawValue }

        func label(_ lm: LanguageManager) -> String {
            switch self {
            case .duplicate: return lm.s.reportErrorDuplicate
            case .notExist:  return lm.s.reportErrorNotExist
            case .wrongInfo: return lm.s.reportErrorWrongInfo
            case .other:     return lm.s.reportErrorOther
            }
        }
    }

    private let storeService = StoreService()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(store.displayName(isEnglish: lm.isEnglish))
                    .font(.subheadline).foregroundColor(Color.premiumNavy)) {
                    Text(lm.s.reportErrorSelectReason)
                        .font(.subheadline).foregroundColor(.secondary)
                }

                Section {
                    ForEach(ErrorReason.allCases) { reason in
                        Button(action: { selectedReason = reason }) {
                            HStack {
                                Text(reason.label(lm)).foregroundColor(.primary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.premiumEmerald)
                                } else {
                                    Image(systemName: "circle").foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button(action: submit) {
                        if isSubmitting {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text(lm.s.reportErrorSubmit).frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedReason == nil || isSubmitting)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(lm.s.reportErrorTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lm.s.cancelButton) { dismiss() }
                }
            }
            .alert(lm.s.reportErrorThanksTitle, isPresented: $showingThanks) {
                Button(lm.s.okButton) { dismiss() }
            } message: {
                Text(lm.s.reportErrorThanksBody)
            }
        }
    }

    private func submit() {
        guard let reason = selectedReason,
              let uid = authViewModel.userProfile?.uid else { return }
        isSubmitting = true
        Task {
            do {
                reportCount = try await storeService.reportStoreError(
                    storeId: store.id, uid: uid, reason: reason.rawValue)
            } catch {}
            isSubmitting = false
            showingThanks = true
        }
    }
}
