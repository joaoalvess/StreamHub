import SwiftUI

struct HeroView: View {
    let items: [MediaItem]
    var heroFocused: FocusState<Bool>.Binding? = nil
    var heroTint: Binding<Color>? = nil
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) { pageDots }
        .onAppear { syncTint() }
        .onChange(of: index) { _, _ in syncTint() }
    }

    private func syncTint() {
        heroTint?.wrappedValue = current?.tint ?? Theme.bg
    }

    @ViewBuilder
    private var pageDots: some View {
        if items.count > 1 {
            HStack(spacing: 10) {
                ForEach(items.indices, id: \.self) { i in
                    Circle()
                        .fill(Theme.textPrimary.opacity(i == index ? 1 : 0.35))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 28)
            .animation(.easeInOut(duration: 0.2), value: index)
        }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            }
            .buttonStyle(HeroButtonStyle(shape: .capsule))
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
        }
        .buttonStyle(HeroButtonStyle(shape: .circle))
        .heroFocusTracked(heroFocused)
    }
}

private struct HeroButtonStyle: ButtonStyle {
    enum Shape { case capsule, circle }
    var shape: Shape

    @Environment(\.isFocused) private var isFocused

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

#Preview {
    HeroView(items: [
        MediaItem(
            title: "Servant",
            kind: .series,
            genres: ["Suspense", "Drama"],
            posterURL: nil,
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/7nsRpSCYcDGLcDmFAISHC8zMQ0D.jpg"),
            logoURL: nil,
            synopsis: "No meio de uma disputa conjugal, um casal enlutado encontra uma força sinistra dentro de sua própria casa.",
            year: 2019
        )
    ])
    .frame(height: 700)
    .background(Theme.bg)
}
