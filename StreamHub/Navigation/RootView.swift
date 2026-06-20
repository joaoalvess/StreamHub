import SwiftUI

struct RootView: View {
    enum Section: Hashable { case search, home, appleTV, loja, biblioteca }

    @State private var selection: Section = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab("Buscar", systemImage: "magnifyingglass", value: Section.search, role: .search) {
                SearchPlaceholderView()
            }
            Tab("Início", systemImage: "house", value: Section.home) {
                HomeView()
            }
            Tab("Apple TV", systemImage: "tv", value: Section.appleTV) {
                AppleTVPlaceholderView()
            }
            Tab("Loja", systemImage: "bag", value: Section.loja) {
                LojaPlaceholderView()
            }
            Tab("Biblioteca", systemImage: "rectangle.stack", value: Section.biblioteca) {
                BibliotecaPlaceholderView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .preferredColorScheme(.dark)
        .background(Theme.bg)
    }
}

#Preview {
    RootView()
}
