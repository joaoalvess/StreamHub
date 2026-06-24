# 05 — Referência de Catálogos

Inventário completo dos **99 catálogos** desta instância (`configId = b11959c7-...`, idioma `pt-BR`). A ordem da tabela = ordem no manifest (= ordem de exibição padrão na Home).

> A chave de roteamento é o par **(`type`, `id`)**. Use `GET /catalog/{type}/{id}.json`. Extras marcados com `*` são obrigatórios. `Home ✅` = `showInHome: true`.

## Tabela completa

| type | id | name | pageSize | Home | extras |
|---|---|---|---|---|---|
| `movie` | `trakt.trending.movies` | Trakt Trending Movies | 50 | ✅ | genre, skip |
| `movie` | `trakt.recommendations.movies` | Trakt Recommendations | 50 | ✅ | genre, skip |
| `movie` | `mdblist.2202` | Latest Blu-ray Releases | 50 | ✅ | genre, skip |
| `movie` | `trakt.popular.movies` | Trakt Popular Movies | 50 | ✅ | genre, skip |
| `movie` | `mdblist.2236` | Top Movies of the week | 50 | ✅ | genre, skip |
| `movie` | `tmdb.trending` | TMDB Trending | 50 | ✅ | genre, skip |
| `movie` | `tmdb.top` | TMDB Popular | 50 | ✅ | genre, skip |
| `movie` | `mdblist.2618` | Top Movies | 50 | ✅ | genre, skip |
| `series` | `trakt.trending.shows` | Trakt Trending Shows | 50 | ✅ | genre, skip |
| `series` | `trakt.recommendations.shows` | Trakt Recommendations | 50 | ✅ | genre, skip |
| `series` | `mdblist.2194` | Latest TV Shows | 50 | ✅ | genre, skip |
| `series` | `trakt.popular.shows` | Trakt Popular Shows | 50 | ✅ | genre, skip |
| `series` | `tmdb.airing_today` | TMDB Airing Today | 50 | ✅ | genre, skip |
| `series` | `tvdb.trending` | TVDB Tendências | 50 | ✅ | genre, skip |
| `series` | `tmdb.top` | TMDB Popular | 50 | ✅ | genre, skip |
| `series` | `mdblist.84401` | Top Reality TV | 50 | ✅ | genre, skip |
| `series` | `tmdb.top_rated` | TMDB Top Rated | 50 | ✅ | genre, skip |
| `anime` | `mal.upcoming` | MAL Próxima Temporada | 25 | ✅ | genre, skip |
| `anime` | `mal.airing` | MAL Em Exibição | 25 | ✅ | genre, skip |
| `anime` | `mal.season_top_new` | MAL Top New This Week | 25 | ✅ | genre, skip |
| `anime` | `mal.season_top` | MAL Top Rated This Week | 25 | ✅ | genre, skip |
| `anime` | `mal.schedule` | MAL Horário de Exibição | 25 | ✅ | genre, skip |
| `anime` | `mal.seasons` | MAL Temporadas | 25 | ✅ | genre, skip |
| `anime` | `mal.top_anime` | MAL Melhores Animes | 25 | ✅ | genre, skip |
| `anime` | `mal.genres` | MAL Gêneros de Anime | 25 | ✅ | genre, skip |
| `anime` | `mal.studios` | MAL Por Estúdio | 25 | ✅ | genre, skip |
| `movie` | `flixpatrol.netflix.br.movie` | Top 10 Movies on Netflix (Brazil) | 10 | ✅ | — |
| `series` | `flixpatrol.netflix.br.series` | Top 10 TV Shows on Netflix (Brazil) | 10 | ✅ | — |
| `movie` | `streaming.nfx` | Netflix (Movies) | 50 | ✅ | genre, skip |
| `series` | `streaming.nfx` | Netflix (Series) | 50 | ✅ | genre, skip |
| `movie` | `flixpatrol.disney.br.movie` | Top 10 Movies on Disney+ (Brazil) | 10 | ✅ | — |
| `series` | `flixpatrol.disney.br.series` | Top 10 TV Shows on Disney+ (Brazil) | 10 | ✅ | — |
| `movie` | `streaming.dnp` | Disney+ (Movies) | 50 | ✅ | genre, skip |
| `series` | `streaming.dnp` | Disney+ (Series) | 50 | ✅ | genre, skip |
| `movie` | `flixpatrol.hbo-max.br.movie` | Top 10 Movies on HBO Max (Brazil) | 10 | ✅ | — |
| `series` | `flixpatrol.hbo-max.br.series` | Top 10 TV Shows on HBO Max (Brazil) | 10 | ✅ | — |
| `movie` | `streaming.hbm` | HBO Max (Movies) | 50 | ✅ | genre, skip |
| `series` | `streaming.hbm` | HBO Max (Series) | 50 | ✅ | genre, skip |
| `movie` | `flixpatrol.amazon-prime.br.movie` | Top 10 Movies on Prime Video (Brazil) | 10 | ✅ | — |
| `series` | `flixpatrol.amazon-prime.br.series` | Top 10 TV Shows on Prime Video (Brazil) | 10 | ✅ | — |
| `movie` | `streaming.amp` | Prime Video (Movies) | 50 | ✅ | genre, skip |
| `series` | `streaming.amp` | Prime Video (Series) | 50 | ✅ | genre, skip |
| `movie` | `flixpatrol.globoplay.br.movie` | Top 10 Movies on Globoplay (Brazil) | 10 | ✅ | — |
| `movie` | `streaming.gop` | Globoplay (Movies) | 50 | ✅ | genre, skip |
| `series` | `streaming.gop` | Globoplay (Series) | 50 | ✅ | genre, skip |
| `movie` | `flixpatrol.apple-tv-store.br.movie` | Top 10 Movies on Apple TV Store (Brazil) | 10 | ✅ | — |
| `movie` | `streaming.clv` | Clarovideo (Movies) | 50 | ✅ | genre, skip |
| `series` | `streaming.clv` | Clarovideo (Series) | 50 | ✅ | genre, skip |
| `movie` | `flixpatrol.hulu.us.movie` | Top 10 Movies on Hulu (United States) | 10 | ✅ | — |
| `series` | `flixpatrol.hulu.us.series` | Top 10 TV Shows on Hulu (United States) | 10 | ✅ | — |
| `movie` | `streaming.hlu` | Hulu (Movies) | 50 | ✅ | genre, skip |
| `series` | `streaming.hlu` | Hulu (Series) | 50 | ✅ | genre, skip |
| `movie` | `flixpatrol.paramount.br.movie` | Top 10 Movies on Paramount+ (Brazil) | 10 | ✅ | — |
| `series` | `flixpatrol.paramount.br.series` | Top 10 TV Shows on Paramount+ (Brazil) | 10 | ✅ | — |
| `movie` | `streaming.pmp` | Paramount+ (Movies) | 50 | ✅ | genre, skip |
| `series` | `streaming.pmp` | Paramount+ (Series) | 50 | ✅ | genre, skip |
| `all` | `flixpatrol.discovery-plus.us.all` | Top 10 on Discovery+ | 10 | ✅ | — |
| `movie` | `streaming.dpe` | Discovery+ (Movies) | 50 | ✅ | genre, skip |
| `series` | `streaming.dpe` | Discovery+ (Series) | 50 | ✅ | genre, skip |
| `movie` | `flixpatrol.apple-tv.br.movie` | Top 10 Movies on Apple TV+ (Brazil) | 10 | ✅ | — |
| `series` | `flixpatrol.apple-tv.br.series` | Top 10 TV Shows on Apple TV+ (Brazil) | 10 | ✅ | — |
| `movie` | `streaming.atp` | Apple TV+ (Movies) | 50 | ✅ | genre, skip |
| `series` | `streaming.atp` | Apple TV+ (Series) | 50 | ✅ | genre, skip |
| `movie` | `streaming.cru` | Crunchyroll (Movies) | 50 | ✅ | genre, skip |
| `series` | `streaming.cru` | Crunchyroll (Series) | 50 | ✅ | genre, skip |
| `movie` | `mdblist.3106` | Action | 50 | — | genre*, skip |
| `movie` | `mdblist.116037` | Animated | 50 | — | genre*, skip |
| `movie` | `mdblist.3107` | Comedy | 50 | — | genre*, skip |
| `movie` | `mdblist.3364` | Sci-Fi | 50 | — | genre*, skip |
| `movie` | `mdblist.3110` | Horror | 50 | — | genre*, skip |
| `movie` | `mdblist.3105` | Drama | 50 | — | genre*, skip |
| `movie` | `mdblist.3108` | Crime | 50 | — | genre*, skip |
| `movie` | `mdblist.3111` | Thriller | 50 | — | genre*, skip |
| `movie` | `mdblist.128062` | MCU | 50 | — | genre*, skip |
| `movie` | `mdblist.128262` | Romance | 50 | — | genre*, skip |
| `movie` | `mdblist.128051` | Documentary | 50 | — | genre*, skip |
| `movie` | `mdblist.130778` | KDrama | 50 | — | genre*, skip |
| `movie` | `mdblist.3112` | War | 50 | — | genre*, skip |
| `movie` | `mdblist.3109` | History | 50 | — | genre*, skip |
| `series` | `mdblist.91213` | Popular Action Shows | 50 | — | genre*, skip |
| `series` | `mdblist.84402` | Animation Shows | 50 | — | genre*, skip |
| `series` | `mdblist.3122` | Comedy Shows | 50 | — | genre*, skip |
| `series` | `mdblist.116038` | Popular Animated Shows | 50 | — | genre*, skip |
| `series` | `mdblist.3125` | Sci-Fi Shows | 50 | — | genre*, skip |
| `series` | `mdblist.3124` | Horror Shows | 50 | — | genre*, skip |
| `series` | `mdblist.3123` | Drama Shows | 50 | — | genre*, skip |
| `series` | `mdblist.128054` | Popular Reality Shows | 50 | — | genre*, skip |
| `series` | `mdblist.3126` | Crime Shows | 50 | — | genre*, skip |
| `series` | `mdblist.128063` | MCU Shows | 50 | — | genre*, skip |
| `series` | `mdblist.91894` | Popular Thriller Shows | 50 | — | genre*, skip |
| `series` | `mdblist.128265` | Popular Romance Shows | 50 | — | genre*, skip |
| `series` | `mdblist.128052` | Popular Documentary Shows | 50 | — | genre*, skip |
| `series` | `mdblist.130775` | Popular KDrama Shows | 50 | — | genre*, skip |
| `other` | `gemini.search` | AI Search | — | — | search*, skip |
| `movie` | `search.movie` | Movies Search | — | — | search*, skip |
| `series` | `search.series` | Series Search | — | — | search*, skip |
| `anime.series` | `search.anime_series` | Anime Series Search | — | — | search*, skip |
| `anime.movie` | `search.anime_movie` | Anime Movies Search | — | — | search*, skip |
| `series` | `calendar-videos` | Calendar videos | — | — | calendarVideosIds* |

