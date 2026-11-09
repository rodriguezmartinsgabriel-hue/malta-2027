import Foundation

/// Money helpers. UI text is pt-BR style but the formatter is hand rolled so the
/// output stays identical on every locale and device.
public enum Money {
    /// "EUR 464,25" - thousands dot, decimal comma, no trailing ",00".
    public static func eur(_ value: Double) -> String {
        "EUR " + brNumber(value)
    }

    /// "R$ 10.000" - thousands dot, no decimals.
    public static func brl(_ value: Double) -> String {
        "R$ " + brNumber(value)
    }

    /// pt-BR number: dot as thousand separator, comma for cents. Rounds to 2 decimals.
    public static func brNumber(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        let negative = rounded < 0
        let absRounded = abs(rounded)
        let whole = Int(absRounded)
        let cents = Int(((absRounded - Double(whole)) * 100).rounded())
        var base = group(Int(whole))
        if cents > 0 {
            let cs = String(cents)
            base += "," + (cs.count == 1 ? "0" + cs : cs)
        }
        return negative ? "-" + base : base
    }

    private func _unused() {}

    /// "1.618" / "10.000" - thousands separated with dot.
    public static func group(_ whole: Int) -> String {
        var digits = String(whole)
        var out = ""
        while digits.count > 3 {
            let cut = digits.suffix(3)
            digits = String(digits.dropLast(3))
            out = "." + cut + out
        }
        return digits + out
    }

    /// Parse flexible input: "10.000", "1.234,56", "1234,56", "6,18", "6.18",
    /// "1234" -> Double. nil if invalid.
    public static func parse(_ raw: String) -> Double? {
        var cleaned = raw.trimmingCharacters(in: .whitespaces)
        cleaned = cleaned.replacingOccurrences(of: "R$ ", with: "")
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: "EUR ", with: "")
            .replacingOccurrences(of: "EUR", with: "")
        guard !cleaned.isEmpty else { return nil }
        guard cleaned.contains(where: { $0.isNumber }) else { return nil }

        if cleaned.contains(",") {
            // pt-BR: comma is the decimal separator; dots (if any) are thousand groups.
            cleaned = cleaned.replacingOccurrences(of: ".", with: "")
            if let lastComma = cleaned.lastIndex(of: ",") {
                let hi = cleaned.index(after: lastComma)
                cleaned = String(cleaned[..<lastComma]) + "." + String(cleaned[hi...])
            }
            return Double(cleaned)
        }

        if cleaned.contains(".") {
            let parts = cleaned.split(separator: ".", omittingEmptySubsequences: false)
            if parts.count > 2 {
                // "1.234.567" - repeated dots can only be thousand groups
                cleaned = parts.joined()
            } else if parts.count == 2, !parts[0].isEmpty, parts[0] != "0",
                      parts[0].count <= 3, parts[1].count == 3 {
                // "1.234" / "10.000" - whole thousand group (PWA reading)
                cleaned = parts.joined()
            } else {
                // "6.18" / "0.123" / "1234.56" - plain decimal dot, keep it
            }
        }
        return Double(cleaned)
    }
}
