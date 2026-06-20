import Foundation

struct MediaRow: Identifiable {
    let id: UUID
    let title: String
    let style: Style
    let items: [MediaItem]

    enum Style {
        case standard
        case continueWatching
        case top10
    }

    init(id: UUID = UUID(), title: String, style: Style, items: [MediaItem]) {
        self.id = id
        self.title = title
        self.style = style
        self.items = items
    }
}
