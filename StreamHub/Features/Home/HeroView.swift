import SwiftUI

struct HeroView: View {
    let items: [MediaItem]
    @State private var index = 0

    @Namespace private var heroFocus

    private var current: MediaItem? {
        guard !items.isEmpty, items.indices.contains(index) else { return nil }
        return items[index]
    }

    private func metadataLine(for item: MediaItem) -> String {
        let genres = item.genres.joined(separator: " · ")
        switch item.kind {
        case .series:
            return genres.isEmpty ? "Programa de TV" : "Programa de TV · " + genres
        case .movie:
            return genres
        }
    }

    private func advance() {
        guard !items.isEmpty else { return }
        index = (index + 1) % items.count
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backdrop

            Theme.heroGradientVertical
            Theme.heroGradientHorizontal

            if let item = current {
                infoBlock(for: item)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
    }

    private var heroHeight: CGFloat {
        #if os(tvOS)
        return 1080 * 0.58
        #else
        return 600
        #endif
    }

    @ViewBuilder
    private var backdrop: some View {
        AsyncImage(url: current?.backdropURL, transaction: Transaction(animation: .default)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            default:
                ZStack {
                    Theme.bgElevated
                    ProgressView()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
        .clipped()
    }

    @ViewBuilder
    private func infoBlock(for item: MediaItem) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if let logoURL = item.logoURL {
                AsyncImage(url: logoURL, transaction: Transaction(animation: .default)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 520, maxHeight: 200, alignment: .leading)
                            .transition(.opacity)
                    default:
                        ProgressView()
                            .frame(height: 120, alignment: .leading)
                    }
                }
            } else {
                Text(item.title)
                    .font(Theme.Font.heroTitle)
                    .foregroundStyle(Theme.textPrimary)
            }

            Text(metadataLine(for: item))
                .font(Theme.Font.meta)
                .foregroundStyle(Theme.textPrimary)

            Text(item.synopsis)
                .font(Theme.Font.meta)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(3)
                .frame(maxWidth: 720, alignment: .leading)

            ctaRow(for: item)
                .padding(.top, 8)
        }
        .padding(.leading, Theme.Metrics.edgeH)
        .padding(.bottom, Theme.Metrics.edgeH)
        .padding(.trailing, Theme.Metrics.edgeH)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

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
}

#Preview {
    HeroView(items: [
        MediaItem(
            title: "Servant",
            kind: .series,
            genres: ["Suspense", "Drama"],
            posterURL: nil,
            backdropURL: URL(string: "https://image.tmdb.org/t/p/original/8tCpUOJ4xCgC3wM6yGZ0H6S2Bbn.jpg"),
            logoURL: nil,
            synopsis: "No meio de uma disputa conjugal, um casal enlutado encontra uma força sinistra dentro de sua própria casa.",
            year: 2019
        ),
        MediaItem(
            title: "Foundation",
            kind: .series,
            genres: ["Ficção Científica", "Drama"],
            posterURL: nil,
            backdropURL: URL(string: "https://image.tmdb.org/t/p/original/2pFBQQjVACwQYa0puS9k7nOQ9LR.jpg"),
            logoURL: nil,
            synopsis: "Um bando de exilados embarca em uma jornada épica para salvar a humanidade e reconstruir a civilização em meio à queda do Império Galáctico.",
            year: 2021
        )
    ])
    .frame(height: 700)
    .background(Theme.bg)
}
