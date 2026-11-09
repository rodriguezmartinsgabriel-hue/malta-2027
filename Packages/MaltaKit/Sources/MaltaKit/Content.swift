import Foundation

/// Marcos ate o embarque (aba Inicio). Texto ASCII como aprovado.
public struct Milestone: Identifiable, Hashable {
    public let id: Int
    public let title: String
    public let body: String

    public init(id: Int, title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}

public enum Milestones {
    public static let all: [Milestone] = [
        Milestone(id: 1, title: "Agora - novembro/2026",
                  body: "Abrir as contas internacionais e testar com R$ 200-500. Definir o aporte mensal."),
        Milestone(id: 2, title: "Fevereiro/2027",
                  body: "Declarar contas no exterior no IRPF de 2027 (Bens e Direitos)."),
        Milestone(id: 3, title: "Junho/2027 (~3 meses antes)",
                  body: "Comecar a converter o CDI para EUR em 3-4 parcelas mensais."),
        Milestone(id: 4, title: "Julho/2027 (60-90 dias antes)",
                  body: "Revisar IOF vigente e promocoes nos apps; avisar os bancos; pedir o ETIAS; contratar seguro."),
        Milestone(id: 5, title: "Agosto/2027",
                  body: "Testar os dois cartoes, imprimir passaportes e reservas, embarcar.")
    ]
}

/// Aba Dinheiro - resumo da pesquisa (research/01-comparativo).
public struct AccountRow: Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let eur: String
    public let cost: String
    public let opening: String

    public init(id: Int, name: String, eur: String, cost: String, opening: String) {
        self.id = id
        self.name = name
        self.eur = eur
        self.cost = cost
        self.opening = opening
    }
}

public let accountRows: [AccountRow] = [
    AccountRow(id: 1, name: "Wise Rende+", eur: "Sim, rende ~1,7% a.a.", cost: "~1,8-1,9%", opening: "Facil, 15 min"),
    AccountRow(id: 2, name: "C6 Conta Global", eur: "Sim", cost: "~4,3%", opening: "So p/ correntista C6"),
    AccountRow(id: 3, name: "Nomad", eur: "Sim (gradual)", cost: "~4,5-5,5%", opening: "Facil"),
    AccountRow(id: 4, name: "Revolut Standard", eur: "Sim", cost: "~0% no teto (R$ 1.000/mes)", opening: "Facil, mas suporte ruim"),
    AccountRow(id: 5, name: "Credito BR comum", eur: "So fatura em BRL", cost: "~7,5-9%", opening: "-")
]

public let moneyRecommendation = "Wise (Rende+) - menor custo, EUR rende ~1,7% a.a. e o IOF cai para 1,1% na conversao via Rende+. Abertura pelo app, so CPF. Segunda conta de confianca: Nomad (FDIC ate US$ 250 mil) ou Inter Global (RA1000, so USD), melhores para quem prioriza seguranca. Nenhuma delas tem FGC: e seguro escolher pela solidez e pelo custo, nao por \"garantia\"."

public let islandNote = "Pagamentos na ilha: cartao da conta global para tudo; dinheiro vivo so como imprevisto. ETIAS (autorizacao online) obrigatorio para brasileiros a partir de 2026/27 - pedir no site oficial travel-europe.europa.eu. Seguro viagem com cobertura medica de EUR 30 mil e exigencia Schengen."

public let footerNote = "Malta 2027 - feito para Nana & Dani. Pesquisa: TinyFish, nov/2026 - nao e conselho financeiro."

/// Aba Links.
public struct UsefulLink: Identifiable, Hashable {
    public let id: Int
    public let title: String
    public let subtitle: String
    public let url: String

    public init(id: Int, title: String, subtitle: String, url: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.url = url
    }
}

public let usefulLinks: [UsefulLink] = [
    UsefulLink(id: 1, title: "Visit Malta", subtitle: "Site oficial de turismo", url: "https://www.visitmalta.com/"),
    UsefulLink(id: 2, title: "Air Malta", subtitle: "Aerea nacional (KM 419)", url: "https://www.airmalta.com/"),
    UsefulLink(id: 3, title: "Gozo Channel", subtitle: "Ferry Malta - Gozo (Mgarr)", url: "https://www.gozochannel.com/"),
    UsefulLink(id: 4, title: "Tallinja", subtitle: "Onibus + cartao Tallinja", url: "https://tallinja.com/"),
    UsefulLink(id: 5, title: "ETIAS", subtitle: "Autorizacao online obrigatoria", url: "https://travel-europe.europa.eu/etias"),
    UsefulLink(id: 6, title: "Itamaraty", subtitle: "Consulado mais proximo: Roma (acreditado junto a Malta) - confirmar", url: "https://www.itamaraty.gov.br/")
]
