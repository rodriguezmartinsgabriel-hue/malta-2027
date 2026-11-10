import SwiftUI

/// Malta 2027 - Liquid Glass design, light mode.
/// Warm cream base with soft brand halos, floating frosted cards, serif numerals.
public enum Theme {
    public static let deep = Color(hex: 0xF3EDDF)        // warm cream base
    public static let ink = Color(hex: 0x241F1C)         // primary text (dark)
    public static let muted = Color(hex: 0x8B8073)       // secondary text
    public static let wine = Color(hex: 0x722F37)        // brand fill
    public static let wineBright = Color(hex: 0xA64650)  // accent on light
    public static let olive = Color(hex: 0x5E6F35)
    public static let oliveBright = Color(hex: 0x5E6F35)
    public static let cream = Color(hex: 0xF6F3EA)

    /// Soft control fill (fields, chips, buttons) on light surfaces.
    public static let soft = ink.opacity(0.055)
    /// Slightly stronger fill for tiny controls (xmarks, icon buttons).
    public static let softStrong = ink.opacity(0.09)
    /// Hairline separator between rows.
    public static let hairline = ink.opacity(0.10)

    public static let wineFill = LinearGradient(
        colors: [Color(hex: 0x8E3B44), wine],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    public static let glowFill = LinearGradient(
        colors: [wineBright, Color(hex: 0x7C8F47)],
        startPoint: .leading, endPoint: .trailing
    )
}

extension Color {
    public init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: 1
        )
    }
}

/// Instrument Serif is the one brand font (hero + numerals). Everything else is SF.
public enum Fonts {
    public static let serifPS = "InstrumentSerif-Regular"

    public static func register() {
        for name in ["InstrumentSerif", "InstrumentSans"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    public static func display(_ size: CGFloat) -> Font { .custom(serifPS, size: size) }
    public static func mono(_ size: CGFloat = 15) -> Font { .system(size: size, design: .monospaced) }
}

// MARK: - Backdrop

/// The app background: warm cream with soft wine and olive halos.
struct ScreenBackdrop: View {
    var body: some View {
        ZStack {
            Theme.deep
            GeometryReader { geo in
                Circle().fill(Theme.wine)
                    .frame(width: 640, height: 640)
                    .blur(radius: 130)
                    .opacity(0.22)
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.02)
                Circle().fill(Theme.olive)
                    .frame(width: 560, height: 560)
                    .blur(radius: 130)
                    .opacity(0.16)
                    .position(x: geo.size.width * 0.98, y: geo.size.height * 0.92)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass

private struct GlassStyle: ViewModifier {
    var corner: CGFloat
    var glow: Color?

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.60), .white.opacity(0.18)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.95), .white.opacity(0.45)],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.10), radius: 18, y: 10)
                    .background {
                        if let glow {
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .fill(glow.opacity(0.10))
                                .blur(radius: 24)
                                .offset(y: 16)
                        }
                    }
            }
    }
}

extension View {
    /// Floating glass card surface.
    func glass(corner: CGFloat = 26, glow: Color? = nil) -> some View {
        modifier(GlassStyle(corner: corner, glow: glow))
    }
}

// MARK: - Screen shell

/// Shared screen shell: serif header + stack of glass cards on the backdrop.
struct MaltaScreen<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let content: () -> Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(Fonts.display(42))
                    .foregroundStyle(Theme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, -6)
                }
                content()
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 44)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

/// Small uppercase group label that sits above a glass card.
struct ScreenLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(1.1)
            .foregroundStyle(Theme.muted)
            .padding(.leading, 6)
            .padding(.top, 6)
    }
}

/// Caption + serif value, used inside stat grids.
struct GlassStat: View {
    let label: String
    let value: String
    var accent: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
            Text(value)
                .font(Fonts.display(21))
                .foregroundStyle(accent ?? Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
    }
}

/// Numeric field row: label left, monospaced value right.
struct RowField: View {
    let title: String
    @Binding var text: String

    init(_ title: String, text: Binding<String>) {
        self.title = title
        _text = text
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
            Spacer(minLength: 12)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Fonts.mono(16))
                .foregroundStyle(Theme.ink)
        }
    }
}

/// Gradient progress capsule on a soft track.
struct ProgressLine: View {
    let ratio: Double

    init(ratio: Double) {
        self.ratio = max(0, min(1, ratio))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule()
                    .fill(Theme.glowFill)
                    .frame(width: max(6, geo.size.width * ratio))
                    .shadow(color: Theme.wineBright.opacity(0.35), radius: 6, y: 1)
            }
        }
        .frame(height: 8)
    }
}

extension Double {
    func rounded2() -> Double {
        (self * 100).rounded() / 100
    }
}
