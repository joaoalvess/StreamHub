---
titulo: "Integração nativa de addons no StreamHub (SwiftUI/tvOS)"
parte_de: "docs/addons"
objetivo: "Traduzir o protocolo de addons do Stremio para uma arquitetura nativa em Swift: modelos Codable, protocolo Addon, AddonManager com agregação, mapeamento para a UI atual e plano de implementação em fases."
ordem: 6
tipo: guia-de-implementacao
relevancia_para_streamhub: alta
atualizado_em: "2026-06-24"
fontes:
  - "manifest.md"
  - "recursos.md"
  - "descoberta-e-agregacao.md"
codigo_referenciado:
  - "StreamHub/Models/MediaItem.swift"
  - "StreamHub/Models/MediaRow.swift"
  - "StreamHub/Models/MockData.swift"
  - "StreamHub/Features/Home/HomeView.swift"
  - "StreamHub/Features/Home/MediaRowView.swift"
  - "StreamHub/Navigation/RootView.swift"
  - "StreamHub/Features/Loja/LojaPlaceholderView.swift"
---

# Integração nativa de addons no StreamHub (SwiftUI/tvOS)

## TL;DR

- O StreamHub vai ter **3–4 addons nativos in-process** (objetos Swift), não servidores HTTP. Não há
  instalação por URL, conta, CORS nem publicação.
- Reaproveitamos do Stremio **3 coisas**: (1) o **contrato de dados** (manifest + `catalog`/`meta`/
  `stream`/`subtitles`), (2) as **convenções de id**, (3) a **lógica de agregação** (filtragem por
  `types`/`idPrefixes`, ordem, fall-through). Ver [descoberta-e-agregacao.md](./descoberta-e-agregacao.md).
- Camadas novas em Swift: **Modelos Codable** (espelham o protocolo) → **protocolo `Addon`** → **`AddonManager`**
  (agrega) → **ViewModels** → **UI existente** (`HomeView`, `MediaRowView`) + telas novas (Detalhe, Player) + a aba **Loja** (lista de addons).
- O `MediaItem` atual usa `UUID` e não tem id estável de conteúdo — **precisa ganhar um `contentId: String`**
  (ex.: `tt1254207`) para casar com o protocolo.
- **Reprodução no tvOS:** `AVPlayer` toca `stream.url` (HLS/MP4 via HTTPS). `infoHash` (torrent) e
  `ytId` **não** tocam nativamente sem motor extra — priorize fontes `url` diretas (ex.: debrid).

---

## 1. Arquitetura de camadas

```
┌─────────────────────────────────────────────────────────────────────┐
│ UI (SwiftUI / tvOS)                                                   │
│   HomeView · MediaRowView · DetailView(novo) · PlayerView(novo) ·     │
│   LojaView(addons)                                                    │
└───────────────▲───────────────────────────────────────────────────────┘
                │ consome view models (MediaRow/MediaItem + estados)
┌───────────────┴───────────────────────────────────────────────────────┐
│ ViewModels (@Observable)                                              │
│   HomeViewModel · DetailViewModel · LojaViewModel                     │
└───────────────▲───────────────────────────────────────────────────────┘
                │ pede catálogos/meta/streams agregados
┌───────────────┴───────────────────────────────────────────────────────┐
│ AddonManager (actor) — AGREGAÇÃO                                      │
│   board() · catalog() · meta() · streams() · subtitles()             │
│   replica is_resource_supported + AggrRequest (ordem, fall-through)  │
└───────────────▲───────────────────────────────────────────────────────┘
                │ chama os addons registrados (ordem = prioridade)
┌───────────────┴───────────────────────────────────────────────────────┐
│ protocolo Addon (in-process)                                         │
│   TMDBCatalogAddon · DebridStreamAddon · OpenSubtitlesAddon · …      │
│   cada um implementa só os recursos que declara no seu manifest      │
└───────────────▲───────────────────────────────────────────────────────┘
                │ usa structs Codable que espelham o protocolo Stremio
┌───────────────┴───────────────────────────────────────────────────────┐
│ Modelos (Codable): AddonManifest · MetaPreview · Meta · Video ·      │
│   Stream · Subtitle · CatalogRequest · …                             │
└───────────────────────────────────────────────────────────────────────┘
```

