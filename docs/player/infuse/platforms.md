---
titulo: "Diferenças por plataforma: iOS/iPadOS, tvOS, macOS, visionOS"
parte_de: "docs/player/infuse"
objetivo: "Detalhar o suporte do esquema infuse:// e dos mecanismos de detecção/abertura/callback em cada plataforma Apple, com foco especial no tvOS (alvo do StreamHub)."
ordem: 3
tipo: referencia
relevancia_para_streamhub: alta
atualizado_em: "2026-06-24"
fontes_oficiais:
  - "https://support.firecore.com/hc/en-us/articles/215090997-API-for-Third-Party-Apps-Services"
  - "https://developer.apple.com/documentation/uikit/uiapplication/canopenurl(_:)"
fontes_comunidade:
  - "https://community.firecore.com/t/apple-tv-infuse-deep-links/56876"
  - "https://community.firecore.com/t/add-x-callback-url-schemes-on-apple-tv/34181"
  - "https://community.firecore.com/t/x-callbacks/59502"
versao_infuse_referencia: "8.4.7+"
---

# Diferenças por plataforma

## TL;DR

- O StreamHub é um app **tvOS** (ver `docs/addons/README.md`). Portanto, a coluna **tvOS** é a que mais importa.
- **Estado atual (Infuse 8.4.7+):** a página oficial lista **todas** as plataformas como suportadas para a API: *"Available platforms: iPhone, iPad, Apple TV, Mac, and Vision"*. Ou seja, **`infuse://x-callback-url/play` e os deep links TMDB são oficialmente suportados em Apple TV agora**.
- **Mas há histórico e caveats:** a API começou **iOS-only** (Infuse 7.6.2). Deep links TMDB no tvOS só passaram a funcionar no **Infuse 8.2.3** (antes disso davam erro de demuxing). E há um caveat de plataforma (Apple) na **detecção** (`canOpenURL`) e no **handling de callbacks** em tvOS.
- O ponto sensível para o StreamHub **não é o Infuse** receber a URL (ele recebe), e sim o **lado do tvOS**: `canOpenURL`/`open` entre apps e o recebimento do callback em tvOS exigem cuidado e validação em device real.

---

## 1. Matriz de suporte

| Recurso | iOS | iPadOS | tvOS (Apple TV) | macOS | visionOS |
|---|---|---|---|---|---|
| `infuse://x-callback-url/play` | Sim | Sim | **Sim** (8.4.7+; historicamente iOS-only) | Sim | Sim |
| `infuse://x-callback-url/save` | Sim | Sim | Sim | Sim | Sim |
| Deep links TMDB `infuse://movie|series/...` | Sim | Sim | **Sim, a partir de 8.2.3** | Sim | Sim |
| Callbacks `x-success`/`x-error` | Sim | Sim | Sim (lado Infuse) — **receber no app de origem: validar** | Sim | Sim |
| Detecção via `canOpenURL` | Sim (c/ `LSApplicationQueriesSchemes`) | Sim | **Sim, com caveats** (ver §3) | Sim (AppKit) | Sim |

Fonte da linha "Available platforms": https://support.firecore.com/hc/en-us/articles/215090997-API-for-Third-Party-Apps-Services
(verbatim: *"Available platforms: iPhone, iPad, Apple TV, Mac, and Vision"* / *"Infuse version: 8.4.7 (or later)"*)

---

## 2. Histórico de versões (de onde veio cada coisa)

Relevante porque usuários com Infuse antigo terão comportamento diferente.

| Versão Infuse | Data | Mudança relevante | Tier |
|---|---|---|---|
| **7.6.2** | 2023-10-31 | Primeira API para apps de terceiros (play, bookmark, save) — **iOS**. | [COMUNIDADE — staff james] |
| **8.1** | 2025-02-18 | Suporte a arquivos `.STRM`. | [OFICIAL release notes] |
| **8.1.4** | 2025-04-22 | Arquivos `.STRMLNK` (link p/ serviços externos). | [OFICIAL release notes] |
| **8.2** | 2025-07-22 | Deep links TMDB (`infuse://movie/...`, `series/...`, episódios). | [OFICIAL release notes] |
| **8.2.3** | 2025-08-26 | Deep links TMDB passam a funcionar **no tvOS**. | [COMUNIDADE — staff james] |
| **8.4.4** | 2026-05-05 | "API additions for metadata, playback, downloads, and playlists". | [OFICIAL release notes] |
| **8.4.6** | 2026-06-05 | "Send and receive playback positions via x-callback-url" (i.e. `position` no callback). | [OFICIAL release notes] |
| **8.4.7** | 2026-06-16 | Versão fixada pela página oficial da API. | [OFICIAL] |

