---
titulo: "Descoberta, instalação e agregação multi-addon"
parte_de: "docs/addons"
objetivo: "Como o Stremio padrão descobre/instala addons (contexto) e — o que importa de fato — como o cliente agrega respostas de vários addons (filtragem, ordem, fall-through)."
ordem: 4
tipo: referencia
relevancia_para_streamhub: mista
atualizado_em: "2026-06-24"
fontes:
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/README.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/deep-links.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/advanced.md"
  - "https://github.com/Stremio/stremio-core/blob/development/src/types/addon/request.rs"
  - "https://github.com/Stremio/stremio-core/blob/development/src/types/addon/manifest.rs"
  - "https://github.com/Stremio/stremio-api-client/blob/master/README.md"
  - "https://github.com/Stremio/stremio-official-addons/blob/master/index.json"
pre_requisitos:
  - "manifest.md"
  - "recursos.md"
---

# Descoberta, instalação e agregação multi-addon

## TL;DR

- **Parte A (contexto, não usada no StreamHub):** no Stremio padrão o usuário instala addons por URL
  (`manifest.json`) ou deep link `stremio://`; a lista de addons fica na conta e sincroniza via
  `api.strem.io`. Existem addons oficiais pré-instalados (Cinemeta, OpenSubtitles, Local Files…).
- **Parte B (ALTA relevância):** a **agregação** é a lógica que o StreamHub precisa replicar
  nativamente. Resumo:
  - **catalog:** o cliente pega **todos os catálogos de todos os addons**, na **ordem de instalação**.
  - **meta/stream/subtitles:** o cliente consulta **todo addon cujo manifest declara o recurso** e
    cujo `type`+`idPrefixes` casam com a requisição, **em paralelo**, na ordem de instalação, com
    **fall-through** (se um addon não responde, tenta o próximo).
- `Manifest::is_resource_supported` é o teste de "este addon atende esta requisição?".

---

## PARTE A — Descoberta e instalação (Stremio padrão · contexto)

> Toda esta parte descreve como o **Stremio oficial** funciona. No StreamHub (addons nativos
> embutidos), nada disto é implementado: "instalar" = registrar o addon no app; "coleção" = a lista
> fixa de 3–4 addons. Está aqui para entendimento do modelo e caso um dia se consuma um addon HTTP
> externo.

### A1. Instalação

- **Por URL:** o usuário cola a URL do `manifest.json` no cliente. Requisito: HTTPS (exceto
  `127.0.0.1`).
- **Deep link `stremio://`:** troque `https://` por `stremio://` na URL do manifest. Ex.:
  `https://watchhub-us.strem.io/manifest.json` → `stremio://watchhub-us.strem.io/manifest.json`.
  Abrir o link foca o app com um prompt de instalação.
- **Botão "Install":** o SDK gera uma landing page em `/` com um botão que usa o deep link
  `stremio://…/manifest.json`.
- **Config embutida:** addons configuráveis instalam com a config no path:
  `stremio://meu.addon.com/<userData>/manifest.json` (ver §3).
- ⚠️ **Link web `app.strem.io/...#/addons?addon=<url>`** — formato com confiança **média**; o nome
  exato do query param não foi confirmado em fonte canônica. Alvos web documentados:
  `app.strem.io/shell-v4.4/` e `staging.strem.io`.

### A2. Coleção de addons e API central

- Os addons instalados formam uma **AddonCollection** persistida localmente e **sincronizada na
  conta do usuário** via API central em `https://api.strem.io`.
- Métodos (do `stremio-api-client` / `stremio-core`, **não** da doc voltada a autores de addon):

| Método | Direção | Transporte | Body |
|---|---|---|---|
| `addonCollectionGet` | puxa a coleção remota | `POST https://api.strem.io/addonCollectionGet` | `{ authKey, update: true, addFromURL: [...] }` |
| `addonCollectionSet` | empurra a coleção local | `POST https://api.strem.io/addonCollectionSet` | `{ authKey, addons: [Descriptor, …] }` |

> ⚠️ Estes métodos vêm do código do engine (`stremio-core/src/types/api/request.rs`,
> `stremio-api-client/apiStore.js`), não da documentação oficial de autoria de addon. Confiança alta
> sobre existência/método/endpoint; o schema completo de resposta não está num doc-spec.

### A3. Addons oficiais pré-instalados

Fonte: `stremio-official-addons/index.json`. Cada um tem `transportUrl` e `flags` (`official`,
`protected` = não removível).

| Nome | id | transportUrl | flags |
|---|---|---|---|
| **Cinemeta** (metadados) | `com.linvo.cinemeta` | `https://v3-cinemeta.strem.io/manifest.json` | official, **protected** |
| YouTube | `com.linvo.stremiochannels` | `https://v3-channels.strem.io/manifest.json` | official |
| WatchHub | `org.stremio.watchhub` | `https://watchhub.strem.io/manifest.json` | official |
| Public Domain Movies | `org.stremio.pubdomainmovies` | `https://caching.stremio.net/publicdomainmovies.now.sh/manifest.json` | official |
| OpenSubtitles v3 | `org.stremio.opensubtitlesv3` | `https://opensubtitles-v3.strem.io/manifest.json` | official |
| **Local Files** (engine torrent/local) | `org.stremio.local` | `http://127.0.0.1:11470/local-addon/manifest.json` | official, **protected** |

