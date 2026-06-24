---
titulo: "Limitações, requisitos de versão e workarounds"
parte_de: "docs/player/infuse"
objetivo: "Limitações conhecidas da integração via infuse://: headers/debrid, ausência de poster/descrição, protocolos não suportados, tvOS, requisitos de versão/Pro, e alternativas (STRM/STRMLNK)."
ordem: 4
tipo: referencia
relevancia_para_streamhub: alta
atualizado_em: "2026-06-24"
fontes_oficiais:
  - "https://support.firecore.com/hc/en-us/articles/215090997-API-for-Third-Party-Apps-Services"
  - "https://support.firecore.com/hc/en-us/articles/30038115451799-STRM-Files"
  - "https://support.firecore.com/hc/en-us/articles/31568155261207-STRMLNK-Files"
  - "https://support.firecore.com/hc/en-us/articles/21072505575319-Connection-Info-for-Emby-Jellyfin-and-Plex"
fontes_comunidade:
  - "https://community.firecore.com/t/can-the-argument-in-the-infuse-api-url-be-located-on-a-share/45786"
  - "https://community.firecore.com/t/support-for-custom-headers-to-connect-to-media-server/58481"
  - "https://community.firecore.com/t/infuse-real-debrid-not-connecting/46513"
versao_infuse_referencia: "8.4.7+"
---

# Limitações, requisitos e workarounds

## TL;DR (os riscos que importam)

1. **Sem headers HTTP no esquema.** Não dá para passar `Authorization`, `User-Agent`, `Cookie` ou `Referer` via `infuse://...play?url=...`. **Mitigação:** links de debrid (TorBox/RealDebrid) normalmente são URLs HTTPS pré-autenticadas (token na própria URL) e **não precisam de headers** — então, na prática, o caso comum do StreamHub funciona. URLs que exijam header custom (proxy reverso, etc.) **vão falhar**.
2. **Sem poster/descrição/título-livre.** O esquema só tem `filename` (que dispara lookup TMDB por nome de arquivo). Não há campo para poster, sinopse, etc.
3. **Só HTTP/HTTPS no `url`.** Magnet/torrent, SMB, NFS, UPnP, FTP **não** são aceitos no parâmetro `url` (confirmação verbatim de staff). HLS `.m3u8` **não confirmado** via esquema.
4. **tvOS:** o esquema é oficialmente suportado (8.4.7+), mas detecção/abertura/callback **entre apps** no tvOS exigem validação em device; features chegam ao tvOS depois do iOS. Ver [platforms.md](./platforms.md).
5. **ID é TMDB nos deep links**, enquanto os addons do StreamHub usam IMDb (`tt...`). Conversão necessária se um dia usarmos deep links TMDB (não no fluxo `/play`).
6. **Versão:** experiência completa exige **Infuse 8.4.7+** (resume bidirecional via callback só desde 8.4.6; API tvOS amadureceu no 8.x).

---

## 1. Headers HTTP / autenticação (o maior risco para debrid)

### 1.1. O fato

O esquema **não tem nenhum parâmetro de header**. Os únicos parâmetros do `/play` são `url`, `position`, `filename`, `sub`, `x-success`, `x-error` (ver [url-schemes.md](./url-schemes.md) §2.2). Não há `header`, `Authorization`, `User-Agent`, `Referer`, `Cookie`.

Fonte (conjunto de parâmetros): https://support.firecore.com/hc/en-us/articles/215090997-API-for-Third-Party-Apps-Services

### 1.2. Por que normalmente NÃO é um problema para debrid

Links "unrestricted" de serviços de debrid (RealDebrid, TorBox, Premiumize, AllDebrid) são **URLs HTTPS pré-autenticadas e single-use**: a autenticação está embutida na própria URL (token/assinatura na query), não em headers. O servidor de debrid serve o arquivo a qualquer cliente que apresente aquela URL. Logo, **passar só a `url` ao Infuse é suficiente** no caso comum.

