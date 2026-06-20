# Home Spec — StreamHub (Início)

Ref principal: `references/hero/hero.png`, `references/continue assistindo/continue assistindo.png`, `references/top10/top 10.png`.

## `Features/Home/HomeView.swift`
```swift
struct HomeView: View {
    @Namespace private var heroFocus
    var body: some View { /* ver abaixo */ }
}
```
Layout (de cima p/ baixo), dentro de um `ScrollView(.vertical)` com `LazyVStack(alignment: .leading, spacing: Theme.Metrics.rowSpacing)`:

1. **`HeroView(items: MockData.heroItems)`** — ocupa ~58% da altura; backdrop sangra no topo (`.ignoresSafeArea(edges: .top)`). CTA primário com `.prefersDefaultFocus(in: heroFocus)` (passar namespace se a assinatura exigir; senão usar `@FocusState` interno do Hero).
2. **Rows** via `ForEach(MockData.rows)` → `MediaRowView(row:)`. Ordem esperada de `MockData.rows`:
   1. "Continue Assistindo" (`.continueWatching`)
   2. "Top 10 séries no Apple TV" (`.top10`)
   3. "Top 10 filmes no Apple TV" (`.top10`)
   4. (opcional) rows `.standard` extras

- Fundo: `Theme.bg` com leve gradiente p/ `Theme.bgElevated` abaixo do hero.
- `.focusScope(heroFocus)` se necessário para o default focus.
- NÃO usar `.clipped()`. Garantir `focusHeadroom` para o lift dos cards na primeira/última row.
- A primeira row deve sobrepor levemente a base do hero (como na ref `continue assistindo.png`, onde os cards começam ainda sobre o fim do backdrop). Ajustar com offset negativo pequeno se necessário — refinar via screenshot.

## Comportamento de foco
- Ao abrir a Home, foco no CTA do hero.
- Descer o foco → entra na primeira row (Continue Assistindo). `.focusSection()` por row mantém a navegação horizontal coesa.
- O sidebar (RootView) colapsa para o pill "Início" quando o foco está no conteúdo (comportamento nativo do `.sidebarAdaptable`).

## Verificação visual (vs refs)
- Hero: imagem cinematográfica sangrando, bloco título+meta+CTA no canto inferior-esquerdo, scrim legível.
- Continue Assistindo: cards 16:9 com barra de progresso e label "T?, E? · ?? min".
- Top 10: numerais gigantes atrás dos pôsteres, título+gênero abaixo.
- Sidebar colapsada (pill) no topo-esquerdo.
