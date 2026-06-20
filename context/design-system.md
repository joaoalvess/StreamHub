# Design System — StreamHub (clone Apple TV / tvOS 27)

> Tokens extraídos das referências em `references/`. Valores são ponto de partida para alta fidelidade; refinar via screenshot no simulador (1920×1080 pt). Todo componente consome estes tokens via `Theme` (ver `StreamHub/Theme/Theme.swift`).

## Plataforma
- tvOS renderiza em **1920×1080 pontos** (Apple TV 4K @1080p) com assets @2x. Tudo em pontos.
- Fontes do tvOS já são grandes (body ≈ 29pt). Preferir as fontes do sistema (`.title`, `.headline`, etc.) com pesos ajustados.

## Paleta (tema escuro)
| Token | Valor | Uso |
|---|---|---|
| `Theme.bg` | preto quase puro, leve tom quente `#0B0A09` | fundo base das telas |
| `Theme.bgElevated` | `#15130F` (cinza-marrom escuro) | gradiente sutil de fundo da Home abaixo do hero |
| `Theme.textPrimary` | branco `#FFFFFF` | títulos, nomes |
| `Theme.textSecondary` | branco 60% | metadados (gênero, T/E, duração) |
| `Theme.textTertiary` | branco 45% | textos auxiliares (preço, "até ser cancelado") |
| `Theme.fill` | branco | botão primário (pill branco com texto preto) |
| `Theme.fillOnDark` | branco 15% | botões secundários circulares (+, ⓘ, ›) |
| `Theme.cardStroke` | branco 8% | borda sutil dos cards |
| `Theme.progressTrack` | branco 25% | trilho da barra de progresso |
| `Theme.progressFill` | branco | preenchimento da barra de progresso |

O fundo da Home tem leve gradiente vertical: topo coberto pelo hero; abaixo, `bg`→`bgElevated`. Em algumas refs há um tom marrom-quente; manter sutil.

## Tipografia
| Token | Base SwiftUI | Peso | Uso |
|---|---|---|---|
| `Theme.Font.sectionTitle` | ~`.title2` (≈30pt) | `.semibold` | "Continue Assistindo", "Top 10 séries no Apple TV" |
| `Theme.Font.heroTitle` | custom ≈ 80pt | `.heavy` + tracking | fallback de título do hero (quando não há logo PNG) |
| `Theme.Font.cardTitle` | ~`.headline` (≈26pt) | `.semibold` | título sob pôster (Top 10) |
| `Theme.Font.meta` | ~`.callout` (≈24pt) | `.regular` | linha de metadados, "T1, E8 · 15 min" |
| `Theme.Font.badge` | ~`.caption` | `.semibold` | selos pequenos |

## Métricas / espaçamentos
| Token | Valor inicial | Uso |
|---|---|---|
| `Theme.Metrics.edgeH` | 80 | margem horizontal de conteúdo (overscan) |
| `Theme.Metrics.rowSpacing` | 44 | gap vertical entre rows |
| `Theme.Metrics.cardSpacing` | 32 | gap horizontal entre cards |
| `Theme.Metrics.titleGap` | 16 | gap entre título da seção e a row |
| `Theme.Metrics.focusHeadroom` | 60 | padding extra dentro de ScrollViews p/ não cortar o lift (~1.1) nem numerais |

## Cantos e cards
| Token | Valor | Uso |
|---|---|---|
| `Theme.Radius.card` | 12 | pôster portrait e card 16:9 |
| `Theme.Radius.pill` | capsule | botões pill / selos |

### Aspect ratios
- **Pôster (Top 10 e rows padrão):** `2:3` (portrait). Altura inicial ≈ 300pt → largura ≈ 200pt.
- **Continue Assistindo / cards 16:9:** `16:9`. Largura inicial ≈ 380pt → altura ≈ 214pt.
- **Hero backdrop:** largura total, ocupa ~58% superior da tela, esmaecendo no conteúdo.

## Foco (tvOS)
- **Sempre** usar `.buttonStyle(.card)` (CardButtonStyle) nos cards → lift/sombra/parallax nativos. NÃO usar `scaleEffect`+`shadow` manual para o lift base.
- **Nunca** aplicar `.clipped()` no container de uma row (corta o lift e numerais).
- Garantir `focusHeadroom` de padding nas LazyHStack/LazyVStack para o card ampliado (~1.1×) não ser cortado.
- Revelações de foco (ex.: glyph de play / reforço de progresso no Continue Assistindo) via `@Environment(\.isFocused)` lido dentro do `label` do botão, animado com `.animation(_:value:)`.
- `.prefersDefaultFocus(in:)` no CTA primário do hero para a Home abrir com foco no hero.

## Gradiente do hero
Dois `LinearGradient` sobrepostos ao backdrop, em `ZStack(alignment:.bottomLeading)`:
1. Vertical: `.black.opacity(0.92)` (bottom) → `.clear` (~55% da altura).
2. Horizontal: `.black.opacity(0.75)` (leading) → `.clear` (~60% da largura).
Garante legibilidade do bloco título/metadados/CTA no canto inferior-esquerdo.

## Numeral Top 10
- `Text("\(rank)")` ~ 220–260pt, `.heavy`, cor branca com baixa opacidade OU com leve stroke; fica **atrás/à esquerda** do pôster, parcialmente ocluso por ele.
- Só o pôster é focável; o numeral é decorativo.
