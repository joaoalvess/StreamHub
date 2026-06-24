# 07 — Guia de Integração (StreamHub / tvOS)

Receitas de consumo para o StreamHub (app **tvOS/SwiftUI**). Hoje o app usa `MockData`; este guia mostra como substituí-lo pelo AIOMetadata. Foco em **sequência de chamadas**, **mapeamento para os modelos do app** e **práticas de cache/performance**.

> Contexto nativo: por ser um app nativo (não navegador), **CORS é irrelevante**. O único cuidado de transporte é que o servidor envia `cache-control: no-store` — o cache é responsabilidade do app.

---

## 1. Modelo de telas → endpoints

| Tela do app | Fonte de dados | Chamada |
|---|---|---|
| **Home** (carrosséis) | Catálogos `showInHome: true` | `manifest.json` → para cada catálogo: `catalog/{type}/{id}.json` |
| **Linha "Netflix", "Disney+"…** | Catálogos `streaming.*` / `flixpatrol.*` | `catalog/{type}/streaming.nfx.json` |
| **Biblioteca por gênero** | `mdblist.*` / `genre=` | `catalog/movie/tmdb.top/genre=Ação.json` |
| **Search** | `search.*` + `gemini.search` | `catalog/movie/search.movie/search={q}.json` |
| **Detalhe (filme/série)** | `meta` | `meta/{type}/{id}.json` |
| **Lista de episódios** | `meta.videos[]` | (vem no mesmo `meta` de série) |
| **Scroll infinito** | extra `skip` | `catalog/.../skip={n}.json` |

---

## 2. Mapeamento API → `MediaItem`

O `MediaItem` atual do app casa quase 1:1 com `MetaPreview`:

| `MediaItem` | Origem na API | Observação |
|---|---|---|
| `title` | `meta.name` | — |
| `kind` | `meta.type` | `"movie"` → `.movie`, `"series"`/anime → `.series` |
| `genres` | `meta.genres` | já traduzido (pt-BR) |
| `posterURL` | `meta.poster` | URL TMDB/TVDB direta |
| `backdropURL` | `meta.background` | — |
| `logoURL` | `meta.logo` | clearlogo transparente (🟧) |
| `synopsis` | `meta.description` | — |
| `year` | `Int(meta.year)` | `year` é **string** na API |
| `serviceBadge` | _(derivado do catálogo de origem)_ | ex.: linha `streaming.nfx` → `"Netflix"`. Não vem no `meta`. |
| `progress` | _(estado local)_ | watchlist/continue-watching do app, não da API |
| `episodeLabel` | _(derivado)_ | de `meta.videos`/`behaviorHints` ou estado local |
| `tint` | _(decisão de UI)_ | local |

> **Identidade:** o `MediaItem.id` atual é `UUID()`. Para casar com a API, adicione um campo estável (`imdbId`/`metaId`) a partir de `meta._imdbId` ou `meta.id` — necessário para abrir o detalhe e deduplicar. Veja [06-id-system.md](./06-id-system.md).

### Campos extras úteis disponíveis (ainda não no `MediaItem`)

`landscapePoster` (pôster 16:9, ótimo para carrossel destacado em TV), `imdbRating`, `app_extras.cast` (com fotos), `app_extras.certificationLocal` (classificação BR), `trailers` (YouTube), `runtime`. Considere estender o modelo de detalhe para aproveitá-los.

---

## 3. Structs `Decodable` de referência

Mínimo viável para parsear catálogo e meta (campos `String?` por segurança — a API entrega números como string):

