---
titulo: "Protocolo de transporte dos addons Stremio"
parte_de: "docs/addons"
objetivo: "Descrever a camada de transporte HTTP/JSON: endpoints, codificação de extra, CORS/HTTPS, cabeçalhos de cache e transports alternativos."
ordem: 1
tipo: referencia
relevancia_para_streamhub: contexto
atualizado_em: "2026-06-24"
fontes:
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/protocol.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/README.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/README.md"
pre_requisitos: []
---

# Protocolo de transporte dos addons Stremio

## TL;DR

- Um addon é um **servidor HTTP stateless** que serve `GET /manifest.json` e responde a recursos em
  `GET /{resource}/{type}/{id}.json`. Tudo é JSON, estilo REST.
- Mínimo para existir: o `manifest.json` + **pelo menos 1 recurso**.
- Parâmetros `extra` (ex.: busca/paginação) vão num **segmento de path**:
  `GET /{resource}/{type}/{id}/{extra}.json`, onde `{extra}` é uma querystring (`chave=valor&...`)
  com valores URL-encoded — **não** é um `?query` real.
- Requisitos para clientes reais: **HTTPS** (exceto `127.0.0.1`) e **CORS liberando todas as
  origens**.
- Cache é controlado por `cacheMaxAge` / `staleRevalidate` / `staleError` (mapeiam para
  `Cache-Control`).
- **No StreamHub (addons nativos):** toda esta camada de transporte é **substituída por chamadas de
  função in-process**. Não há servidor, rota, HTTPS nem CORS. Esta página existe como referência do
  modelo original e para o caso de algum dia consumir um addon HTTP externo.

> Fonte primária desta página: `docs/protocol.md` do `stremio-addon-sdk`
> (`https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/protocol.md`).

## 1. Modelo geral

Citação do protocolo oficial: *"The Stremio addon protocol defines a universal interface to describe
multimedia content. It can describe catalogs, detailed metadata and streams … It is typically
transported over HTTP or IPFS, and follows a paradigm similar to REST."*

- O addon é **stateless**: cada requisição é independente.
- *"To define a minimal addon, you only need an HTTP server/endpoint serving a `/manifest.json` file
  and responding to resource requests at `/{resource}/{type}/{id}.json`."*
- Regra: **"It must provide at least 1 resource and a manifest."** Um addon pode oferecer qualquer
  subconjunto de recursos.
- Recursos atualmente usados: `catalog`, `meta`, `stream`, `subtitles` (+ `addon_catalog`).

## 2. Endpoints (templates exatos)

| Endpoint | Retorna | Notas |
|---|---|---|
| `GET /manifest.json` | objeto Manifest | Único endpoint obrigatório. Ver [manifest.md](./manifest.md). |
| `GET /catalog/{type}/{id}.json` | `{ metas: [MetaPreview] }` | `id` é o id do catálogo definido no manifest (um addon pode ter vários catálogos). |
| `GET /meta/{type}/{id}.json` | `{ meta: Meta }` | `id` é o id do item (como veio no catálogo). |
| `GET /stream/{type}/{videoId}.json` | `{ streams: [Stream] }` | Para itens de vídeo único (filmes), `videoId == id` do item. |
| `GET /subtitles/{type}/{id}.json` | `{ subtitles: [Subtitle] }` | No path, `id` é o hash do arquivo (OpenSubtitles); `videoId`/`videoSize` vão no `extra`. Ver nota em [recursos.md](./recursos.md). |
| `GET /{resource}/{type}/{id}/{extra}.json` | depende do recurso | Forma genérica com `extra` (ver §3). |

Contratos detalhados de cada recurso: [recursos.md](./recursos.md).

## 3. Codificação de `extra` (regra exata)

Citação: *"you should define a route of the format `/{resource}/{type}/{id}/{extraArgs}.json` where
`extraArgs` is the query string stringified object of extra arguments (for example
`"search=game%20of%20thrones&skip=100"`)."*

Regra:

1. Monte os pares `chave=valor` (valores **URL-encoded**).
2. Junte com `&`.
3. Coloque o resultado como **um único segmento de path**, antes de `.json`.

Exemplos reais de URL:

```
https://meu.addon.com/catalog/movie/top/search=game%20of%20thrones&skip=100.json
https://meu.addon.com/catalog/movie/top/genre=Action&skip=100.json
```

Chaves de `extra` que o Stremio envia para catálogos (devem estar declaradas no manifest do
catálogo — ver [manifest.md](./manifest.md)):

| Chave | Significado |
|---|---|
| `search` | Texto de busca. |
| `genre` | Filtro por gênero. |
| `skip` | Offset de paginação. **A página padrão do Stremio é 100**, então `skip` é múltiplo de 100. Se o addon retornar menos de 100 itens, o Stremio entende que chegou ao fim do catálogo. |

> `idPrefixes` **não** se aplica ao recurso `catalog`: um catálogo declarado em `catalogs[]` é sempre
> requisitado.

## 4. CORS, HTTPS, Content-Type e cache

### CORS (obrigatório para clientes reais)

*"For the HTTP transport, each route, including `/manifest.json`, must serve CORS headers that allow
all origins."* Na prática, o cabeçalho é `Access-Control-Allow-Origin: *`. O SDK Node faz isso
automaticamente.

> ⚠️ A doc descreve o requisito de forma semântica ("allow all origins"); o valor literal
> `Access-Control-Allow-Origin: *` é a forma universalmente usada, não citada ao pé da letra nos
> `.md`.

### HTTPS (obrigatório para clientes reais)

*"addon URLs in Stremio must be loaded with HTTPS (except `127.0.0.1`)…"* — qualquer addon não
servido de `127.0.0.1` precisa de HTTPS.

### Content-Type

Respostas são JSON (`application/json`). O protocolo é baseado em recursos `.json` que retornam
JSON. *(O literal `Content-Type: application/json` está implícito; não é impresso nos `.md`.)*

### Cabeçalhos de cache

Definidos globalmente via `serveHTTP(..., { cacheMaxAge })` e/ou por resposta de cada handler:

| Propriedade (na resposta) | Tipo | Mapeia para |
|---|---|---|
| `cacheMaxAge` | int (segundos) | `Cache-Control: max-age=$cacheMaxAge` |
| `staleRevalidate` | int (segundos) | `Cache-Control: stale-while-revalidate=$staleRevalidate` |
| `staleError` | int (segundos) | `Cache-Control: stale-if-error=$staleError` |

Opções de `serveHTTP(addonInterface, options)`: `port`, `cacheMaxAge`, `static` (diretório de
arquivos estáticos).

## 5. Transports e URLs

O Stremio seleciona o "transport" pela URL do addon (a **transportUrl** = URL completa até
`/manifest.json`; a base é essa URL menos `/manifest.json`):

| Sufixo / protocolo | Transport |
|---|---|
| `https://.../manifest.json` | **HTTP** (o usual). |
| `ipfs://.../manifest.json` ou `ipns://.../manifest.json` | **IPFS**. |
| `https://.../stremio/v1` | **legacy** (protocolo v1/v2 antigo). |

O cliente implementa esses transports e traduz requisições `{ resource, type, id, extra }` para o
formato de cada um.

## 6. O que muda no modelo nativo do StreamHub

| Aspecto do transporte | No StreamHub nativo |
|---|---|
| Servidor HTTP + rotas | **Removido.** Cada addon é um objeto Swift com métodos `catalog/meta/stream/subtitles`. |
| `manifest.json` por HTTP | **Vira uma struct Swift** (`AddonManifest`) lida diretamente. |
| Codificação de `extra` no path | **Removida.** `extra` vira um parâmetro tipado (`CatalogExtra`). |
| HTTPS + CORS | **Irrelevante** (sem rede entre cliente e addon). |
| Cache (`Cache-Control`) | Vira **cache em memória/disco no app** (decisão do StreamHub), opcionalmente reaproveitando a semântica de `cacheMaxAge`. |
| Transports (HTTP/IPFS/legacy) | **N/A.** Um addon nativo pode, internamente, buscar dados em qualquer API externa via `URLSession`. |

Como mapear isso em Swift está em [integracao-streamhub.md](./integracao-streamhub.md). Os contratos
de dados que **permanecem** estão em [manifest.md](./manifest.md) e [recursos.md](./recursos.md).