---

## Códigos de plataforma de streaming (`streaming.{code}`)

Os catálogos `streaming.{code}` (50/página, com `genre`/`skip`) existem em pares `movie` + `series` (exceto onde indicado). O `{code}` de 3 letras:

| Código | Plataforma | movie | series |
|---|---|---|---|
| `nfx` | Netflix | ✅ | ✅ |
| `dnp` | Disney+ | ✅ | ✅ |
| `hbm` | HBO Max | ✅ | ✅ |
| `amp` | Prime Video (Amazon) | ✅ | ✅ |
| `pmp` | Paramount+ | ✅ | ✅ |
| `hlu` | Hulu | ✅ | ✅ |
| `atp` | Apple TV+ | ✅ | ✅ |
| `dpe` | Discovery+ | ✅ | ✅ |
| `cru` | Crunchyroll | ✅ | ✅ |
| `gop` | Globoplay | ✅ | ✅ |
| `clv` | Clarovideo | ✅ | ✅ |

> Estes catálogos representam o **acervo completo** da plataforma (não o Top 10). Para rankings diários use os pares `flixpatrol.*`.

## Rankings Top 10 (`flixpatrol.{plataforma}.{país}.{tipo}`)

10 itens/página, **sem extras** (não paginam nem filtram). País: `br` (Brasil) ou `us` (EUA).

