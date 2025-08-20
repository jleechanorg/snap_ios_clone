import SwiftUI

// MARK: - View Extensions

extension View {
    /// Hide keyboard when tapping outside
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Add tap gesture to hide keyboard
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
    
    /// Corner radius for specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// Apply gradient background
    func gradientBackground(colors: [Color], startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> some View {
        self.background(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: startPoint,
                endPoint: endPoint
            )
        )
    }
    
    /// Add shadow with default parameters
    func defaultShadow() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply a modifier conditionally with an else case
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        then trueTransform: (Self) -> TrueContent,
        else falseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueTransform(self)
        } else {
            falseTransform(self)
        }
    }
    
    /// Add loading overlay
    func loadingOverlay(isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        )
    }
    
    /// Add haptic feedback on tap
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: style)
            impact.impactOccurred()
        }
    }
    
    /// Apply device-specific styling
    func phoneOnlyStackNavigationView() -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return AnyView(self.navigationViewStyle(.stack))
        } else {
            return AnyView(self)
        }
    }
}

// MARK: - Custom Shapes

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - ViewModifiers

struct PrimaryButtonStyle: ViewModifier {
    let isEnabled: Bool
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(isEnabled: Bool = true, backgroundColor: Color = .blue, foregroundColor: Color = .white) {
        self.isEnabled = isEnabled
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(isEnabled ? foregroundColor : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isEnabled ? backgroundColor : Color.gray.opacity(0.3))
            .cornerRadius(25)
            .scaleEffect(isEnabled ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.1), value: isEnabled)
    }
}

struct SecondaryButtonStyle: ViewModifier {
    let isEnabled: Bool
    let borderColor: Color
    let foregroundColor: Color
    
    init(isEnabled: Bool = true, borderColor: Color = .blue, foregroundColor: Color = .blue) {
        self.isEnabled = isEnabled
        self.borderColor = borderColor
        self.foregroundColor = foregroundColor
    }
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(isEnabled ? foregroundColor : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(isEnabled ? borderColor : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .scaleEffect(isEnabled ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.1), value: isEnabled)
    }
}

struct CardStyle: ViewModifier {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(backgroundColor: Color = Color(.systemBackground), cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 5) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
    }
}

// MARK: - View Extension for Modifiers

extension View {
    func primaryButtonStyle(isEnabled: Bool = true, backgroundColor: Color = .blue, foregroundColor: Color = .white) -> some View {
        self.modifier(PrimaryButtonStyle(isEnabled: isEnabled, backgroundColor: backgroundColor, foregroundColor: foregroundColor))
    }
    
    func secondaryButtonStyle(isEnabled: Bool = true, borderColor: Color = .blue, foregroundColor: Color = .blue) -> some View {
        self.modifier(SecondaryButtonStyle(isEnabled: isEnabled, borderColor: borderColor, foregroundColor: foregroundColor))
    }
    
    func cardStyle(backgroundColor: Color = Color(.systemBackground), cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 5) -> some View {
        self.modifier(CardStyle(backgroundColor: backgroundColor, cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}

// MARK: - Color Extensions

extension Color {
    static let snapYellow = Color(red: 1.0, green: 0.9, blue: 0.0)
    static let snapBlue = Color(red: 0.0, green: 0.5, blue: 1.0)
    static let snapPurple = Color(red: 0.6, green: 0.2, blue: 1.0)
    
    /// Create color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Get hex string representation
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

// MARK: - String Extensions

extension String {
    /// Validate email format
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    /// Validate username format
    var isValidUsername: Bool {
        let usernameRegEx = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePred = NSPredicate(format:"SELF MATCHES %@", usernameRegEx)
        return usernamePred.evaluate(with: self)
    }
    
    /// Remove whitespace and newlines
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check if string is empty or contains only whitespace
    var isBlank: Bool {
        return self.trimmed.isEmpty
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format for display in chat
    var chatDisplayFormat: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(self) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: self)
        }
    }
    
    /// Check if date is recent (within last 5 minutes)
    var isRecent: Bool {
        return Date().timeIntervalSince(self) < 300 // 5 minutes
    }
    
    /// Time ago string
    var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}