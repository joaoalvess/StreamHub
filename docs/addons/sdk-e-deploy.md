---
titulo: "SDK Node (stremio-addon-sdk) e hospedagem"
parte_de: "docs/addons"
objetivo: "Referência do SDK oficial em Node (handlers, serve, publish) e opções de hospedagem. Relevante só se o StreamHub um dia consumir/rodar um addon HTTP externo."
ordem: 5
tipo: referencia
relevancia_para_streamhub: media
atualizado_em: "2026-06-24"
fontes:
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/README.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/README.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/requests/defineStreamHandler.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/deploying/beamup.md"
  - "https://github.com/Stremio/stremio-addon-linter"
pre_requisitos:
  - "manifest.md"
  - "recursos.md"
---

# SDK Node (`stremio-addon-sdk`) e hospedagem

## TL;DR

- O SDK oficial é em **Node.js**: você cria um `addonBuilder(manifest)`, registra handlers
  (`defineCatalogHandler`, `defineMetaHandler`, `defineStreamHandler`, `defineSubtitlesHandler`) e
  serve com `serveHTTP(getInterface(), { port })`.
- `publishToCentral(url)` lista o addon no catálogo público (só faz sentido para addons HTTP
  públicos).
- Hospedagem real exige **HTTPS + CORS**. Opção gratuita recomendada: **Beamup**.
- **Para o StreamHub:** este SDK **não** é usado na implementação nativa em Swift. Esta página serve
  (1) como referência conceitual dos contratos e (2) caso você queira **prototipar** um addon em Node
  e depois consumi-lo via HTTP, ou portar a lógica para Swift.

---

## 1. Addon mínimo executável (`index.js`)

```javascript
const { addonBuilder, serveHTTP, publishToCentral } = require('stremio-addon-sdk')

const manifest = {
  id: 'org.example.fulladdon',
  version: '1.0.0',
  name: 'Full Example Addon',
  description: 'Demonstra todos os handlers',
  resources: ['catalog', 'meta', 'stream', 'subtitles'],
  types: ['movie', 'series'],
  idPrefixes: ['tt'],
  catalogs: [
    { type: 'movie', id: 'example-top', name: 'Example Top',
      extra: [{ name: 'search', isRequired: false }, { name: 'skip', isRequired: false }] }
  ],
  behaviorHints: { configurable: false, configurationRequired: false }
}

const builder = new addonBuilder(manifest)

// catalog -> { metas: [MetaPreview] }
builder.defineCatalogHandler(({ type, id, extra }) => {
  const meta = { id: 'tt1254207', type: 'movie', name: 'Big Buck Bunny',
    poster: 'https://image.tmdb.org/t/p/w600_and_h900_bestv2/uVEFQvFMMsg4e6yb03xOfVsDz4o.jpg' }
  if (type === 'movie' && id === 'example-top') {
    if (extra && extra.search)
      return Promise.resolve({ metas: extra.search === 'big buck bunny' ? [meta] : [] })
    return Promise.resolve({ metas: [meta] })
  }
  return Promise.resolve({ metas: [] })
})

// meta -> { meta: {} }
builder.defineMetaHandler(({ type, id }) => {
  if (type === 'movie' && id === 'tt1254207')
    return Promise.resolve({ meta: { id, type, name: 'Big Buck Bunny', releaseInfo: '2008',
      poster: 'https://image.tmdb.org/t/p/w600_and_h900_bestv2/uVEFQvFMMsg4e6yb03xOfVsDz4o.jpg' } })
  return Promise.resolve({ meta: {} })
})

// stream -> { streams: [] } (ordenar do maior p/ menor qualidade)
builder.defineStreamHandler(({ type, id }) => {
  if (type === 'movie' && id === 'tt1254207')
    return Promise.resolve({ streams: [{ name: '1080p',
      url: 'http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4' }] })
  return Promise.resolve({ streams: [] })
})

// subtitles -> { subtitles: [] }
builder.defineSubtitlesHandler(({ id }) => {
  if (id === 'tt1254207')
    return Promise.resolve({ subtitles: [{ id: 'sub1', url: 'https://mkvtoolnix.download/samples/vsshort-en.srt', lang: 'eng' }] })
  return Promise.resolve({ subtitles: [] })
})

const addonInterface = builder.getInterface()
serveHTTP(addonInterface, { port: process.env.PORT || 7000 })

// publishToCentral('https://meu-addon.com/manifest.json')  // só p/ addons públicos
```

