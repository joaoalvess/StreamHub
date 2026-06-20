# Component Specs — StreamHub Home (Fase 1)

> Assinaturas CONGELADAS. Cada subagente cria UM arquivo e implementa exatamente a `View` indicada. Consumir `Theme` (design-system.md) e os tipos de `Models/`. tvOS 27, SwiftUI. NÃO inventar tipos novos; NÃO alterar `Theme`/`Models`.

Regras gerais:
- Importar `SwiftUI`.
- Imagens: `AsyncImage` com placeholder `ProgressView()` sobre `Theme.bgElevated` e `.transition(.opacity)`.
- Cards focáveis: `Button { } label: { … }.buttonStyle(.card)`. Sem ação real (Fase 1) → `Button(action: {})`.
- Nada de `.clipped()` em containers de row. Usar `Theme.Metrics.focusHeadroom` de padding onde o lift puder cortar.
- Cada arquivo deve incluir um `#Preview` que funcione com `MockData` (ou itens de exemplo).

---

## `Features/Home/MediaCardView.swift`
```swift
struct MediaCardView: View { let item: MediaItem }
```
- Pôster **2:3** (`posterURL`), `RoundedRectangle(cornerRadius: Theme.Radius.card)`, borda `Theme.cardStroke`.
- Largura fixa via `Theme.Metrics` (altura ≈ 300pt). Envolto em `Button(.card)`.
- Sem título embaixo no estilo padrão (o título aparece só no Top10). Manter simples e reutilizável.

## `Features/Home/ContinueWatchingCardView.swift`
```swift
struct ContinueWatchingCardView: View { let item: MediaItem }
```
- Card **16:9** (`backdropURL`), largura ≈ 380pt.
- Overlay inferior: **barra de progresso** fina (`progress`) — trilho `Theme.progressTrack`, fill `Theme.progressFill`, alinhada à base do card.
- Glyph de **play** (SF Symbol `play.fill` em círculo translúcido) — reforçado/ampliado no foco (`@Environment(\.isFocused)`).
- Selo de serviço (`serviceBadge`) no canto, se houver.
- **Abaixo** do card: `episodeLabel` em `Theme.Font.meta` / `textSecondary`.
- `Button(.card)`.

## `Features/Home/Top10CardView.swift`
```swift
struct Top10CardView: View { let rank: Int; let item: MediaItem }
```
- `ZStack(alignment: .bottomLeading)` (ou `.leading`): numeral gigante atrás + pôster 2:3 na frente, deslocado à direita para ocluir parte do numeral.
- Numeral: `Text("\(rank)")` ~220–260pt `.heavy`, branco baixa opacidade. Decorativo (não focável).
- Só o **pôster** é `Button(.card)`.
- Abaixo: título (`Theme.Font.cardTitle`) + primeiro gênero (`Theme.Font.meta`/`textSecondary`).
- Largura total da célula deve comportar numeral + pôster + headroom (sem `.clipped()`).

## `Features/Home/MediaRowView.swift`
```swift
struct MediaRowView: View { let row: MediaRow }
```
- Título da seção (`Theme.Font.sectionTitle`, `textPrimary`) com `Theme.Metrics.edgeH` de leading e `titleGap` antes da row.
- `ScrollView(.horizontal, showsIndicators: false)` + `LazyHStack(spacing: Theme.Metrics.cardSpacing)`.
- `switch row.style`:
  - `.standard` → `MediaCardView(item:)`
  - `.continueWatching` → `ContinueWatchingCardView(item:)`
  - `.top10` → `Top10CardView(rank: idx+1, item:)` (usar `enumerated`)
- Padding leading/trailing = `edgeH`; padding vertical = `focusHeadroom` para o lift.
- `.focusSection()` na row para navegação por foco coesa.

## `Features/Home/HeroView.swift`
```swift
struct HeroView: View { let items: [MediaItem]; @State private var index = 0 }
```
- `ZStack(alignment: .bottomLeading)`: backdrop `AsyncImage` (`items[index].backdropURL`) fill + `.ignoresSafeArea(edges: .top)`.
- Gradiente duplo (ver design-system.md) sobre o backdrop.
- Bloco inferior-esquerdo (`edgeH` de leading): logo (`logoURL` via AsyncImage) OU título em `Theme.Font.heroTitle`; linha de metadados ("Programa de TV · " + genres); descrição (≤3 linhas, `textSecondary`); HStack de CTAs:
  - Botão primário pill branco (`Theme.fill`, texto preto) — ex.: "Reproduzir" — com `.prefersDefaultFocus(in:)`.
  - Botões circulares secundários (`Theme.fillOnDark`): `plus`, `info.circle` (`ⓘ`).
  - Botão `›` (`chevron.right`) que avança `index` (ciclando em `items`).
- Altura ≈ 58% da tela. Indicadores de página (dots) opcionais alinhados.
- Requer um `FocusState`/namespace local; passar `in:` namespace do HomeView se necessário (ver home-spec.md).

## Placeholders (`Features/{Search,AppleTV,Loja,Biblioteca}/*PlaceholderView.swift`)
```swift
struct SearchPlaceholderView: View {}   // idem AppleTV, Loja, Biblioteca
```
- Tela escura (`Theme.bg`) centralizada com ícone SF Symbol + nome da seção em `Theme.Font.sectionTitle`/`textSecondary` ("Em breve").