Sugestão de organização de arquivos (novos):

```
StreamHub/
  Addons/
    Models/          AddonManifest.swift, Meta.swift, Stream.swift, Subtitle.swift, Requests.swift
    Addon.swift              # protocolo + capability/supports
    AddonManager.swift       # actor de agregação
    Providers/               # os addons nativos
      TMDBCatalogAddon.swift
      DebridStreamAddon.swift
      OpenSubtitlesAddon.swift
  Features/
    Detail/DetailView.swift + DetailViewModel.swift     # novo (recurso meta)
    Player/PlayerView.swift                             # novo (recurso stream)
    Loja/LojaView.swift                                 # substitui o placeholder
    Home/HomeViewModel.swift                            # novo (alimenta HomeView)
```

## 2. Mapeamento conceitual Stremio ↔ StreamHub

| Conceito Stremio | No StreamHub |
|---|---|
| addon (servidor HTTP) | objeto Swift que implementa o protocolo `Addon` (in-process) |
| `manifest.json` | struct `AddonManifest` (em código) |
| instalar addon por URL | registrar o addon na lista do `AddonManager` |
| addon collection (conta) | lista local de addons + flags de habilitado (persistida no device) |
| `catalog` (lista de itens) | uma **`MediaRow`** (`row.title` = nome do catálogo; `items` = `MetaPreview→MediaItem`) |
| Board (todos os catálogos) | as rows da **`HomeView`** (hoje `MockData.rows`) |
| `MetaPreview` | **`MediaItem`** (versão de card) |
| `meta` (detalhe) | **`DetailView`** (nova) + um `MediaItem`/`Meta` rico |
| `Video` (episódio) | item de uma lista de episódios na DetailView |
| `stream` | **`PlayerView`** (nova) tocando `stream.url` |
| `subtitles` | faixas de legenda no player |
| Cinemeta (ids `tt`) | um addon nativo de metadados pode consumir o endpoint público do Cinemeta/TMDB |
| Continue Assistindo / Biblioteca | **estado local** (não é addon): progresso, `episodeLabel`, favoritos |
| `serviceBadge`, `tint` | **decisão de UI** (derivada ou local), não vem do addon |

> Observação sobre `type`: o protocolo usa `movie`/`series`/`channel`/`tv`; o `MediaItem.Kind` atual
> só tem `.movie`/`.series`. Se for usar `channel`/`tv`, estenda o enum (ou guarde o `type` como
> `String`).

## 3. Modelos Codable (espelham o protocolo)

> Estas structs são a tradução 1:1 de [recursos.md](./recursos.md) e [manifest.md](./manifest.md).
> `Sendable` para cruzar o `actor AddonManager`. Campos opcionais = tolerância de decode.

