# Bug 1 — Não consigo subir o foco de volta para o hero / capa do hero cortada

Status: ROOT CAUSE confirmado com evidência de runtime + fix mínimo aplicado e verificado numa cópia isolada (`/tmp/sh-bug1`). Sim dedicado: `SH-Bug1` (tvOS 27).

Sintoma do usuário (PT-BR): "Quando desço o foco do hero para as rows, NÃO consigo subir de volta para o hero; a capa do hero fica cortada."

---

## 1. ROOT CAUSE

A causa raiz **não** é virtualização do `LazyVStack`, **não** é o `.focusScope`/`.prefersDefaultFocus` prendendo foco, e **não** é o `.ignoresSafeArea`. É o **auto-scroll do `ScrollView` dirigido pelo foco que faz "under-scroll" ao subir de volta para o hero**.

Mecânica: o CTA "Reproduzir" fica na **base** do hero (hero tem ~626pt de altura: `1080*0.58`). Quando o foco volta de uma row para o hero, o focus engine do tvOS rola o `ScrollView` apenas o suficiente para deixar o **botão** visível (com a `focusHeadroom` da row) — e isso **não** chega a revelar o topo do hero. Resultado: o foco volta para o botão, mas o hero permanece parcialmente rolado para cima (cortado no topo). É preciso uma **segunda** seta para cima para o hero terminar de descer e aparecer inteiro. O usuário interpreta esse comportamento como "não consigo subir de volta para o hero" + "a capa fica cortada" — são o **mesmo** defeito.

Por que entrar pela primeira vez mostra o hero inteiro mas voltar não? Ao entrar vindo da sidebar (seta para a direita), o `ScrollView` ainda está no offset 0 → hero 100% visível. Depois de descer e voltar, o offset é > 0 e o auto-scroll só "encosta" o botão na área visível, deixando o topo do hero cortado.

### Evidência de runtime (XCUITest + frames do elemento focado)

Teste `testHeroFocusReturn` — fluxo real do usuário (a sidebar `.sidebarAdaptable` recebe o foco inicial; é preciso `.right` para entrar no conteúdo):

| Passo | Ação | Elemento focado | y do "Reproduzir" |
|------|------|-----------------|-------------------|
| 00 | launch | sidebar "Início" (`house`) | — |
| 01 | `.right` (entra no hero) | **Reproduzir** | **472** (hero inteiro) |
| 02 | `.down` (entra na row) | card "tv" | — |
| 03 | `.up` (volta p/ hero) | **Reproduzir** | **376** ← hero AINDA cortado |
| 04 | `.up` de novo | **Reproduzir** | **472** ← só agora restaura |

O `y` do mesmo botão muda 472 → 376 → 472: prova de que **uma** seta para cima não restaura o scroll do hero; precisa de duas.

Screenshots (resize 1400px):
- `context/bugs/bug-1-assets/before-01-hero-entry.png` — entrada no hero (correto, inteiro).
- `context/bugs/bug-1-assets/before-03-up-cutoff.png` — **após subir da row: hero cortado no topo, "Continue Assistindo" puxado para cima**. Este é o sintoma "capa cortada".

### Manifestação secundária (fora do escopo deste fix): foco "travado" entre rows Top 10

Teste `testDeepDownThenUp` (descer 4 rows e subir): entre duas rows `.top10` consecutivas, pressionar `.up` **rola sem mover o foco** — o elemento focado permanece o mesmo card (frame y=160 em dois passos seguidos: `D-up-1` e `D-up-2`). Evidência: `before-deep-up1.png` vs `before-deep-up2-stuck.png` (mesmo card "Oppenheimer" focado, mas a tela rolou). Isso reforça a sensação de "não consigo subir", porém a causa é a **geometria do `Top10CardView`** (numeral gigante de 240pt + `posterInset` de 96pt deslocam o `Button` focável horizontalmente dentro de uma célula muito larga, então o engine não encontra alvo alinhado acima e rola em vez de mover foco). É um problema distinto, pertencente ao escopo do Top 10 — registrado aqui apenas para contexto; **o fix abaixo não o altera**.

### Por que o fix anterior (LazyVStack → VStack) piorou

