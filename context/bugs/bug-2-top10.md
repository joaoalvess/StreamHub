# Bug 2 — Top 10 row não fiel à referência

> Sintoma (usuário, PT-BR): "O Top 10 não parece com o que te mandei, está bem diferente."
> Arquivo afetado: `StreamHub/Features/Home/Top10CardView.swift` (consumido por `MediaRowView.swift`).
> Investigação feita em cópia isolada (`/tmp/sh-bug2`) + simulador próprio (`SH-Bug2`, Apple TV 4K 3rd gen, tvOS 27).

---

## 1. Diff preciso: referência × implementação atual

Medições tiradas pixel-a-pixel da referência `references/top10/top 10.png` (3840×2160 @2x → 1pt = 2px),
usando o card 2 ("Monarch: Legado de Monstros") como amostra limpa e auto-contida.

| Aspecto | Referência (medido) | Atual (`main`, 2:3) | Diferença |
|---|---|---|---|
| **Tipo de arte** | Pôster 2:3 do TMDB com **logo do título embutido na própria arte**, exibido **recortado (`.fill`) num tile mais largo** | Pôster 2:3 inteiro (`posterURL`) | A arte é a mesma; muda só o **recorte/aspecto do tile** |
| **Aspecto do tile** | ~**268pt × ~310pt** (w/h ≈ 0,86 — entre 4:5 e 1:1) | 200pt × 300pt (w/h 0,667 = 2:3) | Tile da `main` é **estreito e alto demais** |
| **Numeral — cor/opacidade** | cinza-claro rgb(197,206,205), **alpha ≈ 0,80** | branco 0,90 | praticamente igual (leve ajuste p/ 0,85) |
| **Numeral — tamanho** | altura de glifo ~126pt → `font size` ≈ **180pt**, peso bold | 240pt `.heavy` | `main` está **grande demais** |
| **Numeral — alinhamento vertical** | **topo do numeral alinhado ao topo do card** (numeral ocupa ~40% superior; card desce bem abaixo) | `ZStack(alignment: .bottomLeading)` → numeral colado na **base** | **alinhamento invertido** — maior contribuinte do "está bem diferente" |
| **Numeral — sobreposição** | card cobre só a **borda direita** do numeral (numeral fica à esquerda do card) | `posterInset 96` afasta o pôster; quase sem sobreposição | ajuste fino |
| **Label abaixo do card** | **apenas o gênero**, **centralizado** sob o card ("Aventura") | **título + gênero, alinhados à esquerda** ("Monarch: Lega…" truncado + gênero) | `main` **duplica o título** (já está embutido na arte) e **alinha errado** |
| **Pitch entre células** | ~300pt (gap ~32pt) | depende de `cardSpacing 32` + cellWidth | ok após ajuste de aspecto |

Evidências (capturas em `context/bugs/bug-2-assets/`):
- `reference-top10-row.png` — fileira "Top 10 séries" da referência.
- `current-2x3-render.png` — render atual (2:3) no simulador.
- `diff-ref-vs-current.png` — **referência (esq.) × atual (dir.)** lado a lado, card "Monarch".
- `aspect-overlay.png` — caixas-guia 2:3 / 3:4 / 4:5 / 1:1 sobre o card da referência (o tile bate em ~4:5–6:7, não em 2:3).
- `ref-tile-vs-full-poster.png` — tile da referência (esq.) × pôster 2:3 completo (dir.): mesma arte, recortada.

### Causa-raiz
A `main` renderiza um **pôster 2:3 inteiro** com o numeral **colado na base** e **título+gênero** embaixo.
A referência usa o **mesmo pôster recortado num tile ~4:5**, com o numeral **alinhado ao topo** e **só o gênero centralizado** embaixo (o título já vem embutido na arte do pôster). O fix anterior do orquestrador (4:5 230×288 + mais overlap) acertou o aspecto mas **não corrigiu o alinhamento vertical do numeral nem removeu o título duplicado** — por isso ainda parecia diferente.

### Sobre os dados / arte (importante)
Os itens de `MockData.top10` usam `posterURL` = pôsteres **2:3 (w500) do TMDB** — e esses pôsteres **já trazem o logotipo do título embutido** (ex.: "MONARCH / LEGADO DE MONSTROS"). Portanto **dá para reproduzir a referência fielmente com os dados atuais**, recortando o 2:3 num tile ~4:5 via `.aspectRatio(.fill)`. **Não é necessária arte nova.**
Ressalva de fidelidade: a referência recorta um tile ligeiramente mais "quadrado" (w/h ≈ 0,86) que corta a base do logo; um 4:5 exato (0,80) mostra um pouco mais da arte. Para um match milimétrico seria preciso `tileHeight` ≈ 312pt (w/h 0,86) — diferença de ~10pt, visualmente irrelevante. Arte dedicada de "key-art quadrada" do Apple TV não existe no nosso dataset (só 2:3 + 16:9), então o recorte do 2:3 é a abordagem fiel mais próxima.

---

## 2. Fix fiel — `Top10CardView.swift` (before / after)

