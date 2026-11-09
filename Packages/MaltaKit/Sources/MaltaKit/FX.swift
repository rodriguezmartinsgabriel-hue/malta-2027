import Foundation

/// Live EUR/BRL quote from open.er-api.com (free, no key, generous with tokenless use).
public struct FXQuote: Codable, Equatable {
    public let rate: Double
    /// e.g. "Wed, 29 Oct 2026 00:01:00 +0000"
    public let fetchedAt: Date

    public init(rate: Double, fetchedAt: Date = Date()) {
        self.rate = rate
        self.fetchedAt = fetchedAt
    }
}

public enum FXError: Error, Equatable {
    case badResponse
    case missingRate
}

public enum LiveFX {
    /// "https://open.er-api.com/v6/latest/EUR"
    public static let url = URL(string: "https://open.er-api.com/v6/latest/EUR")!

    /// Fetch EUR -> BRL. Throws FXError on a malformed payload.
    public static func fetch(session: URLSession = .shared) async throws -> FXQuote {
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        req.timeoutInterval = 15
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw FXError.badResponse
        }
        return try parse(data)
    }

    /// Shape: {"result":"success","rates":{"BRL": 6.18, ...}, ...}
    public static func parse(_ data: Data) throws -> FXQuote {
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rates = obj["rates"] as? [String: Any],
              let brl = rates["BRL"] as? Double, brl > 0
        else { throw FXError.missingRate }
        return FXQuote(rate: brl)
    }
}
