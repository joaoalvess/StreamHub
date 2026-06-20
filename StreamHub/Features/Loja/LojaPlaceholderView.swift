import SwiftUI

struct LojaPlaceholderView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "bag")
                    .font(.system(size: 120, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)

                Text("Loja")
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
    LojaPlaceholderView()
}
