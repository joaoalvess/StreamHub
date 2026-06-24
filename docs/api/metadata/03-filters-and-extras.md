# 03 — Filtros (Tags) e Extras

Dois mecanismos distintos de filtragem:

- **Tags** (`?tag=`) — filtram o **manifest**: reduzem quais catálogos o addon expõe. Operam no nível de descoberta.
- **Extras** (`/{nome}={valor}.json`) — filtram um **catálogo**: paginação, gênero, busca. Operam no nível de consulta.

---

## Tags

### O que são

`GET /manifest.json?tag={tag}` retorna o mesmo manifest, mas com `catalogs` **reduzido** ao subconjunto associado à tag. Servem para instalar/expor apenas um recorte do addon (ex.: só Netflix, só anime, só filmes).

```bash
# Manifest completo: 99 catálogos
curl "$BASE/manifest.json"

# Só catálogos de filme editoriais: 14 catálogos
curl "$BASE/manifest.json?tag=movie"

# Só catálogos da Netflix: 10 catálogos
curl "$BASE/manifest.json?tag=netflix"
```

> A tag **não** altera as rotas de `catalog`/`meta` — só o que o manifest lista. Você pode chamar qualquer catálogo diretamente sabendo seu `(type, id)`, mesmo sem filtrar o manifest.

### Catálogos núcleo (sempre presentes)

**Todo** manifest filtrado por tag inclui, ao final, estes 6 catálogos fixos (busca + calendário):

| type | id | name |
|---|---|---|
| `other` | `gemini.search` | AI Search |
| `movie` | `search.movie` | Movies Search |
| `series` | `search.series` | Series Search |
| `anime.series` | `search.anime_series` | Anime Series Search |
| `anime.movie` | `search.anime_movie` | Anime Movies Search |
| `series` | `calendar-videos` | Calendar videos |

As contagens abaixo **incluem** esses 6.

### Referência de tags

| `tag` | Nº cat. | Conteúdo (além dos 6 núcleo) |
|---|---|---|
| _(sem tag)_ | 99 | Todos os catálogos. |
| `movie` | 14 | 8 catálogos editoriais de filme: `trakt.trending.movies`, `trakt.recommendations.movies`, `mdblist.2202`, `trakt.popular.movies`, `mdblist.2236`, `tmdb.trending`, `tmdb.top`, `mdblist.2618`. |
| `series` | 15 | 9 editoriais de série: `trakt.trending.shows`, `trakt.recommendations.shows`, `mdblist.2194`, `trakt.popular.shows`, `tmdb.airing_today`, `tvdb.trending`, `tmdb.top`, `mdblist.84401`, `tmdb.top_rated`. |
| `anime` | 15 | 9 catálogos MAL: `mal.upcoming`, `mal.airing`, `mal.season_top_new`, `mal.season_top`, `mal.schedule`, `mal.seasons`, `mal.top_anime`, `mal.genres`, `mal.studios`. |
| `netflix` | 10 | `flixpatrol.netflix.br.movie`, `flixpatrol.netflix.br.series`, `streaming.nfx` (movie), `streaming.nfx` (series). |
| `disney` | 10 | `flixpatrol.disney.br.*`, `streaming.dnp` (movie/series). |
| `hbo` | 10 | `flixpatrol.hbo-max.br.*`, `streaming.hbm` (movie/series). |
| `prime` | 10 | `flixpatrol.amazon-prime.br.*`, `streaming.amp` (movie/series). |
| `paramount` | 10 | `flixpatrol.paramount.br.*`, `streaming.pmp` (movie/series). |
| `hulu` | 10 | `flixpatrol.hulu.us.*`, `streaming.hlu` (movie/series). |
| `apple` | 10 | `flixpatrol.apple-tv.br.*`, `streaming.atp` (movie/series). |
| `discovery` | 9 | `flixpatrol.discovery-plus.us.all` (type `all`), `streaming.dpe` (movie/series). |
| `crunchyroll` | 9 | `mal.season_top`, `streaming.cru` (movie/series). |
| `claro` | 9 | `flixpatrol.apple-tv-store.br.movie`, `streaming.clv` (movie/series). |
| `globo` | 9 | `flixpatrol.globoplay.br.movie`, `streaming.gop` (movie/series). |
| `catalog-movie` | 20 | 14 catálogos MDBList de gênero (filme): `mdblist.3106` (Action), `mdblist.116037` (Animated), `mdblist.3107` (Comedy), `mdblist.3364` (Sci-Fi), `mdblist.3110` (Horror), `mdblist.3105` (Drama), `mdblist.3108` (Crime), `mdblist.3111` (Thriller), `mdblist.128062` (MCU), `mdblist.128262` (Romance), `mdblist.128051` (Documentary), `mdblist.130778` (KDrama), `mdblist.3112` (War), `mdblist.3109` (History). |
| `catalog-series` | 20 | 14 catálogos MDBList de gênero (série): `mdblist.91213`, `mdblist.84402`, `mdblist.3122`, `mdblist.116038`, `mdblist.3125`, `mdblist.3124`, `mdblist.3123`, `mdblist.128054`, `mdblist.3126`, `mdblist.128063`, `mdblist.91894`, `mdblist.128265`, `mdblist.128052`, `mdblist.130775`. |

