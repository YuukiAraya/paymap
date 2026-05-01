import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "creditcard.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("PayMap")
                .font(.largeTitle)
                .bold()
            
            Text("決済手段をシェアして、みんなでマップを作ろう！")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 16) {
                // Apple Sign In Button
                SignInWithAppleButton(
                    onRequest: { request in
                        // Setup request
                    },
                    onCompletion: { result in
                        authViewModel.signInWithApple()
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal)
                
                // Google Sign In Button (Mock UI)
                Button(action: {
                    authViewModel.signInWithGoogle()
                }) {
                    HStack {
                        Image(systemName: "g.circle.fill") // Placeholder for Google logo
                        Text("Sign in with Google")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 50)
        }
        .background(Color(.systemGroupedBackground))
    }
}
