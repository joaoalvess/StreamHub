# 04 — Schemas (Tipos de Dados)

Tipos em notação **TypeScript-like** para precisão, seguidos de tabelas campo a campo. Convenções:

- `?` = campo opcional / pode faltar.
- `| null` = campo presente, mas pode vir nulo.
- 🟦 = campo **padrão Stremio**. 🟧 = **extensão do AIOMetadata** (não existe no protocolo base).
- Todos os números "numéricos" (`year`, `imdbRating`, `runtime`) são entregues como **string**, não number — atenção ao desserializar.

---

## Manifest

```ts
interface Manifest {
  id: string;                    // "aio-metadata"
  name: string;                  // "AIOMetadata  | ElfHosted"
  version: string;               // "2.7.1" (semver)
  description: string;
  language: string;              // 🟧 "pt-BR"
  configVersion: number;         // 🟧 1782289932288 — muda a cada edição da config
  logo?: string;                 // URL
  background?: string;           // URL
  resources: string[];           // ["catalog","meta","subtitles"]
  types: string[];               // tipos suportados em meta
  idPrefixes: string[];          // prefixos de ID reconhecidos
  catalogs: Catalog[];           // 99 catálogos (ou subconjunto, com ?tag=)
  behaviorHints: {
    configurable: boolean;       // true
    configurationRequired: boolean; // false
    newEpisodeNotifications: boolean; // true
  };
  stremioAddonsConfig?: {        // assinatura de verificação stremio-addons.net
    issuer: string;
    signature: string;           // JWE
  };
  _debug?: object;               // 🟧 { language, configVersion, timestamp }
  _timestamp?: number;           // 🟧 epoch ms da geração do manifest
}
```

### Catalog

```ts
interface Catalog {
  id: string;                    // "tmdb.trending", "streaming.nfx", "mal.studios"
  type: string;                  // "movie" | "series" | "anime" | "anime.movie" | "anime.series" | "all" | "other"
  name: string;                  // rótulo exibível ("TMDB Trending")
  pageSize?: number;             // 50 | 25 | 10 — ausente em search/calendar
  showInHome?: boolean;          // true = aparece na home; false = só sob demanda
  extra?: Extra[];               // parâmetros aceitos
}

interface Extra {
  name: "skip" | "genre" | "search" | "calendarVideosIds";
  options?: string[];            // valores válidos (para genre)
  isRequired?: boolean;          // true em search.* e mdblist de gênero
}
```

