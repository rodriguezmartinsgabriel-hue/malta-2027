import Foundation

/// Defaults ported 1:1 from the PWA (index.html). ASCII only, no accents, as approved.
public enum Seeds {
    public static let itinerary: [ItineraryDay] = [
        ItineraryDay(title: "Chegada em Malta - check-in em Valletta"),
        ItineraryDay(title: "Valletta a pe: fortalezas, Upper Barrakka, museus"),
        ItineraryDay(title: "Mdina e Rabat - a cidade silenciosa"),
        ItineraryDay(title: "Comino e Blue Lagoon de barco"),
        ItineraryDay(title: "Dia livre em Valletta: compras e rooftop"),
        ItineraryDay(title: "Gozo: ferry Mgarr + Victoria e cidadela"),
        ItineraryDay(title: "Gozo: Ramla Bay e Dwejra Bay"),
        ItineraryDay(title: "Marsaxlokk - mercado de domingo e luzzo coloridos"),
        ItineraryDay(title: "Sliema e ferry para Valletta ao anoitecer"),
        ItineraryDay(title: "Hagar Qim e Mnajdra - templos pre-historicos"),
        ItineraryDay(title: "Dia de praia: St Peter's Pool"),
        ItineraryDay(title: "Valletta: museu de Bellas Artes e Co-Catetral"),
        ItineraryDay(title: "Senglea e Birgu (As tres cidades)"),
        ItineraryDay(title: "Dia livre: dormir mais tarde e cafe"),
        ItineraryDay(title: "Golden Bay / Gnejna"),
        ItineraryDay(title: "Compras + lembrancinhas"),
        ItineraryDay(title: "Valletta gastronomia: pastizzi e ftira"),
        ItineraryDay(title: "Pre-embarque: arrumar as malas"),
        ItineraryDay(title: "Ultimo dia: passeio final e jantar de despedida"),
        ItineraryDay(title: "Embarque de volta"),
        ItineraryDay(title: "Chegada ao Brasil")
    ]

    public static func checklist() -> [ChecklistItem.Group: [ChecklistItem]] {
        [
            .docs: [
                ChecklistItem(text: "Passaporte valido de todas"),
                ChecklistItem(text: "ETIAS aprovado (travel-europe.europa.eu)"),
                ChecklistItem(text: "Seguro viagem Schengen (EUR 30 mil)"),
                ChecklistItem(text: "Passagens impressas e no celular"),
                ChecklistItem(text: "Reservas de hospedagem salvas offline"),
                ChecklistItem(text: "Copia digital dos documentos na nuvem"),
                ChecklistItem(text: "Carteira digital: cartao global fisico + virtual"),
                ChecklistItem(text: "Cartao de credito BR (backup) + aviso viagem")
            ],
            .mala: [
                ChecklistItem(text: "Adaptador UK (Tipo G)"),
                ChecklistItem(text: "Roupa de banho e saida"),
                ChecklistItem(text: "Sapato confortavel para andar"),
                ChecklistItem(text: "Casaco leve (noite fresca)"),
                ChecklistItem(text: "Protetor solar e labial"),
                ChecklistItem(text: "Remedio de uso continuo + receita"),
                ChecklistItem(text: "Carregador + power bank"),
                ChecklistItem(text: "Mochila pequena para passeios de barco"),
                ChecklistItem(text: "Documentos numa necessaire ziploc (praia)")
            ],
            .dinheiro: [
                ChecklistItem(text: "Abrir conta global (Wise ou C6)"),
                ChecklistItem(text: "Testar cartao com R$ 200-500"),
                ChecklistItem(text: "Declarar contas no IRPF de 2027"),
                ChecklistItem(text: "Converter CDI em 3-4 parcelas (a partir de jun/2027)"),
                ChecklistItem(text: "Revisar IOF 60-90 dias antes"),
                ChecklistItem(text: "Avisar os bancos da viagem"),
                ChecklistItem(text: "Definir aporte mensal no cofrinho")
            ]
        ]
    }

    public static let checklistGroups: [(index: Int, label: String)] = [
        (0, "Documentos"),
        (1, "Mala"),
        (2, "Dinheiro")
    ]

    /// Conversion paths: name, IOF, spread.
    public struct Preset: Hashable {
        public let name: String
        public let iof: Double
        public let spread: Double

        public init(name: String, iof: Double, spread: Double) {
            self.name = name
            self.iof = iof
            self.spread = spread
        }
    }

    public static let presets: [Preset] = [
        Preset(name: "Conta global - IOF 3,5% + spread 0,8%", iof: 0.035, spread: 0.008),
        Preset(name: "Wise Rende+ - IOF 1,1% + spread 0,7%", iof: 0.011, spread: 0.007),
        Preset(name: "Via investimento - IOF 1,1% + spread 2,0%", iof: 0.011, spread: 0.020),
        Preset(name: "Credito BR - IOF 3,5% + spread 4,0%", iof: 0.035, spread: 0.040)
    ]

    /// R$ -> EUR: you receive `amount * (1 - IOF) / (rate * (1 + spread))`.
    public static func brlToEur(_ amount: Double, rate: Double, preset: Preset) -> Double {
        guard preset.iof >= 0, preset.iof < 1, preset.spread >= 0 else { return 0 }
        guard rate > 0, amount >= 0 else { return 0 }
        return amount * (1 - preset.iof) / (rate * (1 + preset.spread))
    }
}
