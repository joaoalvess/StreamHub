---
titulo: "Manifest do addon Stremio"
parte_de: "docs/addons"
objetivo: "Anatomia completa do manifest.json — o descritor de capacidades que o cliente lê para decidir o que cada addon sabe fazer."
ordem: 2
tipo: referencia
relevancia_para_streamhub: alta
atualizado_em: "2026-06-24"
fontes:
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/content.types.md"
  - "https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/advanced.md"
pre_requisitos:
  - "protocolo.md"
---

# Manifest do addon Stremio

## TL;DR

- O `manifest.json` é o **descritor de capacidades** do addon. O cliente o lê para saber: qual o id,
  quais `types` e `resources` o addon atende, quais `catalogs` oferece e para quais `idPrefixes` deve
  ser consultado.
- Campos **obrigatórios**: `id`, `name`, `description`, `version`, `resources`, `types`, `catalogs`
  (use `[]` se não houver catálogo).
- `resources` pode ser uma **string** (`"meta"`) ou um **objeto** (`{ name, types, idPrefixes? }`)
  para sobrescrever `types`/`idPrefixes` por recurso.
- `idPrefixes` define para quais ids o addon é chamado (ex.: `["tt"]`). Ausente ⇒ todos os ids.
  **Não** afeta `catalog`.
- **No StreamHub:** o manifest vira uma **struct Swift** que alimenta a lógica de agregação. Os
  campos que importam: `id`, `types`, `resources`, `idPrefixes`, `catalogs` (+ `extra`). Ver
  [integracao-streamhub.md](./integracao-streamhub.md).

> Fonte primária: `docs/api/responses/manifest.md`.

## 1. Campos de topo

