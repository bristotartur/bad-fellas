# Glossário

- **Inimigo comum**: oponente reutilizável que aparece em posição livre aleatória em todas as salas das fases A, B e C e já está na sala quando o jogador entra. Move-se em passos de 16 pixels, levando inicialmente 0,25 segundo por passo; começa a perseguir o jogador quando ambos estão na mesma sala e tenta contornar obstáculos sem atravessá-los. Causa um ponto de dano por segundo enquanto encostado. É derrotado por um ataque de espada que o alcance pela frente e então desaparece; continua ausente quando o jogador retorna à sala. Este termo não inclui os minibosses nem os encontros especiais das fases.
- **Morcego**: inimigo voador com animações direcionais, que sobrevoa lagos e é bloqueado por paredes e pilares. Nasce sobre chão e compartilha as regras de dano e derrota do verme.
- **Lago**: tile de terreno que bloqueia o jogador e o verme e impede que ele seja escolhido como posição inicial. O morcego pode sobrevoá-lo.
- **Pilar**: obstáculo sólido que bloqueia o jogador, o verme e o morcego.
- **Espada**: arma que faz parte do personagem jogador e é usada no ataque normal. O sprite da espada ainda não foi feito; por enquanto, o ataque será representado pelo personagem avançando e recuando.
- **Ponto de vida**: unidade que mede quanto dano o jogador pode receber; ele começa com 10 pontos de vida. Ao perder todos, o jogo reinicia por completo desde o começo, restaurando a vida e o estado inicial das salas e inimigos.
