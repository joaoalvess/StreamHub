import SwiftUI

struct BibliotecaPlaceholderView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 120, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)

                Text("Biblioteca")
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
    BibliotecaPlaceholderView()
}
