import SwiftUI

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
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            case .failure:
                Theme.bgElevated
            case .empty:
                ZStack {
                    Theme.bgElevated
                    ProgressView()
                }
            @unknown default:
                Theme.bgElevated
            }
        }
        .frame(width: Theme.Size.posterWidth, height: Theme.Size.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.cardStroke, lineWidth: 1)
        )
    }
}

#Preview {
    MediaCardView(
        item: MediaItem(
            title: "For All Mankind",
            kind: .series,
            genres: ["Drama", "Ficção Científica"],
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/q6cYZjQAfvJqGGz0e0HQVwL2zFD.jpg"),
            backdropURL: nil,
            synopsis: "Uma releitura da corrida espacial em que a União Soviética chega primeiro à Lua.",
            year: 2019
        )
    )
    .padding(Theme.Metrics.focusHeadroom)
    .background(Theme.bg)
}
