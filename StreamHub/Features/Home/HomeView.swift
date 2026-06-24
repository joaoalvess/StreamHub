import SwiftUI

struct HomeView: View {
    @FocusState private var heroFocused: Bool
    @State private var heroTint: Color = Theme.bg

    private enum ScrollAnchor: Hashable { case top }

    var body: some View {
        ZStack {
            Theme.homeBackground(tint: heroTint)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.45), value: heroTint)

            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: Theme.Metrics.rowSpacing) {
                        HeroView(items: MockData.heroItems, heroFocused: $heroFocused, heroTint: $heroTint)
                            .id(ScrollAnchor.top)
                            .containerRelativeFrame(.vertical) { height, _ in height * 0.9 }

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
                .defaultFocus($heroFocused, true)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