> A **chave única** de um catálogo é o par `(type, id)` — o mesmo `id` pode existir com `type` diferente (ex.: `streaming.nfx` como `movie` e como `series`). Veja [02-endpoints.md](./02-endpoints.md#get-catalogtypeidjson).

---

## Meta

Há duas formas do mesmo objeto:

- **`MetaPreview`** — itens dentro de `catalog.metas[]`. Nesta API vem **enriquecido** (quase tudo de `MetaDetail`, exceto `videos`, `status`, `posterShape` e os flags `_has*`).
- **`MetaDetail`** — objeto em `meta.meta`, retornado por `/meta/...`. Forma completa.

A documentação abaixo descreve `MetaDetail`; `MetaPreview` é o mesmo conjunto **menos** os campos marcados _(somente detail)_.

```ts
interface MetaDetail {
  // ----- Identidade -----
  id: string;                    // 🟦 ID canônico (ex.: "tt33296751", "mal:52991")
  type: "movie" | "series";      // 🟦 anime resolve como movie/series
  name: string;                  // 🟦 título traduzido (language da config)
  imdb_id?: string;              // 🟦 "tt..."
  slug?: string;                 // 🟦 "movie/o-afinador-tmdb:1340206"

  // ----- Texto / catalogação -----
  description?: string;          // 🟦 sinopse
  genres?: string[];             // 🟦 gêneros traduzidos ("Thriller","Crime")
  director?: string;             // 🟦 CSV de diretores
  writer?: string;               // 🟦 CSV de roteiristas
  country?: string;              // 🟦 país(es)
  year?: string;                 // 🟦 "2026"
  releaseInfo?: string;          // 🟦 "2026" (filme) | "1999-" (série em curso)
  released?: string | null;      // 🟦 ISO 8601
  runtime?: string;              // 🟦 "1h48min" | "44min" (humanizado)
  status?: string;               // 🟦 (somente series) "Continuing" | "Ended" | ...
  imdbRating?: string;           // 🟦 "7.4" (string)

  // ----- Imagens -----
  poster?: string;               // 🟦 URL do pôster (TMDB/TVDB direto)
  posterShape?: "poster"|"landscape"|"square"; // 🟦 (somente detail)
  background?: string;           // 🟦 URL do fundo
  logo?: string;                 // 🟧 URL do logo (clearlogo) transparente
  landscapePoster?: string;      // 🟧 URL de pôster horizontal (16:9)
  _rawPosterUrl?: string;        // 🟧 URL bruta do pôster (sem proxy/transform)

  // ----- Mídia rica -----
  trailers?: Trailer[];          // 🟦
  links?: Link[];                // 🟦 imdb, share, Genres, Cast, Directors, Writers
  videos?: Video[];              // 🟦 (somente series/anime) episódios

  // ----- Hints e extensões -----
  behaviorHints?: {
    defaultVideoId?: string | null; // ID a abrir por padrão (filme = próprio id)
    hasScheduledVideos?: boolean;   // true se há episódios futuros agendados
  };
  app_extras?: AppExtras;        // 🟧 elenco com fotos, classificação, pôsteres de temporada

  // ----- IDs cross-source (🟧) -----
  _imdbId?: string;              // "tt..."
  _tmdbId?: string;              // "1340206"
  _tvdbId?: string;              // "359822"

  // ----- Flags de presença (🟧, somente detail de filme) -----
  _hasPoster?: boolean; _hasBackground?: boolean; _hasLogo?: boolean;
  _hasLandscapePoster?: boolean; _hasLinks?: boolean; _hasVideos?: boolean;
}
```

### Campos numéricos como string

| Campo | Tipo entregue | Exemplo | Parse |
|---|---|---|---|
| `year` | string | `"2026"` | `Int(year)` |
| `imdbRating` | string | `"7.4"` | `Double(imdbRating)` |
| `runtime` | string humanizada | `"1h48min"`, `"44min"` | parse manual / exibir como veio |
| `released` | string ISO 8601 \| null | `"2026-05-22T00:00:00.000Z"` | parser de data ISO |

### Diferença `MetaPreview` × `MetaDetail`

| Campo | MetaPreview (catálogo) | MetaDetail (`/meta`) |
|---|---|---|
| `videos` | ❌ | ✅ (series/anime) |
| `status` | ❌ | ✅ (series) |
| `posterShape` | ❌ | ✅ (movie) |
| `_has*` flags | ❌ | ✅ (movie) |
| demais campos | ✅ (já enriquecido) | ✅ |

> **Otimização:** como os catálogos já trazem `MetaPreview` rico (com `description`, `genres`, `imdbRating`, `background`, `logo`, `app_extras`), o StreamHub pode renderizar **cards detalhados sem uma segunda chamada**. Só chame `/meta` quando precisar de `videos` (episódios) ou ao abrir a tela de detalhe. Veja [07-integration.md](./07-integration.md).

---

## Video (episódio)

Item de `MetaDetail.videos[]` (séries e animes).

```ts
interface Video {
  id: string;          // 🟦 "{idSérie}:{season}:{episode}" → "tt0203259:27:21"
  title: string;       // 🟦 título do episódio ("Monstro" | "Episode 1")
  season: number;      // 🟦 0 = especiais
  episode: number;     // 🟦
  thumbnail?: string;  // 🟦 URL do still do episódio
  overview?: string | null; // 🟦 sinopse do episódio
  released?: string | null; // 🟦 ISO 8601 da estreia
  available: boolean;  // 🟧 true = já foi ao ar; false = futuro/não disponível
  runtime?: string;    // 🟧 "43min"
}
```

- **`id`** é a chave para resolver streams em addons de stream (formato `serie:temporada:episodio`).
- Lista vem **completa e ordenada** por `season`/`episode`. Ex.: SVU = 599 vídeos; Frieren = 66.
- Para anime resolvido via `mal:`/`kitsu:`, o `id` do vídeo usa o **ID IMDB** da série (ex.: `mal:52991` → vídeos `tt22248376:0:1`). Veja [06-id-system.md](./06-id-system.md).

---

## Trailer

```ts
interface Trailer {
  source: string;   // 🟦 ID do YouTube ("HYxzyLVJORA")
  ytId?: string;    // 🟧 idem source (redundante)
  type?: string;    // "Trailer" | "Clip" | ...
  name?: string;    // título do vídeo
  lang?: string;    // "en"
}
```

URL de reprodução: `https://www.youtube.com/watch?v={source}`. `name`/`ytId`/`lang` podem faltar em algumas fontes (ex.: TVDB traz só `source`/`type`/`name`).

---

## Link

```ts
interface Link {
  name: string;      // texto exibível ("7.4", "Thriller", "Dustin Hoffman")
  category: string;  // ver tabela
  url: string;       // http(s) externo OU deep-link stremio:///
}
```

Categorias observadas:

| `category` | Significado | `url` aponta para |
|---|---|---|
| `imdb` | Nota IMDB | `https://imdb.com/title/{tt}` |
| `share` | Link de compartilhamento | `https://www.strem.io/s/...` |
| `Genres` | Gênero clicável | `stremio:///discover/...` (deep-link) |
| `Cast` | Ator | `stremio:///search?search=...` |
| `Directors` | Diretor | `stremio:///search?search=...` |
| `Writers` | Roteirista | `stremio:///search?search=...` |

> **StreamHub deve ignorar `url` com esquema `stremio:///`** (são deep-links do app oficial). Para elenco/diretor, use o array estruturado `app_extras.cast`/`directors` em vez de parsear `links`. Para gênero clicável, monte sua própria rota de catálogo com `genre=`.

---

## AppExtras (🟧 extensão)

Bloco de enriquecimento exclusivo do AIOMetadata — **a fonte preferida** para elenco e classificação (dados estruturados, com fotos).

```ts
interface AppExtras {
  cast: Person[];
  directors: Person[];
  writers: Person[];
  certification?: string;       // classificação original ("R", "TV-14")
  certificationLocal?: string;  // classificação local/BR ("16", "14")
  seasonPosters?: string[];     // (series) URLs de pôster por temporada
}

interface Person {
  name: string;
  character: string;            // papel (para cast) ou próprio nome (director/writer)
  photo: string | null;         // URL da foto (TMDB/TVDB) ou null
}
```

Exemplo:

```json
{
  "cast": [
    { "name": "Dustin Hoffman", "character": "Harry Horowitz",
      "photo": "https://image.tmdb.org/t/p/w276_and_h350_face/....jpg" }
  ],
  "certification": "R",
  "certificationLocal": "16",
  "seasonPosters": ["https://artworks.thetvdb.com/.../75692-1.jpg"]
}
```

---

## Envelopes de resposta

```ts
// GET /manifest.json
type ManifestResponse = Manifest;

// GET /catalog/{type}/{id}[/{extras}].json
interface CatalogResponse { metas: MetaPreview[]; }   // [] se vazio

// GET /meta/{type}/{id}.json
interface MetaResponse { meta: MetaDetail | null; }    // null se inexistente

// GET /subtitles/{type}/{id}.json
interface SubtitlesResponse { subtitles: never[]; }    // sempre [] nesta instância
```

---

## Hosts de imagem (não proxiados)

URLs de imagem apontam **direto** para as fontes — o addon **não** faz proxy:

| Host | Origem | Exemplo |
|---|---|---|
| `image.tmdb.org` | TMDB | `https://image.tmdb.org/t/p/w600_and_h900_bestv2/{file}.jpg` |
| `artworks.thetvdb.com` | TVDB | `https://artworks.thetvdb.com/banners/.../{file}.jpg` |

Tamanhos TMDB (segmento `/t/p/{size}/`): `w300`, `w600_and_h900_bestv2`, `original`, `w276_and_h350_face` (fotos de elenco), etc. O StreamHub pode trocar o segmento de tamanho para otimizar download. Como são URLs públicas e diretas, podem ser carregadas/cacheadas pela camada de imagem do app sem passar pelo addon.
