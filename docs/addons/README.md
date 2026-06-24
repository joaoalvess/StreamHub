---
titulo: "Integração de Addons do Stremio — Documentação StreamHub"
parte_de: "docs/addons"
objetivo: "Índice e visão geral de como o protocolo de addons do Stremio funciona e como ele se aplica ao StreamHub (modelo de addons nativos embutidos)."
ordem: 0
tipo: indice
relevancia_para_streamhub: alta
atualizado_em: "2026-06-24"
fontes:
  - "https://github.com/Stremio/stremio-addon-sdk"
  - "https://github.com/Stremio/stremio-addon-sdk/tree/master/docs"
  - "https://stremio.github.io/stremio-addon-guide/"
  - "https://github.com/Stremio/stremio-core"
  - "https://github.com/Stremio/stremio-official-addons"
---

# Integração de Addons do Stremio — Documentação StreamHub

> **Para a IA que vai ler isto:** esta pasta é a fonte da verdade sobre o protocolo de addons do
> Stremio e sobre como o **StreamHub** pretende usá-lo. Cada arquivo é autocontido, começa com
> frontmatter YAML (metadados) e um bloco `## TL;DR`. Termos canônicos estão no glossário abaixo;
> use-os exatamente. Quando um arquivo afirma um fato do protocolo, ele cita a URL da fonte oficial.

## Contexto do StreamHub (leia primeiro)

O StreamHub é um app **SwiftUI para tvOS** (Apple TV, navegação por foco). Hoje todo o conteúdo vem
de `StreamHub/Models/MockData.swift` (estático). O objetivo desta documentação é descrever o
protocolo de addons do Stremio e definir como o StreamHub vai **substituir o MockData por addons**.

Diferença crítica em relação ao Stremio padrão:

- No **Stremio oficial**, addons são servidores HTTP remotos que o usuário **instala por URL**, e a
  lista de addons é sincronizada na conta do usuário via API central (`api.strem.io`).
- No **StreamHub**, os addons serão **nativos e embutidos no app** (3 a 4 addons, in-process, em
  Swift). Uso pessoal; nada é publicado nem instalado remotamente.

Consequência para a leitura: o **transporte HTTP**, a **instalação por URL/deep link** e a
**publicação/sincronização** são **contexto** (não serão implementados como tais). O que de fato
importa para o StreamHub é o **contrato de dados** (manifest + recursos `catalog`/`meta`/`stream`/
`subtitles`), as **convenções de id** e a **lógica de agregação multi-addon**. Cada arquivo marca,
no frontmatter, sua `relevancia_para_streamhub`: `alta`, `media` ou `contexto`.

## Como ler (ordem recomendada)

| # | Arquivo | Objetivo | Relevância p/ StreamHub |
|---|---|---|---|
| 1 | [protocolo.md](./protocolo.md) | Camada de transporte: endpoints HTTP, codificação de `extra`, CORS/HTTPS, cache. | contexto |
| 2 | [manifest.md](./manifest.md) | Anatomia do `manifest.json`: o descritor de capacidades de um addon. | **alta** |
| 3 | [recursos.md](./recursos.md) | Contratos de `catalog`, `meta`, `stream`, `subtitles`, `addon_catalog` (request/response + objetos). | **alta** |
| 4 | [descoberta-e-agregacao.md](./descoberta-e-agregacao.md) | Instalação/descoberta no Stremio padrão (contexto) **e** a lógica de agregação multi-addon (alta). | mista |
| 5 | [sdk-e-deploy.md](./sdk-e-deploy.md) | SDK Node `stremio-addon-sdk`, exemplo executável, hospedagem. | media |
| 6 | [integracao-streamhub.md](./integracao-streamhub.md) | A ponte: arquitetura nativa em Swift, modelos Codable, `AddonManager`, mapeamento para a UI e plano de fases. | **alta** |

Caminho mínimo se você só quer implementar no StreamHub: **manifest.md → recursos.md →
descoberta-e-agregacao.md (seção "Agregação") → integracao-streamhub.md**.

## Visão geral do protocolo (1 minuto)

Um addon Stremio é um **provedor de conteúdo stateless** que expõe um `manifest.json` (declara o que
ele sabe fazer) e responde a requisições de **recursos** em JSON. O cliente pergunta, o addon
responde. O fluxo de dados é hierárquico:

```
Catalog            (lista de itens; alimenta as prateleiras/rows da home)
  └─ MetaPreview   (item resumido dentro de um catálogo)
       └─ Meta     (detalhe completo do item, ao abrir a tela de detalhe)
            └─ Video        (para séries/canais: cada episódio)
                 └─ Stream  (fontes reproduzíveis de um vídeo)
                      └─ Subtitle  (legendas para um stream)
```

Endpoints HTTP (no transporte oficial — no StreamHub viram chamadas de função in-process):

