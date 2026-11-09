# HANDOFF-MAC — Malta 2027

> Para o agente do OpenCode no Mac que vai assumir daqui. Leia isto antes de qualquer coisa.
> Última atualização: 2026-11-09 (sessão no Windows, repo recém-publicado).
> Quem escreve: agente Windows. Quem lê: você no Mac.

## Contexto em 30 segundos

Malta 2027 é o guia da viagem de **Nana** (namorada do Gabriel) e **Dani**. 21 dias em Malta entre o fim de agosto e o início de setembro de 2027 (28/08 → 17/09). Orçamento total default **R$ 10.000** (~EUR 1.618 a EUR/BRL 6,18). As duas usam **iPhone**. O Gabriel quer: (1) trabalhar no Mac, (2) aproveitar a infra que já existe nos repos `analogik-ios` e `migalha-ios`, (3) entregar o app para as duas o mais fácil possível.

## Estado atual do projeto

**A PWA está pronta e testada** — não reimplemente do zero.

```
Malta 2027/
├── index.html            (o app inteiro: 6 abas, CSS+JS inline, ~43 KB)
├── manifest.webmanifest  (PWA install manifest)
├── sw.js                 (service worker, offline shell, cache-first)
├── icon-192.png / icon-512.png / apple-touch-icon.png
├── README.md             (estado + QA)
├── HANDOFF-MAC.md        (este arquivo)
├── research/             (a pesquisa completa que embasa Dinheiro/Orçamento)
└── (research = cópia de D:\projetos\sem-nome\Viagem Nana\, portada junto)
```

### O app (`index.html`)

- Vanilla HTML/CSS/JS, zero framework, zero build. Só dependência externa: Google Fonts (Instrument Serif + Instrument Sans, com fallbacks de sistema).
- Paleta (editorial "elegante editorial", a escolhida pelo Gabriel): fundo creme `#f7f4ec`, papel `#fffdf6`, tinta quente `#241f1c`, vinho `#722f37` (acento principal), oliva `#5e6f35` (ação secundária / progresso).
- **Lei Zero-Char**: código 100% ASCII. Comentários, ids e strings de código em ASCII. Texto de UI também foi mantido sem acentos de propósito (`#722f37`, sem `ó`). Não "corrija" adicionando acentos em `.html` — a auditoria (`char_audit.py`) bloqueia a entrega. `.md` pode ter acentos.
- 6 abas (nav inferior fixa, 48px, `safe-area-inset-bottom`): **Início** (contagem regressiva, cofrinho mensal projetado, meta editável, marcos até o embarque), **Dinheiro** (essência da pesquisa + conversor R$→EUR ao vivo com 4 caminhos), **Orçamento** (gastos com pagador Nana/Dani/Dividido, consumo 50/50, acerto automático), **Roteiro** (21 dias datados do embarque, títulos/notas editáveis, sugestão inicial de Malta/Gozo/Comino), **Checklist** (24 itens em Documentos/Mala/Dinheiro — inclui ETIAS, adaptador Tipo G, seguro Schengen EUR 30 mil), **Links** (Visit Malta, Air Malta, Gozo Channel, Tallinja, ETIAS, Itamaraty, 112).
- Persistência: `localStorage` com prefixo `malta2027:` — chaves: `fx`, `meta`, `monthly`, `start`, `expenses` (array de `{desc, eur, payer: 'nana'|'dani'|'ambas', at}`), `itinerary` (array de `{title, note, done}`), `checklist` (`{docs|mala|dinheiro: [{text, done}]}`), `tab`.
- Seeds ficam no JS (`CHECK_SEED`, `ITINERARY_SEED`, `PRESETS`, `TRIP_START = '2027-08-28'`). Editáveis pelo usuário; se o Gabriel quiser mudar defaults, é no seed + `store.get` fallback.

### QA feito (09/11/2026, viewport 390x844)