```swift
import Foundation

// MARK: Manifest

struct AddonManifest: Codable, Sendable {
    let id: String
    let version: String
    let name: String
    let description: String
    var logo: String?
    var background: String?
    let types: [String]
    let resources: [AddonResource]
    var idPrefixes: [String]?
    var catalogs: [CatalogDefinition] = []
    var behaviorHints: ManifestBehaviorHints?
}

struct ManifestBehaviorHints: Codable, Sendable {
    var adult: Bool?
    var p2p: Bool?
    var configurable: Bool?
    var configurationRequired: Bool?
}

struct CatalogDefinition: Codable, Sendable, Identifiable {
    let type: String
    let id: String
    let name: String
    var extra: [ExtraDefinition]?
}

struct ExtraDefinition: Codable, Sendable {
    let name: String              // "search" | "genre" | "skip"
    var isRequired: Bool?
    var options: [String]?
    var optionsLimit: Int?
}

/// resources[] pode ser uma string OU { name, types, idPrefixes? } — ver manifest.md §2.
enum AddonResource: Codable, Sendable {
    case simple(String)
    case full(name: String, types: [String], idPrefixes: [String]?)

    var name: String {
        switch self {
        case .simple(let n): return n
        case .full(let n, _, _): return n
        }
    }

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let s = try? single.decode(String.self) {
            self = .simple(s); return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self = .full(
            name: try c.decode(String.self, forKey: .name),
            types: try c.decode([String].self, forKey: .types),
            idPrefixes: try c.decodeIfPresent([String].self, forKey: .idPrefixes)
        )
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .simple(let s):
            var c = encoder.singleValueContainer(); try c.encode(s)
        case .full(let name, let types, let idPrefixes):
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(name, forKey: .name)
            try c.encode(types, forKey: .types)
            try c.encodeIfPresent(idPrefixes, forKey: .idPrefixes)
        }
    }

    private enum CodingKeys: String, CodingKey { case name, types, idPrefixes }
}

// MARK: Conteúdo

struct MetaPreview: Codable, Sendable, Identifiable {
    let id: String                // ex.: "tt1254207" (id estável!)
    let type: String
    let name: String
    var poster: String?
    var posterShape: String?
    var genres: [String]?
    var imdbRating: String?
    var releaseInfo: String?
    var description: String?
}

struct Meta: Codable, Sendable, Identifiable {
    let id: String
    let type: String
    let name: String
    var poster: String?
    var posterShape: String?
    var background: String?
    var logo: String?
    var description: String?
    var releaseInfo: String?
    var imdbRating: String?
    var runtime: String?
    var genres: [String]?
    var cast: [String]?
    var director: [String]?
    var links: [MetaLink]?
    var videos: [Video]?
    var behaviorHints: MetaBehaviorHints?
}

struct MetaBehaviorHints: Codable, Sendable {
    var defaultVideoId: String?
}

struct MetaLink: Codable, Sendable {
    let name: String
    let category: String          // "actor" | "director" | "writer" | gênero...
    let url: String               // URL externa ou deep link stremio:///
}

struct Video: Codable, Sendable, Identifiable {
    let id: String                // série: "tt0108778:1:1"
    let title: String             // É "title", não "name"
    var released: String?
    var season: Int?
    var episode: Int?
    var thumbnail: String?
    var overview: String?
    var streams: [Stream]?        // se presente, NÃO pede streams a outros addons p/ este vídeo
}

struct Stream: Codable, Sendable {
    // Exatamente UMA fonte:
    var url: String?
    var ytId: String?
    var infoHash: String?
    var fileIdx: Int?
    var externalUrl: String?
    // Informativos:
    var name: String?             // normalmente a qualidade ("1080p")
    var title: String?            // (deprecando → description)
    var description: String?
    var subtitles: [Subtitle]?
    var behaviorHints: StreamBehaviorHints?
}

struct StreamBehaviorHints: Codable, Sendable {
    var bingeGroup: String?
    var notWebReady: Bool?
    var countryWhitelist: [String]?
    var videoHash: String?
    var videoSize: Int?
    var filename: String?
}

struct Subtitle: Codable, Sendable, Identifiable {
    let id: String
    let url: String
    let lang: String
}

// MARK: Envelopes de resposta (como o protocolo retorna)

struct CatalogResponse: Codable, Sendable { let metas: [MetaPreview] }
struct MetaResponse: Codable, Sendable { let meta: Meta }
struct StreamResponse: Codable, Sendable { let streams: [Stream] }
struct SubtitlesResponse: Codable, Sendable { let subtitles: [Subtitle] }

// MARK: Requests

struct CatalogRequest: Sendable {
    let type: String
    let id: String
    var extra = CatalogExtra()
}
struct CatalogExtra: Sendable {
    var search: String?
    var genre: String?
    var skip: Int?
}
struct SubtitlesExtra: Sendable {
    var videoHash: String?
    var videoSize: Int?
    var filename: String?
}
```

