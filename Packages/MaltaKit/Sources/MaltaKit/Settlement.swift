import Foundation

/// One employee... no: one spending line in the OS budget - who paid what.
public struct Expense: Identifiable, Codable, Hashable, Equatable {
    public enum Payer: String, Codable, CaseIterable {
        case nana
        case dani
        case ambas
    }

    public var id: UUID
    public var desc: String
    public var eur: Double
    public var payer: Payer
    public var at: Date

    public init(id: UUID = UUID(), desc: String, eur: Double, payer: Payer, at: Date = Date()) {
        self.id = id
        self.desc = desc
        self.eur = eur
        self.payer = payer
        self.at = at
    }
}

/// Settlement of the OS budget. Consumption is always split 50/50;
/// "ambas" does not generate debt between the two.
public struct Settlement: Equatable {
    public let nanaPaid: Double
    public let daniPaid: Double
    /// positive: Dani owes Nana; negative: Nana owes Dani; |diff| < 0.5: settled.
    public let diff: Double

    public init(nanaPaid: Double, daniPaid: Double, diff: Double) {
        self.nanaPaid = nanaPaid
        self.daniPaid = daniPaid
        self.diff = diff
    }

    public var total: Double { nanaPaid + daniPaid }
    public var eachConsumed: Double { total / 2 }

    /// nil means "Quitado". (debtor, amount) otherwise.
    public var statement: (debtor: String, amount: Double)? {
        let abs = abs(diff)
        guard abs >= 0.5 else { return nil }
        // diff > 0 means Nana paid more overall, so Dani must pay half of the difference
        return diff > 0 ? ("Dani", abs / 2) : ("Nana", abs / 2)
    }
}

public enum SettlementEngine {
    public static func settle(_ expenses: [Expense]) -> Settlement {
        var nana = 0.0
        var dani = 0.0
        for e in expenses {
            switch e.payer {
            case .nana: nana += e.eur
            case .dani: dani += e.eur
            case .ambas: nana += e.eur / 2; dani += e.eur / 2
            }
        }
        return Settlement(nanaPaid: nana, daniPaid: dani, diff: nana - dani)
    }
}
