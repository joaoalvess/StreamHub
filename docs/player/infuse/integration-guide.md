---
titulo: "Guia de integração StreamHub → Infuse (Swift)"
parte_de: "docs/player/infuse"
objetivo: "Passo a passo de como o StreamHub monta a URL infuse:// a partir de um Stream do scraper, detecta o Infuse instalado, abre o player externo e trata os callbacks de posição/erro. Com snippets Swift."
ordem: 2
tipo: guia
relevancia_para_streamhub: alta
atualizado_em: "2026-06-24"
fontes_oficiais:
  - "https://support.firecore.com/hc/en-us/articles/215090997-API-for-Third-Party-Apps-Services"
  - "https://developer.apple.com/documentation/uikit/uiapplication/canopenurl(_:)"
  - "https://developer.apple.com/documentation/uikit/uiapplication/open(_:options:completionhandler:)"
fontes_comunidade:
  - "https://community.firecore.com/t/can-the-argument-in-the-infuse-api-url-be-located-on-a-share/45786"
versao_infuse_referencia: "8.4.7+"
---

# Guia de integração StreamHub → Infuse (Swift)

## TL;DR

Fluxo do StreamHub para "abrir um stream no Infuse":

1. **Mapear** o `Stream` do addon (AIOStreams) → uma URL HTTP(S) reproduzível + metadados (título, posição, legendas).
2. **Filtrar**: só faz sentido se `stream.url` for HTTP/HTTPS. Magnet/`infoHash` e fontes não-HTTP **não** vão pro esquema do Infuse (ver [url-schemes.md](./url-schemes.md) §6).
3. **Montar** `infuse://x-callback-url/play?...` com `URLComponents`/`URLQueryItem` (encoding correto e automático).
4. **Detectar** o Infuse (iOS/iPadOS): `LSApplicationQueriesSchemes` + `UIApplication.canOpenURL`. Em tvOS, ver [platforms.md](./platforms.md) — checagem/abertura têm caveats.
5. **Abrir**: `UIApplication.shared.open(url)`.
6. **Receber callback**: registrar um esquema próprio (ex.: `streamhub://`) e tratar `x-success` (`lastPlayedUrl` + `position`) para persistir resume, e `x-error` para fallback.

> Toda referência de parâmetros está em [url-schemes.md](./url-schemes.md). Este guia foca no "como" em Swift.

---

## 1. Pré-requisitos no projeto (Info.plist)

### 1.1. Declarar o esquema do Infuse para detecção

Para usar `canOpenURL(infuse://...)`, o esquema **`infuse`** precisa estar em `LSApplicationQueriesSchemes`. Sem isso, `canOpenURL` retorna `false` mesmo com o Infuse instalado.

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>infuse</string>
</array>
```

> **[OFICIAL-derivado]** O nome do esquema `infuse` é derivado das URLs `infuse://...` da doc oficial. A Firecore **não** publica uma instrução verbatim "adicione `infuse` ao `LSApplicationQueriesSchemes`", mas o nome do esquema é inequívoco. Fonte do esquema: https://support.firecore.com/hc/en-us/articles/215090997-API-for-Third-Party-Apps-Services
> Comportamento do `canOpenURL` / requisito do `LSApplicationQueriesSchemes`: https://developer.apple.com/documentation/uikit/uiapplication/canopenurl(_:)

### 1.2. Registrar o esquema de callback do StreamHub

Para receber `x-success`/`x-error`, o StreamHub precisa de um **URL scheme próprio** (ex.: `streamhub`). Em `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.streamhub.callback</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>streamhub</string>
        </array>
    </dict>
</array>
```

> ⚠️ **tvOS:** o handling de URLs de entrada (callbacks) em tvOS tem limitações próprias — ver [platforms.md](./platforms.md). Em iOS/iPadOS este é o padrão.

---

## 2. Mapear o `Stream` do addon para entrada do Infuse

