# Inimigos comuns — proposta inicial

Este documento consolida as decisões já tomadas e propõe regras simples para a primeira versão dos inimigos comuns. Os itens marcados como **Definido** refletem o que você escolheu durante a conversa. Os itens **Sugestão para revisar** são recomendações minhas, ainda sujeitas à sua revisão.

## Objetivo e escopo

Criar um inimigo comum reutilizável para dificultar a travessia das salas. A primeira versão deve priorizar um comportamento completo e fácil de testar, sem tentar resolver minibosses, criaturas invocadas ou encontros especiais.

- **Implementado** — Há dois tipos de inimigo comum: verme ósseo e morcego, reutilizados em todas as salas das fases A, B e C.
- **Definido** — O inimigo já está na sala quando o jogador entra. A descrição da sala da chave da fase A foi ajustada para refletir isso.
- **Definido** — Os inimigos comuns surgem em posições aleatórias de todas as salas das fases A, B e C.
- **Implementado** — Cada uma das 11 salas das fases A, B e C tem um spawner que cria dois inimigos. Cada inimigo é sorteado independentemente entre verme e morcego, permitindo dois iguais ou um de cada tipo.
- **Implementado** — Os inimigos nascem com ao menos 48 pixels de distância entre si, sem sobreposição.
- **Implementado** — O sorteio rejeita posições que colidam com obstáculos que bloqueiam aquele inimigo ou fiquem a menos de 96 pixels do jogador.
- **Implementado** — O sorteio embaralha os tiles existentes e aceita somente o centro de tiles classificados como chão. No atlas atual, chão é `(2, 2)`, lago é `(5, 1)` e pilar é `(5, 3)`. As portas também entram na consulta de colisão, mesmo abertas.
- **Implementado** — Lago e pilar são tipos diferentes de obstáculo: o verme não atravessa nenhum dos dois; o morcego sobrevoa lagos, mas é bloqueado por paredes e pilares. Ambos nascem somente sobre chão.

## Movimento e perseguição

- **Definido** — O inimigo começa a perseguir assim que jogador e inimigo estão na mesma sala.
- **Definido** — O movimento ocorre em passos de 16 pixels, alinhados ao movimento atual do jogador.
- **Definido** — Cada passo do inimigo leva inicialmente 0,25 segundo. Tratar esse valor como ponto de partida para ajustar ao testar.
- **Implementado** — Cada tipo de inimigo define quais obstáculos bloqueiam seu caminho. O verme é bloqueado por lago e pilar; o morcego é bloqueado por pilar, mas não por lago.
- **Implementado** — O inimigo anda apenas nas quatro direções cardeais, sem diagonal, para combinar com os controles atuais do jogador.
- **Implementado** — O TileSet identifica lago em uma camada de colisão própria. O verme colide com essa camada e com a camada de obstáculos sólidos (incluindo pilares); a seleção da posição inicial usa a máscara de colisão da cena do inimigo.
- **Implementado com limite** — O inimigo tenta contornar obstáculos usando movimentos locais. Isso deve funcionar em salas simples; labirintos podem exigir um algoritmo de navegação em grade.

## Combate

- **Definido** — Um ataque de espada derrota o inimigo.
- **Definido** — O ataque precisa alcançar o inimigo pela frente, durante o movimento de ataque. Apenas encostar no inimigo não o derrota.
- **Implementado** — Ao ser derrotado, o inimigo para de agir e causar dano imediatamente, mostra a animação de ferimento por aproximadamente 0,33 segundo e desaparece.
- **Definido** — O inimigo causa um ponto de dano por segundo enquanto encosta no jogador.
- **Definido** — O jogador começa com 10 pontos de vida.
- **Implementado** — A vida aparece no canto superior esquerdo e persiste quando a cena da fase muda.
- **Implementado** — O botão esquerdo do mouse faz o jogador avançar e recuar; uma área frontal derrota no máximo um inimigo por ataque.
- **Implementado** — Ao perder todos os pontos de vida, a partida reinicia na fase A com vida cheia.
- **Implementado** — O primeiro dano ocorre após um segundo inteiro de contato contínuo; separar interrompe a contagem, e um novo contato inicia outra contagem.
- **Implementado** — Cada ataque do jogador pode derrotar no máximo um inimigo.

## Salas, derrota e progresso

- **Definido** — Um inimigo derrotado continua ausente quando o jogador sai e retorna à sala.
- **Definido** — Ao perder todos os pontos de vida, o jogo reinicia por completo desde o começo, restaurando os 10 pontos de vida e o estado inicial das salas e inimigos.
- **Definido** — O reinício completo também apaga chaves, puzzles concluídos e qualquer outro progresso da partida.

## Estado e integração

- **Implementado** — A vida aparece no canto superior esquerdo e persiste quando a cena da fase muda.
- **Implementado** — O botão esquerdo do mouse faz o jogador avançar e recuar; a área de ataque frontal derrota no máximo um inimigo por ataque.
- **Implementado** — Ao perder todos os pontos de vida, a partida reinicia na fase A com vida cheia e estado inicial.
- **Implementado** — A folha `assets/bone-worm-animations.png` contém 16 quadros em quatro linhas: parado, movimento, ataque de contato e ferimento. A direção horizontal espelha o sprite; cada sala das fases A, B e C tem um spawner.
- **Implementado** — O morcego usa `assets/bat-directional.png` para direita, esquerda e cima e `assets/bat-front.png` para baixo. Há animações de voo, ataque e ferimento nas quatro direções; ele compartilha as regras de dano e derrota do verme.
- **Estado atual do projeto** — O sprite da espada ainda não foi feito; o ataque é representado pelo avanço e recuo do jogador.
- **Integração indicada pelo plano** — A sala principal da fase A libera a porta A depois que todos os oponentes forem derrotados. A sala precisa acompanhar as derrotas dos inimigos; essa regra depende da implementação das salas e portas.

## Ordem sugerida de implementação

1. Jogar para ajustar perseguição, dano e distância do golpe.
2. Melhorar a navegação em salas com obstáculos complexos.
3. Trocar o placeholder do ataque por arte/animação da espada quando estiver disponível.
