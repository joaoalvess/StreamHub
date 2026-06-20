import SwiftUI

struct AppleTVPlaceholderView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "tv")
                    .font(.system(size: 120, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)

                Text("Apple TV")
                    .font(Theme.Font.sectionTitle)
                    .foregroundStyle(Theme.textSecondary)

                Text("Em breve")
                    .font(Theme.Font.meta)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }
}

#Preview {
    AppleTVPlaceholderView()
}
