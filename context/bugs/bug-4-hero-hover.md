# Bug 4 — Hover do hero "bem zuado"

> Sintoma (usuário, PT-BR): "O hover do hero está bem zuado."
> Arquivo afetado: `StreamHub/Features/Home/HeroView.swift` (`ctaRow` / `circleButton`).
> Investigação feita em cópia isolada (`/tmp/sh-bug4`) + simulador próprio (`SH-Bug4`, Apple TV 4K 3rd gen, tvOS 27).
> Estados de foco capturados em runtime via UI test (`XCUIRemote.shared.press(.right/.left)` + `XCTAttachment`), extraídos do `.xcresult`.

---

## 1. Causa-raiz + evidência

A referência (`references/hero/hero.png` e `references/hero/hero hover next title.png`) define o padrão clássico de botão de hero do Apple TV:

- **Não focado:** botão **plano/transparente** — texto branco ("Reproduzir") ou ícone branco (`+`, `ⓘ`, `›`), **sem nenhum fundo**.
- **Focado:** vira **preenchimento branco sólido** (cápsula no primário, círculo nos secundários) com **conteúdo preto** + leve escala. **Sem "placa"/lift de card.**
- Só **um** botão por vez fica branco (o focado); ao mover o foco para o `›`, o `›` vira círculo branco e o primário **volta a ser texto plano** (sem pill branca).

O código atual faz o **oposto disso**, por três motivos somados:

1. **Fundos FIXOS, sempre visíveis.** O primário desenha sempre uma `Capsule()` branca (`Theme.fill`); os secundários desenham sempre um `Circle()` cinza (`Theme.fillOnDark`). Logo o `+`/`ⓘ`/`›` **nunca** ficam planos (a referência os quer planos quando não focados) e o foco **nunca** produz o preenchimento branco.
2. **`.buttonStyle(.card)` é o estilo errado para botões de hero.** Em tvOS o `CardButtonStyle` é feito para **pôsteres**: ele envolve o conteúdo numa **placa retangular arredondada** que **levanta (lift) e escurece** ao focar — não acompanha a forma `Capsule`/`Circle`. Resultado: ao focar, a pill branca vira um **quadrado arredondado cinza/escurecido** e os círculos viram **quadrados arredondados** — exatamente o "zuado". Doc Apple: *"applies a Liquid Glass effect when the button has focus … displays content edge-to-edge"*, pensado para conteúdo tipo pôster (não pill/texto). [1][2]
3. **Indicação de foco invertida.** Como o fundo já é fixo, o único feedback de foco é o lift/escurecimento da placa do `.card` — i.e. o botão focado fica **mais escuro/levantado**, em vez de virar **branco**. É o inverso da referência.

### Por que o fix anterior (`.plain` + `@Environment(\.isFocused)` no label) ficou PIOR

O orquestrador trocou para `.buttonStyle(.plain)` com labels customizados lendo `@Environment(\.isFocused)` **dentro do label do Button**. Dois problemas conhecidos de tvOS explicam o resultado pior:

- **`@Environment(\.isFocused)` lido dentro do `label` do `Button` NÃO atualiza de forma confiável em tvOS.** `isFocused` é "whether the **nearest focusable ancestor** has focus" — no nível do label o ancestral focável ainda não envolve a view como o valor espera; o lugar correto é **dentro de um `ButtonStyle.makeBody`** (a body do style é instalada **dentro** do container focável do Button). [3][5]
- **`.buttonStyle(.plain)` em tvOS tem bugs de foco** — quebra `FocusValues` e, em vários relatos, deixa o botão **não focável** ou mantém um realce de foco residual; `.focusEffectDisabled(true)` também **não** remove o efeito de foco de forma confiável no `Button` de tvOS (a DTS recomenda **criar um `ButtonStyle` customizado**). [4][6]

Ou seja: `.plain` + isFocused-no-label = foco que não registra/atualiza + possível highlight residual + scaleEffect causando jank → "pior". A correção certa é um **`ButtonStyle` customizado** lendo `isFocused` em `makeBody`.

### Evidência por botão (capturas)

Pasta: `context/bugs/bug-4-assets/`.