## 4. Protocolo `Addon` + capacidade + `AddonManager`

### 4.1 Protocolo `Addon`

Implementações default vazias fazem cada addon implementar **só** os recursos que declara.

```swift
protocol Addon: Sendable {
    var manifest: AddonManifest { get }
    func catalog(_ request: CatalogRequest) async throws -> [MetaPreview]
    func meta(type: String, id: String) async throws -> Meta?
    func streams(type: String, videoId: String) async throws -> [Stream]
    func subtitles(type: String, videoId: String, extra: SubtitlesExtra) async throws -> [Subtitle]
}

extension Addon {
    func catalog(_ request: CatalogRequest) async throws -> [MetaPreview] { [] }
    func meta(type: String, id: String) async throws -> Meta? { nil }
    func streams(type: String, videoId: String) async throws -> [Stream] { [] }
    func subtitles(type: String, videoId: String, extra: SubtitlesExtra) async throws -> [Subtitle] { [] }
}
```

### 4.2 Capacidade (`is_resource_supported` em Swift)

Tradução direta da regra em [descoberta-e-agregacao.md](./descoberta-e-agregacao.md) §B1.

```swift
extension AddonManifest {
    /// (types, idPrefixes) efetivos para um recurso (objeto sobrescreve; string cai p/ o topo).
    func capability(for resource: String) -> (types: [String], idPrefixes: [String]?)? {
        for res in resources {
            switch res {
            case .simple(let n) where n == resource:
                return (types, idPrefixes)
            case .full(let n, let t, let pfx) where n == resource:
                return (t, pfx ?? idPrefixes)
            default:
                continue
            }
        }
        return nil
    }

    /// Vale para meta/stream/subtitles. (catalog é tratado pelo board + extra.)
    func supports(resource: String, type: String, id: String) -> Bool {
        guard let cap = capability(for: resource) else { return false }
        let typeOK = cap.types.contains(type)
        let idOK: Bool
        if let prefixes = cap.idPrefixes, !prefixes.isEmpty {
            idOK = prefixes.contains { id.hasPrefix($0) }
        } else {
            idOK = true            // sem idPrefixes ⇒ todos os ids
        }
        return typeOK && idOK
    }
}
```

### 4.3 `AddonManager` (agregação)

```swift
actor AddonManager {
    private let addons: [any Addon]   // ordem = prioridade (= "ordem de instalação")

    init(addons: [any Addon]) { self.addons = addons }

    // BOARD: todos os catálogos sem extra obrigatório, na ordem dos addons.
    func board() -> [(addon: any Addon, catalog: CatalogDefinition)] {
        addons.flatMap { addon in
            addon.manifest.catalogs
                .filter { !($0.extra?.contains { $0.isRequired == true } ?? false) }
                .map { (addon, $0) }
        }
    }

    // Catálogos que declaram busca (para a aba Buscar).
    func searchCatalogs() -> [(addon: any Addon, catalog: CatalogDefinition)] {
        addons.flatMap { addon in
            addon.manifest.catalogs
                .filter { $0.extra?.contains { $0.name == "search" } ?? false }
                .map { (addon, $0) }
        }
    }

    func items(for addon: any Addon, catalog: CatalogDefinition,
               extra: CatalogExtra = .init()) async -> [MetaPreview] {
        (try? await addon.catalog(CatalogRequest(type: catalog.type, id: catalog.id, extra: extra))) ?? []
    }

    // META: primeiro addon que suporta e responde (fall-through).
    func meta(type: String, id: String) async -> Meta? {
        for addon in addons where addon.manifest.supports(resource: "meta", type: type, id: id) {
            if let m = try? await addon.meta(type: type, id: id) { return m }
        }
        return nil
    }

    // STREAMS: todos os addons que suportam, em paralelo, preservando a ordem dos addons.
    func streams(type: String, videoId: String) async -> [Stream] {
        let matching = addons.enumerated()
            .filter { $0.element.manifest.supports(resource: "stream", type: type, id: videoId) }
        return await withTaskGroup(of: (Int, [Stream]).self) { group in
            for (index, addon) in matching {
                group.addTask { (index, (try? await addon.streams(type: type, videoId: videoId)) ?? []) }
            }
            var byIndex: [(Int, [Stream])] = []
            for await pair in group { byIndex.append(pair) }
            return byIndex.sorted { $0.0 < $1.0 }.flatMap { $0.1 }   // ordem dos addons
        }
    }

    func subtitles(type: String, videoId: String, extra: SubtitlesExtra) async -> [Subtitle] {
        var all: [Subtitle] = []
        for addon in addons where addon.manifest.supports(resource: "subtitles", type: type, id: videoId) {
            all += (try? await addon.subtitles(type: type, videoId: videoId, extra: extra)) ?? []
        }
        return all
    }

    func enabledAddons() -> [AddonManifest] { addons.map(\.manifest) }   // p/ a Loja
}
```

