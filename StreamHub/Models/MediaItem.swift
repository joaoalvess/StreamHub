import Foundation

struct MediaItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let kind: Kind
    let genres: [String]
    let posterURL: URL?
    let backdropURL: URL?
    let logoURL: URL?
    let synopsis: String
    let year: Int
    let serviceBadge: String?
    let progress: Double?
    let episodeLabel: String?

    enum Kind: String {
        case movie
        case series
    }

    init(
        id: UUID = UUID(),
        title: String,
        kind: Kind,
        genres: [String],
        posterURL: URL?,
        backdropURL: URL?,
        logoURL: URL? = nil,
        synopsis: String,
        year: Int,
        serviceBadge: String? = nil,
        progress: Double? = nil,
        episodeLabel: String? = nil
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.genres = genres
        self.posterURL = posterURL
        self.backdropURL = backdropURL
        self.logoURL = logoURL
        self.synopsis = synopsis
        self.year = year
        self.serviceBadge = serviceBadge
        self.progress = progress
        self.episodeLabel = episodeLabel
    }
}