| Campo | Tipo | Obrigatório | Significado |
|---|---|---|---|
| `id` | string | **sim** | Identificador único, separado por pontos. Ex.: `"com.stremio.filmon"`. |
| `name` | string | **sim** | Nome legível. |
| `description` | string | **sim** | Descrição legível. |
| `version` | string | **sim** | Versão [semver](https://semver.org/). Ex.: `"1.0.0"`. |
| `resources` | array de strings **ou** objetos | **sim** | Recursos suportados. Ex.: `["catalog","meta","stream","subtitles"]`. Ver §2. |
| `types` | array de strings | **sim** | Tipos suportados (ver §4). Ex.: `["movie","series"]`. |
| `catalogs` | array de Catalog | **sim** | Catálogos oferecidos. **Use `[]` se o addon não provê `catalog`.** Ver §3. |
| `idPrefixes` | array de strings | não | Só chama o addon para ids que começam com esses prefixos. Ex.: `["yt_id:","tt"]`. Não afeta `catalog`. |
| `addonCatalogs` | array de Addon-Catalog | não | Catálogos de **outros addons** (descoberta). Ver `addon_catalog` em [recursos.md](./recursos.md). |
| `background` | string (URL) | não | Imagem de fundo do addon (png/jpg, ≥1024×786). |
| `logo` | string (URL) | não | Ícone do addon (png monocromático, 256×256). |
| `contactEmail` | string | não | Email de contato (botão "Report" no app). |
| `behaviorHints` | objeto | não | Dicas de comportamento. Ver §5. |
| `config` | array de Config | não | Esquema de configuração do usuário. Ver §6. |

## 2. `resources[]` — as duas formas

**Forma A — string.** Ex.: `"meta"`. Os `types` e `idPrefixes` do topo do manifest valem para o
recurso.

**Forma B — objeto** `{ name, types, idPrefixes? }`. Sobrescreve `types`/`idPrefixes` para aquele
recurso específico:

```json
{ "name": "stream", "types": ["movie"], "idPrefixes": ["tt"] }
```

- `name` — nome do recurso (`catalog`/`meta`/`stream`/`subtitles`/`addon_catalog`).
- `types` — tipos que **este recurso** atende (sobrescreve o topo).
- `idPrefixes` — opcional; sobrescreve o topo. Omitido ⇒ casa com todos os ids dos `types` dados.

Citação: *"A resource may either be a string (e.g. `"meta"`) or an object of the format
`{ name, types, idPrefixes? }`."* E: o filtro de `idPrefixes` **não importa para `catalog`**.

## 3. `catalogs[]` — objeto Catalog

| Campo | Tipo | Obrigatório | Significado |
|---|---|---|---|
| `type` | string | **sim** | Tipo de conteúdo do catálogo. |
| `id` | string | **sim** | Id único do catálogo (único por addon; um addon pode ter vários). |
| `name` | string | **sim** | Nome legível (vira o título da prateleira/row). |
| `extra` | array de Extra | não | Propriedades extras suportadas (busca/gênero/paginação). Ver abaixo. |

### Objeto Extra (dentro de `catalogs[].extra[]`)

| Campo | Tipo | Obrigatório | Significado |
|---|---|---|---|
| `name` | string | **sim** | Nome da propriedade: `search`, `genre`, `skip`. |
| `isRequired` | boolean | não | `true` se a propriedade sempre precisa ser passada. |
| `options` | array de strings | não | Valores possíveis (ex.: gêneros: `["Action","Comedy","Drama"]`). |
| `optionsLimit` | number | não | Limite de valores que o usuário pode escolher de `options`. Padrão **1**. |

Padrões comuns:

| Intenção | `extra` |
|---|---|
| Catálogo com busca | `[{ "name": "search", "isRequired": false }]` |
| Catálogo **só de busca** (não aparece no Board/Discover) | `[{ "name": "search", "isRequired": true }]` |
| Filtro por gênero | `[{ "name": "genre", "isRequired": false, "options": ["Action","Drama"] }]` |
| Paginação | `[{ "name": "skip", "isRequired": false }]` |

> ⚠️ **Forma legada (deprecada).** Catálogos antigos usavam arrays de string:
> `extraSupported: ["search"]` e `extraRequired: ["search"]` (e um campo `genres: [...]`). Foi
> substituída pelo array de objetos `extra[]` acima (com `options` no lugar de `genres`). Documentado
> aqui só para reconhecer manifests antigos.

## 4. `types[]` — tipos de conteúdo

Fonte: `docs/api/responses/content.types.md`.

| Tipo | Significado |
|---|---|
| `movie` | Filme (vídeo único; `videoId == id`). |
| `series` | Série (tem array `videos` no Meta — episódios). |
| `channel` | Canal (também usa `videos`). |
| `tv` | TV ao vivo — os streams devem ser ao vivo, sem duração. |

## 5. `behaviorHints` (do manifest) — todos opcionais

| Sub-campo | Tipo | Padrão | Significado |
|---|---|---|---|
| `adult` | boolean | `false` | Addon inclui conteúdo adulto (gera aviso). |
| `p2p` | boolean | `false` | Addon usa conteúdo P2P (ex.: BitTorrent) — pode expor o IP do usuário. |
| `configurable` | boolean | `false` | Mostra botão de configuração apontando para `/configure`. |
| `configurationRequired` | boolean | `false` | Esconde "Install"; mostra "Configure" (config obrigatória antes de usar). |

## 6. `config[]` — esquema de configuração do usuário

Para usar: `behaviorHints.configurable = true` + `config[]`. O SDK gera uma página em `/configure`.

| Campo | Tipo | Obrigatório | Significado |
|---|---|---|---|
| `key` | string | **sim** | Chave que identifica o valor escolhido. |
| `type` | string | **sim** | Um de: `text`, `number`, `password`, `checkbox`, `select`. |
| `default` | string | não | Valor padrão. (Para checkbox, `"checked"` liga por padrão.) |
| `title` | string | não | Título do campo. |
| `options` | array | não | Lista de opções (para `type: "select"`). |
| `required` | boolean | não (padrão `false`) | Se o valor é obrigatório (vale para `text`/`number`). |

A configuração do usuário é entregue ao addon **embutida no path da URL**
(`https://dominio.com/{userData}/manifest.json`, `…/{userData}/stream/{type}/{id}.json`); cada
handler recebe `args.config`. Ver [descoberta-e-agregacao.md](./descoberta-e-agregacao.md) §3.

> ⚠️ Inconsistências da doc oficial: o texto cita `type: "boolean"` e `"string"` em alguns pontos,
> mas a lista enumerada de tipos é `text|number|password|checkbox|select`. Trate `"string"` ≡ `text`
> e use `checkbox` para booleanos.

## 7. Exemplo completo de `manifest.json`

```json
{
  "id": "org.stremio.example",
  "version": "1.0.0",
  "name": "Example Addon",
  "description": "Exemplo com catálogos, streams e config",
  "logo": "https://example.com/logo.png",
  "background": "https://example.com/background.jpg",
  "contactEmail": "hello@example.com",
  "types": ["movie", "series"],
  "idPrefixes": ["tt"],
  "resources": [
    "catalog",
    "meta",
    { "name": "stream", "types": ["movie", "series"], "idPrefixes": ["tt"] },
    { "name": "subtitles", "types": ["movie"], "idPrefixes": ["tt"] }
  ],
  "catalogs": [
    {
      "type": "movie",
      "id": "top",
      "name": "Top Movies",
      "extra": [
        { "name": "genre", "options": ["Action", "Comedy", "Drama"], "isRequired": false },
        { "name": "skip", "isRequired": false }
      ]
    },
    {
      "type": "movie",
      "id": "search",
      "name": "Movie Search",
      "extra": [{ "name": "search", "isRequired": true }]
    }
  ],
  "behaviorHints": { "adult": false, "p2p": false, "configurable": true, "configurationRequired": false },
  "config": [
    { "key": "apiKey", "type": "text", "title": "API Key", "required": true },
    { "key": "quality", "type": "select", "title": "Max Quality", "options": ["720p", "1080p", "4K"], "default": "1080p" }
  ]
}
```

Manifests reais para comparação: `https://v3-cinemeta.strem.io/manifest.json`.

## 8. Como o manifest é usado na agregação (resumo)

Para `meta`/`stream`/`subtitles`, o cliente só chama um addon quando: o `type` da requisição está em
`manifest.types` (ou nos `types` do objeto de recurso) **E** — se `idPrefixes` existe — o `id` começa
com um dos prefixos. Catálogos são casados por compatibilidade de `extra` (Board = catálogos sem
`extra` obrigatório; Busca = catálogos que declaram `search`). Detalhes e a implementação Swift
equivalente: [descoberta-e-agregacao.md](./descoberta-e-agregacao.md) e
[integracao-streamhub.md](./integracao-streamhub.md).