| Estado | ATUAL (`.card`) | Referência / esperado |
|---|---|---|
| Primário focado | `before-primary-focused.png`: pill vira **quadrado arredondado cinza escurecido + lift** (não cápsula branca) | pill **branca**, texto preto |
| `+` focado | `before-plus-focused.png`: continua **círculo cinza**, vira placa quadrada levantada (não branco) | **círculo branco**, ícone preto |
| `ⓘ` focado | `before-info-focused.png`: idem, placa cinza levantada | **círculo branco**, ícone preto |
| Não focados | sempre com **fundo** (pill branca fixa + círculos cinza fixos) | **planos**, sem fundo |
| Launch | `before-launch-sidebar-open.png`: **sidebar aberta com foco em "Início"** — foco default **não** caiu no hero | sidebar **recolhida**, hero focado |

(`before-full-launch.png` mostra o frame inteiro do launch com a sidebar expandida.)

#### Observação sobre o foco default (sidebar aberta no launch)
`.prefersDefaultFocus(in: heroFocus)` está declarado **dentro de um namespace local do `HeroView`** (`@Namespace private var heroFocus`), que **não** é o foco default da tela. Com `TabView(.sidebarAdaptable)` (`RootView.swift`), no launch o tvOS entrega o foco à **sidebar**, não ao hero — por isso a sidebar abre expandida (`before-launch-sidebar-open.png` / `before-full-launch.png`). Confirmado: **quando o foco está no hero, a sidebar recolhe** (`after-hero-focused-sidebar-collapsed.png`). Isso é **pré-existente e ortogonal** ao hover; o fix do hover **não** o altera (e também não o piora). Ver "Nota" no item 2 para a correção opcional. `HomeView` ainda tem um `@Namespace heroFocus` **declarado e nunca usado** (ruído, não causa do bug).

---

## 2. Fix mínimo e fiel — `HeroView.swift` (before / after)

Um `ButtonStyle` customizado lendo `@Environment(\.isFocused)` em `makeBody` (caminho idiomático e suportado em tvOS [3][5]): não focado = plano (conteúdo branco, fundo `clear`); focado = preenchimento branco + conteúdo preto + escala sutil; **sem placa de card**. Mantém `Button` real → continua focável e respeita `.prefersDefaultFocus(in:)`.

### BEFORE (`main`)
```swift
@ViewBuilder
private func ctaRow(for item: MediaItem) -> some View {
    HStack(spacing: 24) {
        Button(action: {}) {
            Text("Reproduzir")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 40)
                .padding(.vertical, 18)
                .background(Theme.fill, in: Capsule())
        }
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
```

### AFTER (fiel — buildado e testado no simulador)
```swift
@ViewBuilder
private func ctaRow(for item: MediaItem) -> some View {
    HStack(spacing: 24) {
        Button(action: {}) {
            Text("Reproduzir")
                .font(.system(size: 26, weight: .semibold))
        }
        .buttonStyle(HeroButtonStyle(shape: .capsule))
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
    }
    .buttonStyle(HeroButtonStyle(shape: .circle))
}
```

E adicionar (mesmo arquivo, fora do `struct HeroView`):
```swift
private struct HeroButtonStyle: ButtonStyle {
    enum Shape { case capsule, circle }
    var shape: Shape

    @Environment(\.isFocused) private var isFocused   // válido dentro de makeBody em tvOS

    func makeBody(configuration: Configuration) -> some View {
        let active = isFocused
        return Group {
            switch shape {
            case .capsule:
                configuration.label
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(active ? Color.black : Theme.textPrimary)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .background(
                        Capsule().fill(active ? AnyShapeStyle(Theme.fill) : AnyShapeStyle(Color.clear))
                    )
            case .circle:
                configuration.label
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(active ? Color.black : Theme.textPrimary)
                    .frame(width: 64, height: 64)
                    .background(
                        Circle().fill(active ? AnyShapeStyle(Theme.fill) : AnyShapeStyle(Color.clear))
                    )
            }
        }
        .scaleEffect(configuration.isPressed ? 1.04 : (active ? 1.08 : 1.0))
        .animation(.easeOut(duration: 0.18), value: active)
        .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
```