## 5. Ligando à UI existente

### 5.1 `MediaItem` precisa de um id estável

`StreamHub/Models/MediaItem.swift` hoje usa `id: UUID` — isso **perde** o id do protocolo
(`tt1254207`), necessário para pedir `meta`/`stream`. Mudança mínima recomendada: adicionar
`contentId` (e, se for usar `channel`/`tv`, guardar o `type` como string).

```swift
// adicionar em MediaItem (mantém UUID p/ Identifiable/diffing da UI):
let contentId: String?     // id do protocolo, ex.: "tt1254207". nil = item só-mock/local.
```

Mapper `MetaPreview → MediaItem` (os campos que a UI não usa do protocolo ficam nil/derivados):

```swift
extension MediaItem {
    init(preview p: MetaPreview) {
        self.init(
            title: p.name,
            kind: p.type == "series" ? .series : .movie,
            genres: p.genres ?? [],
            posterURL: p.poster.flatMap(URL.init(string:)),
            backdropURL: nil,                                   // MetaPreview não traz background
            synopsis: p.description ?? "",
            year: Int(p.releaseInfo?.prefix(4) ?? "") ?? 0,
            tint: nil
        )
        // contentId/type: setar via init próprio (id estável = p.id)
    }
}
```

> `progress`, `episodeLabel`, `serviceBadge` e `tint` **não** vêm do addon: são estado local
> (Continue Assistindo/Biblioteca) ou estética. Mantenha-os fora do mapeamento do protocolo.

### 5.2 `HomeView` consumindo addons (em vez de `MockData.rows`)

```swift
@Observable @MainActor
final class HomeViewModel {
    private let manager: AddonManager
    var rows: [MediaRow] = []
    init(manager: AddonManager) { self.manager = manager }

    func load() async {
        var built: [MediaRow] = []
        for entry in await manager.board() {
            let metas = await manager.items(for: entry.addon, catalog: entry.catalog)
            guard !metas.isEmpty else { continue }
            built.append(MediaRow(title: entry.catalog.name,
                                  style: rowStyle(for: entry.catalog),
                                  items: metas.map(MediaItem.init(preview:))))
        }
        rows = built
    }

    // Heurística de estilo (decisão de UI; o protocolo não tem "top10"):
    private func rowStyle(for catalog: CatalogDefinition) -> MediaRow.Style {
        catalog.id.localizedCaseInsensitiveContains("top") ? .top10 : .standard
    }
}
```

`HomeView` muda só a fonte das rows (de `MockData.rows` → `viewModel.rows`); `MediaRowView` e o Hero
não precisam mudar. O Hero pode usar os primeiros itens de um catálogo "em alta".