| id | Plataforma | País | Tipo |
|---|---|---|---|
| `flixpatrol.netflix.br.movie` / `.series` | Netflix | BR | movie/series |
| `flixpatrol.disney.br.movie` / `.series` | Disney+ | BR | movie/series |
| `flixpatrol.hbo-max.br.movie` / `.series` | HBO Max | BR | movie/series |
| `flixpatrol.amazon-prime.br.movie` / `.series` | Prime Video | BR | movie/series |
| `flixpatrol.paramount.br.movie` / `.series` | Paramount+ | BR | movie/series |
| `flixpatrol.apple-tv.br.movie` / `.series` | Apple TV+ | BR | movie/series |
| `flixpatrol.globoplay.br.movie` | Globoplay | BR | movie (só) |
| `flixpatrol.apple-tv-store.br.movie` | Apple TV Store | BR | movie (só) |
| `flixpatrol.hulu.us.movie` / `.series` | Hulu | US | movie/series |
| `flixpatrol.discovery-plus.us.all` | Discovery+ | US | `all` (misto) |

## Catálogos MDBList por gênero

Listas curadas por ID numérico do MDBList. Os de gênero (tags `catalog-movie`/`catalog-series`) têm `genre` **obrigatório** e `showInHome: false`.

**Filmes:** `3106` Action · `116037` Animated · `3107` Comedy · `3364` Sci-Fi · `3110` Horror · `3105` Drama · `3108` Crime · `3111` Thriller · `128062` MCU · `128262` Romance · `128051` Documentary · `130778` KDrama · `3112` War · `3109` History