```swift
struct CatalogResponse: Decodable {
    let metas: [Meta]
}

struct MetaResponse: Decodable {
    let meta: Meta?
}

struct Meta: Decodable {
    let id: String
    let type: String
    let name: String
    let description: String?
    let genres: [String]?
    let year: String?
    let imdbRating: String?
    let runtime: String?
    let poster: String?
    let background: String?
    let logo: String?
    let landscapePoster: String?
    let status: String?
    let imdb_id: String?
    let videos: [Video]?          // só em series/anime
    let trailers: [Trailer]?
    let app_extras: AppExtras?

    // IDs cruzados (🟧)
    let _imdbId: String?
    let _tmdbId: String?
    let _tvdbId: String?
}

struct Video: Decodable {
    let id: String                // "tt...:S:E"
    let title: String
    let season: Int
    let episode: Int
    let thumbnail: String?
    let overview: String?
    let released: String?
    let available: Bool?
    let runtime: String?
}

struct Trailer: Decodable {
    let source: String            // YouTube id
    let type: String?
    let name: String?
}

struct AppExtras: Decodable {
    let cast: [Person]?
    let directors: [Person]?
    let certification: String?
    let certificationLocal: String?
    let seasonPosters: [String]?
}

struct Person: Decodable {
    let name: String
    let character: String?
    let photo: String?
}
```

> `JSONDecoder` padrão: **não** use `.convertFromSnakeCase` (quebraria `imdb_id`, `app_extras`, `_imdbId`). Mantenha as chaves como vêm ou use `CodingKeys` explícitas.

### Endpoint helper

```swift
struct AIOMetadata {
    static let base = URL(string:
      "https://aiometadata.elfhosted.com/stremio/b11959c7-94fd-4fd2-aa24-6655c4fd7164")!

    static func catalog(type: String, id: String, extras: [String: String] = [:]) -> URL {
        var path = "catalog/\(type)/\(id)"
        if !extras.isEmpty {
            // extras no PATH, unidos por '&', valores URL-encoded, sufixo .json
            let joined = extras.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            path += "/\(joined)"
        }
        return base.appendingPathComponent(path + ".json")
    }

    static func meta(type: String, id: String) -> URL {
        base.appendingPathComponent("meta/\(type)/\(id).json")
    }
}
```

> ⚠️ Os extras vão no **path** (`/genre=Drama&skip=20.json`), **não** em query string. Garanta o URL-encoding do valor (espaços → `%20`), mas mantenha `=` e `&` literais como separadores.

---

## 4. Receita: montar a Home

```
1. GET /manifest.json
2. Filtrar catalogs onde showInHome == true (e type ∈ {movie, series, anime, all})
3. Para cada catálogo (em paralelo, com limite de concorrência):
      GET /catalog/{type}/{id}.json
      → mapear metas[] em [MediaItem]
4. Renderizar uma MediaRow por catálogo, preservando a ordem do manifest
```

- **Concorrência:** limite a ~4–6 requisições simultâneas para não saturar.
- **Ordem:** a ordem dos catálogos no manifest é a ordem editorial — preserve-a.
- **serviceBadge:** derive do catálogo de origem (você sabe que `streaming.nfx` = Netflix ao disparar a chamada).
- Catálogos já trazem `MetaPreview` rico → **não** precisa de `/meta` para renderizar os cards.

## 5. Receita: scroll infinito (paginação)

```
estado: skip = 0, pageSize = catálogo.pageSize (50/25/10)
carregar próxima página:
   GET /catalog/{type}/{id}/skip={skip}.json
   anexar metas ao acumulador
   skip += (qtde recebida)        // incremente pelo recebido, não pelo pageSize fixo
fim quando: metas.isEmpty  OU  qtde recebida < pageSize
```

> TMDB tende a devolver ~20 itens mesmo com `pageSize: 50`. Sempre incremente `skip` pelo **número real recebido**.

## 6. Receita: busca

```
debounce do texto (≥300ms)
multiplexar conforme escopo:
   filmes:  GET /catalog/movie/search.movie/search={q}.json
   séries:  GET /catalog/series/search.series/search={q}.json
   anime:   GET /catalog/anime.series/search.anime_series/search={q}.json
   IA:      GET /catalog/other/gemini.search/search={q}.json   (linguagem natural)
URL-encode {q}.  Tratar metas:[] como "sem resultados".
```

- Use `search.*` para busca exata por título; `gemini.search` para "filmes parecidos com…".

## 7. Receita: detalhe + episódios