```
Cliente (StreamHub)                          Addon
   ──  GET /manifest.json              ─────▶  Manifest
   ──  GET /catalog/{type}/{id}.json   ─────▶  { metas:     [MetaPreview] }
   ──  GET /meta/{type}/{id}.json      ─────▶  { meta:      Meta          }
   ──  GET /stream/{type}/{id}.json    ─────▶  { streams:   [Stream]      }
   ──  GET /subtitles/{type}/{id}.json ─────▶  { subtitles: [Subtitle]    }
```

Um addon pode implementar **qualquer subconjunto** desses recursos (no mínimo 1 recurso + o
manifest). O cliente decide **quais** addons consultar para cada requisição usando os campos
`types` e `idPrefixes` do manifest (ver [descoberta-e-agregacao.md](./descoberta-e-agregacao.md)).

## Glossário (termos canônicos)

| Termo | Definição |
|---|---|
| **addon** | Provedor de conteúdo que expõe um manifest e responde a recursos. No Stremio é um servidor HTTP; no StreamHub é um objeto Swift in-process. |
| **manifest** | Objeto JSON que descreve o addon: `id`, `version`, `name`, `types`, `resources`, `catalogs`, etc. Ver [manifest.md](./manifest.md). |
| **transportUrl** | URL completa para o `manifest.json` de um addon (ex.: `https://x.com/manifest.json`). A base é essa URL menos `/manifest.json`. Conceito do transporte HTTP — irrelevante no modelo nativo. |
| **resource (recurso)** | Capacidade que um addon oferece: `catalog`, `meta`, `stream`, `subtitles`, `addon_catalog`. |
| **type (tipo)** | Tipo de conteúdo: `movie`, `series`, `channel`, `tv`. |
| **id** | Identificador universal de um item. IDs do IMDb começam com `tt` (ex.: `tt1254207`). |
| **videoId** | ID de um vídeo específico. Para filmes, é igual ao `id` do item. Para episódios de série (Cinemeta): `imdbId:temporada:episodio` (ex.: `tt0944947:1:1`). |
| **idPrefixes** | Lista de prefixos de `id` que o addon atende (ex.: `["tt"]`). Usada pelo cliente para filtrar quais addons consultar. Não se aplica a `catalog`. |
| **extra** | Parâmetros adicionais de um `catalog`: `search`, `genre`, `skip`. |
| **catalog** | Lista de itens (`MetaPreview`). Vira uma prateleira/row na home. |
| **MetaPreview** | Versão resumida do item, retornada dentro de um catálogo. |
| **Meta** | Detalhe completo de um item (descrição, elenco, vídeos/episódios, etc.). |
| **Stream** | Fonte reproduzível de um vídeo: `url`, `ytId`, `infoHash`+`fileIdx` ou `externalUrl`. |
| **Subtitle** | Legenda: `{ id, url, lang }`. |
| **behaviorHints** | Dicas de comportamento (no manifest, no stream e no meta). Ex.: `bingeGroup`, `notWebReady`, `configurable`. |
| **bingeGroup** | Marca em `stream.behaviorHints` que faz o cliente auto-selecionar o stream do mesmo grupo no próximo episódio (binge). |
| **Cinemeta** | Addon oficial padrão de metadados do Stremio (`https://v3-cinemeta.strem.io`). Resolve todos os IDs `tt` (IMDb). Ver [descoberta-e-agregacao.md](./descoberta-e-agregacao.md). |
| **addon collection** | Conjunto de addons instalados pelo usuário, sincronizado na conta via `api.strem.io`. Contexto — não usado no modelo nativo. |
| **agregação** | Lógica do cliente para combinar respostas de vários addons (ordem de instalação, filtragem por `types`/`idPrefixes`, fall-through). É o que o StreamHub precisa replicar nativamente. |

## Fontes canônicas

Toda afirmação sobre o protocolo nesta pasta vem destas fontes oficiais (não de memória):

- **SDK + docs do protocolo:** `https://github.com/Stremio/stremio-addon-sdk` e
  `…/tree/master/docs` (em especial `docs/protocol.md`, `docs/api/responses/*`,
  `docs/api/requests/*`).
- **Guia de addons (tutorial):** `https://stremio.github.io/stremio-addon-guide/`.
- **Engine do cliente (comportamento de agregação/instalação):** `https://github.com/Stremio/stremio-core`
  e `https://github.com/Stremio/stremio-api-client`.
- **Addons oficiais pré-instalados:** `https://github.com/Stremio/stremio-official-addons`.

## Convenção de confiança

Quando um fato não está na documentação oficial do SDK (mas sim no código do engine, ou só em
fontes secundárias), o arquivo marca explicitamente com **"⚠️ confiança média"** ou **"fora da doc
oficial do SDK"**. Discrepâncias conhecidas da própria doc oficial também são sinalizadas. Não trate
nada marcado assim como contrato estável sem verificar na fonte.
