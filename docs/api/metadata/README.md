# AIOMetadata API — Documentação Técnica

> Documentação de referência do addon **AIOMetadata** (protocolo Stremio Addon), consumido nativamente pelo StreamHub para catálogos e metadados de filmes, séries e animes.
>
> **Público-alvo:** agentes de IA e desenvolvedores implementando a camada de dados do StreamHub. Documento factual, sem suposições — todo comportamento aqui descrito foi verificado contra a API real em 2026-06.

---

## O que é

AIOMetadata é um **addon de metadados** do Stremio que agrega dados de múltiplas fontes (TMDB, TVDB, TVMaze, MyAnimeList, IMDB, Trakt, MDBList, FlixPatrol, Fanart.tv) e os expõe através do **protocolo de addons do Stremio**: um contrato HTTP/JSON simples e stateless baseado em três recursos — `catalog`, `meta` e `subtitles`.

Não é um servidor de streams/vídeo. Ele fornece **listas curadas** (catálogos) e **fichas técnicas** (metadados) — pôsteres, sinopses, elenco, episódios, trailers, classificações. O StreamHub o usa como backend de descoberta e detalhe de conteúdo, controlando 100% da camada de apresentação.

## Identidade da instância documentada

| Campo | Valor |
|---|---|
| **Nome** | `AIOMetadata \| ElfHosted` |
| **ID do addon** | `aio-metadata` |
| **Versão** | `2.7.1` (observada) |
| **Host** | `https://aiometadata.elfhosted.com` (ElfHosted, atrás de Cloudflare, runtime Express) |
| **Config ID** | `b11959c7-94fd-4fd2-aa24-6655c4fd7164` |
| **Idioma** | `pt-BR` |
| **Recursos** | `catalog`, `meta`, `subtitles` |
| **Catálogos** | 99 |

## URL base

```
https://aiometadata.elfhosted.com/stremio/{configId}/
```

O `{configId}` (`b11959c7-...`) é um identificador **opaco** que referencia uma configuração salva no servidor — define idioma, fontes de metadados ativas, quais catálogos aparecem e em que ordem. Veja [01-overview.md](./01-overview.md#config-id).

## Quickstart (3 chamadas essenciais)

```bash
BASE="https://aiometadata.elfhosted.com/stremio/b11959c7-94fd-4fd2-aa24-6655c4fd7164"

# 1. Descobrir o addon: o que ele oferece (catálogos, tipos, recursos)
curl "$BASE/manifest.json"

# 2. Carregar um catálogo (lista de itens) — ex.: filmes em alta no TMDB
curl "$BASE/catalog/movie/tmdb.trending.json"

# 3. Carregar a ficha completa de um item (metadados + episódios)
curl "$BASE/meta/series/tt0203259.json"
```

Toda resposta é JSON (`application/json; charset=utf-8`), CORS liberado (`access-control-allow-origin: *`), e **sempre HTTP 200** mesmo em "não encontrado" (erros são representados como `null`/lista vazia — veja [02-endpoints.md](./02-endpoints.md#tratamento-de-erros)).

## Índice da documentação

| Arquivo | Conteúdo |
|---|---|
| [01-overview.md](./01-overview.md) | Arquitetura, modelo de addon Stremio, papel do Config ID, fontes de dados, tipos de conteúdo, infraestrutura. |
| [02-endpoints.md](./02-endpoints.md) | Referência de cada rota: `manifest`, `catalog`, `meta`, `subtitles`. Request, response, headers, erros. |
| [03-filters-and-extras.md](./03-filters-and-extras.md) | Sistema de **tags** (`?tag=`) e **extras** (`skip`, `genre`, `search`, `calendarVideosIds`). Paginação, busca, filtragem. |
| [04-schemas.md](./04-schemas.md) | Tipos completos campo a campo: `Manifest`, `Catalog`, `MetaPreview`, `MetaDetail`, `Video`, `Trailer`, `Link`, `app_extras`. |
| [05-catalog-reference.md](./05-catalog-reference.md) | Tabela dos 99 catálogos, códigos de plataforma de streaming, mapa `tag → catálogos`. |
| [06-id-system.md](./06-id-system.md) | Sistema de IDs, prefixos, resolução cross-source, formato de ID de episódio. |
| [07-integration.md](./07-integration.md) | Receitas de consumo para o StreamHub: montar Home, paginar, buscar, abrir detalhe, listar episódios. |
| [examples/](./examples/) | Respostas JSON reais (amostras truncadas) de cada endpoint. |

## Convenções deste documento

- `{configId}` — placeholder do ID de configuração na URL base.
- `{type}` — tipo de conteúdo Stremio (`movie`, `series`, `anime`, …).
- `{id}` — identificador do catálogo (em rotas `catalog`) ou do conteúdo (em rotas `meta`).
- Blocos `bash` usam a variável `$BASE` definida no Quickstart.
- "Verificado" = comportamento observado diretamente na API, não inferido da especificação.

## Glossário rápido

| Termo | Significado |
|---|---|
| **Addon** | Servidor HTTP que implementa o protocolo Stremio (manifest + recursos). |
| **Manifest** | Documento de autodescrição do addon (`/manifest.json`). |
| **Catalog** | Lista paginável de itens (`metas`) — ex.: "Trending", "Top 10 Netflix". |
| **Meta** | Ficha de um item: `MetaPreview` (resumida, em catálogos) ou `MetaDetail` (completa, em `/meta`). |
| **Resource** | Capacidade do addon: `catalog`, `meta`, `subtitles`. |
| **Extra** | Parâmetro opcional/obrigatório de um catálogo (`skip`, `genre`, `search`, …). |
| **Tag** | Filtro de query (`?tag=`) que reduz o manifest a um subconjunto de catálogos. |
| **Config ID** | UUID na URL que seleciona a configuração salva (idioma, fontes, catálogos). |