Fontes:
- Release notes oficiais: https://firecore.com/releases
- iOS 7.6.2 (staff): https://community.firecore.com/t/add-x-callback-url-schemes-on-apple-tv/34181
- tvOS deep links 8.2.3 (staff): https://community.firecore.com/t/apple-tv-infuse-deep-links/56876

> **Implicação p/ StreamHub:** exigir **Infuse 8.4.7+** para a experiência completa (incl. `position`/resume bidirecional e Apple TV). Em versões anteriores, partes do fluxo (resume via callback, deep links no tvOS) podem não existir. Ver [limitations.md](./limitations.md).

---

## 3. tvOS — o caso do StreamHub (detalhe)

### 3.1. O Infuse no tvOS aceita o esquema?

**Sim, no Infuse atual.** A página oficial lista "Apple TV" e fixa 8.4.7+. Lançar a reprodução de uma URL HTTP(S) remota no Apple TV a partir de outro app tvOS via `infuse://x-callback-url/play?url=...` é **oficialmente suportado agora**.

### 3.2. Histórico: deep links TMDB eram quebrados no tvOS

- **[COMUNIDADE]** mrfatboy, 2025-08-07: testou `infuse://movie/842924` no Apple TV e recebeu o erro *"Failed to open input stream in demuxing stream"*, enquanto o **mesmo link funcionava no iPhone**.
- **[COMUNIDADE — staff james]**, 2025-08-07: *"Deep links are not yet supported on Apple TV but these will be available in one of the next updates."*
- **[COMUNIDADE — staff james]**, 2025-08-26: *"This is now available in Infuse 8.2.3"* — capacidade nova: *"Deep link to movies, series, and episodes using TMDB IDs (tvOS)."*
- Fonte: https://community.firecore.com/t/apple-tv-infuse-deep-links/56876

> Conclusão: deep links TMDB no tvOS só são confiáveis a partir de 8.2.3. Para o StreamHub isso é secundário (usaremos `/play`, não deep link TMDB), mas é sinal de que **funcionalidades chegam ao tvOS depois do iOS**.

### 3.3. Caveat de plataforma (Apple): detecção e abertura entre apps no tvOS

Este é o ponto que exige atenção do **lado do StreamHub** (não do Infuse).

**`canOpenURL` no tvOS:** a mesma regra do iOS se aplica — retorna `false` se o esquema não estiver em `LSApplicationQueriesSchemes`. Apps tvOS **podem** consultar/abrir esquemas custom de outros apps **se o esquema estiver whitelisted**. Mas:

- **[OFICIAL Apple]** Na doc do `canOpenURL`, a linha de disponibilidade lista *"iOS 3.0+ · iPadOS 3.0+ · Mac Catalyst 13.1+ · tvOS · visionOS 1.0+"* — note que **`tvOS` aparece sem número de versão**, diferente de todas as outras plataformas. A API existe no tvOS, mas a documentação da Apple é magra/atípica nesse ponto. Fonte: https://developer.apple.com/documentation/uikit/uiapplication/canopenurl(_:)
- **[COMUNIDADE / 3rd-party]** O `LSApplicationQueriesSchemes` afeta **apenas** `canOpenURL`, **não** `openURL` — em qualquer plataforma. `canOpenURL` só checa esquemas listados no Info.plist e **não** consegue checar Universal Links. (Branch tvOS integration; useyourloaf.com.)
- **NÃO CONFIRMADO (verbatim Apple):** não há afirmação oficial de que o tvOS **restrinja adicionalmente** `openURL`/`canOpenURL` entre apps além da regra padrão do whitelist. O comportamento documentado é o mesmo do iOS; a única anomalia é o badge de versão ausente. **Validar em device real** (ver §3.5).

### 3.4. Caveat: handoff entre apps que NÃO é deep link de mídia

Separado do `/play`: ao abrir um item de serviço externo (via `.strmlnk`) cuja origem é outro app de streaming, o botão "Open" no tvOS pode **só abrir a home do app de destino**, sem aprofundar no item:

- **[COMUNIDADE]** c-mac, 2026-04-06: *"...clicking the 'open' button on a details page in Infuse did in fact open the TV app, but only to the homepage of course."* — Fonte: https://community.firecore.com/t/x-callbacks/59502

