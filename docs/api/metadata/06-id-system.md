# 06 — Sistema de IDs e Resolução Cross-Source

O ponto mais sutil da integração. O AIOMetadata aceita IDs de **várias bases** e os resolve para um item canônico, mantendo um mapa cruzado de identificadores.

## Prefixos reconhecidos (`manifest.idPrefixes`)

```json
["tmdb:", "tt", "tvdb:", "mal:", "tvmaze:", "kitsu:", "anidb:", "anilist:", "tvdbc:",
 "upnext_", "unwatched_", "mdblist_upnext_", "pmdb_resume_"]
```

| Prefixo | Base | Formato | Domínio |
|---|---|---|---|
| `tt` | **IMDB** | `tt33296751` | Filmes e séries (canônico) |
| `tmdb:` | **TMDB** | `tmdb:1340206` | Filmes e séries |
| `tvdb:` | **TVDB** | `tvdb:75692` | Séries |
| `tvdbc:` | TVDB Collection | `tvdbc:...` | Coleções TVDB |
| `mal:` | **MyAnimeList** | `mal:52991` | Anime |
| `kitsu:` | **Kitsu** | `kitsu:1` | Anime |
| `anidb:` | **AniDB** | `anidb:...` | Anime |
| `anilist:` | **AniList** | `anilist:1` | Anime |
| `tvmaze:` | **TVMaze** | `tvmaze:...` | Séries |
| `upnext_` | Interno | `upnext_...` | Estado: próximo a assistir |
| `unwatched_` | Interno | `unwatched_...` | Estado: não assistidos |
| `mdblist_upnext_` | Interno | `mdblist_upnext_...` | Estado: próximos (MDBList) |
| `pmdb_resume_` | Interno | `pmdb_resume_...` | Estado: continuar assistindo |

> Os 4 últimos (`upnext_`, `unwatched_`, `mdblist_upnext_`, `pmdb_resume_`) são prefixos de **estado de progresso** — ligados a integrações de watchlist/continue-watching. Não aparecem em catálogos públicos desta config; relevantes só se o StreamHub integrar progresso via esses serviços.

## Comportamento de resolução (verificado)

Ao chamar `/meta/{type}/{id}.json` com diferentes prefixos, o campo `meta.id` retornado segue duas regras:

### Filmes e séries "tradicionais" → canonizados para IMDB

```bash
GET /meta/movie/tmdb:1340206.json   →  meta.id = "tt33296751"   (virou IMDB)
GET /meta/series/tvdb:75692.json    →  meta.id = "tt0203259"    (virou IMDB)
GET /meta/movie/tt33296751.json     →  meta.id = "tt33296751"   (inalterado)
```

Para esses, o `id` de entrada **não-IMDB é resolvido para `tt...`** na saída.

### Anime → mantém o prefixo de origem

```bash
GET /meta/series/mal:52991.json     →  meta.id = "mal:52991"    (mantém mal:)
GET /meta/series/kitsu:1.json       →  meta.id = "kitsu:1"      (mantém kitsu:)
GET /meta/series/anilist:1.json     →  meta.id = "anilist:1"    (mantém anilist:)
```

Anime preserva o ID da base de origem (MAL/Kitsu/AniList) — refletindo a convenção do ecossistema Stremio, em que addons de stream de anime indexam por esses IDs. **Mesmo assim**, o `imdb_id` e os `_*Id` cruzados vêm preenchidos.

## Mapa cruzado sempre presente (🟧 `_*Id`)

Todo `MetaDetail`/`MetaPreview` traz os três identificadores resolvidos, independentemente do prefixo de entrada:

```json
{
  "id": "mal:52991",
  "imdb_id": "tt22248376",
  "_imdbId": "tt22248376",
  "_tmdbId": "209867",
  "_tvdbId": "424536"
}
```

| Campo | Conteúdo |
|---|---|
| `id` | ID canônico de roteamento (IMDB para filme/série; prefixo de origem para anime). |
| `imdb_id` | Sempre o `tt...` quando existe. |
| `_imdbId` / `_tmdbId` / `_tvdbId` | IDs nas três bases principais. |

> **Estratégia recomendada para o StreamHub:** indexe seu cache/banco local pelo `_imdbId` (ou `_tmdbId`) como **chave estável**, e guarde o `id` original para reconstruir a rota. Assim, o mesmo título referenciado por `mal:`, `tmdb:` ou `tt` colapsa em um único registro.

## Formato de ID de episódio

Em `MetaDetail.videos[].id`:

```
{idDaSérie}:{season}:{episode}
```

- O `{idDaSérie}` usado é o **ID canônico** da série — para anime resolvido via `mal:`, é o **IMDB** da série, não o `mal:`:

```bash
GET /meta/series/mal:52991.json
  meta.id            = "mal:52991"
  meta.videos[0].id  = "tt22248376:0:1"   ← usa o tt, não mal:52991
```

- `season: 0` → especiais.
- Esse `id` (`tt...:S:E`) é a chave para solicitar streams a addons de stream no ecossistema Stremio.

> **Atenção:** o `id` da **série** (`mal:52991`) e o prefixo do `id` dos **episódios** (`tt22248376:...`) podem divergir. Ao montar links de episódio, use sempre `video.id` como veio — não reconstrua a partir de `meta.id`.

## Slug

Campo `slug` (🟦) é um identificador legível, não use para roteamento:

```
"movie/o-afinador-tmdb:1340206"
"series/lei-&-ordem:-unidade-de-vítimas-especiais-0203259"
```

Serve para URLs amigáveis/share; o roteamento de API é sempre por `id`.

## Resumo de decisão

```
Tenho um item de catálogo e quero o detalhe:
  → use (meta.type, meta.id) do item:  GET /meta/{type}/{id}.json
     - movie/series: id é tt... (ou tmdb:/tvdb: também resolvem)
     - anime:        id é mal:/kitsu:/anilist: (mantém prefixo)

Quero deduplicar / casar com outra fonte:
  → use _imdbId (preferencial) ou _tmdbId como chave estável.

Quero abrir um episódio:
  → use video.id literal ("{tt}:{season}:{episode}").
```
