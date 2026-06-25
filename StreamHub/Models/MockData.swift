import Foundation
import SwiftUI

enum MockData {
    static let heroItems: [MediaItem] = [
        MediaItem(
            title: "Servant",
            kind: .series,
            genres: ["Suspense", "Drama", "Terror"],
            posterURL: nil,
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/7nsRpSCYcDGLcDmFAISHC8zMQ0D.jpg"),
            synopsis: "Um casal da Filadélfia em luto contrata uma jovem babá para cuidar de um boneco terapêutico que substitui o filho que perderam. A chegada da misteriosa Leanne traz forças inexplicáveis para dentro de casa. Criada por M. Night Shyamalan, a série mistura horror psicologico e tensão domestica.",
            year: 2019,
            serviceBadge: "tv",
            tint: Color(hex: 0x4A2E22),
            ageRating: .sixteen
        ),
        MediaItem(
            title: "The Boys",
            kind: .series,
            genres: ["Ação", "Ficção Científica", "Comédia"],
            posterURL: nil,
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/n6vVs6z8obNbExdD3QHTr4Utu1Z.jpg"),
            synopsis: "Em um mundo onde super-heróis abusam de seus poderes em vez de usá-los para o bem, um grupo de vigilantes decide enfrentá-los. Liderados por Billy Butcher, Os Rapazes expõem a corrupção por trás da poderosa corporação Vought. Sátira violenta e ácida sobre fama, poder e politica.",
            year: 2019,
            serviceBadge: "Prime",
            tint: Color(hex: 0x5A1A1A),
            ageRating: .eighteen
        ),
        MediaItem(
            title: "For All Mankind",
            kind: .series,
            genres: ["Drama", "Ficção Científica"],
            posterURL: nil,
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/9OQ5BIITkJwRJo9JA6AlCfJIGBQ.jpg"),
            synopsis: "E se a corrida espacial nunca tivesse terminado? Nesta história alternativa, os soviéticos chegam primeiro à Lua e a NASA é forçada a inovar sem parar. A serie acompanha astronautas e suas familias enquanto a exploração espacial redefine o mundo.",
            year: 2019,
            serviceBadge: "tv",
            tint: Color(hex: 0x1B2A44),
            ageRating: .fourteen
        ),
        MediaItem(
            title: "Monarch: Legado de Monstros",
            kind: .series,
            genres: ["Ação", "Aventura", "Ficção Científica"],
            posterURL: nil,
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/7IY4wELVMvtUc78vPiuL8kQV2iA.jpg"),
            synopsis: "Após o ataque de Godzilla em São Francisco, dois irmãos seguem os passos do pai para descobrir os segredos da organização Monarch. A jornada revela uma rede global de monstros colossais e uma história familiar enterrada. Ambientada no universo MonsterVerse.",
            year: 2023,
            serviceBadge: "tv",
            tint: Color(hex: 0x1E3530),
            ageRating: .twelve
        )
    ]

