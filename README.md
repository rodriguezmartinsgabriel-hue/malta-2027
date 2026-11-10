# Malta 2027

> **PWA v2 (2026-11-09, branch `fix/pwa-aaa`)** - o `index.html` foi reescrito. O que vale agora:
> - **v3 (2026-11-09):** dois blocos, no aparelho (`malta2027:v3`) e no servidor: **compartilhado** (`malta_sync`: embarque, roteiro, checklist, diario, fotos, gastos juntas) e **pessoal** (`malta_private`: poupanca e gastos so meus, uma linha por conta, invisivel para a outra). Quem e Nana ou Dani vem do e-mail (`malta_members`), nao e escolha na tela. Juncao campo a campo com hora da ultima edicao e lapides para apagados (`mergeShared`/`mergePrivate`); Fotos do diario: copia em IndexedDB + bucket privado `malta-diary`. Realtime avisa o outro aparelho. Dados v1/v2 migram sozinhos.
> - Sync LIGADO (2026-11-09): `CONFIG` aponta para o projeto Supabase `malta-2027` (ref `gdwcpziredxssaqwwxtk`). Login por e-mail e senha (cada uma cria a conta e confirma pelo link do e-mail); o plano gratis nao deixa editar o template de e-mail, por isso nao e codigo de 6 digitos. So os dois e-mails da policy leem/gravam `malta_sync`. O sync junta os dois lados (`mergeState`) e roda sozinho.
> - `sw.js` proprio (sem Workbox): rede primeiro para o app, cache como reserva offline. Trocar `VERSION` ao mudar a lista de arquivos.
> - As secoes abaixo que citam "colar URL + anon key no sheet" e "link magico" descrevem a v1 e estao desatualizadas.

O guia interativo da viagem de Nana e Dani a Malta — 21 dias entre o fim de agosto e o início de setembro de 2027.

**Estado atual (11/11/2026):** a **PWA é o app principal** — `index.html` com UI Liquid Glass (cartões de vidro creme/vinho/oliva, dock flutuante de 6 itens, serifada Instrument nos números). HTML/CSS/JS vanilla. Roda em qualquer celular; offline robusto via **Workbox** (`sw.js`) quando servida por HTTP(S). Instalar: Safari (iPhone) → Compartilhar → Adicionar à Tela de Início.

**App nativo iOS (SwiftUI):** pronto no repo (`Apps/Malta/` + `Packages/MaltaKit/`), **pausado** até você ter a conta Apple Developer (US$ 99/ano) — sem ela, o nativo só roda por Xcode direto com certificado de 7 dias. Quando tiver a conta, o caminho é TestFlight (ver seção abaixo).

**Destino no Mac:** virar app iOS para as duas via Safari/Capacitor → Xcode → TestFlight, aproveitando a infra que já existe nos repos `analogik-ios` e `migalha-ios` (ver `HANDOFF-MAC.md` — **leia isso primeiro**).

## O que tem aqui

| Caminho | O que é |
|---|---|
| `index.html` | O app inteiro (6 seções: Início, Dinheiro, Orçamento, Roteiro, Checklist, Links) |
| `manifest.webmanifest` | PWA manifest (nome, ícones, standalone, cores) |
| `sw.js` | Service worker **Workbox** — app shell, mapa/tiles offline, dados (clima/FX) network-first |
| `icon-192.png`, `icon-512.png`, `apple-touch-icon.png` | Ícones (estrela 8 pontas vinho sobre creme) |
| `HANDOFF-MAC.md` | O handoff para o agente do Mac — contexto, estado, QA, plano iOS e comandos |
| `research/` | Toda a pesquisa TinyFish que embasa o app (IOF, contas globais, tributos, confiança, roteiro) |

## Escopo da viagem

- Destino: Malta. 21 dias. Embarque 28/08/2027, retorno 17/09/2027 (editável no app).
- Orçamento total editável, default R$ 10.000 (~EUR 1.618 a 6,18).
- Dinheiro: IOF 3,5% (compra de moeda e cartão), 1,1% via investimento; nenhuma conta global tem FGC. Recomendação: Wise Rende+ (EUR rende ~1,7% a.a.) como principal; Nomad (FDIC) ou Inter Global (RA1000) como segunda conta. Detalhes em `research/`.
- As duas usam iPhone. **Cada uma banca a própria viagem** (economia/meta pessoais por perfil) e viajam juntas: o que for dividido fica marcado como "juntas" (despesas com acerto 50/50), e cada uma pode lançar gastos "só meus". Roteiro, checklist e diário são compartilhados. Dados ficam no `localStorage` de cada aparelho; com Supabase configurado, sincronizam entre os dois iPhones.

## Como rodar local

```bash
python3 -m http.server 8793
# abrir http://localhost:8793/index.html
```

