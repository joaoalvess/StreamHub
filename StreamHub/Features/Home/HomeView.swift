import SwiftUI

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

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