Notas:
- **Por que `ButtonStyle` e não label-`isFocused`:** `ButtonStyleConfiguration` **não** expõe foco (só `role`/`label`/`isPressed`); `@Environment(\.isFocused)` lido **em `makeBody`** atualiza certo porque a body fica dentro do ancestral focável do Button — diferente do label, onde não atualiza. [3][5]
- **Não usar `.card`/`.plain`/`.focusEffectDisabled`** aqui: `.card` traz a placa; `.plain` tem bugs de focabilidade/`FocusValues`; `.focusEffectDisabled` é não confiável no Button de tvOS. O `ButtonStyle` custom já substitui todo o visual de foco. [1][4][6]
- **Escala sutil** (1.08) sem `.clipped()` em ancestral apertado → sem corte/jank. O `infoBlock` tem `padding(.top, 8)` e o hero tem folga; não há clipping do lift.
- **Foco default / sidebar (opcional, fora do escopo do hover):** para a Home abrir com o hero focado (sidebar recolhida, como na referência), elevar a preferência ao nível da tela — ex.: em `HomeView`, usar o `@Namespace heroFocus` que já existe e propagá-lo ao `HeroView` aplicando `.focusScope`/`.prefersDefaultFocus` no nível certo, ou marcar a seção do hero como default da tela. **Não** é necessário para corrigir o "hover zuado" e foi mantido fora deste fix para diff mínimo.

---

## 3. Verificação (capturas da cópia — before vs after)

Build `** BUILD SUCCEEDED **` e `** TEST SUCCEEDED **` na cópia; estados de foco dirigidos por `XCUIRemote` e capturados em runtime.

| Estado | Before (`.card`) | After (`HeroButtonStyle`) |
|---|---|---|
| Primário focado | `before-primary-focused.png` (quadrado cinza escurecido + lift) | `after-primary-focused.png` (**cápsula branca, texto preto**) ✓ |
| `+` focado | `before-plus-focused.png` (círculo cinza, placa levantada) | `after-plus-focused.png` (**círculo branco, `+` preto**) ✓ |
| `ⓘ` focado | `before-info-focused.png` (círculo cinza, placa levantada) | `after-info-focused.png` (**círculo branco, ícone preto**) ✓ |
| Não focados | sempre com fundo (pill/círculos sólidos) | **planos** — texto/ícones brancos, sem fundo ✓ |
| Hero focado | sidebar abria no launch | `after-hero-focused-sidebar-collapsed.png`: sidebar recolhe quando o foco está no hero ✓ |

Resultado: o após bate com `references/hero/hero.png` (primário focado = pill branca; secundários planos) e com `references/hero/hero hover next title.png` (foco no `›`/secundário = círculo branco; primário volta a texto plano). Sem placa de card, sem círculos cinza fixos, sem inversão de foco.

Arquivo completo aplicado/testado: `/tmp/sh-bug4/StreamHub/Features/Home/HeroView.swift`.

---

## Fontes (pesquisa)
1. Apple — `CardButtonStyle` (Liquid Glass no foco; conteúdo edge-to-edge; uso tipo card/pôster): https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/card
2. Apple — `borderedProminent` ("In tvOS, applies a Liquid Glass effect when the button gains focus"): https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/borderedprominent
3. Apple — `EnvironmentValues.isFocused` ("whether the nearest focusable ancestor has focus"): https://developer.apple.com/documentation/swiftui/environmentvalues/isfocused
4. Apple Developer Forums — `.focusEffectDisabled` não confiável no Button de tvOS; DTS recomenda `ButtonStyle` customizado: https://developer.apple.com/forums/thread/780128
5. Apple — `ButtonStyleConfiguration` (só `role`/`label`/`isPressed`; sem foco → ler `@Environment(\.isFocused)` em `makeBody`): https://developer.apple.com/documentation/swiftui/buttonstyleconfiguration
6. Apple Developer Forums — `PlainButtonStyle()` quebra `FocusValues` em tvOS: https://developer.apple.com/forums/thread/670315
7. Apple — `.plain` PrimitiveButtonStyle ("may apply a visual effect to indicate the pressed, focused, or enabled state"): https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/plain

O padrão visual exato do botão de hero do app Apple TV é proprietário (sem doc pública dedicada); a verdade de referência são os screenshots em `references/hero/`, dos quais o comportamento acima foi reproduzido e verificado no simulador.