## QA (evidências em 09/11/2026)

- Playwright (viewport 390x844): todas as 6 abas renderizam; 0 erros no console (a única 404 era favicon de sessão antiga).
- Fluxo de despesas testado ponta-a-ponta: lançar 2 gastos (EUR 28,50 Nana + EUR 900 Dani) → consumo 50/50 = EUR 464,25 cada → acerto "Nana deve EUR 435,75".
- Bug de checklist (`undefined` em itens) encontrado e corrigido com migração de estado.
- `char_audit.py` (Lei Zero-Char): 0 ERROR na pasta. Código 100% ASCII de propósito.
- `android` não aplicável; as duas usam iPhone.


## Publicação (11/11/2026)

- **Link (Vercel, produção):** https://malta-2027-nine.vercel.app
- **Link anterior (GitHub Pages):** https://rodriguezmartinsgabriel-hue/malta-2027/ (repo público)
- **Acesso aos dados (segurança):** os **dados/sync da viagem** ficam restritos às duas contas quando o Supabase estiver configurado, via login (Google/link mágico) + RLS allowlist. E-mails autorizados no schema: `nataliacprestes@gmail.com` (Natália) e `danielalimags@outlook.com` (Dani). Sem Supabase configurado, o app funciona em modo local por aparelho (cada um vê só o seu). A casca do site é acessível a quem tiver o link; o que é protegido é o acesso aos dados compartilhados.

## Pesquisa open source (11/11/2026)

Via TinyFish (GitHub/Reddit): TREK (`liketrek/TREK`, planejador self-hosted), AdventureLog, `makinacorpus/maplibre-offline-pmtiles` (mapa offline PWA), Open-Meteo (clima sem chave), Frankfurter/ECB (câmbio sem chave), OSM/Nominatim (lugares sem chave), Workbox (offline). Inspiração de features; código implementado sob medida para a Malta 2027.

## Avisos

Não é conselho financeiro. IOF vive em liminar do STF (16/07/2025) sem referendo do Plenário — revisar alíquota 60–90 dias antes do embarque. Pesquisa de preços coletada via TinyFish em 09/11/2026.

---

# PWA — Liquid Glass (app principal) — 10/11/2026

A PWA ganhou a mesma UI do app nativo: cartões de vidro flutuando num fundo creme com halos vinho/oliva, dock cápsula de 6 itens, números em Instrument Serif e micro-interações (toggle de FX ao vivo, sheet de sync, anel de progresso).

## O que tem na PWA (11/11/2026)

- **Login/onboarding:** ao abrir o link, cada uma escolhe "Quem é você? Nana / Dani" (+ nome). Com Supabase configurado: **Entrar com Google** (OAuth) ou **link mágico por e-mail**; sem Supabase: entra em modo local e nada bloqueia.
- **Pessoal x juntas:** economia/meta (poupança/cofrinho) são **pessoais por perfil**. Gastos podem ser **"juntas"** (divididos, alimentam o acerto 50/50) ou **"só meu"** (pessoal de quem pagou, fora do acerto). Roteiro, checklist e diário são **compartilhados**.
- **Clima em Malta** (Inicio): previsão atual + 7 dias via **Open-Meteo** (sem chave, open source), cache 3h.
- **Mapa da viagem** (Roteiro): **MapLibre GL** com tiles **OpenStreetMap/OpenFreeMap** e pins dos dias do roteiro; busca de lugares em Malta via **Nominatim/OSM** (sem chave); botão "Abrir navegação". Tiles cacheados pelo Workbox para uso offline após o primeiro carregamento.
- **Diário da viagem** (Roteiro): nota por dia + fotos (comprimidas no aparelho; com sync ligado a nota do dia vai junto).
- **Exportar PDF:** botão em Orçamento gera a versão para impressão/PDF (roteiro dia a dia + orçamento + acerto).
- **FX ao vivo + backup:** `open.er-api.com` com cache 36h e fallback automático para **Frankfurter/ECB** (sem chave, BRL). Cotação manual continua disponível.
- **Sync Supabase:** avatar no topo do Inicio abre o sheet (URL + anon key + trip id `nana-dani`), tabela-blob `malta_sync` em `research/supabase/schema.sql`. Sem configuração, 100% local.
- **Offline (Workbox):** app shell, fontes, tiles do mapa e dados (clima/FX) com estratégias de cache; funciona sem internet depois do primeiro acesso.

## Rodar localmente

```bash
python3 -m http.server 8000   # na raiz do repo
# abrir http://localhost:8000
```

## Login e onboarding (10/11/2026)

Quem abre o link cai numa tela de onboarding: **"Quem é você? Nana / Dani"** + nome opcional. Isso identifica a pessoa em cada aparelho e grava o perfil local (localStorage).

