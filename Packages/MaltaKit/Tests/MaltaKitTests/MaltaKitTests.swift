import XCTest
@testable import MaltaKit

final class test_money_formato_ponto_e_virga: XCTestCase {
    func test_eur_decimal_como_pwa() {
        XCTAssertEqual(Money.eur(464.25), "EUR 464,25")
        XCTAssertEqual(Money.eur(1_618.0), "EUR 1.618")
    }

    func test_brl_milhares() {
        XCTAssertEqual(Money.brl(10_000), "R$ 10.000")
        XCTAssertEqual(Money.brl(928.5), "R$ 928,50")
    }

    func test_parse_aceita_variants() {
        XCTAssertEqual(Money.parse("1.234,56"), 1234.56)
        XCTAssertEqual(Money.parse("1234,56"), 1234.56)
        XCTAssertEqual(Money.parse("1234.56"), 1234.56)
        XCTAssertEqual(Money.parse("1234"), 1234)
        XCTAssertNil(Money.parse("abc"))
        XCTAssertNil(Money.parse("   "))
    }

    func test_parse_milhares_ponto_grupo_regresso_10000() {
        // regressao do smoke test: "10.000" foi interpretado como dez
        XCTAssertEqual(Money.parse("10.000"), 10_000)
        XCTAssertEqual(Money.parse("1.234"), 1_234)
        XCTAssertEqual(Money.parse("123.456.789"), 123_456_789)
    }

    func test_parse_decimal_ponto_virgula_ok() {
        XCTAssertEqual(Money.parse("6,18"), 6.18)
        XCTAssertEqual(Money.parse("6.18"), 6.18)
        XCTAssertEqual(Money.parse("0.123"), 0.123)
        XCTAssertEqual(Money.parse("R$ 10.000"), 10_000)
        XCTAssertEqual(Money.parse("EUR 464,25"), 464.25)
    }
}

final class test_settlement_acerto_50_50: XCTestCase {
    func test_cenario_do_qa_da_pwa_nana_deve_quatrocentos() {
        // QA PWA: 2 gastos (EUR 28,50 Nana + EUR 900 Dani) ->
        // consumo 464,25 cada -> "Nana deve EUR 435,75".
        let s = SettlementEngine.settle([
            Expense(desc: "Transfer", eur: 28.50, payer: .nana),
            Expense(desc: "Hospedagem", eur: 900, payer: .dani)
        ])
        XCTAssertEqual(s.total, 928.5, accuracy: 0.001)
        XCTAssertEqual(s.eachConsumed, 464.25, accuracy: 0.001)
        XCTAssertEqual(s.statement?.debtor, "Nana")
        XCTAssertEqual(s.statement!.amount, 435.75, accuracy: 0.001)
    }

    func test_quitado_quando_aproximadamente_zero() {
        let s = SettlementEngine.settle([
            Expense(desc: "cafe", eur: 10, payer: .ambas)
        ])
        XCTAssertNil(s.statement)
    }

    func test_dani_deve_quando_nana_pagou_mais() {
        let s = SettlementEngine.settle([
            Expense(desc: "restaurante", eur: 100, payer: .nana)
        ])
        XCTAssertEqual(s.statement?.debtor, "Dani")
        XCTAssertEqual(s.statement!.amount, 50, accuracy: 0.001)
    }

    func test_ambas_nao_gera_divida() {
        let s = SettlementEngine.settle([
            Expense(desc: "ferry", eur: 40, payer: .ambas),
            Expense(desc: "outro ferry", eur: 40, payer: .ambas)
        ])
        XCTAssertNil(s.statement)
    }
}

final class test_trip_datas_e_conversor: XCTestCase {
    func test_conversor_match_do_html() {
        // PWA: 10000 BRL, rate 6.18, preset global (IOF 3,5% + spread 0,8%)
        let got = Seeds.brlToEur(10_000, rate: 6.18, preset: Seeds.presets[0])
        XCTAssertEqual(got, 1_549.0959, accuracy: 0.01)
    }

    func test_seeds_portados() {
        XCTAssertEqual(Seeds.itinerary.count, 21)
        let cc = Seeds.checklist()
        XCTAssertEqual(ChecklistItem.Group.allCases.count, 3)
        XCTAssertEqual(cc[.docs]!.count, 8)
        XCTAssertEqual(cc[.mala]!.count, 9)
        XCTAssertEqual(cc[.dinheiro]!.count, 7)
        XCTAssertEqual(Seeds.presets.count, 4)
    }

    func test_cofrinho_projeta_aportes() {
        // monthsUntil(+1) aportes; 800/mes por 21 meses ate 28/08/2027 a partir de 09/11/2026
        let now = Trip.date(fromISO: "2026-11-09")
        let months = monthsUntil(start: Trip.date(fromISO: "2027-08-28"), from: now)
        XCTAssertEqual(months, 9) // nov/26 -> ago/27
        XCTAssertEqual(projected(monthly: 800, months: months), 8_000)
    }

    func test_weekday_e_daymonth_labels() {
        let d = Trip.date(fromISO: "2027-08-28")
        XCTAssertEqual(Trip.weekdayLabel(for: d), "SAB")
        XCTAssertEqual(Trip.dayMonthLabel(for: d), "28/08")
    }

    func test_fx_parse_do_payload_erapi() {
        let json = """
        {"result":"success","rates":{"BRL": 6.1877, "USD": 1.08}}
        """
        let q = try! LiveFX.parse(Data(json.utf8))
        XCTAssertEqual(q.rate, 6.1877, accuracy: 0.0001)
    }

    func test_fx_parse_falha_sem_brl() {
        let json = """
        {"result":"success","rates":{"USD": 1.08}}
        """
        XCTAssertThrowsError(try LiveFX.parse(Data(json.utf8)))
    }
}

final class test_supabase_map_codificacao: XCTestCase {
    func test_expense_roundtrip() throws {
        let e = Expense(desc: "Jantar", eur: 33.10, payer: .ambas)
        let rows = SyncMap.expenseRows([e], tripID: "viagem")
        let back = SyncMap.decodeExpenses(rows)
        XCTAssertEqual(back.count, 1)
        XCTAssertEqual(back[0].desc, "Jantar")
        XCTAssertEqual(back[0].eur, 33.10)
        XCTAssertEqual(back[0].payer, .ambas)
    }

    func test_itinerary_roundtrip_ordem_preservada() {
        let days = [ItineraryDay(title: "d1"), ItineraryDay(title: "d2"), ItineraryDay(title: "d3")]
        let rows = SyncMap.itineraryRows(days, tripID: "viagem")
        // shuffle the payload, decode must restore order by idx
        let shuffled = Array(rows.shuffled())
        let back = SyncMap.decodeItinerary(shuffled)
        XCTAssertEqual(back.map(\.title), ["d1", "d2", "d3"])
    }

    func test_checklist_roundtrip() {
        var groups: [ChecklistItem.Group: [ChecklistItem]] = [:]
        groups[.docs] = [ChecklistItem(text: "Passaporte valido")]
        groups[.mala] = [ChecklistItem(text: "Adaptador UK (Tipo G)")]
        let rows = SyncMap.checklistRows(groups, tripID: "viagem")
        let back = SyncMap.decodeChecklist(rows)
        XCTAssertEqual(back[.docs]?.first?.text, "Passaporte valido")
        XCTAssertEqual(back[.mala]?.first?.text, "Adaptador UK (Tipo G)")
    }

    func test_config_do_bundle_fica_nil_com_placeholders() {
        XCTAssertNil(SupabaseConfig.fromBundle(Bundle(for: BundleProbe.self)))
    }
}

final class BundleProbe {}
