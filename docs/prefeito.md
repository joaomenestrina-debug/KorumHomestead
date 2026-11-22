# O Prefeito

*Pedido do dono em 22/11/2026: "um prefeito que fale todos os textos de alertas e eventos, com uma personalidade no
estilo da GLaDOS, do Portal, com humor".*

A personalidade abaixo é **nossa**. Ela usa o tom que o dono pediu (calma, educada, seca, com elogios que viram
alfinetadas), mas não usa nada do Portal: nem nomes, nem frases, nem piadas conhecidas do jogo (bolo, ciência,
testes, câmaras, neurotoxina). Quem conhece o Portal reconhece o tom, não o texto.

## Quem ele é

**Prefeito Ambrósio** (em inglês, **Mayor Ambrose**). Administra a vila há mais tempo do que qualquer um lembra e acha
que a vila funciona *apesar* de todo mundo, inclusive de você.

- **Meticuloso.** Conta tudo: ervas, moedas, passos dos seguidores, ratos do Celeiro. Guarda tudo no **Livro de
  Registros**, e você está nele.
- **Educado até demais.** Nunca levanta a voz. Elogia de um jeito que deixa a dúvida se foi elogio.
- **Seco.** Fala de um desastre e de um sucesso no mesmo tom.
- **Orgulhoso, mas não admite.** Por trás da ironia ele gosta da vila e de você. Uma vez ou outra isso escapa, e ele
  corrige na frase seguinte.
- **Burocrata.** Formulários, carimbos, protocolos, o Formulário 7-B para pedir outro Formulário 7-B.

### Piadas que voltam

- O **Livro de Registros** e o que ele anota sobre você ("Anotado. Com caneta.").
- Os **ratos do Celeiro**: ele sabe quantos são e tem opinião sobre cada um.
- A **planta do gabinete**, a única da vila que ele mesmo rega. Nunca cresce.
- A **poeira da Mina**, que ele considera um ataque pessoal.
- Os **seguidores** como funcionários que ele tolera: o Bram canta demais, a Sela pergunta demais, o Garrick tem medo de
  tudo que já morreu.

## Como ele fala

- **Curto.** Uma frase, no máximo duas. Os avisos aparecem no ícone da tela e no chat, então cerca de 110 letras.
- **Diz o fato primeiro.** O jogador tem de entender o aviso mesmo sem rir: o que ficou pronto, quanto ganhou, quem
  voltou.
- **Humor sem crueldade.** Pode ironizar as escolhas do jogador, a vila e os seguidores. Não ofende o jogador de
  verdade, não fala de aparência, de coisas do mundo real, de política ou de religião. Nada de palavrão. Classificação
  "T" (adolescente), como manda a política de addons da Blizzard.
- **Português do Brasil natural.** A piada em português não precisa ser tradução da inglesa. As duas dizem o mesmo
  fato, e cada uma pode ter a sua graça.
- **Sem travessão** (—). Vírgula, dois-pontos ou duas frases.
- **Na história do WoW Forever ele não inventa nada:** lugar, povo ou conflito só se estiver em
  [`historia-forever.md`](historia-forever.md).

### Exemplos (o tom, não o texto final)

| Momento | Português | English |
|---|---|---|
| Uma planta pronta | O %s está pronto. Colha antes que ele desenvolva opiniões. | Your %s is ready. Harvest it before it develops opinions. |
| Um grupo voltou | Um grupo voltou. Inteiro, na maior parte. | A group is back. Mostly in one piece. |
| Celeiro quase cheio | O Celeiro está em %d%%. Os ratos pediram um aumento de espaço. Eu neguei. | The Barn is at %d%%. The rats asked for more room. I said no. |
| Uma conquista | Conquista: %s. Vou emoldurar. Não temos molduras, mas a intenção conta. (%d pontos) | Achievement: %s. I will frame it. We have no frames, but it is the thought. (%d points) |
| Ao entrar no jogo | Ah, você voltou. A vila quase não sentiu sua falta. Quase. | Ah, you are back. The village barely missed you. Barely. |

## Onde ele fala

Cada momento é a chave do texto que ele substitui. As falas dele para a chave `readyAlert` são `mayor_readyAlert_1`,
`mayor_readyAlert_2`... no `Locales.lua`, com os mesmos códigos (`%s`, `%d`) na mesma ordem. O jogo sorteia uma (sem
repetir a anterior). Se um momento não tem fala, ou se o Prefeito está desligado nos Ajustes ("O Prefeito fala"),
aparece o texto simples de hoje.

Hoje ele já pode falar em: planta pronta, colheita ao entrar, obra pronta, nível da Vila, semente nova, Lótus Negra,
fabricação pronta, Celeiro quase cheio ou cheio, grupo que sai e que volta, seguidor promovido, encomenda entregue,
encomenda do dia e sequência, cada tipo de visitante que chega e cada resposta a eles, chefe e raide do personagem,
conquista (no chat e no título do cartão) e uma saudação ao entrar no jogo. A lista completa, com os textos de hoje,
está em [`tarefas/T6.11.md`](tarefas/T6.11.md).

## Próximos passos

1. **T6.11 (Codex):** escrever as falas de todos os momentos, nas duas línguas.
2. **A11 (Codex):** retrato do Prefeito, no estilo dos retratos dos seguidores.
3. **Claude:** o retrato no cartão das conquistas e no lembrete do voo e da fila; momentos novos onde fizer sentido
   (volta depois de muito tempo fora, falha numa masmorra, motivo de um botão não funcionar).