- **[COMUNIDADE / 3rd-party — consenso]** "unrestricted/direct links" de debrid não exigem headers; a auth vai na URL. (RealDebrid API e guias de debrid.) **NÃO CONFIRMADO por uma frase verbatim da Firecore**, mas consistente com o fato de o esquema não ter header e mesmo assim links de debrid tocarem.
- **[COMUNIDADE]** Integração RealDebrid + Infuse na prática é feita via **WebDAV** (`dav.real-debrid.com`, HTTPS, usuário + senha de WebDAV) ou links diretos — usando **basic auth (credenciais), não headers custom**. Threads:
  - https://community.firecore.com/t/infuse-real-debrid-not-connecting/46513 (usuário resolveu usando a **senha de WebDAV**, não a senha da conta; staff james deu suporte de config em 2024-01-03)
  - https://community.firecore.com/t/how-to-use-real-debrid-with-infuse/50664

### 1.3. Quando É um problema

- Fontes que exigem **header custom** (ex.: proxy reverso de Jellyfin com `Authorization` próprio; CDNs que checam `Referer`/`User-Agent`). Essas URLs **falharão** no Infuse via esquema — ele só fará um GET "limpo".
- O Infuse **não expõe UI para headers custom definidos pelo usuário** (apenas envia headers fixos próprios para roteamento Emby/Jellyfin/Plex):
  - **[OFICIAL]** Headers que o Infuse **envia** (fixos, ex.: `User-Agent: Infuse-Direct/7.7`, `X-Emby-Authorization`, `X-Plex-Token`): https://support.firecore.com/hc/en-us/articles/21072505575319-Connection-Info-for-Emby-Jellyfin-and-Plex — não há UI para o usuário adicionar headers arbitrários.
  - **[COMUNIDADE]** Pedido de feature "custom headers" (Thermometer, 2025-12-24) **sem resposta/confirmação de staff** → **NÃO CONFIRMADO / não suportado** atualmente: https://community.firecore.com/t/support-for-custom-headers-to-connect-to-media-server/58481

### 1.4. Mitigação para o StreamHub

- **Preferir streams de debrid já "cacheados"** (URL HTTPS direta) — que é o caso típico do AIOStreams quando há debrid. Esses tocam no Infuse sem headers.
- Se um stream **exigir headers**, **não** oferecer "Abrir no Infuse" para ele (ou marcar como incompatível) e usar o **player nativo** do StreamHub (que pode setar headers).
- **[a validar]** se o StreamHub mantiver um proxy local que reescreve a request adicionando headers e expõe uma URL HTTP local sem auth — o Infuse poderia consumir essa URL local. (Padrão usado por alguns clientes Stremio/Kodi.) Não testado aqui.

---

## 2. Metadados: sem poster, descrição ou título livre

