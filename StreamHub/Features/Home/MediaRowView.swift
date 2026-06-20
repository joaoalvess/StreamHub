import SwiftUI

struct MediaRowView: View {
    let row: MediaRow

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Metrics.titleGap) {
            Text(row.title)
                .font(Theme.Font.sectionTitle)
                .foregroundStyle(Theme.textPrimary)
                .padding(.leading, Theme.Metrics.edgeH)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Theme.Metrics.cardSpacing) {
                    ForEach(Array(row.items.enumerated()), id: \.element.id) { idx, item in
                        switch row.style {
                        case .standard:
                            MediaCardView(item: item)
                        case .continueWatching:
                            ContinueWatchingCardView(item: item)
                        case .top10:
                            Top10CardView(rank: idx + 1, item: item)
                        }
                    }
                }
                .padding(.leading, Theme.Metrics.edgeH)
                .padding(.trailing, Theme.Metrics.edgeH)
                .padding(.vertical, Theme.Metrics.focusHeadroom)
            }
            .focusSection()
        }
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: Theme.Metrics.rowSpacing) {
            ForEach(MockData.rows) { row in
                MediaRowView(row: row)
            }
        }
    }
    .background(Theme.backgroundGradient)
}
