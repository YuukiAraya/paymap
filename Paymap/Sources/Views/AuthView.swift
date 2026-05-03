import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var lm: LanguageManager

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.premiumNavy, Color.premiumNavy.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Language toggle (top-right)
                HStack {
                    Spacer()
                    Picker("", selection: Binding(
                        get: { lm.language },
                        set: { lm.language = $0 }
                    )) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                    .padding()
                }

                Spacer()

                // Logo & Title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.premiumEmerald.opacity(0.2))
                            .frame(width: 120, height: 120)
                        Image(systemName: "creditcard.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(
                                LinearGradient(colors: [Color.premiumEmerald, .white], startPoint: .top, endPoint: .bottom)
                            )
                    }

                    Text("PayMap")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(lm.s.appSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 60)

                Spacer()

                // Login Buttons
                VStack(spacing: 14) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                            .frame(height: 50)
                    } else {
                        SignInWithAppleButton(
                            onRequest: { request in
                                let appleRequest = authViewModel.startAppleSignIn()
                                request.requestedScopes = appleRequest.requestedScopes
                                request.nonce = appleRequest.nonce
                            },
                            onCompletion: { result in
                                authViewModel.handleAppleSignIn(result: result)
                            }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 52)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        Button(action: { authViewModel.signInWithGoogle() }) {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.headline)
                                Text(lm.s.signInWithGoogle)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .foregroundColor(Color.premiumNavy)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}
