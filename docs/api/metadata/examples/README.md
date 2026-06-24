# Amostras de Resposta (JSON real)

Respostas reais da API, capturadas em 2026-06 contra `configId = b11959c7-...` (`pt-BR`). Arrays longos foram **truncados** para legibilidade (marcados com `_comment`).

| Arquivo | Endpoint de origem | Notas |
|---|---|---|
| [manifest-response.json](./manifest-response.json) | `GET /manifest.json` | Top-level + 7 catálogos representativos (dos 99). `options` de `genre` truncadas. |
| [catalog-movie-response.json](./catalog-movie-response.json) | `GET /catalog/movie/tmdb.trending.json` | 2 dos ~20 `metas` (mostra `MetaPreview` enriquecido completo). |
| [meta-movie-response.json](./meta-movie-response.json) | `GET /meta/movie/tt33296751.json` | `MetaDetail` de filme, íntegro. |
| [meta-series-response.json](./meta-series-response.json) | `GET /meta/series/tt0203259.json` | `MetaDetail` de série; `videos` truncado (3 primeiros + último de 599). |
| [meta-anime-response.json](./meta-anime-response.json) | `GET /meta/series/mal:52991.json` | Anime via `mal:`; mostra resolução cross-source e `videos` com `id` IMDB. |

> Schemas correspondentes em [../04-schemas.md](../04-schemas.md). Onde aparecer `"_comment": "...truncado..."`, é marcação desta amostra, **não** um campo da API.
