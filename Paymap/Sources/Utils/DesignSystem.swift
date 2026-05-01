import SwiftUI

// MARK: - Colors
extension Color {
    static let brandPrimary = Color("BrandPrimary", bundle: nil) // Deep Navy
    static let brandSecondary = Color("BrandSecondary", bundle: nil) // Emerald Green
    static let surfaceBackground = Color("SurfaceBackground", bundle: nil) // Slightly off-white/dark
    
    // Fallback colors for code-only setup
    static let premiumNavy = Color(red: 0.1, green: 0.15, blue: 0.3)
    static let premiumEmerald = Color(red: 0.2, green: 0.8, blue: 0.6)
    static let premiumCardBackground = Color(.secondarySystemGroupedBackground)
}

// MARK: - Glassmorphism Modifier
struct Glassmorphism: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard() -> some View {
        self.modifier(Glassmorphism())
    }
}

// MARK: - Custom Buttons
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.premiumEmerald, Color.premiumEmerald.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
            .shadow(color: Color.premiumEmerald.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(Color.premiumNavy)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.premiumNavy.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}