> Isso é uma limitação do **app de destino** (suporte a deep link dele), **não** do `infuse://...play`. Mencionado aqui só para não confundir os dois cenários.

### 3.5. Recomendação prática para o StreamHub (tvOS)

1. **Validar em Apple TV físico** (não só simulador) três coisas:
   - `canOpenURL("infuse://")` retorna `true` com `infuse` no `LSApplicationQueriesSchemes`.
   - `open("infuse://x-callback-url/play?url=...")` lança o Infuse e inicia a reprodução.
   - O Infuse consegue **voltar** ao StreamHub via `x-success` (entrega do callback em tvOS).
2. Ter **fallback** sempre pronto: se a detecção/abertura/callback falhar no tvOS, cair no **player nativo** do StreamHub.
3. **Alternativa file-based:** se o esquema/handoff se mostrar instável no tvOS, considerar `.STRM` (Infuse toca a URL HTTP(S) direto a partir da biblioteca, sem depender de cross-app launch). Ver [limitations.md](./limitations.md) §"Workarounds" e o resumo de STRM/STRMLNK no [README.md](./README.md).

---

## 4. iOS / iPadOS

- Plataforma de referência da API (foi a primeira a ganhá-la, em 7.6.2). Tudo funciona conforme [url-schemes.md](./url-schemes.md) e [integration-guide.md](./integration-guide.md).
- Detecção: `LSApplicationQueriesSchemes` + `UIApplication.canOpenURL` (limite de 50 chamadas — cachear).
- Abertura: `UIApplication.shared.open(_:)`.
- Callback: `onOpenURL` (SwiftUI) ou `application(_:open:options:)` (UIKit).

---

## 5. macOS

- A API é listada como suportada ("Mac"). **[a validar]** os mecanismos de **detecção/abertura** no macOS são via **AppKit** (`NSWorkspace.open(_:)`), não `UIApplication` — adapte o código do [integration-guide.md](./integration-guide.md) se for dar suporte a macOS.
- `LSApplicationQueriesSchemes` é um conceito de iOS; no macOS a abertura por esquema funciona via `NSWorkspace`/Launch Services sem o mesmo gating. Detecção de "app instalado por esquema" no macOS usa `NSWorkspace.urlForApplication(toOpen:)`. **[a validar]** detalhes — fora do escopo do StreamHub (tvOS), documentado só por completude.
- Observação: o Infuse para Mac pode ser a versão **Apple Silicon nativa** ou rodar o app iPad em Macs Apple Silicon; comportamento do esquema **[a validar]** nesse último caso.

---

## 6. visionOS

- Listado como suportado ("Vision"). Compartilha o stack UIKit/SwiftUI do iPadOS; o padrão do [integration-guide.md](./integration-guide.md) deve valer. **Fora do escopo do StreamHub** — documentado só por completude. Sem validação específica.

---

## 7. Resumo de risco por plataforma (para o StreamHub)

| Plataforma | Risco da integração | Ação |
|---|---|---|
| **tvOS** (alvo) | **Médio** — esquema oficialmente suportado, mas detecção/abertura/callback entre apps no tvOS precisam de validação em device; features chegam ao tvOS depois do iOS. | Validar em Apple TV real; ter fallback nativo; considerar STRM. |
| iOS/iPadOS | Baixo | Padrão; só implementar. |
| macOS | Baixo-médio | Adaptar p/ AppKit se for suportar. |
| visionOS | Baixo | Mesmo stack do iPadOS. |

---

## Fontes

- **[OFICIAL]** "Available platforms" e versão — https://support.firecore.com/hc/en-us/articles/215090997-API-for-Third-Party-Apps-Services
- **[OFICIAL]** Release notes (histórico de versões) — https://firecore.com/releases
- **[OFICIAL Apple]** `canOpenURL(_:)` (badge tvOS sem versão; regra do whitelist) — https://developer.apple.com/documentation/uikit/uiapplication/canopenurl(_:)
- **[COMUNIDADE]** Deep links no tvOS / 8.2.3 (staff) — https://community.firecore.com/t/apple-tv-infuse-deep-links/56876
- **[COMUNIDADE]** API iOS em 7.6.2 (staff) — https://community.firecore.com/t/add-x-callback-url-schemes-on-apple-tv/34181
- **[COMUNIDADE]** Handoff "Open" → home no tvOS — https://community.firecore.com/t/x-callbacks/59502