Confirma que a hipótese de "virtualização derrubando o hero" é **falsa**. Trocar para `VStack` renderiza todas as rows de imediato, aumenta a altura total do conteúdo e muda a geometria de scroll/foco — sem tocar na causa real (under-scroll do auto-scroll). Mexer na altura do conteúdo só perturbou o engine de foco negativamente, daí ter ficado pior. (Pesquisa: não há bug documentado da Apple de virtualização de `LazyVStack` quebrando foco para cima.)

### Citações (tvOS 26/27 é posterior ao cutoff do modelo)

- `focusScope(_:)` **não** prende foco — só limita o escopo de `prefersDefaultFocus`/`resetFocus`. Logo não era a causa. https://developer.apple.com/documentation/swiftui/view/focusscope(_:)
- `prefersDefaultFocus(_:in:)` exige `focusScope` ancestral com o **mesmo** `Namespace.ID` e só define foco **inicial**; não controla traversal up/down. https://developer.apple.com/documentation/swiftui/view/prefersdefaultfocus(_:in:)
- `@Namespace` gera um `Namespace.ID` distinto por instância: os dois `heroFocus` (um em `HomeView`, inerte; outro em `HeroView`) são namespaces diferentes apesar do nome igual — red herring confirmado.
- `focusSection()` ajuda o engine a saltar "gaps" não-focáveis, mas no teste **não** corrigiu o under-scroll (ver §3). https://developer.apple.com/documentation/swiftui/view/focussection()
- tvOS overscan/safe area: ~60pt topo/base, 80pt laterais; `.ignoresSafeArea()` empurra conteúdo para baixo do overscan. Afeta o repouso, mas **não** o under-scroll. https://developer.apple.com/design/human-interface-guidelines/layout
- `ScrollViewProxy.scrollTo(_:anchor:)` para rolar programaticamente até um `.id`. https://developer.apple.com/documentation/swiftui/scrollviewproxy/scrollto(_:anchor:)

---

## 2. FIX MÍNIMO (arquivos reais sob `StreamHub/`)

Ideia: quando **qualquer** botão do hero ganha foco, rolar o `ScrollView` para o topo (`anchor: .top`), revelando o hero inteiro em **uma** seta para cima. Usa `ScrollViewReader` + `@FocusState`. Não mexe em `LazyVStack`, `focusScope`, `prefersDefaultFocus`, `ignoresSafeArea` nem `.clipped()` — escopo cirúrgico na causa raiz.

### `StreamHub/Features/Home/HomeView.swift`

ANTES:
```swift
struct HomeView: View {
    @Namespace private var heroFocus

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: Theme.Metrics.rowSpacing) {
                HeroView(items: MockData.heroItems)

                ForEach(MockData.rows) { row in
                    MediaRowView(row: row)
                }
            }
        }
        .background(Theme.backgroundGradient)
        .ignoresSafeArea()
    }
}
```

DEPOIS:
```swift
struct HomeView: View {
    @FocusState private var heroFocused: Bool

    private enum ScrollAnchor: Hashable { case top }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: Theme.Metrics.rowSpacing) {
                    HeroView(items: MockData.heroItems, heroFocused: $heroFocused)
                        .id(ScrollAnchor.top)

                    ForEach(MockData.rows) { row in
                        MediaRowView(row: row)
                    }
                }
            }
            .onChange(of: heroFocused) { _, focused in
                if focused {
                    withAnimation { proxy.scrollTo(ScrollAnchor.top, anchor: .top) }
                }
            }
        }
        .background(Theme.backgroundGradient)
        .ignoresSafeArea()
    }
}
```
Obs.: o `@Namespace heroFocus` de `HomeView` era inerte (não usado) — foi substituído pelo `@FocusState`. Nenhuma outra mudança no `HomeView`.

### `StreamHub/Features/Home/HeroView.swift`

(1) Aceitar o binding de foco. ANTES:
```swift
struct HeroView: View {
    let items: [MediaItem]
    @State private var index = 0

    @Namespace private var heroFocus
```
DEPOIS:
```swift
struct HeroView: View {
    let items: [MediaItem]
    var heroFocused: FocusState<Bool>.Binding? = nil
    @State private var index = 0

    @Namespace private var heroFocus
```

