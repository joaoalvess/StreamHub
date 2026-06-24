---
titulo: "Recursos do addon: catalog, meta, stream, subtitles, addon_catalog"
parte_de: "docs/addons"
objetivo: "Contratos exatos de request/response de cada recurso e a definição completa dos objetos (MetaPreview, Meta, Video, MetaLink, Stream, Subtitle)."
ordem: 3
tipo: referencia
relevancia_para_streamhub: alta
atualizado_em: "2026-06-24"
fontes:
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/meta.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/stream.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/subtitles.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/meta.links.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/addon_catalog.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/requests/defineCatalogHandler.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/advanced.md"
pre_requisitos:
  - "manifest.md"
---

# Recursos do addon: catalog, meta, stream, subtitles, addon_catalog

## TL;DR

- Cada recurso tem um **request** (args que o handler recebe: `type`, `id`, às vezes `extra`,
  sempre `config`) e um **response** (envelope JSON).
- Envelopes: `catalog → { metas: [MetaPreview] }`, `meta → { meta: Meta }`,
  `stream → { streams: [Stream] }`, `subtitles → { subtitles: [Subtitle] }`,
  `addon_catalog → { addons: [...] }`. Todos podem incluir `cacheMaxAge`/`staleRevalidate`/`staleError`.
- **MetaPreview** (no catálogo) é um subconjunto do **Meta** (na tela de detalhe).
- **Stream** carrega exatamente **uma** fonte: `url`, `ytId`, `infoHash`(+`fileIdx`) ou `externalUrl`.
- Convenção de id: filmes `videoId == id`; episódios de série: `tt...:temporada:episodio`.
- **No StreamHub:** estes objetos viram **structs Codable** em Swift e o handler vira um método
  `async`. Ver [integracao-streamhub.md](./integracao-streamhub.md).

> Os nomes/flags de campo abaixo foram extraídos byte-a-byte dos arquivos `.md` oficiais via
> `gh api .../contents/...`. Discrepâncias com a versão "publicada" da doc estão sinalizadas.

---

## 1. `catalog` — `defineCatalogHandler`

### Request (args do handler)

| Arg | Significado |
|---|---|
| `type` | Tipo do catálogo (`movie`/`series`/`channel`/`tv`). |
| `id` | Id do catálogo requisitado (definido em `manifest.catalogs[]`). |
| `extra` | Objeto com `search`, `genre`, `skip` (só os que o catálogo declara em `extra`). |
| `config` | Configuração do usuário. |

`extra`: `search` (texto), `genre` (filtro), `skip` (offset; passo de **100**; <100 itens ⇒ fim do
catálogo). `idPrefixes` **não** se aplica a `catalog`.

### Response

`{ metas: [MetaPreview] }` (+ campos de cache opcionais).

### Objeto MetaPreview (item do catálogo)

| Campo | Tipo | Obrigatório | Significado |
|---|---|---|---|
| `id` | string | **sim** | Id universal. Pode ter prefixo do addon (ex.: `yt_id:UCxxxx`). |
| `type` | string | **sim** | Tipo (`movie`/`series`/`channel`/`tv`). |
| `name` | string | **sim** | Nome do conteúdo. |
| `poster` | string | **sim** | URL do pôster (PNG). Aspecto 1:0.675 (IMDb) ou 1:1 (quadrado). <100kb (idealmente <50kb). |
| `posterShape` | string | não | `square` (1:1), `poster` (1:0.675) ou `landscape` (1:1.77). Padrão `poster`. |
| `genres` | array de strings | não | Ex.: `["Thriller","Horror"]`. **⚠️ A ser deprecado em favor de `links`.** |
| `imdbRating` | string | não | Nota IMDb, `"0.0"`–`"10.0"`. |
| `releaseInfo` | string | não | Ano. Para séries/canais: intervalo com til (`"2000-2014"`, ou em curso `"2000-"`). |
| `director`, `cast` | arrays de strings | não | Nomes. **⚠️ A ser deprecado em favor de `links`.** |
| `links` | array de MetaLink | não | Links internos do Stremio (ator/gênero/diretor). Ver §2.1. |
| `description` | string | não | Sinopse curta. |
| `trailers` | array | não | `{ "source": "<ytId>", "type": "Trailer"\|"Clip" }`. **⚠️ A ser deprecado.** |

> ⚠️ **Importante:** `background`, `logo` e `runtime` **não** fazem parte do MetaPreview documentado —
> eles pertencem ao **Meta** completo (§2). No catálogo, espere só os campos acima.

