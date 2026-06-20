# Navigation Spec — StreamHub (Fase 1)

## Decisão: SIDEBAR nativo (resolvido por ground-truth dos HEICs)
Os arquivos `references/header/header *.heic` mostram que a navegação expandida do Apple TV (versão PT-BR das refs) é uma **sidebar à esquerda**, que **colapsa** para um pill "Início" no topo-esquerdo quando o foco está no conteúdo.

→ Usar **`TabView` nativo** com **`.tabViewStyle(.sidebarAdaptable)`** (tvOS 18+; atual no 27). Isso entrega exatamente o comportamento colapsar/expandir, sem header custom. (O `references/search/search harry potter.png` mostra uma barra superior em inglês — é de OUTRA fonte; usar só para o layout de resultados de busca numa fase futura, NÃO para a navegação.)

## Sidebar de referência (estado expandido)
Topo: avatar do usuário "Joao". Itens: 🔍 Buscar · 🏠 Início (selecionado) · Apple TV · MLS · 🛒 Loja · 📚 Biblioteca. Seção "Canais e Apps": Disney+, Globoplay, HBO Max, Paramount+.

## `Navigation/RootView.swift` (Fase 1)
```swift
struct RootView: View {
    enum Section: Hashable { case search, home, appleTV, loja, biblioteca }
    @State private var selection: Section = .home
    var body: some View {
        TabView(selection: $selection) {
            Tab("Buscar", systemImage: "magnifyingglass", value: Section.search, role: .search) { SearchPlaceholderView() }
            Tab("Início", systemImage: "house", value: Section.home) { HomeView() }
            Tab("Apple TV", systemImage: "tv", value: Section.appleTV) { AppleTVPlaceholderView() }
            Tab("Loja", systemImage: "bag", value: Section.loja) { LojaPlaceholderView() }
            Tab("Biblioteca", systemImage: "rectangle.stack", value: Section.biblioteca) { BibliotecaPlaceholderView() }
        }
        .tabViewStyle(.sidebarAdaptable)
        .preferredColorScheme(.dark)
        .background(Theme.bg)
    }
}
```
- Selecionar `.home` por padrão (Início é a tela principal da Fase 1).
- API de **`Tab` baseada em valor** (não `.tabItem`). `Tab(role: .search)` p/ a aba de busca.
- **Evitar `TabSection`** na Fase 1 (bug reportado de foco com `.sidebarAdaptable` no tvOS). A seção "Canais e Apps" + avatar ficam para polimento (ver next-phases.md).

## Integração
- `StreamHub/StreamHubApp.swift`: trocar `ContentView()` por `RootView()`.
- `ContentView.swift` pode ser removido/esvaziado (substituído por `RootView`). Como o projeto usa synchronized groups, basta criar/editar os arquivos; sem mexer no `project.pbxproj`.