(2) Marcar os botões do hero com o binding (mantendo `focusScope`/`prefersDefaultFocus` como estão). ANTES:
```swift
            .buttonStyle(.card)
            .prefersDefaultFocus(in: heroFocus)

            circleButton(symbol: "plus", action: {})
            circleButton(symbol: "info.circle", action: {})
            circleButton(symbol: "chevron.right", action: advance)
        }
        .focusScope(heroFocus)
    }

    @ViewBuilder
    private func circleButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 64, height: 64)
                .background(Theme.fillOnDark, in: Circle())
        }
        .buttonStyle(.card)
    }
}
```
DEPOIS:
```swift
            .buttonStyle(.card)
            .prefersDefaultFocus(in: heroFocus)
            .heroFocusTracked(heroFocused)

            circleButton(symbol: "plus", action: {})
            circleButton(symbol: "info.circle", action: {})
            circleButton(symbol: "chevron.right", action: advance)
        }
        .focusScope(heroFocus)
    }

    @ViewBuilder
    private func circleButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 64, height: 64)
                .background(Theme.fillOnDark, in: Circle())
        }
        .buttonStyle(.card)
        .heroFocusTracked(heroFocused)
    }
}

private extension View {
    @ViewBuilder
    func heroFocusTracked(_ binding: FocusState<Bool>.Binding?) -> some View {
        if let binding {
            focused(binding)
        } else {
            self
        }
    }
}
```
Um único `FocusState<Bool>.Binding` compartilhado pelos 4 botões fica `true` quando **qualquer** um deles está focado — exatamente o que queremos. O `#Preview` do `HeroView` continua válido (parâmetro opcional, default `nil`).

---

## 3. VERIFICAÇÃO (cópia `/tmp/sh-bug1`, sim `SH-Bug1` tvOS 27)

Método: criada uma scheme compartilhada com o target de UITests testável; driven via `XCUIRemote.shared.press(...)`; cada passo registra o frame do elemento `hasFocus == true` (via `NSPredicate`) + screenshot anexada; export por `xcresulttool export attachments`.

Variantes testadas (todas compilaram e passaram):
- **Fix A** (`.focusSection()` só no hero): **NÃO** corrigiu o under-scroll (passo 03 continuou y=376). Descarta `focusSection` como solução.
- **Fix B** (`.ignoresSafeArea(edges:.top)` no hero + `.horizontal` no ScrollView): muda só o repouso (y=592), under-scroll **persiste**. Descarta safe area como causa.
- **Fix mínimo (ScrollViewReader, recomendado)**: passo 03 = **y=472, idêntico ao passo 01** → hero restaurado por completo em **uma** seta para cima.

Antes vs depois (mesmo fluxo `.right → .down → .up`):

| | passo 01 (entrada) | passo 03 (voltar do row) |
|--|--|--|
| ANTES | y=472 (inteiro) | **y=376 (cortado)** — `before-03-up-cutoff.png` |
| DEPOIS | y=472 (inteiro) | **y=472 (inteiro)** — `after-03-up-restored.png` |

Comparação visual: `after-03-up-restored.png` é pixel-idêntico a `after-01-hero-entry.png` (e a `before-01-hero-entry.png`). O hero volta inteiro, com "Continue Assistindo" espiando na base — comportamento esperado.

Logs/resultados na cópia: `/tmp/sh-bug1/test-before.log`, `/tmp/sh-bug1/test-min.log`, `/tmp/sh-bug1/test-deep.log`.

### Observações para o orquestrador (não incluídas no fix — fora do escopo)
- Foco inicial: ao abrir a Home, o foco fica na **sidebar** ("Início"), não no CTA do hero (spec home-spec.md §27 pede CTA). O `prefersDefaultFocus` não vence o `TabView(.sidebarAdaptable)`. Item separado.
- Spec home-spec.md §14/§23: hero deveria usar `.ignoresSafeArea(edges:.top)` no backdrop e **NÃO** usar `.clipped()` — o código atual usa `.ignoresSafeArea()` global e `.clipped()` no backdrop (`HeroView.swift:70`). Não é a causa deste bug; é dívida de fidelidade à spec.
- "Travamento" de foco entre rows Top 10 (ver §1) — pertence ao escopo do Top 10 (`Top10CardView` geometria do numeral/posterInset).