### Exemplo

```json
{
  "metas": [
    {
      "id": "tt1254207",
      "type": "movie",
      "name": "Big Buck Bunny",
      "releaseInfo": "2008",
      "poster": "https://image.tmdb.org/t/p/w600_and_h900_bestv2/uVEFQvFMMsg4e6yb03xOfVsDz4o.jpg",
      "posterShape": "poster"
    }
  ]
}
```

---

## 2. `meta` — `defineMetaHandler`

### Request

| Arg | Significado |
|---|---|
| `type` | Tipo do item. |
| `id` | Id do item (como veio no MetaPreview). |
| `config` | Configuração do usuário. |

Sem `extra`.

### Response

`{ meta: Meta }` (+ cache).

### Objeto Meta (detalhe completo)

| Campo | Tipo | Obrigatório | Significado |
|---|---|---|---|
| `id` | string | **sim** | Id universal. |
| `type` | string | **sim** | Tipo. |
| `name` | string | **sim** | Nome. |
| `genres` | array de strings | não | **⚠️ deprecando → `links`.** |
| `poster` | string | não | URL do pôster (1:0.675 ou 1:1; <100kb). |
| `posterShape` | string | não | `square`/`poster`/`landscape`. Padrão `poster`. |
| `background` | string | não | Fundo da tela de detalhe (PNG, máx 500kb). |
| `logo` | string | não | Logo da tela de detalhe (PNG). |
| `description` | string | não | Sinopse. |
| `releaseInfo` | string | não | Ano / intervalo. |
| `director`, `cast` | arrays de strings | não | **⚠️ deprecando → `links`.** |
| `imdbRating` | string | não | `"0.0"`–`"10.0"`. |
| `released` | string | não | Data ISO 8601 do lançamento. Ex.: `"2010-12-06T05:00:00.000Z"`. |
| `trailers` | array | não | **⚠️ deprecando → `meta.trailers` como array de Stream.** |
| `links` | array de MetaLink | não | Links internos (ator/gênero/diretor, etc.). Ver §2.1. |
| `videos` | array de Video | não | Para `series`/`channel`. Se ausente (ex.: filme), assume-se 1 vídeo cujo id == id do meta. Ver §2.2. |
| `runtime` | string | não | Legível, ex.: `"120m"`. |
| `language` | string | não | Idioma falado. |
| `country` | string | não | País de origem. |
| `awards` | string | não | Resumo de prêmios. |
| `website` | string | não | Site oficial. |
| `behaviorHints` | objeto | não | Ver abaixo. |

**`meta.behaviorHints`:** `defaultVideoId` (string) — abre a tela de detalhe direto nos streams
desse vídeo.

> ⚠️ **Fora da doc oficial do SDK:** `behaviorHints.hasScheduledVideos` e `trailerStreams` aparecem
> nos dados reais (Cinemeta/`stremio-core`), mas **não** estão em `docs/api/responses/meta.md`. Não
> dependa deles como contrato do SDK.

### 2.1 Objeto MetaLink

Fonte: `meta.md`, `meta.links.md`.

| Campo | Tipo | Obrigatório | Significado |
|---|---|---|---|
| `name` | string | **sim** | Nome legível do link. |
| `category` | string | **sim** | Categoria (agrupa os links). Recomendado: `actor`, `director`, `writer`. **Reservadas (não use): `imdb`, `share`, `similar`.** |
| `url` | string | **sim** | URL externa **ou** um deep link do Stremio. |

Gêneros/atores/diretores são expressos como MetaLinks cujo `url` é um deep link, agrupados por
`category`. Formas de deep link (`meta.links.md`):

```
stremio:///search?search=${query}
stremio:///discover/${transportUrl}/${type}/${catalogId}?${extra}
stremio:///detail/${type}/${id}
stremio:///detail/${type}/${id}/${videoId}
```

### 2.2 Objeto Video (episódios de série/canal)

| Campo | Tipo | Obrigatório | Significado |
|---|---|---|---|
| `id` | string | **sim** | Id do vídeo. Para séries IMDb: `tt0108778:1:1`. |
| `title` | string | **sim** | Título do vídeo. *(O campo é `title`, não `name`.)* |
| `released` | string | **sim** | Data ISO 8601 de exibição. |
| `thumbnail` | string | não | URL do thumbnail (PNG no aspecto do vídeo, máx 5kb). |
| `streams` | array de Stream | não | Embute streams no meta. **Exclusivo:** se passado, o Stremio **não** pede streams a outros addons para esse vídeo. |
| `available` | boolean | não | `true` marca como reproduzível (dispensável se `streams` foi passado). |
| `episode` | number | não | Número do episódio. |
| `season` | number | não | Número da temporada. |
| `trailers` | array de Stream | não | Trailers do vídeo. |
| `overview` | string | não | Resumo do vídeo. |

