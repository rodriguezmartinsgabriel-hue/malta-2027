import SwiftUI

/// Malta 2027 design tokens. Native iOS first: system fonts, system controls and
/// system layout carry the app. Brand colors appear only in accents and the home
/// hero; typography hierarchy comes from the system text styles.
public enum Theme {
    public static let bg = Color(hex: 0xF6F3EA)       // warm app background
    public static let paper = Color(hex: 0xFFFEF9)    // list row background
    public static let ink = Color(hex: 0x241F1C)      // primary text
    public static let muted = Color(hex: 0x7B7466)    // secondary text
    public static let wine = Color(hex: 0x722F37)     // accent
    public static let wineSoftBg = Color(hex: 0xF6E7E4)
    public static let olive = Color(hex: 0x5E6F35)    // secondary accent
    public static let oliveSoft = Color(hex: 0xE9EDD9)
    public static let line = Color(hex: 0x241F1C).opacity(0.12)

    /// Acerto banner (the single solid-brand block in the app).
    public static let creamOnInk = Color(hex: 0xF5F2EA)
    public static let mutedOnInk = Color(hex: 0xECD9D5)
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

/// Instrument Serif is the one brand font (home hero + key numbers). Everything
/// else is the system font (SF Pro), which is what a native iOS app ships with.
public enum Fonts {
    public static let serifPS = "InstrumentSerif-Regular"

    public static func register() {
        for name in ["InstrumentSerif", "InstrumentSans"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    public static func body(_ size: CGFloat = 16) -> Font { .system(size: size) }
    public static func mono(_ size: CGFloat = 10) -> Font { .system(size: size, design: .monospaced) }
    public static func display(_ size: CGFloat) -> Font { .custom(serifPS, size: size) }
}

/// Small secondary paragraph, used as section footers.
public struct Note: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(Theme.muted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Trailing decimal field in a list row (native look: label left, value right).
public struct RowField: View {
    let title: String
    @Binding var text: String

    public init(_ title: String, text: Binding<String>) {
        self.title = title
        _text = text
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .lineLimit(1)
            Spacer(minLength: 12)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Fonts.mono(15))
                .foregroundStyle(Theme.ink)
        }
    }
}

/// Progress bar (olive fill by default).
public struct ProgressLine: View {
    let ratio: Double
    var tint: Color

    public init(ratio: Double, tint: Color = Theme.olive) {
        self.ratio = max(0, min(1, ratio))
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line.opacity(0.5))
                Capsule().fill(tint).frame(width: geo.size.width * ratio)
            }
        }
        .frame(height: 6)
    }
}
