# Bug 3 — Efeito de foco (hover) dos itens diferente do Apple TV

> Status: ROOT CAUSE confirmado em runtime + FIX verificado em cópia isolada (sim tvOS 27).
> Sintoma (usuário, PT-BR): "O efeito de hover (foco) dos itens está diferente do que te mandei." — ao focar um item, o efeito difere do Apple TV.

---

## 1. ROOT CAUSE

Os três cards de row aplicam uma **borda cinza fixa e independente de foco** (`Theme.cardStroke` = branco 8%) via `.overlay(RoundedRectangle…strokeBorder…)`, presente **igualmente no estado focado e no não-focado**. No Apple TV real o card **não tem borda quando não-focado** e ganha um **anel branco brilhante somente ao receber foco** (claramente visível nos cards 16:9 do "Continue Assistindo"). A implementação atual está, na prática, **invertida**: uma borda cinza-fosca sempre ligada que nunca se acende no foco.

A fix anterior do orquestrador (remover a borda) corrigiu o "cinza sempre ligado" mas **também removeu o anel de foco branco que a Apple mostra** → o card focado ficou subdefinido e ainda não bateu com a referência. Por isso o usuário continuou insatisfeito.

Observação importante de pesquisa: o `.buttonStyle(.card)` **já aplica** scale-up + lift + sombra + motion no foco — isso funciona no app atual (confirmado em runtime). O que o `.card` NÃO entrega é o specular/parallax forte (isso vem do `.highlight`, próprio do `.borderless`) e, sobretudo, **o anel branco de foco não existe** no código. A diferença que o usuário percebe num print estático é dominada por esse anel branco ausente. (O specular/parallax do `.highlight` é efeito de movimento, não aparece em screenshot estático/centralizado — diff de pixels antes/depois ao adicioná-lo foi ~0; por isso NÃO foi incluído na fix, para manter o diff mínimo e verificável.)

### Evidência

**Referência Apple TV** (`references/continue assistindo/continue assistindo.png`):
- Card FOCADO (Big Bang, 1º da row): anel branco nítido (~4pt) + lift + sombra. → `context/bugs/bug-3-shots/reference-cw-focused.png`
- Card NÃO-FOCADO (Pânico): bordas limpas, **sem** borda. → `context/bugs/bug-3-shots/reference-cw-unfocused.png`

**Runtime atual do app (ANTES da fix)** — capturado dirigindo foco via `XCUIRemote` em cópia isolada:
- Card focado: lift/scale/sombra do `.card` presentes, porém a borda é a mesma cinza-fosca dos vizinhos (sem anel branco) → praticamente indistinguível. → `context/bugs/bug-3-shots/before-cw-focused.png`

**Triptych comparativo (ANTES | DEPOIS | REFERÊNCIA)**: `context/bugs/bug-3-shots/triptych-before-after-reference-cw.png`

**Citações (pesquisa, cross-checada):**
- `.card`/CardButtonStyle "doesn't pad the content, and applies a motion effect when a button has focus" — conteúdo edge-to-edge; lift/scale/sombra/motion vêm do focus engine. https://developer.apple.com/documentation/swiftui/cardbuttonstyle
- Apple confirma "scale up and lift each lockup" no foco; o sample app usa `.clipShape(RoundedRectangle(cornerRadius: 12))` + overlay de stroke DENTRO do label (logo, clipShape/overlay NÃO conflitam com o `.card`). https://developer.apple.com/documentation/swiftui/creating-a-tvos-media-catalog-app-in-swiftui
- Specular highlight + gimbal/parallax vêm do `.highlight` hover effect (auto-anexado pelo `.borderless`, não pelo `.card`). https://developer.apple.com/documentation/swiftui/hovereffect/highlight
- HIG: usar efeitos de foco do sistema; não recriar scaleEffect/shadow manuais. https://developer.apple.com/design/human-interface-guidelines/focus-and-selection

---

## 2. FIX MÍNIMA (before/after — aplicar nos arquivos reais em `StreamHub/Features/Home/`)

A correção é a mesma nos 3 cards: trocar a borda cinza fixa por um **anel branco dirigido por foco** (`@Environment(\.isFocused)`), invisível quando não-focado, animado. Para `MediaCardView` e `Top10CardView` o pôster precisa virar um subview que lê `isFocused` (o `.card` faz o `Button` ser focável; o label lê o foco). `ContinueWatchingCardView` já tinha `CardLabel` lendo `isFocused`.

### `MediaCardView.swift`

**ANTES** (poster como `private var` dentro de `MediaCardView`, sem foco; stroke cinza fixo):
```swift
struct MediaCardView: View {
    let item: MediaItem

    var body: some View {
        Button(action: {}) {
            poster
        }
        .buttonStyle(.card)
    }

    private var poster: some View {
        AsyncImage(url: item.posterURL, transaction: Transaction(animation: .default)) { phase in
            // …mesmo conteúdo…
        }
        .frame(width: Theme.Size.posterWidth, height: Theme.Size.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.cardStroke, lineWidth: 1)
        )
    }
}
```