Mapa completo `tag → (type, id)` em [05-catalog-reference.md](./05-catalog-reference.md).

> **Observações verificadas:**
> - `claro` inclui `flixpatrol.apple-tv-store.br.movie` (Apple TV **Store**, loja de compra/aluguel — distinta do Apple TV+ em `apple`).
> - `crunchyroll` reaproveita `mal.season_top` (top de anime da temporada) além do catálogo próprio `streaming.cru`.
> - Plataformas BR (`netflix`, `disney`, `hbo`, `prime`, `paramount`, `apple`, `globo`, `claro`) usam rankings FlixPatrol do **Brasil** (`.br.`); `hulu` e `discovery` usam **EUA** (`.us.`).

---

## Extras

Extras são parâmetros de catálogo declarados em `catalog.extra[]` no manifest. Cada um tem `name`, opcional `options[]` (valores válidos) e opcional `isRequired`.

**Apenas 4 nomes de extra** existem em todo o addon:

| Extra | Onde | Obrigatório? | Função |
|---|---|---|---|
| `skip` | Quase todos os catálogos | Não | Paginação (offset). |
| `genre` | Catálogos editoriais e de plataforma | Não (exceto MDBList de gênero) | Filtro por gênero **ou** seletor genérico (estúdio/temporada/dia). |
| `search` | `search.*`, `gemini.search` | **Sim** | Termo de busca. |
| `calendarVideosIds` | `calendar-videos` | **Sim** | IDs de séries para montar o calendário. |

### `skip` (paginação)

Offset numérico — pula os N primeiros itens. Combine com o `pageSize` do catálogo para paginar.

```bash
curl "$BASE/catalog/movie/tmdb.trending.json"            # página 1
curl "$BASE/catalog/movie/tmdb.trending/skip=20.json"    # página 2 (offset 20)
curl "$BASE/catalog/movie/tmdb.trending/skip=40.json"    # página 3
```

- O incremento ideal = `pageSize` do catálogo (50 para Trakt/streaming/mdblist; 25 para MAL; 10 para FlixPatrol). Na prática, fontes TMDB devolvem ~20 por requisição — pagine pelo **tamanho real recebido**, não cegamente pelo `pageSize` declarado.
- Fim da lista: quando a resposta vier com **menos itens que o esperado** ou `metas: []`.

### `genre` (filtro / seletor genérico)

O Stremio só oferece **um** controle de filtro tipo dropdown — o `genre`. O AIOMetadata **reaproveita** esse extra para semânticas diferentes conforme o catálogo:

| Catálogo | Semântica de `genre` | Nº de opções | Idioma das opções |
|---|---|---|---|
| `trakt.*` (movie) | Gênero | 27 | Inglês (`Action`, `Comedy`…) |
| `trakt.*` (shows) | Gênero | 37 | Inglês |
| `tmdb.trending` | Gênero | 2 | PT-BR |
| `tmdb.top` (movie) | Gênero | 19 | **PT-BR** (`Ação`, `Comédia`, `Terror`…) |
| `tmdb.top`/`tmdb.top_rated` (series) | Gênero | 16 | PT-BR (`Action & Adventure`, `Sci-Fi & Fantasy`…) |
| `streaming.*` (movie) | Gênero | 19 | PT-BR |
| `streaming.*` (series) | Gênero | 16 | PT-BR |
| `mdblist.*` (gênero) | Gênero | 42–43 | Inglês — **`isRequired: true`** |
| `tvdb.trending` | Gênero | 31 | — |
| `mal.genres` | Gênero de anime | 78 | Inglês (`Isekai`, `Shounen`, `Mecha`…) |
| `mal.studios` | **Estúdio** | 100 | Nomes de estúdio (`Madhouse`, `MAPPA`, `ufotable`…) |
| `mal.seasons` | **Temporada** (ano/estação) | 441 | `Spring 2026`, `Winter 2026`, `Fall 2025`… |
| `mal.schedule` | **Dia da semana** | 7 | — |
| `mal.*` (demais) | Placeholder | 1 | — |

```bash
# Gênero (valor exato das options; TMDB = PT-BR)
curl "$BASE/catalog/movie/tmdb.top/genre=Ação.json"

# Estúdio (via mal.studios)
curl "$BASE/catalog/anime/mal.studios/genre=ufotable.json"

# Temporada de anime (via mal.seasons)
curl "$BASE/catalog/anime/mal.seasons/genre=Winter%202026.json"
```

> **Regras críticas de `genre`:**
> 1. O valor **deve ser idêntico** a uma string de `extra.options` do catálogo (case-sensitive, com acentos). Valor inválido → catálogo retorna a lista default, **sem erro**.
> 2. O idioma das opções segue a fonte, **não** o `language` global: TMDB/`streaming.*` em PT-BR, Trakt/MAL/MDBList em inglês. Sempre leia `options` do manifest antes de montar a URL.
> 3. Nos catálogos MDBList de gênero (`mdblist.3106`…), `genre` é **obrigatório** (`isRequired: true`) — embora cada um já represente um gênero, o Stremio injeta o seletor para refinamento.

### `search` (busca textual)

Obrigatório nos catálogos de busca. O termo é o texto a procurar.

```bash
curl "$BASE/catalog/movie/search.movie/search=batman.json"
curl "$BASE/catalog/series/search.series/search=breaking.json"
curl "$BASE/catalog/anime/search.anime_series/search=naruto.json"
```

Catálogos com `search` (todos `isRequired: true`):

| type | id | Busca |
|---|---|---|
| `movie` | `search.movie` | Filmes por título |
| `series` | `search.series` | Séries por título |
| `anime.series` | `search.anime_series` | Séries de anime |
| `anime.movie` | `search.anime_movie` | Filmes de anime |
| `other` | `gemini.search` | **Busca semântica (IA)** — aceita linguagem natural |

A **busca Gemini** difere das demais: interpreta a intenção. Ex.: `search=filmes como Inception` retorna `Tenet`, `Ilha do Medo`, `O Grande Truque`, `Amnésia`, `Matrix`. Use-a para descoberta por descrição; use `search.*` para busca exata por título.

```bash
curl "$BASE/catalog/other/gemini.search/search=filmes%20como%20Inception.json"
```

### `calendarVideosIds`

Obrigatório no catálogo `calendar-videos` (`type: series`). Recebe IDs de séries acompanhadas para montar a agenda de próximos episódios. É consumido internamente pelo cliente Stremio para a feature de **notificação de novos episódios** (`behaviorHints.newEpisodeNotifications: true`). Sem IDs, retorna `{"metas": []}`.

> Para o StreamHub, esta é uma feature opcional — só relevante se o app implementar "minha agenda de episódios". A lista de IDs viria da watchlist local do usuário.

---

## Resumo de combinação de filtros

```
Manifest filtrado   →  /manifest.json?tag=netflix
Catálogo bruto      →  /catalog/series/streaming.nfx.json
+ página            →  /catalog/series/streaming.nfx/skip=50.json
+ gênero            →  /catalog/series/streaming.nfx/genre=Drama.json
+ gênero + página   →  /catalog/series/streaming.nfx/genre=Drama&skip=50.json
busca               →  /catalog/movie/search.movie/search=batman.json
```