### 5.3 Aba **Loja** = lista de addons

`StreamHub/Features/Loja/LojaPlaceholderView.swift` ("Em breve") vira uma lista dos addons
registrados — no modelo nativo, "instalar/desinstalar" = **habilitar/desabilitar** (persistido com
`@AppStorage`/store próprio). Renderize `manifest.name`, `manifest.description`, `manifest.logo` e os
`resources`/`types` que cada um provê. Opcional: um campo para colar a URL de um addon HTTP externo
(reaproveitando os mesmos modelos Codable via `URLSession`).

### 5.4 Tela de Detalhe e Player (novas)

- **DetailView** ← `manager.meta(type:id:)`. Para séries, lista `meta.videos` (episódios). Ao
  selecionar um vídeo, chama `manager.streams(type:videoId:)`.
- **PlayerView** (tvOS) com `AVKit`:

```swift
import SwiftUI
import AVKit

struct PlayerView: View {
    let stream: Stream
    var body: some View {
        if let s = stream.url, let url = URL(string: s) {
            VideoPlayer(player: AVPlayer(url: url)).ignoresSafeArea()
        } else {
            // infoHash (torrent) / ytId não são reproduzíveis nativamente — ver §7
            Text("Fonte não reproduzível nativamente.")
        }
    }
}
```

## 6. Lacunas no código atual (o que falta para suportar addons)

| Lacuna | Onde | Ação |
|---|---|---|
| Sem id estável de conteúdo | `Models/MediaItem.swift` (`id: UUID`) | Adicionar `contentId: String?` (§5.1). |
| Sem camada de rede | — | `URLSession` nos addons que buscam APIs externas (TMDB/OpenSubtitles/debrid). |
| Conteúdo 100% estático | `Models/MockData.swift` | Vira **fixture de teste/preview**; produção usa `AddonManager`. |
| Sem ViewModels / carregamento assíncrono | `Features/Home/HomeView.swift` | `HomeViewModel` (§5.2). |
| Sem tela de detalhe | — | `Features/Detail/DetailView.swift` (recurso `meta`). |
| Sem player | — | `Features/Player/PlayerView.swift` (recurso `stream`). |
| Loja é placeholder | `Features/Loja/LojaPlaceholderView.swift` | `LojaView` lista/habilita addons (§5.3). |
| Sem persistência | — | Biblioteca, Continue Assistindo e addons habilitados (ex.: `SwiftData`/`UserDefaults`). |
| `Kind` só movie/series | `Models/MediaItem.swift` | Estender se for usar `channel`/`tv`. |

## 7. Reprodução no tvOS (caveat crítico)

| Fonte do Stream | tvOS nativo |
|---|---|
| `url` (HLS `.m3u8` / `.mp4` via HTTPS) | ✅ `AVPlayer`/`VideoPlayer` direto. **Priorize esta fonte.** |
| `externalUrl` | Abrir em outro contexto / deep link; não toca no player. |
| `infoHash` (torrent) | ❌ Não nativo. O Stremio desktop usa um streaming server (`127.0.0.1:11470`) que converte torrent→HTTP. No tvOS você precisaria de um motor de torrent embarcado ou de um **serviço debrid** que devolva `url` HTTPS direto. |
| `ytId` (YouTube) | ❌ Sem player nativo de YouTube no tvOS. |

**Consequência de design:** para um app pessoal de tvOS, o addon de streams mais prático é um que
**resolva para `url` HTTPS direto** — ex.: integração com **Real-Debrid/AllDebrid/Premiumize** (que
convertem torrents/hosters em links diretos) ou apontar para o **seu próprio servidor de mídia**
(Jellyfin/Plex/HTTP). Streams `infoHash` puros não tocarão sem trabalho extra.

## 8. Os 3–4 addons nativos (sugestão)