### BEFORE (`main`)
```swift
private let numeralSize: CGFloat = 240
private let numeralLeading: CGFloat = 8
private let posterInset: CGFloat = 96

private var cellWidth: CGFloat { posterInset + Theme.Size.posterWidth }

var body: some View {
    VStack(alignment: .leading, spacing: 14) {
        artwork
        caption
            .padding(.leading, posterInset)
            .frame(width: cellWidth, alignment: .leading)
    }
}

private var artwork: some View {
    ZStack(alignment: .bottomLeading) {          // numeral na BASE
        numeral
        Button(action: {}) { poster }
            .buttonStyle(.card)
            .padding(.leading, posterInset)
    }
    .frame(width: cellWidth, alignment: .leading)
}

private var numeral: some View {
    Text("\(rank)")
        .font(.system(size: numeralSize, weight: .heavy))   // 240 heavy
        .foregroundStyle(Theme.textPrimary.opacity(0.9))
        .monospacedDigit().lineLimit(1).fixedSize()
        .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 6)
        .padding(.leading, numeralLeading)
        .accessibilityHidden(true)
}

private var poster: some View {
    AsyncImage(...) { ... }
        .frame(width: Theme.Size.posterWidth, height: Theme.Size.posterHeight)  // 200×300 (2:3)
        .clipShape(...).overlay(... strokeBorder ...)
}

private var caption: some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(item.title)                          // TÍTULO duplicado
            .font(Theme.Font.cardTitle).foregroundStyle(Theme.textPrimary).lineLimit(1)
        if let genre = item.genres.first {
            Text(genre).font(Theme.Font.meta).foregroundStyle(Theme.textSecondary).lineLimit(1)
        }
    }
}
```

### AFTER (fiel — testado no simulador)
```swift
private let tileWidth: CGFloat = 268
private let tileHeight: CGFloat = 322          // tile ~4:5 (w/h ~0.83); use 312 p/ w/h 0.86 exato
private let numeralSize: CGFloat = 180         // glifo ~126pt como na referência
private let posterInset: CGFloat = 78          // card cobre a borda direita do numeral

private var cellWidth: CGFloat { posterInset + tileWidth }

var body: some View {
    VStack(alignment: .leading, spacing: 12) {
        artwork
        caption
            .frame(width: tileWidth, alignment: .center)   // gênero CENTRALIZADO sob o card
            .padding(.leading, posterInset)
    }
}

private var artwork: some View {
    ZStack(alignment: .topLeading) {           // numeral alinhado ao TOPO
        numeral
        Button(action: {}) { poster }
            .buttonStyle(.card)
            .padding(.leading, posterInset)
    }
    .frame(width: cellWidth, alignment: .leading)
}

private var numeral: some View {
    Text("\(rank)")
        .font(.system(size: numeralSize, weight: .bold))   // 180 bold
        .foregroundStyle(Theme.textPrimary.opacity(0.85))
        .monospacedDigit().lineLimit(1).fixedSize()
        .accessibilityHidden(true)
}

private var poster: some View {
    AsyncImage(url: item.posterURL, ...) { phase in
        case .success(let image):
            image.resizable()
                .aspectRatio(contentMode: .fill)   // recorta o 2:3 no tile ~4:5
                .transition(.opacity)
        // ... failure/empty iguais
    }
    .frame(width: tileWidth, height: tileHeight)
    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        .strokeBorder(Theme.cardStroke, lineWidth: 1))
}

private var caption: some View {                // SÓ o gênero (título já vem na arte)
    Group {
        if let genre = item.genres.first {
            Text(genre).font(Theme.Font.meta).foregroundStyle(Theme.textSecondary).lineLimit(1)
        }
    }
}
```

Notas:
- **Não** é preciso mexer em `MediaRowView.swift` nem em `Theme`. `cardSpacing 32` + a nova `cellWidth` já produzem o pitch ~300pt. (As constantes do tile são locais ao `Top10CardView`; se preferir centralizar em `Theme.Size`, é opcional.)
- Removida a `shadow` do numeral (a referência não tem sombra perceptível no numeral).
- O arquivo completo aplicado/testado está em `/tmp/sh-bug2/StreamHub/Features/Home/Top10CardView.swift`.

---

## 3. Verificação (capturas da cópia, lado a lado com a referência)

- `fixed-render.png` — fileira "Top 10" renderizada com o fix no simulador `SH-Bug2`.
- `verify-ref-vs-fixed.png` — **referência (esq.) × fix (dir.)**, card "Monarch": aspecto, numeral (topo, cinza-claro, card cobrindo a borda direita) e gênero centralizado batem.

Build `** BUILD SUCCEEDED **`; app instalado/lançado; screenshots confirmam o match.
Diferença residual: a referência recorta um tile ~10pt mais baixo (corta a base do logo "LEGADO DE MONSTROS"); ajustar `tileHeight` 322→312 deixa idêntico se desejado.

---

## Fontes (pesquisa)
- Apple — Human Interface Guidelines, "Top Shelf" / artwork em tvOS: https://developer.apple.com/design/human-interface-guidelines/top-shelf
- Apple TV for Partners — Artwork requirements (pôster/key-art com title treatment embutido): https://tvpartners.apple.com/support/3708-artwork-requirements

O padrão "Top 10" do app Apple TV é proprietário (sem doc pública dedicada); a verdade de referência é o screenshot `references/top10/top 10.png`, do qual todas as medições acima foram extraídas.