**Séries:** `91213` Action · `84402` Animation · `3122` Comedy · `116038` Animated · `3125` Sci-Fi · `3124` Horror · `3123` Drama · `128054` Reality · `3126` Crime · `128063` MCU · `91894` Thriller · `128265` Romance · `128052` Documentary · `130775` KDrama

**MDBList editoriais (Home):** `2202` Latest Blu-ray · `2236` Top Movies week · `2618` Top Movies · `2194` Latest TV · `84401` Top Reality TV

## Catálogos de anime (`mal.*`)

| id | Conteúdo | `genre` significa |
|---|---|---|
| `mal.airing` | Em exibição | — |
| `mal.upcoming` | Próxima temporada | — |
| `mal.season_top` | Top da temporada | — |
| `mal.season_top_new` | Novos top da semana | — |
| `mal.top_anime` | Melhores de todos os tempos | — |
| `mal.schedule` | Cronograma | dia da semana (7 opções) |
| `mal.seasons` | Por temporada | `Spring 2026` … (441 opções) |
| `mal.genres` | Por gênero | gênero de anime (78 opções) |
| `mal.studios` | Por estúdio | estúdio (100 opções: `MAPPA`, `ufotable`…) |

> Itens de catálogos `anime` têm `type: "series"` ou `"movie"` (não `"anime"`). IDs com prefixo `mal:`. Ao abrir o detalhe, resolva via `/meta/series/mal:{id}.json`. Veja [06-id-system.md](./06-id-system.md).

## Catálogos de busca

| (type, id) | Busca |
|---|---|
| (`movie`, `search.movie`) | Filmes por título |
| (`series`, `search.series`) | Séries por título |
| (`anime.series`, `search.anime_series`) | Séries de anime |
| (`anime.movie`, `search.anime_movie`) | Filmes de anime |
| (`other`, `gemini.search`) | Busca semântica por IA (linguagem natural) |

## Fontes por prefixo de ID de catálogo

| Prefixo | Fonte | Catálogos |
|---|---|---|
| `trakt.*` | Trakt | trending/popular/recommendations (movie+series) |
| `tmdb.*` | TMDB | trending, top, top_rated, airing_today |
| `tvdb.*` | TVDB | trending |
| `mdblist.*` | MDBList | listas por ID numérico |
| `mal.*` | MyAnimeList | catálogos de anime |
| `flixpatrol.*` | FlixPatrol | rankings Top 10 |
| `streaming.*` | Catálogo por plataforma | acervo por serviço |
| `search.*` | Busca interna | busca textual |
| `gemini.*` | Google Gemini | busca semântica |
| `calendar-videos` | Interno | agenda de episódios |

Mapa `tag → catálogos` completo em [03-filters-and-extras.md](./03-filters-and-extras.md#referência-de-tags).
