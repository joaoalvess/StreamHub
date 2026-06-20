# Próximas fases — StreamHub

Referências disponíveis em `references/`. Cada fase = sua própria spec → componentes → build/screenshot.

## Polimento da Fase 1 (depois do mock aprovado)
- "Canais e Apps" na sidebar (Disney+, Globoplay, HBO Max, Paramount+) com ícones de marca + avatar "Joao" no topo (resolver bug de foco do `TabSection`).
- Wordmarks (logo PNG) reais no hero (`references/hero/hero.png`).
- Carrossel automático do hero + dots de página.
- Reforço de foco no Continue Assistindo (revelar play/progresso), parallax fino.

## Fase 2 — Busca (`references/search/`)
- Teclado on-screen (grid de letras), "Buscas Recentes", grid "Explore".
- Resultados agrupados (Filmes / Séries) — layout em `search harry potter.png`.
- Estado de digitação + filtragem do mock.

## Fase 3 — Seleção de filme / Detalhe (`references/select movie/`)
- Card de pré-visualização expandido ao focar: backdrop, logo, sinopse, "Reproduzir", `+`/download, elenco/direção.
- Trailer em autoplay no card + transição p/ fullscreen ("Passe o Dedo para Cima...").
- Estados: loading, transição, "Captura de Tela Salva".

## Fase 4 — Player (`references/player/`)
- Timeline/scrubber, botões Informações / Capítulos / Continue Assistindo.
- Menu de Legendas (Ativadas/Desativadas, Idioma, Estilo).
- Menu de Áudio (Aprimorar Diálogo, Limite de Volume, Faixa de áudio).
- Painel "Informações" com pôster + sinopse + "Do Início".

## Fase 5 — Dados/funcionalidade reais
- Integração TMDB (busca/catálogo) substituindo o mock.
- Playback real com AVKit (`VideoPlayer` / `AVPlayerViewController`).
- Estado de "Continue Assistindo" persistente.