**DEPOIS** (poster extraído para `PosterLabel` que lê `isFocused`; anel branco animado):
```swift
struct MediaCardView: View {
    let item: MediaItem

    var body: some View {
        Button(action: {}) {
            PosterLabel(item: item)
        }
        .buttonStyle(.card)
    }
}

private struct PosterLabel: View {
    let item: MediaItem
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        AsyncImage(url: item.posterURL, transaction: Transaction(animation: .default)) { phase in
            // …mesmo conteúdo…
        }
        .frame(width: Theme.Size.posterWidth, height: Theme.Size.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(.white.opacity(isFocused ? 1 : 0), lineWidth: 4)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
```

### `Top10CardView.swift`

**ANTES** (`poster` como `private var` sem foco; stroke cinza fixo; usado em `artwork` via `Button { poster }`):
```swift
            Button(action: {}) {
                poster
            }
            .buttonStyle(.card)
            .padding(.leading, posterInset)
// …
    private var poster: some View {
        AsyncImage(url: item.posterURL, …) { … }
        .frame(width: Theme.Size.posterWidth, height: Theme.Size.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.cardStroke, lineWidth: 1)
        )
    }
```

**DEPOIS** (usar `Top10PosterLabel(item:)` no botão; mover o pôster para subview com foco; anel branco animado):
```swift
            Button(action: {}) {
                Top10PosterLabel(item: item)
            }
            .buttonStyle(.card)
            .padding(.leading, posterInset)
// …remover o `private var poster`…
// …adicionar fora do struct:
private struct Top10PosterLabel: View {
    let item: MediaItem
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        AsyncImage(url: item.posterURL, …) { … }
        .frame(width: Theme.Size.posterWidth, height: Theme.Size.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(.white.opacity(isFocused ? 1 : 0), lineWidth: 4)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
```

### `ContinueWatchingCardView.swift`

`CardLabel` já lê `@Environment(\.isFocused)`. Trocar apenas o overlay.

**ANTES:**
```swift
        .frame(width: Theme.Size.wideCardWidth, height: Theme.Size.wideCardHeight)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.cardStroke, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
```

**DEPOIS:**
```swift
        .frame(width: Theme.Size.wideCardWidth, height: Theme.Size.wideCardHeight)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(.white.opacity(isFocused ? 1 : 0), lineWidth: 4)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
```

### Notas de implementação
- `Theme.cardStroke` deixa de ser usado pelos cards. Pode permanecer no `Theme` (sem efeito colateral) ou ser removido se não houver outros usos — verificar antes de remover. NÃO alterar `Theme` é o padrão; deixar o token quieto é o mais seguro.
- `lineWidth: 4` (pt) casa com a espessura do anel na referência (≈8px @2x). Ajuste fino opcional: 3–5pt.
- Não usar `.clipped()` na row (já respeitado) — o `focusHeadroom` garante que o lift/anel não cortem.
- OPCIONAL (não verificável em screenshot estático, NÃO incluído na fix): adicionar `.hoverEffect(.highlight)` ao label para specular/parallax mais "Apple". Compila/roda em tvOS 27, mas o diff de pixels foi ~0 num print centralizado; avaliar só se quiser o brilho/tilt extra ao mover o trackpad. Risco baixo de dupla-projeção sobre o `.card`.

---

## 3. VERIFICAÇÃO (cópia isolada, sim tvOS 27, foco dirigido via XCUIRemote)

Método: cópia em `/tmp/sh-bug3`, sim "SH-Bug3" (Apple TV 4K 3rd gen, tvOS 27); UI test `testCaptureFocusStates` pressiona `.down/.right` para focar cards e anexa screenshots; extração via `xcresulttool export attachments`. Build e teste: **SUCCEEDED** antes e depois.

| Estado | Screenshot |
|---|---|
| ANTES — CW focado (borda cinza fixa, sem anel) | `context/bugs/bug-3-shots/before-cw-focused.png` |
| DEPOIS — CW focado (anel branco nítido) | `context/bugs/bug-3-shots/after-cw-focused.png` |
| DEPOIS — CW não-focado (bordas limpas, sem borda) | `context/bugs/bug-3-shots/after-cw-unfocused-row.png` |
| DEPOIS — Top 10 row, pôster focado com anel | `context/bugs/bug-3-shots/after-top10-focused-row.png` |
| Comparativo ANTES \| DEPOIS \| REFERÊNCIA | `context/bugs/bug-3-shots/triptych-before-after-reference-cw.png` |

**Resultado:** o card focado passou a exibir o anel branco brilhante idêntico à referência; os não-focados ficaram com bordas limpas (sem o cinza fosco antigo); lift/scale/sombra do `.card` preservados. Fidelidade ao Apple TV confirmada visualmente contra `references/continue assistindo/continue assistindo.png`.
