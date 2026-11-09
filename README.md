# Malta 2027

O guia interativo da viagem de Nana e Dani a Malta — 21 dias entre o fim de agosto e o início de setembro de 2027.

**Estado atual (09/11/2026):** PWA completa em `index.html` (HTML/CSS/JS vanilla, zero dependências além do Google Fonts, 43 KB). Roda em qualquer celular; offline via `sw.js` quando servida por HTTP(S). Instalar: Safari (iPhone) → Compartilhar → Adicionar à Tela de Início.

**Destino no Mac:** virar app iOS para as duas via Safari/Capacitor → Xcode → TestFlight, aproveitando a infra que já existe nos repos `analogik-ios` e `migalha-ios` (ver `HANDOFF-MAC.md` — **leia isso primeiro**).

## O que tem aqui

| Caminho | O que é |
|---|---|
| `index.html` | O app inteiro (6 seções: Início, Dinheiro, Orçamento, Roteiro, Checklist, Links) |
| `manifest.webmanifest` | PWA manifest (nome, ícones, standalone, cores) |
| `sw.js` | Service worker — cache do app shell (só ativa em HTTP/HTTPS) |
| `icon-192.png`, `icon-512.png`, `apple-touch-icon.png` | Ícones (estrela 8 pontas vinho sobre creme) |
| `HANDOFF-MAC.md` | O handoff para o agente do Mac — contexto, estado, QA, plano iOS e comandos |
| `research/` | Toda a pesquisa TinyFish que embasa o app (IOF, contas globais, tributos, confiança, roteiro) |

## Escopo da viagem

- Destino: Malta. 21 dias. Embarque 28/08/2027, retorno 17/09/2027 (editável no app).
- Orçamento total editável, default R$ 10.000 (~EUR 1.618 a 6,18).
- Dinheiro: IOF 3,5% (compra de moeda e cartão), 1,1% via investimento; nenhuma conta global tem FGC. Recomendação: Wise Rende+ (EUR rende ~1,7% a.a.) como principal; Nomad (FDIC) ou Inter Global (RA1000) como segunda conta. Detalhes em `research/`.
- As duas usam iPhone. Dados ficam no `localStorage` de cada aparelho (não sincronizam).

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

## Avisos

Não é conselho financeiro. IOF vive em liminar do STF (16/07/2025) sem referendo do Plenário — revisar alíquota 60–90 dias antes do embarque. Pesquisa de preços coletada via TinyFish em 09/11/2026.
