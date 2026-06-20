# Progress / Handoff — StreamHub

> Log de handoff entre subagentes e fases. Cada agente atualiza a sua linha.

## Fase 1 — Mock visual da Home + navegação (em andamento)

### Fundação (contrato) — main agent
- [x] `context/*.md` escritos (design-system, data-model, component-specs, navigation-spec, home-spec, next-phases).
- [x] `StreamHub/Theme/Theme.swift`
- [x] `StreamHub/Models/MediaItem.swift`
- [x] `StreamHub/Models/MediaRow.swift`

### Dados — subagente curador
- [ ] `StreamHub/Models/MockData.swift` (URLs TMDB verificadas com curl → 200)

### Dados — subagente curador
- [x] `StreamHub/Models/MockData.swift` (URLs TMDB verificadas; hero 4, Continue 5, Top10 séries/filmes, Em alta)

### Componentes — workflow (fan-out)
- [x] `Features/Home/MediaCardView.swift`
- [x] `Features/Home/ContinueWatchingCardView.swift`
- [x] `Features/Home/Top10CardView.swift`
- [x] `Features/Home/MediaRowView.swift`
- [x] `Features/Home/HeroView.swift`
- [x] `Features/Home/HomeView.swift`
- [x] `Navigation/RootView.swift`
- [x] Placeholders: Search / AppleTV / Loja / Biblioteca

### Integração + verificação
- [x] `StreamHubApp.swift` → `RootView()`
- [x] Build tvOS 27 OK (BUILD SUCCEEDED, 0 erros)
- [x] Screenshot da Home vs referências (hero full-bleed + sidebar colapsada + Continue Assistindo + Top 10)

## Rodada de correções (feedback do usuário)
1. Bug "não dá para subir de volta ao hero / capa cortada": root cause = `LazyVStack` descarregava o hero ao rolar (foco não retornava). Fix: `HomeView` agora usa `VStack`.
2. Top 10 "bem diferente": cards eram 2:3 (alto demais). Fix: `Top10CardView` ~4:5 (230×288), mais overlap com o numeral (posterInset 74), sem stroke.
3. Hover dos itens diferente: removido o stroke/borda dos cards (Apple TV não tem) — `MediaCardView`, `ContinueWatchingCardView`, `Top10CardView`.
4. Hover do hero "zuado": trocado `.buttonStyle(.card)` por estilo reativo a foco (`HeroPillLabel`/`HeroIconLabel`): sem foco = transparente + branco; com foco = preenchido branco + preto. Bate com `references/hero/hero hover next title.png`.

Validado por screenshot: hero (primário focado vira pill branco; ícones planos), Top 10 (cards quadrados + numerais). Itens 1 e 3 (navegação/hover por foco) precisam de verificação manual no simulador — não dá para automatizar foco aqui (device headless, sem permissão de Acessibilidade p/ teclas).

## Fase 1 — CONCLUÍDA ✅
Ajustes de fidelidade aplicados após 1ª build:
- Hero full-bleed: removido `GeometryReader` que prendia a largura à safe area; `HomeView` com `.ignoresSafeArea()`. (Os cantos arredondados/margens eram da safe area, não da sidebar.)
- Navegação confirmada como sidebar nativa (`.sidebarAdaptable`) — bate com os HEICs. Sidebar colapsa para o pill "Início" quando o foco vai ao conteúdo (~assenta em alguns segundos via `prefersDefaultFocus`).
- Top 10 validado por screenshot (numerais gigantes atrás dos pôsteres).

Screenshots de referência da validação: `build/home_final.png` (canônica), `build/rows_top.png` (Top 10).

## Decisões registradas
- Navegação: `TabView` + `.tabViewStyle(.sidebarAdaptable)` (sidebar nativa) — confirmado pelos HEICs.
- Imagens: `AsyncImage` + URLs TMDB.
- Cards: `.buttonStyle(.card)`.
- Synchronized groups: arquivos novos em `StreamHub/` entram no target automaticamente.

## Pendências / riscos
- `TabSection` ("Canais e Apps") adiado por bug de foco no `.sidebarAdaptable`.
- Logos (wordmarks) do hero opcionais; fallback em texto.
- Tokens de tamanho/espaçamento a refinar via screenshot.