O scraper retorna objetos `Stream` (ver `docs/addons/recursos.md`). O que interessa para o Infuse:

| Campo do Stream (Stremio) | Uso no Infuse |
|---|---|
| `stream.url` | vira `url=` — **só se for HTTP/HTTPS**. |
| `stream.infoHash` / `fileIdx` (magnet) | **descartar** para Infuse (não suportado no esquema). |
| `stream.title` / `name` / metadados do `Meta` | derivar um `filename` "estilo nome de arquivo" (ver §2.2). |
| `subtitles[].url` (do recurso `subtitles` ou do próprio stream) | vira `sub=` — uma legenda. |
| posição salva localmente pelo StreamHub | vira `position=` (segundos). |

### 2.1. Modelo mínimo de entrada (exemplo)

```swift
struct InfusePlayItem {
    let videoURL: URL          // HTTP/HTTPS obrigatório
    let filename: String?      // ex.: "Inception-2010.mp4" (dispara lookup TMDB)
    let subtitleURL: URL?      // legenda externa única (sidecar)
    let resumePositionSeconds: Int?   // resume
}
```

### 2.2. Derivando o `filename` (metadados)

O esquema **não tem campo "título" livre**. O Infuse usa o `filename` para um lookup no TMDB se ele seguir os naming styles recomendados (https://support.firecore.com/hc/articles/215090947-Metadata-101). Logo:

- Filme: `"{Título} ({Ano}).{ext}"` → ex.: `"Inception (2010).mkv"`.
- Série: `"{Série} S{NN}E{NN}.{ext}"` → ex.: `"Mad Men S01E01.mkv"`.
- Use a extensão real do arquivo do stream quando souber (mkv/mp4); se não souber, **[a validar]** se a extensão importa para o playback (provavelmente não, mas importa para o match TMDB).

> Se o título correto não for crítico, você pode omitir `filename`. O Infuse ainda toca a `url`; só o metadado/poster ficará genérico. Ver [limitations.md](./limitations.md) sobre por que não há poster/descrição via esquema.

---

## 3. Montar a URL `infuse://...play` em Swift

**Use `URLComponents` + `URLQueryItem`.** Isso resolve o encoding obrigatório (ver [url-schemes.md](./url-schemes.md) §5) automaticamente e suporta `url` repetido (playlist), já que `queryItems` é um array que aceita chaves duplicadas.

```swift
import Foundation

enum InfuseURLBuilder {

    /// Monta infuse://x-callback-url/play?... para 1+ itens.
    /// callbackBase: esquema de retorno do app, ex.: "streamhub://infuse"
    static func playURL(
        items: [InfusePlayItem],
        successCallback: String? = "streamhub://infuse/success",
        errorCallback: String? = "streamhub://infuse/error"
    ) -> URL? {
        guard !items.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = "infuse"
        components.host = "x-callback-url"
        components.path = "/play"

        var queryItems: [URLQueryItem] = []

        // Parâmetros repetíveis são associados POSICIONALMENTE pela ordem de
        // aparição (1º url ↔ 1º position ↔ 1º filename ↔ 1º sub). Por isso
        // emitimos os campos de cada item juntos, na ordem.
        for item in items {
            queryItems.append(URLQueryItem(name: "url", value: item.videoURL.absoluteString))
            if let pos = item.resumePositionSeconds {
                queryItems.append(URLQueryItem(name: "position", value: String(pos)))
            }
            if let name = item.filename {
                queryItems.append(URLQueryItem(name: "filename", value: name))
            }
            if let sub = item.subtitleURL {
                queryItems.append(URLQueryItem(name: "sub", value: sub.absoluteString))
            }
        }

        if let s = successCallback {
            queryItems.append(URLQueryItem(name: "x-success", value: s))
        }
        if let e = errorCallback {
            queryItems.append(URLQueryItem(name: "x-error", value: e))
        }

        components.queryItems = queryItems

        // URLComponents percent-encoda os valores, mas NÃO encoda '+' nem alguns
        // caracteres em querystrings legadas. Forçamos o encode de '+' para evitar
        // que o Infuse o interprete como espaço.
        if let q = components.percentEncodedQuery {
            components.percentEncodedQuery = q.replacingOccurrences(of: "+", with: "%2B")
        }

        return components.url
    }
}
```

### 3.1. Caso simples (um único stream — o típico do StreamHub)

```swift
let item = InfusePlayItem(
    videoURL: URL(string: "https://abc.torbox.app/dl/xyz/Inception.2010.mkv?token=...")!,
    filename: "Inception (2010).mkv",
    subtitleURL: URL(string: "https://opensubtitles.example/inception.pt-BR.srt"),
    resumePositionSeconds: 845
)

if let url = InfuseURLBuilder.playURL(items: [item]) {
    open(url)   // ver §4
}
```

### 3.2. Por que não concatenar strings à mão

URLs de debrid quase sempre têm query própria (`?token=...&exp=...`). Se você fizer `"infuse://...play?url=\(videoURL)"` sem encodar, os `&`/`=`/`?` da URL do vídeo vão **vazar** para a querystring do `infuse://` e o Infuse vai parsear errado. `URLQueryItem` encoda esses caracteres no **valor**, preservando a estrutura. (Regra de encoding oficial: [url-schemes.md](./url-schemes.md) §5.)

---

## 4. Detectar o Infuse e abrir (iOS/iPadOS)

```swift
import UIKit

enum InfuseLauncher {

    static var isInstalled: Bool {
        guard let probe = URL(string: "infuse://") else { return false }
        // Requer 'infuse' em LSApplicationQueriesSchemes; senão retorna false
        // mesmo com o app instalado.
        return UIApplication.shared.canOpenURL(probe)
    }

    /// Abre a URL no Infuse. open(_:) NÃO exige LSApplicationQueriesSchemes,
    /// mas usamos isInstalled para decidir UI/fallback antes.
    static func open(_ url: URL, completion: ((Bool) -> Void)? = nil) {
        UIApplication.shared.open(url, options: [:]) { success in
            completion?(success)
        }
    }
}
```

Notas de comportamento (Apple, verbatim — https://developer.apple.com/documentation/uikit/uiapplication/canopenurl(_:) ):

- `canOpenURL` retorna `false` *"if the device doesn't have an installed app registered to handle the URL's scheme, or if you haven't declared the URL's scheme in your Info.plist file"*.
- Há um **limite de 50 chamadas** a `canOpenURL` (depois disso sempre retorna `false` até reinstalar/atualizar o app). Não chame em loop; cacheie o resultado.
- `open(_:options:completionHandler:)` **não** é restringido pelo `LSApplicationQueriesSchemes`: *"If an app is available to handle the URL, the system will launch it, even if you haven't declared the scheme."* Ou seja, dá para **abrir** sem declarar; só a **detecção** (`canOpenURL`) precisa da declaração.

### 4.1. Padrão de UI recomendado

```swift
func playInInfuse(item: InfusePlayItem) {
    guard let url = InfuseURLBuilder.playURL(items: [item]) else { return }

    guard InfuseLauncher.isInstalled else {
        // Mostrar opção de instalar (App Store) OU usar player nativo do StreamHub.
        // Deep link da App Store do Infuse: https://apps.apple.com/app/infuse/id1136220934
        presentInstallInfusePrompt()
        return
    }

    InfuseLauncher.open(url) { success in
        if !success {
            // Falha ao abrir (raro se isInstalled == true). Fallback p/ player nativo.
            self.fallbackToNativePlayer(item)
        }
    }
}
```

---

## 5. Receber os callbacks (x-success / x-error)

O Infuse abrirá `streamhub://infuse/success?lastPlayedUrl=...&position=...` (ou `.../error?...`). O StreamHub trata isso no entry point de URL.

### 5.1. SwiftUI (`onOpenURL`)

```swift
import SwiftUI

@main
struct StreamHubApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    InfuseCallbackHandler.handle(url)
                }
        }
    }
}
```

### 5.2. Parser do callback

```swift
import Foundation

enum InfuseCallbackHandler {

    static func handle(_ url: URL) {
        guard url.scheme == "streamhub",
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return }

        let items = comps.queryItems ?? []
        func value(_ name: String) -> String? {
            items.first(where: { $0.name == name })?.value
        }
        func values(_ name: String) -> [String] {
            items.filter { $0.name == name }.compactMap { $0.value }
        }

        switch comps.path {
        case "/infuse/success":
            // play -> lastPlayedUrl + position (segundos). save -> sem parâmetros.
            let lastURL = value("lastPlayedUrl")
            let position = value("position").flatMap(Int.init)   // segundos
            persistResume(forStreamURL: lastURL, positionSeconds: position)

        case "/infuse/error":
            let code = value("errorCode")
            let message = value("errorMessage")   // já vem percent-encoded; URLComponents decoda
            let failed = values("failedUrl")
            handleInfuseError(code: code, message: message, failedURLs: failed)

        default:
            break
        }
    }

    static func persistResume(forStreamURL: String?, positionSeconds: Int?) { /* ... */ }
    static func handleInfuseError(code: String?, message: String?, failedURLs: [String]) { /* ... */ }
}
```

Notas:

- O `position` do `x-success` é o gancho de **resume** (segundos). Persista-o associado ao item/stream para reabrir depois com `position=` (§3).
- O `x-success` é **uma única chamada** ao fim da playlist / quando o player fecha (não por vídeo) — ver notas verbatim em [url-schemes.md](./url-schemes.md) §2.3.
- Como o casamento é por `lastPlayedUrl`, e a `url` que mandamos pode ser de debrid single-use, **guarde um mapa** `videoURL → itemId` antes de abrir o Infuse, para reassociar o callback ao item certo.
- **Não há tabela oficial de `errorCode`** ([url-schemes.md](./url-schemes.md) §4.2) — trate como opaco.

---

## 6. Checklist de implementação

- [ ] `LSApplicationQueriesSchemes` contém `infuse` (detecção).
- [ ] `CFBundleURLTypes` registra o esquema de callback (ex.: `streamhub`).
- [ ] Builder usa `URLComponents`/`URLQueryItem` (encoding correto) — nunca concatenação de string.
- [ ] Só oferecer "Abrir no Infuse" quando `stream.url` for HTTP/HTTPS (filtrar magnet/infoHash).
- [ ] `canOpenURL` cacheado (limite de 50 chamadas).
- [ ] Fallback para player nativo / prompt de instalação quando `isInstalled == false`.
- [ ] Handler de `onOpenURL` persiste `position` (resume) e trata `x-error`.
- [ ] Mapa `videoURL → itemId` para reassociar o callback.
- [ ] tvOS: tratar caveats de detecção/abertura/callback descritos em [platforms.md](./platforms.md).
- [ ] Validar em runtime: legendas (`sub`), resume (`position`), e se HLS (`.m3u8`) funciona via esquema (**[a validar]**).

---

## Fontes

- **[OFICIAL]** API Infuse (parâmetros, exemplos) — https://support.firecore.com/hc/en-us/articles/215090997-API-for-Third-Party-Apps-Services
- **[OFICIAL Apple]** `canOpenURL(_:)` — https://developer.apple.com/documentation/uikit/uiapplication/canopenurl(_:)
- **[OFICIAL Apple]** `open(_:options:completionHandler:)` — https://developer.apple.com/documentation/uikit/uiapplication/open(_:options:completionhandler:)
- **[OFICIAL]** Metadata 101 (naming style p/ `filename`) — https://support.firecore.com/hc/articles/215090947-Metadata-101
- **[COMUNIDADE]** `url` só aceita HTTP (quote staff) — https://community.firecore.com/t/can-the-argument-in-the-infuse-api-url-be-located-on-a-share/45786