`Cinemeta` é o id `tt` resolver universal de metadados (`CINEMETA_URL` no `stremio-core`).

---

## PARTE B — Agregação multi-addon (ALTA relevância)

Esta é a lógica de negócio que o StreamHub **precisa** reproduzir, mesmo com addons nativos. Fontes:
`docs/api/README.md` (autor-facing) + `stremio-core` (`is_resource_supported`, `AggrRequest::plan`).

### B1. O teste de capacidade: `is_resource_supported`

Para uma requisição de recurso (caminho `{ resource, type, id }`), um addon "suporta" se:

- **catalog / addon_catalog:** casa por `type` **+ id do catálogo** **+** `is_extra_supported(extra)`
  (os `extra` pedidos são compatíveis com o que o catálogo declara).
- **meta / stream / subtitles:**
  1. Resolve os `types`/`idPrefixes` do recurso (forma objeto sobrescreve; forma string cai para os
     do topo do manifest).
  2. `type_supported` = o `type` da requisição está nos `types`.
  3. `id_supported` = `idPrefixes` ausente/vazio ⇒ **todos os ids**; senão, o `id` começa com **algum**
     prefixo (`starts_with`).
  4. Suporta se `type_supported && id_supported`.

Citação (`docs/api/README.md`): *"For `/meta/movie/tt1254207`, we'd try to load meta from all addons
that have `"movie"` in `manifest.types`… If `manifest.idPrefixes` is defined, `["tt"]` will match
this request, but something different (e.g. `["yt_id:"]`) won't."*

### B2. O plano de agregação: `AggrRequest::plan(addons)`

| Tipo de requisição | Plano |
|---|---|
| **AllCatalogs** `{ type?, extra }` (montar o Board/Discover) | `addons.iter().flat_map(catalogs.filter(type casa && is_extra_supported))` — itera os addons **na ordem da coleção** e pega **todo catálogo compatível** de cada um. |
| **AllOfResource** (`meta`/`stream`/`subtitles` para um `id`) | `addons.iter().filter(|a| a.manifest.is_resource_supported(path))` — **todo addon** que suporta, **na ordem da coleção**; cada um gera uma requisição ao seu `transportUrl`. |

Detalhes de execução (`stremio-core`):

- As requisições são **disparadas em paralelo** (concorrentes) e **deduplicadas/cacheadas** por
  requisição idêntica.
- **Ordem = ordem de instalação** dos addons (os catálogos no Board aparecem nessa ordem).
- **Fall-through** (`stremio-addon-guide` step4): *"In case that your add-on is unable to provide data
  for this ID, Stremio will ask the next one that matches the requested ID."*
- Página de catálogo: `CATALOG_PAGE_SIZE = 100` (bate com o passo de `skip` documentado).

Resumindo:

- **catalog** → união de todos os catálogos compatíveis de todos os addons (ordem de instalação).
  Cada catálogo vira uma prateleira.
- **meta** → consulta os addons que suportam aquele `type`+`id`; normalmente usa o primeiro que
  responde (fall-through).
- **stream** → consulta **todos** os addons compatíveis e **concatena** os streams (cada addon já
  ordena os seus do maior p/ menor qualidade); `bingeGroup` controla auto-seleção no próximo
  episódio.
- **subtitles** → consulta todos os addons de legenda compatíveis e junta.

### B3. Pseudocódigo da agregação (independente de linguagem)

```text
function planCatalogs(addons, type?, extra):
    result = []
    for addon in addons (ordem de instalação):
        for catalog in addon.manifest.catalogs:
            if (type == null or catalog.type == type) and isExtraSupported(catalog, extra):
                result.append((addon, catalog))
    return result            # cada par vira uma prateleira

function planResource(addons, resource, type, id):       # meta | stream | subtitles
    return [ addon for addon in addons (ordem de instalação)
             if isResourceSupported(addon.manifest, resource, type, id) ]

function isResourceSupported(manifest, resource, type, id):
    (types, idPrefixes) = resolveResource(manifest, resource)   # objeto sobrescreve; string cai p/ topo
    typeOK = type in types
    idOK   = (idPrefixes is empty) or any(id.startsWith(p) for p in idPrefixes)
    return typeOK and idOK
```

A tradução disto para Swift (`AddonManager`) está em
[integracao-streamhub.md](./integracao-streamhub.md) §4.

---

## O que vale / não vale no modelo nativo (resumo)

| Tema | StreamHub nativo |
|---|---|
| Instalação por URL / `stremio://` / botão Install | **Não.** Addons são registrados em código. |
| `api.strem.io` (coleção sincronizada, `addonCollection*`) | **Não.** Lista local de addons. |
| Addons oficiais (Cinemeta etc.) | **Contexto.** Um addon nativo pode, internamente, *consumir* o endpoint público do Cinemeta como fonte de metadados — mas isso é detalhe de implementação do addon, não "instalação". |
| `is_resource_supported` + `AggrRequest` (filtragem/ordem/fall-through) | **SIM — replicar.** É o coração da integração. |
| `config` por addon | **Opcional.** Se um addon nativo precisa de config (ex.: chave de API), modele um `config` próprio; sem path/URL. |