    static let rows: [MediaRow] = [
        MediaRow(
            title: "Continue Assistindo",
            style: .continueWatching,
            items: [
                MediaItem(
                    title: "The Big Bang Theory",
                    kind: .series,
                    genres: ["Comédia"],
                    posterURL: nil,
                    backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/rwYvhVv0vwbulMwxOfEsuAr1JrT.jpg"),
                    synopsis: "Os físicos Leonard e Sheldon entendem tudo sobre o funcionamento do universo, mas nada sobre as pessoas. Seu mundo nerd vira de cabeça para baixo quando a vizinha Penny, uma aspirante a atriz, se muda para o apartamento em frente.",
                    year: 2007,
                    serviceBadge: "tv",
                    progress: 0.42,
                    episodeLabel: "T1, E8 · 15 min"
                ),
                MediaItem(
                    title: "O Mundo Sombrio de Sabrina",
                    kind: .series,
                    genres: ["Terror", "Drama", "Fantasia"],
                    posterURL: nil,
                    backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/gMMnf8VRg3Z98WaFmOLr9Jk8pIs.jpg"),
                    synopsis: "Dividida entre o mundo dos mortais e o das bruxas, a meio-bruxa Sabrina Spellman enfrenta as forças das trevas enquanto luta para proteger sua família e os amigos que ama.",
                    year: 2018,
                    serviceBadge: "tv",
                    progress: 0.67,
                    episodeLabel: "T2, E4 · 23 min"
                ),
                MediaItem(
                    title: "Pânico",
                    kind: .movie,
                    genres: ["Terror", "Suspense"],
                    posterURL: nil,
                    backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/ifUfE79O1raUwbaQRIB7XnFz5ZC.jpg"),
                    synopsis: "Vinte e cinco anos depois de uma série de assassinatos brutais ter chocado a tranquila cidade de Woodsboro, um novo assassino veste a máscara de Ghostface e começa a perseguir um grupo de adolescentes para ressuscitar segredos do passado mortal da cidade.",
                    year: 2022,
                    serviceBadge: "tv",
                    progress: 0.18,
                    episodeLabel: "17 min"
                ),
                MediaItem(
                    title: "Pesadelo na Cozinha",
                    kind: .series,
                    genres: ["Reality"],
                    posterURL: nil,
                    backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/5xISdWrDjpEhvzibj05a69g5lh.jpg"),
                    synopsis: "O chef Gordon Ramsay percorre os Estados Unidos para ajudar restaurantes em apuros a darem a volta por cima, enfrentando desde cozinhas insalubres até equipes despreparadas em busca de soluções.",
                    year: 2023,
                    serviceBadge: "tv",
                    progress: 0.55,
                    episodeLabel: "T5, E3 · 49 min"
                ),
                MediaItem(
                    title: "Hazbin Hotel",
                    kind: .series,
                    genres: ["Animação", "Comédia", "Musical"],
                    posterURL: nil,
                    backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/5SWWe369D4Fjs2RDVhMagNJLlps.jpg"),
                    synopsis: "Charlie, a princesa do Inferno, embarca na missão impossível de reabilitar os pecadores condenados em seu próprio hotel para esvaziar a superlotação infernal por meio da redenção, em vez do extermínio.",
                    year: 2024,
                    serviceBadge: "tv",
                    progress: 0.31,
                    episodeLabel: "T2, E5 · 27 min"
                )
            ]
        ),
        MediaRow(
            title: "Top 10 séries no Apple TV",
            style: .top10,
            items: [
                MediaItem(
                    title: "Seus Amigos e Vizinhos",
                    kind: .series,
                    genres: ["Drama", "Crime"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/o5Vm3l82wzNSsvyr3lqNAUFJMQb.jpg"),
                    backdropURL: nil,
                    synopsis: "Demitido em desgraca e ainda lidando com o divorcio, um gestor de fundos passa a roubar as casas dos vizinhos do abastado Westmont Village, descobrindo que os segredos por tras das fachadas ricas sao mais perigosos do que imaginava.",
                    year: 2025,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Monarch: Legado de Monstros",
                    kind: .series,
                    genres: ["Ficcao Cientifica", "Acao"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/reJ0kHd3DIp2bHQZAmLiqoTPnfw.jpg"),
                    backdropURL: nil,
                    synopsis: "Apos sobreviver ao ataque de Godzilla a San Francisco, Cate embarca em uma jornada pelo mundo para descobrir a verdade sobre sua familia e a misteriosa organizacao conhecida como Monarch.",
                    year: 2023,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Margo Esta em Apuros",
                    kind: .series,
                    genres: ["Comedia", "Drama"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/1OLkF9vLM2PsIm0duu7seQbnfyU.jpg"),
                    backdropURL: nil,
                    synopsis: "Recem-saida da faculdade e aspirante a escritora, Margo, filha de uma ex-garconete e um ex-lutador profissional, precisa se virar com um bebe recem-nascido, uma pilha crescente de contas e cada vez menos meios de paga-las.",
                    year: 2026,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Mulheres Imperfeitas",
                    kind: .series,
                    genres: ["Drama", "Suspense"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/yAkwOx16FaLFon6XmOhgyzQ7j0c.jpg"),
                    backdropURL: nil,
                    synopsis: "Um crime abala a vida de tres mulheres unidas por uma longa amizade, expondo segredos e tensoes que ameacam destruir tudo o que construiram juntas.",
                    year: 2026,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "For All Mankind",
                    kind: .series,
                    genres: ["Ficcao Cientifica", "Drama"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/7Fhjr8cKiFgSkeH62CS9h7y24YI.jpg"),
                    backdropURL: nil,
                    synopsis: "Em uma historia alternativa em que a corrida espacial nunca terminou, a NASA e o mundo continuam a expandir as fronteiras da exploracao espacial apos a Uniao Sovietica chegar primeiro a Lua.",
                    year: 2019,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Falando a Real",
                    kind: .series,
                    genres: ["Comedia", "Drama"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/oaYi4n3pgBLeQ6FH3SU8G3XcSqq.jpg"),
                    backdropURL: nil,
                    synopsis: "Um terapeuta enlutado decide romper as regras e dizer aos pacientes exatamente o que pensa, provocando mudancas radicais e caoticas na vida deles e na sua propria.",
                    year: 2023,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Ruptura",
                    kind: .series,
                    genres: ["Ficcao Cientifica", "Suspense"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/3DjOAUBR8Hra4R9kK9U8jDaoqyC.jpg"),
                    backdropURL: nil,
                    synopsis: "Mark lidera uma equipe de funcionarios cujas memorias foram cirurgicamente divididas entre o trabalho e a vida pessoal. Quando um colega misterioso aparece fora do escritorio, comeca uma jornada para descobrir a verdade sobre seus empregos.",
                    year: 2022,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Ted Lasso",
                    kind: .series,
                    genres: ["Comedia", "Drama"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/5fhZdwP1DVJ0FyVH6vrFdHwpXIn.jpg"),
                    backdropURL: nil,
                    synopsis: "Um tecnico de futebol americano e contratado para comandar um time de futebol ingles, apesar de nao ter qualquer experiencia, conquistando a todos com seu otimismo incansavel.",
                    year: 2020,
                    serviceBadge: "tv"
                )
            ]
        ),
        MediaRow(
            title: "Top 10 filmes no Apple TV",
            style: .top10,
            items: [
                MediaItem(
                    title: "Oppenheimer",
                    kind: .movie,
                    genres: ["Drama", "História"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/1OsQJEoSXBjduuCvDOlRhoEUaHu.jpg"),
                    backdropURL: nil,
                    synopsis: "A história do físico J. Robert Oppenheimer e seu papel no desenvolvimento da bomba atômica durante a Segunda Guerra Mundial.",
                    year: 2023,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Barbie",
                    kind: .movie,
                    genres: ["Comédia", "Fantasia"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/yRRuLt7sMBEQkHsd1S3KaaofZn7.jpg"),
                    backdropURL: nil,
                    synopsis: "Barbie vive no Mundo de Barbie até começar a ter uma crise existencial e partir para o mundo real em busca de respostas.",
                    year: 2023,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Moana 2",
                    kind: .movie,
                    genres: ["Animação", "Aventura"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/dnqgkKoIGf6hErzRm6VtaK1OJrD.jpg"),
                    backdropURL: nil,
                    synopsis: "Moana embarca em uma nova jornada pelos mares distantes da Oceania após um chamado inesperado de seus ancestrais.",
                    year: 2024,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Venom: A Última Rodada",
                    kind: .movie,
                    genres: ["Ação", "Ficção Científica"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/eZIIPjL7oGqfmF7Gw5ZnbDjH6yu.jpg"),
                    backdropURL: nil,
                    synopsis: "Eddie e Venom estão foragidos e perseguidos por seus dois mundos enquanto o cerco se fecha sobre eles.",
                    year: 2024,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Deadpool & Wolverine",
                    kind: .movie,
                    genres: ["Ação", "Comédia"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/53YWSo75mSaw1vd2YEeX5kwkRos.jpg"),
                    backdropURL: nil,
                    synopsis: "Wade Wilson é recrutado pela TVA e une forças com um relutante Wolverine em uma missão que abala o multiverso.",
                    year: 2024,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Meu Malvado Favorito 4",
                    kind: .movie,
                    genres: ["Animação", "Comédia"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/s8BefU3RIJrfipTpsDtOiatlp8j.jpg"),
                    backdropURL: nil,
                    synopsis: "Gru e sua família enfrentam um novo inimigo enquanto recebem um novo membro: Gru Jr., disposto a atormentar o pai.",
                    year: 2024,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Divertida Mente 2",
                    kind: .movie,
                    genres: ["Animação", "Família"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/lHKNS35r4RTa9GO72vdadMLxoiV.jpg"),
                    backdropURL: nil,
                    synopsis: "Riley entra na adolescência e novas emoções chegam ao posto de comando, lideradas pela ansiosa Ansiedade.",
                    year: 2024,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Transformers: O Início",
                    kind: .movie,
                    genres: ["Animação", "Ficção Científica"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/9yPuNAZQd5m5iKpQV2MDAfcwW9N.jpg"),
                    backdropURL: nil,
                    synopsis: "A origem de Optimus Prime e Megatron, antes inseparáveis, cuja amizade muda para sempre o destino de Cybertron.",
                    year: 2024,
                    serviceBadge: "tv"
                )
            ]
        ),
        MediaRow(
            title: "Em alta",
            style: .standard,
            items: [
                MediaItem(
                    title: "Ruptura",
                    kind: .series,
                    genres: ["Ficção científica", "Mistério", "Drama"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/3DjOAUBR8Hra4R9kK9U8jDaoqyC.jpg"),
                    backdropURL: nil,
                    synopsis: "Mark lidera uma equipe de funcionários cujas memórias foram cirurgicamente divididas entre a vida no trabalho e a vida pessoal. Uma reviravolta enigmática os leva a confrontar a verdadeira natureza de seu emprego.",
                    year: 2022,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Duna: Parte Dois",
                    kind: .movie,
                    genres: ["Ficção científica", "Aventura"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/8LJJjLjAzAwXS40S5mx79PJ2jSs.jpg"),
                    backdropURL: nil,
                    synopsis: "Paul Atreides se une a Chani e aos Fremen enquanto busca vingança contra os conspiradores que destruíram sua família, tentando impedir um futuro terrível que só ele consegue prever.",
                    year: 2024
                ),
                MediaItem(
                    title: "The Last of Us",
                    kind: .series,
                    genres: ["Drama", "Terror", "Ação e aventura"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/el1KQzwdIm17I3A6cYPfsVIWhfX.jpg"),
                    backdropURL: nil,
                    synopsis: "Vinte anos após o colapso da civilização por uma infecção fúngica, Joel é contratado para escoltar a jovem Ellie para fora de uma zona de quarentena, numa travessia brutal pelos Estados Unidos.",
                    year: 2023,
                    serviceBadge: "HBO"
                ),
                MediaItem(
                    title: "Oppenheimer",
                    kind: .movie,
                    genres: ["Drama", "História"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/1OsQJEoSXBjduuCvDOlRhoEUaHu.jpg"),
                    backdropURL: nil,
                    synopsis: "A história do físico J. Robert Oppenheimer e seu papel no desenvolvimento da bomba atômica durante o Projeto Manhattan, e as consequências que assombraram sua vida.",
                    year: 2023
                ),
                MediaItem(
                    title: "Shōgun",
                    kind: .series,
                    genres: ["Drama", "Guerra e política", "Ação e aventura"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/gaOb9hyCDUcbZiTYcHy7mIFmNo.jpg"),
                    backdropURL: nil,
                    synopsis: "No Japão feudal de 1600, o Lorde Toranaga luta por sua sobrevivência enquanto um navio europeu naufragado revela segredos capazes de mudar o equilíbrio de poder e desafiar seus inimigos.",
                    year: 2024
                ),
                MediaItem(
                    title: "Pobres Criaturas",
                    kind: .movie,
                    genres: ["Ficção científica", "Comédia", "Romance"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/iOdcXYSVzBgmBJzNIlIMOZ6fz0F.jpg"),
                    backdropURL: nil,
                    synopsis: "Trazida de volta à vida por um cientista pouco ortodoxo, a jovem Bella Baxter embarca numa jornada exuberante de autodescoberta e liberdade ao redor do mundo.",
                    year: 2023
                ),
                MediaItem(
                    title: "O Urso",
                    kind: .series,
                    genres: ["Comédia", "Drama"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/tAJYUFaWot3jn5vtDUoxNNIw9aF.jpg"),
                    backdropURL: nil,
                    synopsis: "Um jovem chef de alta gastronomia retorna a Chicago para administrar a lanchonete da família após uma tragédia, enfrentando o caos da cozinha, dívidas e relações conturbadas.",
                    year: 2022,
                    serviceBadge: "tv"
                ),
                MediaItem(
                    title: "Barbie",
                    kind: .movie,
                    genres: ["Comédia", "Aventura", "Fantasia"],
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500/yRRuLt7sMBEQkHsd1S3KaaofZn7.jpg"),
                    backdropURL: nil,
                    synopsis: "Após uma crise existencial, Barbie deixa a perfeição da Barbieland e parte para o mundo real ao lado de Ken, descobrindo verdades sobre si mesma e sobre o que significa ser humana.",
                    year: 2023
                )
            ]
        )
    ]
}