### Exemplos

Video de série:

```json
{ "id": "tt0108778:1:1", "title": "Pilot", "released": "1994-09-22T20:00:00.000Z", "season": 1, "episode": 1, "overview": "Monica and the gang introduce Rachel to the real world..." }
```

Meta mínimo:

```json
{
  "meta": {
    "id": "tt1254207", "type": "movie", "name": "Big Buck Bunny",
    "releaseInfo": "2008",
    "poster": "https://image.tmdb.org/t/p/w600_and_h900_bestv2/uVEFQvFMMsg4e6yb03xOfVsDz4o.jpg",
    "posterShape": "poster"
  }
}
```

Exemplo real completo: `https://v3-cinemeta.strem.io/meta/series/tt0386676.json`.

---

## 3. `stream` — `defineStreamHandler`

### Request

| Arg | Significado |
|---|---|
| `type` | Tipo. |
| `id` | **videoId**. Filmes: `videoId == id` do meta. Séries IMDb (Cinemeta): `imdbId:temporada:episodio`, ex.: `"tt0898266:9:17"`. |
| `config` | Configuração do usuário. |

### Response

`{ streams: [Stream] }`, **ordenados do maior para o menor qualidade** (+ cache).

### Objeto Stream

**Exatamente um ponteiro de fonte** deve ser fornecido:

| Campo de fonte | Tipo | Quando usar |
|---|---|---|
| `url` | string | Link direto http(s)/ftp(s)/rtmp para um vídeo reproduzível. |
| `ytId` | string | Id de vídeo do YouTube (player embutido). |
| `infoHash` | string | Info hash de torrent. Combine com `fileIdx`. **Sem `fileIdx`, escolhe o maior arquivo do torrent.** |
| `fileIdx` | number | Índice do arquivo de vídeo dentro do torrent (ou nzb/rar/zip/7z/tgz/tar). |
| `externalUrl` | string | Deep link do Stremio **ou** URL externa aberta no navegador (ex.: link da Netflix). Use quando não há stream reproduzível direto. |

Outras fontes/avançadas: `fileMustInclude` (regex p/ arquivo em arquivos comprimidos — não vale para
torrent), `nzbUrl` + `servers` (usenet), `rarUrls`/`zipUrls`/`7zipUrls`/`tgzUrls`/`tarUrls` (arrays
de Source Object).

**Campos informativos / de comportamento (opcionais):**

| Campo | Tipo | Significado |
|---|---|---|
| `name` | string | Nome do stream; normalmente a **qualidade** (ex.: `"1080p"`). |
| `title` | string | Descrição do stream. **⚠️ deprecando → `description`.** |
| `description` | string | Descrição do stream (antigo `title`). |
| `subtitles` | array de Subtitle | Legendas deste stream (mesmo formato de §4). |
| `sources` | array de strings | Trackers + nós DHT p/ descoberta de peers quando `infoHash`. Formato: `tracker:<http\|udp>://host:port`, `dht:<node_id>`. |

**`stream.behaviorHints` (opcionais):**

| Campo | Tipo | Significado |
|---|---|---|
| `countryWhitelist` | array de strings | Códigos ISO 3166-1 alpha-3 **em minúsculo** onde o stream é acessível. |
| `notWebReady` | boolean | `true` se a `url` não é https ou não é MP4 (não reproduzível direto na web). |
| `bingeGroup` | string | Streams com o mesmo `bingeGroup` são auto-selecionados no próximo episódio (binge). Ex.: `"meuAddon-720p"`. |
| `proxyHeaders` | objeto | Só com `url` e **requer `notWebReady: true`**. `{ "request": {...}, "response": {...} }` de headers. |
| `videoHash` | string | Hash OpenSubtitles do vídeo (para casar legendas). |
| `videoSize` | number | Tamanho do vídeo em bytes. |
| `filename` | string | Nome do arquivo de vídeo. **Recomendado** quando usa `stream.url`. |

### Exemplos