- Todas as 6 abas renderizam. **0 erros no console.**
- Fluxo de despesas ponta-a-ponta verificado: 2 gastos (EUR 28,50 Nana / EUR 900 Dani) → consumo EUR 464,25 cada → acerto "Nana deve EUR 435,75".
- Bug conhecido e já corrigido: itens "undefined" na checklist (seed não estava normalizado) + migração de estado para dados antigos no localStorage.
- `char_audit.py` na pasta: **0 ERROR** (resultado: LIMPO).
- Manifest servido como `application/manifest+json`; SW como `text/javascript` (python http.server).

## O que precisa fazer no Mac (em ordem de valor)

### Caminho recomendado (o mais rápido para as duas terem no bolso): PWA instalada + Capacitor → TestFlight

O Gabriel escolheu iPhone para as duas. Há dois caminhos para "app de verdade" no iPhone além do Safari:

**Opção A (recomendada): Capacitor wrap.** Reaproveita 100% do `index.html`:

```bash
cd ~/Developer/malta-2027
npm create vite@latest .   # ou: npm init -y && npm install @capacitor/core @capacitor/cli
npm install @capacitor/core @capacitor/ios
npx cap init "Malta 2027" app.malta.nana --web-dir=. ?  # webDir = raiz dos arquivos estáticos
npx cap add ios
npx cap sync
```

Detalhe: como a PWA não tem `node_modules` nem build, tratar o diretório raiz como web assets e apontar `webDir` para `.` funciona. Alternativa limpa: mover o app para `web/` e usar `webDir: 'web'`.

**Opção B: reescrever em SwiftUI**, copiando o padrão de `analogik-ios`/`migalha-ios` (ver abaixo). Mais barato enquanto o app é pequeno, mas retrabalho de tudo que já está pronto e testado. Só se o Gabriel quiser polimento nativo sério (Widgets, Live Activity da contagem regressiva, Apple Pay…).

**Decisão pendente do Gabriel:** A ou B? Default sugerido = **A (Capacitor)**, porque: zero reescrita, TestFlight com a mesma esteira já usada nos outros apps, e a PWA continua funcionando no navegador se um dia precisar.

### TestFlight / distribuição (o padrão que já funciona nos outros repos)

`analogik-ios/README.md` e `migalha-ios` têm a receita comprovada:

1. App Store Connect → criar o app (bundle id, ex.: `app.malta.nana` ou `com.analogiklabs.malta`).
2. App Store Connect API → chave Admin → baixar `.p8` → gerar `ASC_KEY_P8_BASE64`.
3. GitHub Actions: copiar o workflow `.github/workflows` de `analogik-ios` (TestFlight manual trigger, Xcode no runner `macos-15`/`macos-26`). Secrets: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64`, `APPLE_TEAM_ID`.
4. TestFlight → rodar workflow → build chega no app dele em 15–30 min → distribuir para Nana e Dani (TestFlight externo com e-mails delas).

Se for Capacitor: o workflow precisa de `npm ci && npx cap sync` antes do build.

### Alternativa sem store (zero custo): PWA pelo Safari

Se o Gabriel desistir da App Store: as duas abrem no Safari → **Compartilhar → Adicionar à Tela de Início**. O ícone já está pronto (`apple-touch-icon.png`). Perde: push notification real (Web Push no iOS 16.4+ funciona mas é frágil), Live Activities, atalho com badge.

## O que falta / dívida consciente

1. **Sync entre os dois iPhones**: hoje `localStorage` é por aparelho — cada uma vê os dados do próprio celular (orçamento 50/50 só fica igual se as duas lançarem os mesmos gastos, ou uma for a "dona" dos lançamentos). Se quiser acerto 100% compartilhado: trocar `localStorage` por Supabase (`migalha` já usa `@supabase/supabase-js` — copiar o padrão de auth/RLS de lá) ou CloudKit. Decisão do Gabriel; manter mínimo enquanto não pedir.
2. **Câmbio fixo 6,18**: FX é editável no app mas fica gravado no aparelho; não há cotação automática. Se quiser FX ao vivo: API pública gratuita (ex.: open.er-api.com) via fetch no `loadFx()`.
3. **Conteúdo de roteiro**: é sugestão inicial de Malta/Gozo/Comino/Marsaxlokk — a dupla precisa revisar e marcar o que fica (tudo editável no app).
4. **QA de iOS real**: nenhum teste em WKWebView real do iPhone ainda — fazer na primeira rodada no Mac (Safari > Web Inspector).
5. **Push notification de lembretes** ("faltam 30 dias — converta o CDI"): None. Só com app nativo ou Web Push no iOS 16.4+.
6. `sw.js` só registra em HTTP/HTTPS — funciona quando hospedado; não funciona abrindo `file://`.
7. O diretório `Malta 2027/` está dentro do repo git `sem-nome` (D:\projetos\sem-nome) — agora tem `.git` próprio dentro dele; o Gabriel pode querer remover o gitlink no pai ou ignorar.

