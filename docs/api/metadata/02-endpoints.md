# 02 — Endpoints (Referência de Rotas)

Todas as rotas são `GET`, retornam `application/json; charset=utf-8` e usam a URL base:

```
$BASE = https://aiometadata.elfhosted.com/stremio/{configId}
```

Visão geral das rotas:

| Método | Rota | Recurso | Resposta |
|---|---|---|---|
| GET | `/manifest.json` | — | `Manifest` |
| GET | `/manifest.json?tag={tag}` | — | `Manifest` filtrado |
| GET | `/catalog/{type}/{id}.json` | catalog | `{ metas: MetaPreview[] }` |
| GET | `/catalog/{type}/{id}/{extras}.json` | catalog | `{ metas: MetaPreview[] }` |
| GET | `/meta/{type}/{id}.json` | meta | `{ meta: MetaDetail }` |
| GET | `/subtitles/{type}/{id}.json` | subtitles | `{ subtitles: [] }` |
| GET | `/configure` | — | UI HTML de configuração |

---

## GET `/manifest.json`

Documento de autodescrição do addon. **Primeira chamada** de qualquer integração — dela se extrai a lista de catálogos a renderizar.

### Request

```bash
curl "$BASE/manifest.json"
```

### Response (estrutura de topo)

```json
{
  "id": "aio-metadata",
  "name": "AIOMetadata  | ElfHosted",
  "version": "2.7.1",
  "description": "A metadata addon for power users...",
  "language": "pt-BR",
  "configVersion": 1782289932288,
  "logo": "https://.../logo.png",
  "background": "https://.../bg.jpg",
  "resources": ["catalog", "meta", "subtitles"],
  "types": ["movie", "series", "anime.movie", "anime.series", "anime", "Trakt", "collection"],
  "idPrefixes": ["tmdb:", "tt", "tvdb:", "mal:", "tvmaze:", "kitsu:", "anidb:", "anilist:", "tvdbc:", "upnext_", "unwatched_", "mdblist_upnext_", "pmdb_resume_"],
  "behaviorHints": { "configurable": true, "configurationRequired": false, "newEpisodeNotifications": true },
  "catalogs": [ /* 99 objetos Catalog */ ],
  "stremioAddonsConfig": { "issuer": "https://stremio-addons.net", "signature": "..." }
}
```