```json
{ "streams": [ { "name": "1080p", "url": "http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4" } ] }
```

```json
{ "streams": [ { "name": "MeuAddon 720p", "infoHash": "dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c", "fileIdx": 0, "behaviorHints": { "bingeGroup": "meuAddon-720p" } } ] }
```

> **Nota de reprodução para tvOS (ver [integracao-streamhub.md](./integracao-streamhub.md)):** o
> `AVPlayer` toca `url` HLS/MP4 sobre HTTP(S). `infoHash` (torrent) e `ytId` **não** são
> reproduzíveis nativamente sem um motor extra (no Stremio desktop, o streaming server em
> `127.0.0.1:11470` converte torrent→HTTP). Para o StreamHub, priorize fontes `url` diretas.

---

## 4. `subtitles` — `defineSubtitlesHandler`

### Request

| Arg | Significado |
|---|---|
| `type` | Tipo. |
| `id` | videoId. *(No path do transporte, o `id` é o hash OpenSubtitles; `videoId`/`videoSize` vêm no `extra`.)* |
| `extra` | `videoHash` (hash OpenSubtitles), `videoSize` (bytes), `filename`. |
| `config` | Configuração do usuário. |

### Response

`{ subtitles: [Subtitle] }` (+ cache).

### Objeto Subtitle

| Campo | Tipo | Obrigatório | Significado |
|---|---|---|---|
| `id` | string | **sim** | Id único por legenda (diferencia legendas do mesmo idioma). |
| `url` | string | **sim** | URL do arquivo de legenda. |
| `lang` | string | **sim** | Código de idioma. Se não for ISO 639-2 válido, o valor literal é mostrado. |

Formatos: `.srt` e `.vtt`. Para legendas mal codificadas, aponte `url` para
`http://127.0.0.1:11470/subtitles.vtt?from=<url-encoded>` (o streaming server adivinha a codificação).

```json
{ "subtitles": [ { "id": "sub1", "url": "https://mkvtoolnix.download/samples/vsshort-en.srt", "lang": "eng" } ] }
```

---

## 5. `addon_catalog` — descoberta de outros addons

Recurso para **descoberta**: retorna catálogos de **manifests de outros addons** (um addon que é um
diretório de addons instaláveis). Declarado em `manifest.addonCatalogs[]`.

### Request

`type`, `id` (do addon catalog, definido no manifest), `config`.

### Response

`{ addons: [AddonCatalogEntry] }`:

| Campo | Tipo | Obrigatório | Significado |
|---|---|---|---|
| `transportName` | string | **sim** | Só `http` é oficialmente suportado hoje. |
| `transportUrl` | string | **sim** | URL do `manifest.json` do addon. |
| `manifest` | objeto | **sim** | O Manifest completo do addon. |

```json
{
  "addons": [
    {
      "transportName": "http",
      "transportUrl": "https://example.addon.org/manifest.json",
      "manifest": { "id": "org.myexampleaddon", "version": "1.0.0", "name": "simple example", "catalogs": [], "resources": ["stream"], "types": ["movie"], "idPrefixes": ["tt"] }
    }
  ]
}
```

> Para o StreamHub (addons nativos fixos), `addon_catalog` é **contexto** — a "lista de addons" é a
> própria lista registrada no app.

---

## 6. Convenções de id (essencial para agregação)

- **IDs IMDb** começam com `tt` (ex.: `tt1254207`). Episódios de série: `tt3107288:1:1` =
  T1E1 do meta `tt3107288`.
- **Cinemeta é o addon de metadados padrão.** Ele resolve **todos os ids `tt`**. Logo, um addon que
  só serve `stream`/`subtitles` para ids `tt` **não precisa** implementar `meta` — o Cinemeta cobre.
  Endpoint: `https://v3-cinemeta.strem.io/meta/{type}/{imdbId}.json`.
- **Prefixos customizados:** um addon pode usar prefixo próprio (ex.: `yt_id:UCxxxx`). Aí ele
  **precisa** implementar `meta` para esse prefixo.
- **`idPrefixes` matching:** o addon só é chamado para ids que começam com algum prefixo da lista.
  Ausente/vazio ⇒ todos os ids. Não se aplica a `catalog`.
- ⚠️ **Kitsu (`kitsu:<id>`, animes):** convenção da comunidade, **não** documentada no SDK oficial.

A lógica completa de "qual addon o cliente consulta e em que ordem" está em
[descoberta-e-agregacao.md](./descoberta-e-agregacao.md).