## Decisões já tomadas (não reabrir sem motivo)

- Escopo: as 6 abas — dinheiro, orçamento, roteiro, checklist, cofrinho, links. Nada além disso sem pedido.
- Dinheiro: IOF 3,5% (remessa própria, cartão, espécie) e 1,1% (investimento). **Nenhuma conta global tem FGC** — por isso recomendação Wise (custo+rendimento) principal, Nomad/Inter como backup de confiança. Ver `research/04-investindo-em-euro.md` e `research/05-confiabilidade.md`.
- Rota recomendada para acumular: ~R$ 2–4 mil em conta global EUR desde já (Wise Rende+, IOF 1,1%) + resto em Tesouro Selic/CDB convertendo parcelado nos 3–6 meses pré-embarque.
- Tipografia: Instrument Serif (display) + Instrument Sans (texto) + ui-monospace (dados). Paleta creme/vinho/oliva. iOS fará fallback para sistema nativo de qualquer forma.
- Nome: **Malta 2027** (era "Viagem Nana"; renomeado a pedido do Gabriel quando Dani entrou no plano).
- Dados: localStorage, sem backend. Sincronização = decisão futura do Gabriel.

## Como validar no Mac (antes de subir qualquer coisa para TestFlight)

```bash
cd ~/Developer/malta-2027
python3 -m http.server 8793
open http://127.0.0.1:8793/    # ou o Safari com o Simulador
```

- `python3` serve com MIME types corretos (manifest `application/manifest+json`, `sw.js` `text/javascript`) — mesma ferramenta usada no Windows; em ambos funcionou.
- Checar console do Safari (Develop > Show Web Inspector): **0 erros** na sessão de 09/11/2026.
- Testar de verdade no iPhone dela via TestFlight antes de mandar para as duas.

## Se algo quebrar: onde procurar

- Conversão EUR/BRL errada → `PRESETS` e `fx()` no `index.html` (FX default 6,18; gravado em `malta2027:fx`).
- Acerto de contas errado → `settlement()` (moeda única; cada item conta metade para cada uma; `ambas` não gera dívida).
- Checklist quebrada em dados antigos → `checklistState()` já normaliza strings vindas de versões passadas.
- Roteiro não muda junto com a data de embarque → `renderCountdown()` lê `malta2027:start` e `renderItinerary()` recalcula as datas.
- IA não: "AP no Safari" = PWA, não há servidor. Se o Gabriel quiser cotação FX ou sync, virar fetch HTTP normal.

## O que eu faria na sequência (sugestão, não obrigação)

1. Gabriel confirma A (Capacitor) ou B (SwiftUI).
2. Se A: `npx cap init` + `npx cap add ios` + abrir no Xcode, escolher o Team, build no device real.
3. Rodar 1 semana no aparelho do Gabriel (ele é o "dono do app"), polir.
4. Criar o workflow de TestFlight (copiar de `analogik-ios`), subir, distribuir para Nana e Dani.
5. Só depois: FX ao vivo, sync, push. Sempre com a regra do escopo mínimo.
