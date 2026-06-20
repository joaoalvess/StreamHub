# Data Model — StreamHub (Fase 1, mock)

> Contrato CONGELADO. Todas as Views codam contra estes tipos. Definidos em `StreamHub/Models/`. Dados em `StreamHub/Models/MockData.swift`.

## `MediaItem` (`Models/MediaItem.swift`)
```swift
import Foundation

struct MediaItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let kind: Kind                 // .movie | .series
    let genres: [String]           // ex.: ["Suspense", "Drama"]
    let posterURL: URL?            // 2:3 portrait
    let backdropURL: URL?          // 16:9 landscape
    let logoURL: URL?              // wordmark PNG transparente (opcional)
    let synopsis: String
    let year: Int
    let serviceBadge: String?      // SF Symbol ou texto curto: "tv", "HBO", etc. (opcional p/ Fase 1)

    // Específico de "Continue Assistindo":
    let progress: Double?          // 0...1, nil se não aplicável
    let episodeLabel: String?      // "T1, E8 · 15 min" ou "1 h 16 min"

    enum Kind: String { case movie, series }
}
```
Init com `id: UUID = UUID()` por padrão. `Hashable`/`Identifiable` para uso em `ForEach`.

## `MediaRow` (`Models/MediaRow.swift`)
```swift
import Foundation

struct MediaRow: Identifiable {
    let id: UUID
    let title: String              // "Continue Assistindo", "Top 10 séries no Apple TV"
    let style: Style
    let items: [MediaItem]

    enum Style { case standard, continueWatching, top10 }
}
```
Init com `id: UUID = UUID()` por padrão.

## `MockData` (`Models/MockData.swift`) — a ser CURADO por subagente
Expor:
```swift
enum MockData {
    static let heroItems: [MediaItem]   // 4–6 títulos p/ o carrossel do hero (com backdrop + logo/título + synopsis)
    static let rows: [MediaRow]         // na ordem da Home (ver home-spec.md)
}
```

### Conteúdo alvo (bater com as referências quando possível)
- **Hero:** Servant (Apple TV+), e mais alguns destaques cinematográficos (ex.: The Boys, Animais Fantásticos, For All Mankind, Monarch).
- **Continue Assistindo (16:9, com `progress` + `episodeLabel`):** The Big Bang Theory ("T1, E8 · 15 min"), O Mundo Sombrio de Sabrina/equivalente, Pânico ("17 min"), Pesadelo na Cozinha ("T5, E3 · 49 min"), Hazbin Hotel ("T2, E5 · 27 min"). Use títulos reais com backdrops.
- **Top 10 séries no Apple TV (portrait, rank 1..10):** Seus Amigos Vizinhos, Monarch: Legado de Monstros, Margô Está em Apuros, Mulheres Imperfeitas, For All Mankind, Falando a Real... (gênero abaixo).
- **Top 10 filmes no Apple TV (portrait, rank 1..10):** seleção de 10 filmes populares.
- **(Opcional) rows padrão extras:** "Em alta", "Porque você assistiu...", etc., com pôsteres 2:3.

### Imagens — regra
- Usar CDN do TMDB: backdrops `https://image.tmdb.org/t/p/w1280<path>.jpg`, pôsteres `https://image.tmdb.org/t/p/w500<path>.jpg`, logos `https://image.tmdb.org/t/p/w500<path>.png` (quando houver).
- **Validar cada URL com `curl -sI` → HTTP 200** antes de fixar. Substituir qualquer 404.
- `logoURL` é opcional: se não houver wordmark confiável, deixar `nil` (HeroView cai no título em texto).