Campos detalhados em [04-schemas.md](./04-schemas.md#manifest). O parâmetro `?tag=` filtra `catalogs` — veja [03-filters-and-extras.md](./03-filters-and-extras.md#tags).

Amostra completa: [examples/manifest-response.json](./examples/manifest-response.json).

### Headers de resposta relevantes

```
content-type: application/json; charset=utf-8
x-manifest-language: pt-BR
x-manifest-version: 1782289932288
etag: W/"032d7a2ac59b3e1469dbdad689127b6a"
cache-control: no-cache, no-store, must-revalidate
access-control-allow-origin: *
```

---

## GET `/catalog/{type}/{id}.json`

Retorna uma **lista de itens** (catálogo). É o recurso de descoberta.

### Parâmetros de rota

| Parâmetro | Descrição | Exemplos |
|---|---|---|
| `{type}` | `type` do catálogo, **exatamente como declarado no manifest**. | `movie`, `series`, `anime`, `other`, `all` |
| `{id}` | `id` do catálogo, do manifest. | `tmdb.trending`, `streaming.nfx`, `mal.top_anime`, `search.movie` |

> **Atenção ao par `(type, id)`:** alguns IDs existem com **dois tipos**. Ex.: `streaming.nfx` existe como `movie` *e* como `series`. A chave única do catálogo é o par `(type, id)`, não o `id` isolado. `GET /catalog/movie/streaming.nfx.json` ≠ `GET /catalog/series/streaming.nfx.json`.

### Request

```bash
curl "$BASE/catalog/movie/tmdb.trending.json"
```

### Response

```json
{
  "metas": [
    {
      "id": "tt33296751",
      "type": "movie",
      "name": "O Afinador",
      "poster": "https://image.tmdb.org/t/p/w600_and_h900_bestv2/....jpg",
      "description": "Niki é um afinador de pianos...",
      "genres": ["Thriller", "Crime", "Drama"],
      "imdbRating": "7.4",
      "year": "2026",
      "releaseInfo": "2026",
      "background": "https://...",
      "landscapePoster": "https://...",
      "logo": "https://...",
      "...": "demais campos — ver 04-schemas.md#metapreview"
    }
  ]
}
```

- O array `metas` contém objetos `MetaPreview` (mas **enriquecidos** — esta API retorna em catálogo praticamente todos os campos da ficha, inclusive `trailers`, `links`, `app_extras`). Schema em [04-schemas.md](./04-schemas.md#metapreview).
- **Tamanho da página** varia por fonte (`pageSize` do manifest):
  - Trakt / `streaming.*` / `mdblist.*`: **50** por página (resposta observada às vezes traz menos — ex.: TMDB devolve ~20 itens por requisição).
  - `mal.*`: **25**.
  - `flixpatrol.*` (Top 10): **10**.
- Paginação via extra `skip` — veja abaixo e em [03-filters-and-extras.md](./03-filters-and-extras.md#skip-paginação).

Amostra: [examples/catalog-movie-response.json](./examples/catalog-movie-response.json).

### Catálogo vazio / inexistente

```bash
curl "$BASE/catalog/movie/nao.existe.json"
# HTTP 200 → {"metas":[]}
```

---

## GET `/catalog/{type}/{id}/{extras}.json`

Mesma rota, com **extras** no path. Extras modificam o que o catálogo retorna: paginação (`skip`), filtro (`genre`), termo de busca (`search`).

### Formato dos extras

- **Um extra:** `…/{nome}={valor}.json`
- **Vários extras:** unidos por `&` literal no path (não é query string): `…/{n1}={v1}&{n2}={v2}.json`
- O `{valor}` deve ser **URL-encoded** quando contém espaços/símbolos.

### Exemplos verificados

```bash
# Paginação: segunda página (pular os 20 primeiros)
curl "$BASE/catalog/movie/tmdb.trending/skip=20.json"

# Filtro por gênero (valor EXATO de extra.options; TMDB usa PT-BR)
curl "$BASE/catalog/movie/tmdb.top/genre=Drama.json"

# Busca textual
curl "$BASE/catalog/movie/search.movie/search=batman.json"

# Combinação: gênero + página 2
curl "$BASE/catalog/movie/tmdb.top/genre=Drama&skip=20.json"
```

> **`genre` é case-sensitive e idioma-dependente.** O valor precisa ser **idêntico** a uma das strings em `catalog.extra[].options` do manifest. Em catálogos TMDB as opções estão em **português** (`Ação`, `Comédia`, `Terror`), enquanto Trakt/MAL usam **inglês** (`Action`, `Comedy`, `Horror`). Passar `genre=Action` para um catálogo TMDB **não filtra** (retorna a lista default). Sempre derive os valores válidos do manifest.

Detalhes completos de cada extra (incluindo o uso de `genre` como seletor de estúdio/temporada nos catálogos MAL): [03-filters-and-extras.md](./03-filters-and-extras.md).

---

## GET `/meta/{type}/{id}.json`

Retorna a **ficha completa** (`MetaDetail`) de um item: descrição, elenco, trailers, classificações e — para séries/animes — a **lista de episódios** (`videos`).

### Parâmetros de rota

| Parâmetro | Descrição |
|---|---|
| `{type}` | `movie` ou `series` (anime é resolvido como um destes). |
| `{id}` | ID do item, com qualquer prefixo reconhecido em `idPrefixes`. |

### Request

```bash
# Por IMDB id
curl "$BASE/meta/series/tt0203259.json"

# Por TMDB id (resolve para o mesmo item canônico)
curl "$BASE/meta/movie/tmdb:1340206.json"

# Por MyAnimeList id (anime)
curl "$BASE/meta/series/mal:52991.json"
```

### Response — filme

```json
{
  "meta": {
    "id": "tt33296751",
    "type": "movie",
    "name": "O Afinador",
    "description": "...",
    "genres": ["Thriller", "Crime", "Drama"],
    "director": "Daniel Roher",
    "writer": "Robert Ramsey, Daniel Roher",
    "year": "2026",
    "released": "2026-05-22T00:00:00.000Z",
    "runtime": "1h48min",
    "country": "Canada, United States of America",
    "imdbRating": "7.4",
    "poster": "https://image.tmdb.org/t/p/...",
    "background": "https://image.tmdb.org/t/p/original/...",
    "landscapePoster": "https://image.tmdb.org/t/p/original/...",
    "logo": "https://image.tmdb.org/t/p/original/...",
    "posterShape": "poster",
    "trailers": [{ "source": "HYxzyLVJORA", "type": "Trailer", "ytId": "HYxzyLVJORA", "lang": "en" }],
    "links": [ /* imdb, share, Genres, Cast, Directors, Writers */ ],
    "app_extras": { "cast": [...], "directors": [...], "writers": [], "certification": "R", "certificationLocal": "16" },
    "behaviorHints": { "defaultVideoId": "tt33296751", "hasScheduledVideos": false },
    "_tmdbId": "1340206", "_tvdbId": "359822", "_imdbId": "tt33296751"
  }
}
```

Amostra: [examples/meta-movie-response.json](./examples/meta-movie-response.json).

### Response — série (com episódios)

Idêntico ao filme, **mais** o array `videos` (um item por episódio) e os campos `status`/`releaseInfo` de série em andamento:

```json
{
  "meta": {
    "id": "tt0203259",
    "type": "series",
    "name": "Lei & Ordem: Unidade de Vítimas Especiais",
    "status": "Continuing",
    "releaseInfo": "1999-",
    "videos": [
      {
        "id": "tt0203259:0:1",
        "title": "Episode 1",
        "season": 0,
        "episode": 1,
        "thumbnail": "https://artworks.thetvdb.com/banners/episodes/75692/543161.jpg",
        "overview": null,
        "released": null,
        "available": false,
        "runtime": "45min"
      }
      /* ... 599 episódios no total nesta série ... */
    ],
    "app_extras": { "cast": [...], "seasonPosters": [...], "certification": "TV-14" }
  }
}
```

Pontos críticos sobre `videos` (schema em [04-schemas.md](./04-schemas.md#video)):

- **`id` do episódio** = `{idDaSérie}:{season}:{episode}` — ex.: `tt0203259:27:21`. Esse é o ID usado para resolver streams em addons de stream.
- **`season: 0`** = especiais/extras.
- **`available`** = `true` se o episódio já foi ao ar; `false` para episódios futuros já catalogados.
- A lista vem **completa** (todas as temporadas), ordenada por temporada/episódio.

Amostras: [examples/meta-series-response.json](./examples/meta-series-response.json), [examples/meta-anime-response.json](./examples/meta-anime-response.json).

### Item inexistente

```bash
curl "$BASE/meta/movie/tt00000000.json"
# HTTP 200 → {"meta":null}
```

---

## GET `/subtitles/{type}/{id}.json`

Recurso declarado em `resources`, mas **nesta instância retorna sempre vazio**.

```bash
curl "$BASE/subtitles/series/tt0203259.json"
# HTTP 200 → {"subtitles":[]}
```

> O StreamHub **não deve depender** deste endpoint para legendas. Legendas, se necessárias, virão de outro addon/serviço. Documentado aqui apenas por completude do protocolo.

---

## GET `/configure`

```bash
curl "$BASE/configure"
# HTTP 200 → text/html (UI web de configuração)
```

Página HTML para criar/editar a configuração (gera um novo `{configId}`). **Não faz parte do consumo em runtime** do StreamHub — relevante apenas para gerar/alterar o Config ID. Veja [01-overview.md](./01-overview.md#config-id).

---

## Tratamento de erros

O protocolo Stremio **não usa códigos HTTP de erro** para "não encontrado". Resumo do comportamento observado:

| Situação | HTTP | Corpo |
|---|---|---|
| `meta` de ID inexistente | `200` | `{"meta": null}` |
| `catalog` inexistente ou sem resultados | `200` | `{"metas": []}` |
| `subtitles` (sempre) | `200` | `{"subtitles": []}` |
| Path malformado / fora do padrão | `404` | `text/html` |

**Regras de defesa para o cliente:**

1. Sempre verificar `meta != null` e `metas.length > 0` — **não** confiar só no status HTTP.
2. Tratar `404` (path malformado) e timeouts de rede como erro real.
3. Como o servidor envia `no-store`, implementar **retry com backoff** e **cache próprio** (veja [07-integration.md](./07-integration.md)).