São exemplos; o contrato (manifest + recursos) é o que importa. Cada um implementa só o que declara.

| # | Addon | Recursos | Fonte interna sugerida | Observação |
|---|---|---|---|---|
| 1 | **Catálogo + Metadados** | `catalog`, `meta` | TMDB (precisa de API key) ou o endpoint público do **Cinemeta** (`https://v3-cinemeta.strem.io`) | Substitui `MockData` (catálogos "Em alta", "Top", busca) e a tela de detalhe. Use ids `tt` para alinhar com Cinemeta. |
| 2 | **Streams** | `stream` | Indexador + **debrid** (Real-Debrid…) que devolve `url` HTTPS | Coração da reprodução; ver §7. Declarar `idPrefixes: ["tt"]`. |
| 3 | **Legendas** | `subtitles` | OpenSubtitles | Faixas no player; usa `videoHash`/`filename`. |
| 4 | *(opcional)* **Biblioteca/Continue** | — | Estado local (não é addon Stremio) | Favoritos e progresso ficam no app, não no protocolo. |

Exemplo de um addon nativo:

```swift
struct OpenSubtitlesAddon: Addon {
    let manifest = AddonManifest(
        id: "local.opensubtitles",
        version: "1.0.0",
        name: "OpenSubtitles",
        description: "Legendas via OpenSubtitles",
        types: ["movie", "series"],
        resources: [.simple("subtitles")],
        idPrefixes: ["tt"]
    )

    func subtitles(type: String, videoId: String, extra: SubtitlesExtra) async throws -> [Subtitle] {
        // chamar a API do OpenSubtitles via URLSession, mapear p/ [Subtitle]
        return []
    }
}
```

Registro no app:

```swift
let manager = AddonManager(addons: [
    TMDBCatalogAddon(apiKey: …),
    DebridStreamAddon(token: …),
    OpenSubtitlesAddon()
])
```

## 9. Plano de implementação em fases

1. **Modelos + protocolo** — adicionar `Addons/Models/*` e `Addon.swift` (§3, §4.1–4.2). Sem UI.
   Testes de decode com JSON real do Cinemeta.
2. **AddonManager + 1 addon de catálogo** — `AddonManager` (§4.3) + um `TMDBCatalogAddon`/Cinemeta.
   `HomeViewModel` alimentando a `HomeView` (§5.2). `MockData` vira fixture.
3. **Detalhe + meta** — `DetailView` consumindo `manager.meta` (filme e série/episódios).
4. **Streams + Player** — addon de streams (debrid → `url`) + `PlayerView` (§5.4, §7).
5. **Legendas** — `OpenSubtitlesAddon` + faixas no player.
6. **Loja + persistência** — `LojaView` (habilitar/desabilitar addons) + Biblioteca/Continue
   Assistindo locais.

## 10. Checklist de fidelidade ao protocolo

- [ ] Ids de conteúdo são **strings estáveis** (ex.: `tt…`), não UUID.
- [ ] `videoId` de série é `imdbId:temporada:episodio`; de filme é o próprio id.
- [ ] `AddonManager` filtra por `types` **e** `idPrefixes` (vazio ⇒ todos) antes de chamar um addon.
- [ ] Catálogos com `extra.isRequired` (ex.: só-busca) **não** entram no Board.
- [ ] `skip` pagina de 100 em 100; <100 itens = fim do catálogo.
- [ ] Streams são concatenados na **ordem dos addons**; cada addon ordena os seus do melhor p/ pior.
- [ ] Streams priorizam `url` HTTPS (tvOS); `infoHash`/`ytId` tratados como não-reproduzíveis ou via debrid.
- [ ] Um addon implementa **só** os recursos que declara em `resources`.
- [ ] Cada addon valida o próprio `manifest` na inicialização (campos obrigatórios — ver
      [sdk-e-deploy.md](./sdk-e-deploy.md) §4).
```
