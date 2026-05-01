import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

class AuthViewModel: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // Unhashed nonce for Apple Sign In
    private var currentNonce: String?
    
    struct UserProfile {
        let uid: String
        let displayName: String
        let email: String
        var totalContributions: Int
    }
    
    override init() {
        super.init()
        listenToAuthState()
    }
    
    // MARK: - Auth State Persistence
    private func listenToAuthState() {
        // Guard: Firebase must be configured before accessing Auth
        guard FirebaseApp.app() != nil else {
            print("ℹ️ Firebase not configured. Running in mock mode.")
            return
        }
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.isAuthenticated = true
                    self?.userProfile = UserProfile(
                        uid: user.uid,
                        displayName: user.displayName ?? "Unknown",
                        email: user.email ?? "",
                        totalContributions: 0
                    )
                } else {
                    self?.isAuthenticated = false
                    self?.userProfile = nil
                }
            }
        }
    }
    
    // MARK: - Apple Sign In
    func startAppleSignIn() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        guard FirebaseApp.app() != nil else {
            mockSignIn(provider: "Apple")
            return
        }
        switch result {
        case .success(let authorization):
            guard
                let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentNonce,
                let appleIDToken = appleIDCredential.identityToken,
                let idTokenString = String(data: appleIDToken, encoding: .utf8)
            else {
                errorMessage = "Apple Sign In failed: invalid credential"
                return
            }
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            signInWithCredential(credential)
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            // Firebase not configured – use mock mode
            mockSignIn(provider: "Google")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Cannot find root view controller"
            return
        }
        
        isLoading = true
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                self.errorMessage = "Google Sign In failed: missing token"
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            self.signInWithCredential(credential)
        }
    }
    
    // MARK: - Common Sign In
    private func signInWithCredential(_ credential: AuthCredential) {
        isLoading = true
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let user = result?.user {
                    self.isAuthenticated = true
                    self.userProfile = UserProfile(
                        uid: user.uid,
                        displayName: user.displayName ?? "Unknown",
                        email: user.email ?? "",
                        totalContributions: 0
                    )
                }
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Mock Sign In (Firebase not configured)
    private func mockSignIn(provider: String) {
        isAuthenticated = true
        userProfile = UserProfile(uid: "\(provider.lowercased())_mock_user", displayName: "\(provider) User", email: "\(provider.lowercased())@example.com", totalContributions: 0)
    }
    
    // MARK: - Helpers for Apple Sign In Nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { byte in charset[Int(byte) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