Rodar: `npm install stremio-addon-sdk && node index.js`.

## 2. API do SDK (assinaturas)

| Símbolo | Assinatura / efeito |
|---|---|
| `new addonBuilder(manifest)` | Cria o builder. **Lança erro se o manifest é inválido** (roda o linter). |
| `builder.defineCatalogHandler(fn)` | `fn({ type, id, extra, config }) → Promise<{ metas, cacheMaxAge? }>`. |
| `builder.defineMetaHandler(fn)` | `fn({ type, id, config }) → Promise<{ meta }>`. |
| `builder.defineStreamHandler(fn)` | `fn({ type, id, config }) → Promise<{ streams }>` (ordenar high→low). |
| `builder.defineSubtitlesHandler(fn)` | `fn({ type, id, extra, config }) → Promise<{ subtitles }>`. |
| `builder.getInterface()` | Retorna `{ manifest, get({resource,type,id,extra}) → Promise }` imutável. |
| `serveHTTP(iface, { port, cacheMaxAge?, static? })` | Sobe servidor HTTP + landing page em `/`. Aceita args de processo `--launch` (abre Stremio web) e `--install` (desktop). |
| `getRouter(iface)` | Converte para um router Express (para montar no seu próprio servidor). |
| `publishToCentral(url)` | Lista o addon no catálogo Community Addons (precisa estar publicamente hospedado). |

Toda resposta de handler pode incluir `cacheMaxAge` / `staleRevalidate` / `staleError`.

Scaffold rápido: `npm i -g stremio-addon-sdk` → `addon-bootstrap hello-world` → `cd hello-world &&
npm install && npm start -- --launch`.

## 3. Hospedagem

- **Requisito (clientes reais):** HTTPS + CORS. *"addon URLs in Stremio must be loaded with HTTPS
  (except `127.0.0.1`) and must support CORS!"* O SDK trata CORS automaticamente.
- **Dev local:** `serveHTTP(..., { port })` serve em `http://127.0.0.1:<port>` (o desktop aceita
  `127.0.0.1` sem HTTPS). `--launch` abre o Stremio web; `--install` abre o desktop. Torrents não
  funcionam na versão web.
- **Beamup** (host gratuito recomendado pelo SDK, baseado em Dokku): `npm install beamup-cli -g` →
  `beamup config` → `beamup` no diretório do projeto. Precisa de conta GitHub + chave SSH; o projeto
  deve respeitar `PORT`.
- **Outros hosts documentados:** Heroku, Fleek, Glitch, cloudno.de, Evennode; `localtunnel` para dev.
  `now.sh` **não** é mais recomendado.
- **Estático / serverless / qualquer linguagem:** como o protocolo é só `GET` de JSON, um addon pode
  ser totalmente estático (ex.: `Stremio/stremio-static-addon-example` no GitHub Pages) ou escrito em
  qualquer linguagem (PHP/Python/Go/Rust…).
- **Publicação manual (sem SDK):** UI em `https://stremio.github.io/stremio-publish-addon/`. Coleção
  pública: `https://api.strem.io/addonscollection.json`.

## 4. `stremio-addon-linter`

- Valida manifests. API: `linter.lintManifest(manifest) → { valid, errors, warnings }`.
- É dependência do SDK; roda dentro de `new addonBuilder(manifest)` (daí o "lança se inválido").
- Campos obrigatórios que ele exige: `id`, `name`, `description`, `version`, `resources`, `types`,
  `catalogs` (use `[]` se não houver catálogo).

## 5. Relevância para o StreamHub

| Item | StreamHub nativo |
|---|---|
| `serveHTTP` / `getRouter` / landing page | **N/A** (sem servidor). |
| `publishToCentral` / Beamup / hospedagem | **N/A** (nada publicado). |
| Assinaturas dos handlers (`define*Handler`) | **Modelo conceitual** do protocolo `Addon` em Swift (`catalog/meta/stream/subtitles` async). |
| `linter` / campos obrigatórios | **Boa prática:** validar o `AddonManifest` Swift na inicialização. |
| Prototipar um addon em Node antes de portar p/ Swift | **Opção válida** se quiser testar a lógica de fonte de dados rápido. |

A arquitetura Swift equivalente está em [integracao-streamhub.md](./integracao-streamhub.md).
