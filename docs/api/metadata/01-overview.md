# 01 — Visão Geral e Arquitetura

## 1. O modelo de addon do Stremio

O AIOMetadata implementa o **protocolo de addons do Stremio**. Esse protocolo define um addon como um servidor HTTP **stateless** que:

1. Se autodescreve em `GET /manifest.json` — declara seu `id`, `version`, quais **recursos** (`resources`) implementa, quais **tipos** (`types`) de conteúdo manipula, quais **catálogos** (`catalogs`) oferece e quais **prefixos de ID** (`idPrefixes`) reconhece.
2. Responde a requisições de recurso no formato de rota:
   ```
   GET /{resource}/{type}/{id}.json
   GET /{resource}/{type}/{id}/{extras}.json
   ```
3. Retorna sempre JSON, sempre HTTP 200 (ausência = `null`/`[]`, nunca 4xx/5xx para "não encontrado").

Os três recursos relevantes aqui:

| Resource | Rota | Retorna | Uso |
|---|---|---|---|
| `catalog` | `/catalog/{type}/{id}.json` | `{ metas: MetaPreview[] }` | Listas de conteúdo (Home, gêneros, Top 10, busca). |
| `meta` | `/meta/{type}/{id}.json` | `{ meta: MetaDetail }` | Ficha completa de um item (detalhe + episódios). |
| `subtitles` | `/subtitles/{type}/{id}.json` | `{ subtitles: [] }` | Legendas. **Nesta instância retorna sempre vazio** (veja [02-endpoints.md](./02-endpoints.md#get-subtitles)). |

> **Importante para o StreamHub:** o app **não precisa do cliente oficial do Stremio**. O protocolo é HTTP/JSON puro — basta o StreamHub fazer `GET` nas rotas e desserializar. É exatamente isso que significa "consumir nativamente para controle máximo".

## 2. Arquitetura de dados (agregação)

O AIOMetadata é um **agregador**. Cada catálogo é alimentado por uma fonte upstream, e cada ficha de metadados é montada combinando várias fontes. O addon faz o trabalho de:

- Buscar listas em provedores (Trakt, TMDB, MDBList, MAL, FlixPatrol).
- Cruzar identificadores entre bases (IMDB ↔ TMDB ↔ TVDB ↔ MAL ↔ Kitsu).
- Normalizar tudo no formato `Meta` do Stremio, traduzido para o idioma configurado.
- Enriquecer com campos extras não-padrão (`app_extras.cast`, `landscapePoster`, `logo`, `_tmdbId`…).

### Fontes de dados por origem de catálogo

| Prefixo do catálogo | Fonte | Natureza |
|---|---|---|
| `trakt.*` | **Trakt** | Trending, popular, recomendações personalizadas. |
| `tmdb.*` | **TMDB** (The Movie Database) | Trending, popular, top rated, no ar hoje. |
| `tvdb.*` | **TVDB** (TheTVDB) | Trending de séries, gêneros. |
| `mdblist.*` | **MDBList** | Listas curadas por ID numérico (gêneros, coleções, "Top X"). |
| `mal.*` | **MyAnimeList** | Anime: temporadas, em exibição, top, por gênero/estúdio. |
| `flixpatrol.*` | **FlixPatrol** | Rankings "Top 10" por plataforma e país. |
| `streaming.*` | Catálogo por plataforma | Catálogo de uma plataforma (Netflix, Disney+…), filtrável por gênero. |
| `search.*` | Busca textual | Busca por título em movie/series/anime. |
| `gemini.search` | **Google Gemini** | Busca semântica/linguagem natural (ex.: "filmes como Inception"). |
| `calendar-videos` | Interno | Próximos episódios de séries acompanhadas (notificações). |

Fontes de metadados (ficha): **TMDB, TVDB, TVMaze, MyAnimeList, IMDB, Fanart.tv** — a fonte primária é escolhida na configuração (`description` do manifest: _"You choose the source"_).

## 3. Config ID

Na URL `…/stremio/{configId}/…`, o `{configId}` (`b11959c7-94fd-4fd2-aa24-6655c4fd7164`) é um **identificador opaco** que aponta para uma configuração salva no servidor. Ele determina, de forma observável:

- **Idioma** dos metadados e nomes de catálogo → aqui `pt-BR` (refletido em `manifest.language` e no header `x-manifest-language`).
- **Quais catálogos** aparecem e **em que ordem** (os 99 catálogos desta instância).
- **Fontes de metadados** ativas e suas prioridades.
- **Chaves de provedor** associadas (Trakt/MDBList/TMDB/Gemini), mantidas no servidor — nunca expostas na URL além do UUID.

Propriedades:

- É **estável**: a mesma URL serve a mesma configuração sempre.
- Tem uma **versão**: `manifest.configVersion` (e header `x-manifest-version`) — um número que muda quando a configuração é editada. Útil como chave de cache de invalidação.
- A configuração é criada/editada pela UI web em `GET /stremio/{configId}/configure` (HTML, `text/html`). O StreamHub não precisa dessa UI em runtime; basta consumir as rotas JSON.

> **Múltiplas configurações:** é possível ter vários `{configId}` (ex.: um por idioma, ou um por conjunto de catálogos). Trocar de configuração = trocar o UUID na URL base. Em respostas de catálogo, alguns `links` internos podem referenciar outros UUIDs de configuração (artefato do cache compartilhado do addon) — o StreamHub deve **ignorar** esses deep-links `stremio:///…` e usar sempre seu próprio `{configId}`.

## 4. Tipos de conteúdo (`types`)

`manifest.types` declara os tipos que o addon manipula em `meta`:

```json
["movie", "series", "anime.movie", "anime.series", "anime", "Trakt", "collection"]
```

Já os **catálogos** usam um conjunto parcialmente diferente de `type` (a chave de roteamento real). Tipos observados em uso:

| `type` | Onde aparece | Observações |
|---|---|---|
| `movie` | Catálogos de filme; `meta` de filme. | Tipo padrão Stremio. |
| `series` | Catálogos de série; `meta` de série. | Tipo padrão Stremio. **Anime também é resolvido como `series`/`movie` na `meta`.** |
| `anime` | Catálogos MAL (`mal.*`). | Os **itens** dentro desses catálogos têm `type: "series"` ou `"movie"`, não `"anime"`. |
| `anime.movie` / `anime.series` | Catálogos de busca de anime (`search.anime_*`). | Subtipos só para roteamento de busca. |
| `all` | `flixpatrol.discovery-plus.us.all`. | Tipo especial Stremio: mistura filmes e séries. |
| `other` | `gemini.search`. | Categoria genérica para conteúdo sem tipo fixo. |
| `Trakt`, `collection` | Declarados em `types`, sem catálogo correspondente nesta config. | Reservados para meta de coleções. |

> **Regra de ouro:** o `type` na rota de `catalog` deve ser o `type` **declarado para aquele catálogo no manifest**. O `type` na rota de `meta` deve casar com o `type` do item (que pode diferir do `type` do catálogo de origem — ex.: um item de catálogo `anime` é buscado em `/meta/series/...`). Veja [06-id-system.md](./06-id-system.md).

## 5. Infraestrutura e características HTTP

| Aspecto | Valor observado |
|---|---|
| Host | `aiometadata.elfhosted.com` (provedor **ElfHosted**) |
| Edge | **Cloudflare** (`cf-cache-status: DYNAMIC`) |
| Runtime | **Express** (`x-powered-by: Express`) |
| Content-Type | `application/json; charset=utf-8` |
| CORS | Totalmente liberado: `access-control-allow-origin: *`, métodos `GET,POST,PUT,DELETE,OPTIONS`, headers `*` |
| Cache HTTP | `cache-control: no-cache, no-store, must-revalidate, max-age=0, s-maxage=0` → **respostas não devem ser cacheadas pela camada HTTP**; o cache é responsabilidade do cliente (StreamHub). |
| ETag | Presente (`W/"…"`) — pode ser usado com `If-None-Match`. |
| Headers custom | `x-manifest-language` (ex.: `pt-BR`), `x-manifest-version` (= `configVersion`). |

> **Implicação de cache:** como o servidor envia `no-store`, o StreamHub deve implementar seu **próprio cache em memória/disco** com TTL definido pelo app (ex.: 5–15 min para catálogos, mais longo para `meta` imutável). Não confie no cache HTTP padrão. Veja [07-integration.md](./07-integration.md#cache).

## Próximos documentos

- Detalhes de cada rota → [02-endpoints.md](./02-endpoints.md)
- Filtros e paginação → [03-filters-and-extras.md](./03-filters-and-extras.md)
- Formato exato dos dados → [04-schemas.md](./04-schemas.md)
