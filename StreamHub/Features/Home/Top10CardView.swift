import SwiftUI

struct Top10CardView: View {
    let rank: Int
    let item: MediaItem

    private let numeralSize: CGFloat = 240
    private let numeralLeading: CGFloat = 8
    private let posterInset: CGFloat = 96

    private var cellWidth: CGFloat {
        posterInset + Theme.Size.posterWidth
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            artwork
            caption
                .padding(.leading, posterInset)
                .frame(width: cellWidth, alignment: .leading)
        }
    }

    private var artwork: some View {
        ZStack(alignment: .bottomLeading) {
            numeral
            Button(action: {}) {
                poster
            }
            .buttonStyle(.card)
            .padding(.leading, posterInset)
        }
        .frame(width: cellWidth, alignment: .leading)
    }

    private var numeral: some View {
        Text("\(rank)")
            .font(.system(size: numeralSize, weight: .heavy))
            .foregroundStyle(Theme.textPrimary.opacity(0.9))
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
            .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 6)
            .padding(.leading, numeralLeading)
            .accessibilityHidden(true)
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

    private var caption: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(Theme.Font.cardTitle)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            if let genre = item.genres.first {
                Text(genre)
                    .font(Theme.Font.meta)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    HStack(alignment: .top, spacing: Theme.Metrics.cardSpacing) {
        Top10CardView(
            rank: 1,
            item: MediaItem(
                title: "Seus Amigos Vizinhos",
                kind: .series,
                genres: ["Drama"],
                posterURL: URL(string: "https://image.tmdb.org/t/p/w500/q6cYZjQAfvJqGGz0e0HQVwL2zFD.jpg"),
                backdropURL: nil,
                synopsis: "Um psicanalista de Westchester vê a própria vida desmoronar e passa a roubar dos ricos vizinhos.",
                year: 2024
            )
        )
        Top10CardView(
            rank: 10,
            item: MediaItem(
                title: "For All Mankind",
                kind: .series,
                genres: ["Ficção Científica"],
                posterURL: URL(string: "https://image.tmdb.org/t/p/w500/q6cYZjQAfvJqGGz0e0HQVwL2zFD.jpg"),
                backdropURL: nil,
                synopsis: "Uma releitura da corrida espacial em que a União Soviética chega primeiro à Lua.",
                year: 2019
            )
        )
    }
    .padding(Theme.Metrics.focusHeadroom)
    .background(Theme.backgroundGradient)
}