```
ao abrir um item:
   GET /meta/{item.type}/{item.id}.json
   se meta == null → erro/placeholder
   filme: exibir descrição, elenco (app_extras.cast), trailer, classificação
   série/anime:
       agrupar meta.videos por season (season 0 = especiais)
       exibir episódios; usar video.available para marcar "não lançado"
       botão play do episódio usa video.id ("tt...:S:E")
```

- **Anime:** abra com o `id` original (`mal:`/`kitsu:`); os episódios virão com `id` IMDB (`tt...:S:E`). Veja [06-id-system.md](./06-id-system.md).

---

## 8. Cache

O servidor envia `no-store` → **implemente cache próprio**:

| Dado | TTL sugerido | Justificativa |
|---|---|---|
| `manifest.json` | 12–24 h (ou via `configVersion`) | Muda só ao reconfigurar. Invalide quando `x-manifest-version` mudar. |
| Catálogos "trending"/"Top 10" | 15–60 min | Rotativos. |
| Catálogos estáticos (gênero, acervo) | algumas horas | Estáveis. |
| `meta` de filme | dias | Praticamente imutável. |
| `meta` de série em curso | horas | `videos` cresce com novos episódios. |
| Imagens (TMDB/TVDB) | longo | URLs com hash — use cache da camada de imagem. |

- Chave de cache: a própria **URL** (já inclui extras).
- `manifest.configVersion` / header `x-manifest-version` = sinal de invalidação global.

## 9. Performance

- **Evite `/meta` redundante:** o catálogo já traz dados ricos para os cards. `/meta` só ao abrir detalhe (ou para `videos`).
- **Tamanho de imagem:** troque o segmento de tamanho nas URLs TMDB para baixar só o necessário:
  - card de pôster: `…/t/p/w300/…` ou `w500`
  - background/hero em TV: `…/t/p/original/…` ou `w1280`
  - foto de elenco: `w276_and_h350_face` (como já vem)
- **Paralelismo limitado** + cancelamento de requisições ao sair da tela (use `Task`/`async let` com cancelamento).
- **Pré-carregue** os primeiros N catálogos da Home; carregue o resto sob demanda (lazy rows).

## 10. Robustez

- Toda chamada pode vir `200` com `meta: null` / `metas: []` → trate como vazio, **não** como sucesso com dados.
- `404`/timeout → erro real; aplique **retry com backoff** (ex.: 2 tentativas, 0.5s/2s).
- Campos opcionais: assuma que **qualquer** campo além de `id`/`type`/`name` pode faltar.
- Ignore `url` com esquema `stremio:///` nos `links` (deep-links do app oficial).
- Números são strings: `Int(meta.year)`, `Double(meta.imdbRating)`.

## 11. Checklist de implementação

- [ ] Camada de rede (`URLSession` async) com a base `…/stremio/{configId}/`.
- [ ] Builder de URL com extras no **path** (não query string).
- [ ] `Decodable` sem `convertFromSnakeCase`.
- [ ] Cache com TTL por tipo de recurso + invalidação por `configVersion`.
- [ ] `MediaItem` com ID estável (`_imdbId`/`id`) além do `UUID` de UI.
- [ ] Mapper `Meta → MediaItem` (incl. `kind` por `type`, `year` String→Int).
- [ ] Home dirigida pelo manifest (`showInHome`), preservando ordem.
- [ ] Paginação por `skip` incrementado pelo recebido.
- [ ] Busca com debounce + `search.*`/`gemini.search`.
- [ ] Detalhe com `meta` + agrupamento de `videos` por temporada.
- [ ] Tratamento de `null`/`[]`/`404` + retry/backoff.

---

## Referências cruzadas

- Rotas e respostas → [02-endpoints.md](./02-endpoints.md)
- Extras e paginação → [03-filters-and-extras.md](./03-filters-and-extras.md)
- Tipos de dados → [04-schemas.md](./04-schemas.md)
- Catálogos disponíveis → [05-catalog-reference.md](./05-catalog-reference.md)
- IDs e resolução → [06-id-system.md](./06-id-system.md)
- Amostras JSON → [examples/](./examples/)
