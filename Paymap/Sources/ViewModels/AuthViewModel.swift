import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

class AuthViewModel: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private var currentNonce: String?
    private let storeService = StoreService()

    struct UserProfile {
        let uid: String
        var displayName: String
        var email: String
        var totalContributions: Int
        var badges: [String]
        var isPremium: Bool
        var photoURL: String?
    }

    override init() {
        super.init()
        listenToAuthState()
    }

    // MARK: - Auth State
    private func listenToAuthState() {
        guard FirebaseApp.app() != nil else {
            print("ℹ️ Firebase not configured. Running in mock mode.")
            return
        }
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let user = user {
                Task { await self.loadOrCreateProfile(for: user) }
            } else {
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.userProfile = nil
                }
            }
        }
    }

    private func loadOrCreateProfile(for user: FirebaseAuth.User) async {
        do {
            let data = try await storeService.fetchOrCreateUser(
                uid: user.uid,
                displayName: user.displayName ?? "Unknown",
                email: user.email ?? ""
            )
            await MainActor.run {
                isAuthenticated = true
                userProfile = UserProfile(
                    uid: user.uid,
                    displayName: user.displayName ?? "Unknown",
                    email: user.email ?? "",
                    totalContributions: data.totalContributions,
                    badges: data.badges,
                    isPremium: data.isPremium,
                    photoURL: data.photoURL
                )
            }
        } catch {
            await MainActor.run {
                isAuthenticated = true
                userProfile = UserProfile(
                    uid: user.uid,
                    displayName: user.displayName ?? "Unknown",
                    email: user.email ?? "",
                    totalContributions: 0,
                    badges: [],
                    isPremium: false,
                    photoURL: nil
                )
            }
        }
    }

    // MARK: - Apple Sign In
    func startAppleSignIn() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        guard FirebaseApp.app() != nil else { mockSignIn(provider: "Apple"); return }
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8)
            else { errorMessage = "Apple Sign In failed"; return }
            signInWithCredential(OAuthProvider.appleCredential(
                withIDToken: token, rawNonce: nonce, fullName: credential.fullName))
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Google Sign In
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            mockSignIn(provider: "Google"); return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first?.windows.first?.rootViewController
        else { errorMessage = "Cannot find root view controller"; return }

        isLoading = true
        GIDSignIn.sharedInstance.signIn(withPresenting: root) { [weak self] result, error in
            guard let self else { return }
            self.isLoading = false
            if let error = error { self.errorMessage = error.localizedDescription; return }
            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                self.errorMessage = "Google Sign In failed"; return
            }
            self.signInWithCredential(GoogleAuthProvider.credential(
                withIDToken: idToken, accessToken: user.accessToken.tokenString))
        }
    }

    private func signInWithCredential(_ credential: AuthCredential) {
        isLoading = true
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            guard let self else { return }
            DispatchQueue.main.async { self.isLoading = false }
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            }
            // Auth state listener handles profile loading
        }
    }

    // MARK: - Update Display Name
    func updateDisplayName(_ name: String) async throws {
        guard FirebaseApp.app() != nil, let user = Auth.auth().currentUser else {
            await MainActor.run {
                userProfile?.displayName = name
            }
            return
        }
        let request = user.createProfileChangeRequest()
        request.displayName = name
        try await request.commitChanges()
        if let uid = userProfile?.uid {
            try? await Firestore.firestore().collection("users").document(uid)
                .updateData(["displayName": name])
        }
        await MainActor.run { userProfile?.displayName = name }
    }

    // MARK: - Update Email
    func updateEmail(_ email: String) async throws {
        if FirebaseApp.app() != nil, let user = Auth.auth().currentUser {
            try await user.updateEmail(to: email)
        }
        if let uid = userProfile?.uid, FirebaseApp.app() != nil {
            try? await Firestore.firestore().collection("users")
                .document(uid).updateData(["email": email])
        }
        await MainActor.run { userProfile?.email = email }
    }

    // MARK: - Add Points
    func addContributionPoints(_ points: Int) async {
        guard let uid = userProfile?.uid, FirebaseApp.app() != nil else { return }
        do {
            let (total, newBadges) = try await storeService.addPoints(to: uid, points: points)
            await MainActor.run {
                userProfile?.totalContributions = total
                if !newBadges.isEmpty {
                    userProfile?.badges.append(contentsOf: newBadges)
                }
            }
        } catch {
            print("addPoints error: \(error)")
        }
    }

    // MARK: - Check Explorer Badge
    func checkExplorerBadge() async {
        guard let uid = userProfile?.uid, FirebaseApp.app() != nil else { return }
        do {
            let stores = try await storeService.fetchStoresByUser(uid: uid)
            let categories = Set(stores.map { $0.category })
            if categories.count >= 5 {
                try await storeService.awardExplorerBadge(to: uid)
                await MainActor.run {
                    if userProfile?.badges.contains("brExplorer") == false {
                        userProfile?.badges.append("brExplorer")
                    }
                }
            }
        } catch { print("checkExplorerBadge error: \(error)") }
    }

    // MARK: - Sign Out
    func signOut() {
        try? Auth.auth().signOut()
    }

    // MARK: - Mock Sign In
    private func mockSignIn(provider: String) {
        isAuthenticated = true
        userProfile = UserProfile(
            uid: "\(provider.lowercased())_mock_user",
            displayName: "\(provider) User",
            email: "\(provider.lowercased())@example.com",
            totalContributions: 0,
            badges: [],
            isPremium: false,
            photoURL: nil
        )
    }

    // MARK: - Apple Sign In Helpers
    private func randomNonceString(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).compactMap { String(format: "%02x", $0) }.joined()
    }
}