- **Com Supabase configurado** (URL + anon key preenchidos no sheet de sync): aparecem também **"Entrar com Google"** e **"Enviar link de acesso"** (e-mail mágico). O perfil é vinculado ao e-mail da conta.
- **Sem Supabase configurado**: entra direto em modo local (perfil escolhido), e o sync continua 100% local até configurar.

### Ativar o login (2 minutos, dono: Gabriel)

1. Crie um projeto Supabase (gratis) — **um projeto novo, so da Malta** (nao reutilize o do Grude: a anon key da Malta vai para o repo publico).
2. Rode `research/supabase/schema.sql` no SQL Editor.
3. Em **Auth > Providers**: deixe **E-mail** ligado (magic link funciona sem configuracao extra). Para Google, ligue o provider Google e cole o Client ID/Secret.
4. Em **Auth > URL Configuration**: coloque a URL do site no **Site URL** e adicione-a aos **Redirect URLs**.
5. Em **Settings > API**, copie a **Project URL** e a **anon public key**.
6. Abra o app em cada iPhone uma vez, toque no avatar (canto superior direito do Inicio), cole URL + anon key no card Supabase e salve. A partir daí, o login aparece e o sync liga.

> A anon key fica no localStorage de cada aparelho (nao vai no repo de proposito). Se preferir embutir antes de publicar, preencha `window.MALTA_SUPABASE_URL` / `window.MALTA_SUPABASE_KEY` num `config.js` servido antes do app.

---

# App nativo iOS (SwiftUI) — pausado (09/11/2026)

O app foi portado para **nativo SwiftUI** e está pronto no repo. **Pausado por decisão do Gabriel (10/11/2026):** a PWA é o app principal enquanto não houver conta Apple Developer paga.

## Estado do app nativo

- `Apps/Malta/` — app SwiftUI completo (6 abas: Inicio, Dinheiro, Orcamento, Roteiro, Checklist, Links).
- `Packages/MaltaKit/` — pacote com dados/calculos/sync: `Money`, `Settlement`, `Trip`, `Seeds`, `LiveFX` (cotacao ao vivo `open.er-api.com`, cache 36h), `Supabase` (REST), `SyncMap`, `Content` (seeds das 4 contas + recomendacao).
- `Malta.xcodeproj` — **artefato gerado**: nunca editar o pbxproj a mao; a arvore vem de `tools/gen_project.py` (rodar `python3 tools/gen_project.py --check` falha se faltar arquivo).
- `Config/*.xcconfig` — build settings fora do pbxproj. `Config/Local.xcconfig` e git-ignored (SUPABASE_URL/ANON_KEY + DEVELOPMENT_TEAM).

## UI nativa (dialeto Apple)

- Estrutura = iOS nativo: `NavigationStack` + large title, `List/Form` insetGrouped, secoes nativas, tab bar translucida own-build com 6 items (UIKit colapsa >5 em "More").
- Tipografia = SF do sistema; **Instrument Serif** aparece so no hero do Inicio e nos numeros-chave (marca). Sem eyebrows, pills ou blocos decorativos (ex-slop da PWA).
- Paleta: fundo creme `#F6F3EA`, papel `#FFFEF9`, vinho `#722F37`, oliva `#5E6F35`.

## Sync Supabase (2 iPhones)

1. Criar projeto no Supabase (free) e rodar `research/supabase/schema.sql`.
2. No app: botao no topo do Inicio > colar URL + anon key + trip id (`nana-dani`) > Salvar e conectar. Ou preencher `Config/Local.xcconfig` (compila embutido).

## Build/run no Mac

```bash
xcodebuild -project Malta.xcodeproj -scheme Malta \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
APP=$(ls -d ~/Library/Developer/Xcode/DerivedData/Malta-*/Build/Products/Debug-iphonesimulator/Malta.app | head -1)
xcrun simctl install "UDID" "$APP" && xcrun simctl launch "UDID" app.malta.nana
```

Smoke de aba via env: `SIMCTL_CHILD_MALTA_TAB=dinheiro xcrun simctl launch ... app.malta.nana`.

## Testes

`cd Packages/MaltaKit && swift test` — 19 testes verdes (inclui regressao do parse pt-BR "10.000" e conversor QA da PWA).

## Pendencias (dono: Gabriel) — nativo pausado

- [ ] Conta Apple Developer (US$ 99/ano) — requisito para destravar o nativo (TestFlight).
- [ ] Bundle ID final (hoje `app.malta.nana`) — confirmar antes do ASC.
- [ ] Chaves ASC (ASC_KEY_ID / ASC_ISSUER_ID / .p8 / APPLE_TEAM_ID) para TestFlight.
- [ ] SUPABASE_URL + ANON_KEY para ativar o sync (serve para PWA **e** nativo).
- [ ] Development Team (Free Team hoje) para assinar nos aparelhos reais.