- O esquema `/play` **não** aceita poster, backdrop, sinopse, elenco, ano (como campos próprios). O único "metadado" é o **`filename`**, que o Infuse usa para um **lookup TMDB** se seguir os naming styles (https://support.firecore.com/hc/articles/215090947-Metadata-101).
- Consequência: o título/poster exibidos no Infuse dependem do **match TMDB pelo nome de arquivo**. Se o `filename` for ambíguo ou ausente, o item aparece genérico.
- **Não há** como forçar um poster/título específicos do StreamHub dentro do player do Infuse via esquema. **[OFICIAL — por ausência]** (nenhum parâmetro desse tipo na doc).

---

## 3. Protocolos e tipos de stream não suportados (no esquema)

| Tipo de stream do scraper | Via esquema `infuse://...play`? | Observação |
|---|---|---|
| HTTP/HTTPS → mp4/mkv (debrid cacheado) | **Sim** | Caso principal. |
| HLS `.m3u8` (HTTPS) | **[a validar]** | "any http link" deveria cobrir, mas **sem confirmação oficial**. Testar. |
| magnet / torrent (`infoHash`) | **Não** | Não é HTTP. Resolver via debrid antes, ou usar outro caminho. |
| FTP/FTPS/SFTP | **Não** (no `url=`) | Suportado pelo app como fonte de biblioteca, não no esquema. |
| SMB/NFS/UPnP/DLNA/WebDAV | **Não** (no `url=`) | Idem. Confirmado por staff. |

> **[COMUNIDADE — staff Firecore, verbatim]** *"It can be any http link as long as it is accessible from your current location. SMB, NFS, UPnP, etc… cannot be used here."* — https://community.firecore.com/t/can-the-argument-in-the-infuse-api-url-be-located-on-a-share/45786

Consequência p/ StreamHub: **filtrar** a lista de streams e só oferecer "Abrir no Infuse" para `stream.url` HTTP/HTTPS. Streams magnet/`infoHash` ficam fora (ou exigem resolução via debrid antes).

---

## 4. Legendas (`sub`) — limitações

- O esquema aceita `sub` (URL de legenda externa, sidecar), associada por posição a cada `url`. Ver [url-schemes.md](./url-schemes.md) §2.2.
- **[a validar]** **formatos** aceitos (SRT/VTT/ASS/SSA) e **quantidade** (o exemplo oficial mostra **uma** `sub` por `url`; não está documentado passar múltiplas faixas por vídeo). Os exemplos oficiais usam `.srt`.
- **[a validar]** se a `sub` precisa ser HTTP/HTTPS (provável, mesma regra do `url`) e se URLs com query/token funcionam (devem, com encoding).
- Legendas **embutidas** no container (mkv) são tratadas pelo próprio Infuse no playback — independem do esquema.

---

## 5. Resume / posição — limitações

- **Enviar** posição inicial: `position=` (segundos) no `/play` — suportado.
- **Receber** posição de volta: `x-success` → `position` (segundos) — suportado, **mas só a partir do Infuse 8.4.6** ("Send and receive playback positions via x-callback-url", release notes oficiais — https://firecore.com/releases). Em versões anteriores o resume bidirecional pode não existir.
- Granularidade: **segundos inteiros** (a doc diz "expressed as an integer number of seconds"). Sem milissegundos.
- O `x-success` é **uma chamada única** ao fim/fechamento (não por vídeo numa playlist) — o `position` retornado é o do **`lastPlayedUrl`**. Para múltiplos vídeos, você só recebe a posição do último.

---

## 6. Requisitos de versão e Infuse Pro

### 6.1. Versão mínima

- **Página oficial fixa Infuse 8.4.7+** para o conjunto documentado (cross-platform, incl. Apple TV). https://support.firecore.com/hc/en-us/articles/215090997-API-for-Third-Party-Apps-Services
- Histórico (ver [platforms.md](./platforms.md) §2): API iOS desde **7.6.2**; deep links TMDB desde **8.2** (tvOS desde **8.2.3**); `position` no callback desde **8.4.6**.
- **Recomendação StreamHub:** exigir/assumir **8.4.7+**. Em versões anteriores, degradar (sem resume via callback, sem deep link tvOS).

### 6.2. Infuse Pro — é necessário?

- **NÃO CONFIRMADO** que o esquema / x-callback-url exija **Infuse Pro**. A página oficial da API **não menciona** requisito de Pro. https://support.firecore.com/hc/en-us/articles/215090997-API-for-Third-Party-Apps-Services
- **[OFICIAL-implied]** Infuse é grátis para baixar; reprodução básica e **Direct URL** estão no tier grátis; **Pro** adiciona principalmente sync iCloud nativo, alguns codecs/áudio raros e acesso a futuras versões maiores. Como o esquema apenas entrega uma URL para o Infuse tocar (capacidade de direct-URL, grátis), é **muito provável** que funcione no Infuse grátis — mas **não há frase oficial** afirmando isso. **Validar** com uma instalação grátis.

---

## 7. Outras limitações / incertezas

| Item | Estado |
|---|---|
| Tabela de `errorCode` do `x-error` | **NÃO CONFIRMADO** — doc só exemplifica `errorCode=100`. Tratar como opaco. |
| `x-source` / `x-cancel` (spec x-callback-url) | **NÃO CONFIRMADO** que o Infuse leia/use. Doc só cita `x-success`/`x-error`. |
| Pareamento posicional de `url`/`position`/`filename`/`sub` | **INFERIDO** do exemplo oficial; algoritmo não descrito explicitamente. |
| Limite de tamanho da URL `infuse://` (muitos itens / URLs longas de debrid) | **[a validar]** — URLs de debrid são longas; com playlist grande pode haver limite prático do sistema. |
| Recebimento de callback em **tvOS** no app de origem | **[a validar em device]** — ver [platforms.md](./platforms.md) §3. |
| HLS `.m3u8` via esquema | **[a validar]** — ver §3. |
| Formatos/múltiplas faixas de `sub` | **[a validar]** — ver §4. |
| Funciona no Infuse **grátis** (sem Pro) | **[a validar]** — ver §6.2. |

---

## 8. Workarounds e alternativas ao deep link

### 8.1. Arquivos `.STRM` (alternativa file-based, boa p/ tvOS)

- **[OFICIAL]** Um `.strm` é *"a versatile format which can be used to build a library of lightweight text files, each containing an HTTP link to a video file stored elsewhere"* — ou seja, **um arquivo de texto cujo conteúdo é UMA URL HTTP(S) direta**. O Infuse o adiciona à **biblioteca** e toca o vídeo **diretamente**.
- Metadados: **não embutidos** no arquivo; vêm de **TMDB pelo NOME do arquivo** (seguir naming styles). Fonte: https://support.firecore.com/hc/en-us/articles/30038115451799-STRM-Files
- Adicionado no **Infuse 8.1** (2025-02-18).
- **Por que importa p/ tvOS:** não depende de cross-app launch (`canOpenURL`/`open`). Se o esquema se mostrar instável no tvOS, gerar `.strm` num local que o Infuse indexa é uma rota alternativa. **Limitação:** é file-based (precisa de um storage que o Infuse leia — cloud/share/iCloud), não um "abrir agora" instantâneo, e o casamento de metadados é por nome de arquivo.

### 8.2. Arquivos `.STRMLNK`

- **[OFICIAL]** `.strmlnk` = arquivo de texto cujo conteúdo é **uma URL para um título em serviço externo** (Netflix, Apple TV+, YouTube...). Aparece com botão **"Open"** que faz handoff para o app do serviço (ao contrário do `.strm`, que o Infuse toca direto). Fonte: https://support.firecore.com/hc/en-us/articles/31568155261207-STRMLNK-Files
- Adicionado no **Infuse 8.1.4** (2025-04-22).
- **Pouco relevante p/ StreamHub:** nosso conteúdo é URL de vídeo (debrid), não link de serviço de streaming. STRMLNK serve para "atalho para abrir no app X", não para tocar um mp4. Além disso, no tvOS o "Open" pode só abrir a home do app de destino (ver [platforms.md](./platforms.md) §3.4).
- **NÃO CONFIRMADO** que `.strmlnk`/`.strm` embutam título/poster/temporada/episódio/legenda no arquivo — o formato oficial é **só a URL**; metadados via TMDB pelo nome do arquivo.

### 8.3. Player nativo do StreamHub (fallback principal)

- Sempre ter o player nativo como fallback: cobre magnet/HLS/headers custom que o esquema do Infuse **não** cobre, e funciona quando o Infuse não está instalado ou quando o cross-app launch falha no tvOS.

### 8.4. Document interaction / "Open in…" (iOS) — pouco útil aqui

- No iOS, o padrão clássico "Open in…" (`UIDocumentInteractionController`) serve para **arquivos locais**, não para entregar uma **URL remota** a outro app. Para o caso do StreamHub (URL remota), o **esquema `infuse://`** é o caminho certo, não document interaction. **[a validar]** apenas se algum dia precisarmos compartilhar um arquivo local.

---

## Fontes

- **[OFICIAL]** API Infuse (parâmetros, ausência de header/poster, versão) — https://support.firecore.com/hc/en-us/articles/215090997-API-for-Third-Party-Apps-Services
- **[OFICIAL]** STRM — https://support.firecore.com/hc/en-us/articles/30038115451799-STRM-Files
- **[OFICIAL]** STRMLNK — https://support.firecore.com/hc/en-us/articles/31568155261207-STRMLNK-Files
- **[OFICIAL]** Headers fixos enviados pelo Infuse (Emby/Jellyfin/Plex) — https://support.firecore.com/hc/en-us/articles/21072505575319-Connection-Info-for-Emby-Jellyfin-and-Plex
- **[OFICIAL]** Release notes (versões: STRM 8.1, deep link 8.2, position 8.4.6) — https://firecore.com/releases
- **[COMUNIDADE]** `url` só HTTP (quote staff) — https://community.firecore.com/t/can-the-argument-in-the-infuse-api-url-be-located-on-a-share/45786
- **[COMUNIDADE]** Pedido de custom headers (sem confirmação) — https://community.firecore.com/t/support-for-custom-headers-to-connect-to-media-server/58481
- **[COMUNIDADE]** RealDebrid + Infuse (WebDAV / credenciais) — https://community.firecore.com/t/infuse-real-debrid-not-connecting/46513 e https://community.firecore.com/t/how-to-use-real-debrid-with-infuse/50664
