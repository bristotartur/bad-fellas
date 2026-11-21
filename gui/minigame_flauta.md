# Minigame da flauta

Em `gui/flute_minigame.tscn`, edite as duas partes em `NoteSequences/Sequence1` e
`NoteSequences/Sequence2`. Alterne a visibilidade pelo ícone de olho para
visualizar uma sequência por vez. Selecione cada nó `Note` e escolha sua
orientação em **Direction** no Inspetor. Mova ou redimensione os nós para
ajustar as posições; duplique ou remova nós para alterar a quantidade de notas.
A ordem de reprodução é a ordem das posições da esquerda para a direita.

Ao interagir com o Sapo Sabido com a flauta, o jogador ouve e vê as notas
brancas surgirem uma a uma a 100 BPM. Após a última semínima, elas permanecem
visíveis por mais uma mínima e desaparecem. O jogador repete a sequência usando
WASD ou as setas; cada acerto aparece colorido. Ao errar, o sapo escolhe uma fala aleatória e reproduz novamente a sequência
atual. Há uma pausa de uma mínima antes e depois da fala. Entre as duas partes há também uma pausa de uma mínima. Depois das duas
sequências, o painel fecha e o jogo continua normalmente. A melodia é a
primeira parte de Brilha, Brilha, Estrelinha, tocada com tons gerados pelo jogo;
as alturas são associadas à posição de cada nota na sequência. O sapo canta
duas oitavas abaixo da flauta, com harmônicos e vibrato.

Na primeira interação com a flauta, o sapo apresenta o desafio. Após completar
as duas sequências, ele apresenta o diálogo final e, nas próximas interações,
usa uma fala diferente. Esses estados duram até o reinício do jogo.
