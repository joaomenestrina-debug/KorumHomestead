# Os personagens da vila

*Pedidos do dono em 22/11/2026: primeiro "um prefeito que fale os alertas e eventos, com uma personalidade no estilo da
GLaDOS, do Portal, com humor"; depois, como o jogador é o **dono** da vila, não um prefeito, "vários personagens, e os
comentários vêm deles, dependendo de onde é".*

São cinco pessoas que trabalham **para você, o dono da vila**. Cada uma comenta a sua parte. O código está em
`Voices.lua`, e a opção "Os personagens falam", nos Ajustes, liga e desliga todos.

## Regras de todos

- **O tom do Portal, sem o Portal.** O Intendente tem o tom que o dono pediu (calmo, educado, seco, elogio que vira
  alfinetada). Os outros têm humor próprio. **Nada do Portal:** nem nomes, nem frases, nem piadas conhecidas (bolo,
  ciência, testes, câmaras, neurotoxina).
- **O fato primeiro.** Quem não rir tem de entender o aviso: o que ficou pronto, quanto ganhou, quem voltou.
- **Curto:** uma frase, no máximo duas, cerca de 110 letras (aparece no ícone da tela e no chat).
- **Humor sem crueldade.** Ironizar as escolhas do dono, a vila, os seguidores: sim. Ofender o jogador, aparência,
  mundo real, política, religião, palavrão: não. Classificação "T".
- **Português do Brasil natural.** A piada em português não precisa ser a inglesa traduzida, mas o fato é o mesmo.
  Sem travessão (—).
- **História do WoW Forever** só com o que está em [`historia-forever.md`](historia-forever.md).
- Eles se conhecem e **podem citar uns aos outros** de vez em quando ("A Capataz diz que..."), sem virar novela.
- Tratam o jogador como **o dono**: "senhor(a) da vila", "patrão", com o grau de ironia de cada um.

## Os cinco

### Intendente Ambrósio (Steward Ambrose): a vila como um todo
Entrada no jogo, nível da Vila, semente nova, construções, Lótus Negra, conquistas.

Administra a vila em seu nome há mais tempo do que qualquer um lembra, e acha que ela funciona *apesar* de você.
Educado até demais, nunca levanta a voz, elogia de um jeito que deixa dúvida. Anota tudo no **Livro de Registros**
("Anotado. Com caneta."). Por trás da ironia, gosta da vila e de você; quando isso escapa, corrige na frase seguinte.
Tem uma **planta no gabinete**, a única que ele mesmo rega, que nunca cresce.

> Ah, o senhor voltou. A vila quase não sentiu sua falta. Quase. · *Ah, you are back. The village barely missed you. Barely.*

### Capataz Dorota (Foreman Dorota): o trabalho
Horta, Mina, Lagoa, Celeiro e Oficina.

Prática, impaciente, mãos sempre sujas de terra. Reclama da **poeira da Mina**, dos **ratos do Celeiro** (sabe quantos
são e tem nome para alguns) e da sua demora para colher. Tem coração mole com as plantas: fala delas como se fossem
gente. Acha os formulários do Intendente uma perda de tempo.

> O %s está pronto. Colha logo, que ele já está me olhando torto. · *Your %s is ready. Pick it before it starts giving me looks.*

### Escrivão Tibério (Clerk Tiberius): o dinheiro
Mercado: encomendas, encomenda do dia, sequência.

Pedante e ansioso com números. Comemora cada moeda como uma vitória pessoal e sofre com cada arredondamento. Confere
tudo três vezes. Tem medo do Intendente e admiração pela Capataz ("ela produz, eu só conto").

> Encomenda entregue: +%s moedas. Conferi três vezes. Está certo. Acho. · *Order delivered: +%s coins. Checked three times. It is right. I think.*

### Mordomo Fenwick (Butler Fenwick): quem chega
Visitantes: mensageiro, mercador, caravana, peixe e veio raros, e as respostas a eles.

Recebe todo mundo com pompa exagerada, como se a vila fosse um palácio. Esnobe com caravanas ("cheiram a estrada") e
com peixe ("um peixe na Lagoa, senhor, e ele não foi convidado"). Anuncia tudo como numa corte.

> Anuncio a chegada de um mercador generoso. Generoso, ele diz. Veremos. · *I announce a generous merchant. Generous, he says. We shall see.*

### Conselheira Marga (Advisor Marga): os seguidores
Estalagem: grupos que saem e voltam, promoções, chamados, os chefes e raides do personagem.

Aventureira aposentada, com histórias de guerra exageradas ("no meu tempo a gente fazia isso de olhos fechados").
Trata os seguidores como filhos: se orgulha, se preocupa, briga. Fica emocionada quando alguém é promovido e finge que
foi poeira no olho (culpa da Mina).

> Um grupo voltou. Todos inteiros. Quase não chorei. · *A group is back. All in one piece. I barely cried.*

## Onde cada um fala

Cada momento é a chave do texto que ele substitui; as falas da chave `readyAlert` são `say_readyAlert_1`,
`say_readyAlert_2`... no `Locales.lua`, com os mesmos códigos na mesma ordem. O jogo sorteia uma, sem repetir a
anterior, com o nome de quem fala antes. Sem fala, aparece o texto simples. A tabela de quem fala cada momento está em
`Voices.lua` (`WHO`) e no briefing [`tarefas/T6.11.md`](tarefas/T6.11.md).

## Próximos passos

1. **T6.11 (Codex):** as falas de todos os momentos, nas duas línguas.
2. **A11 (Codex):** os cinco retratos, no estilo dos retratos dos seguidores.
3. **Claude:** o retrato de quem fala no cartão das conquistas e no lembrete do voo e da fila; momentos novos onde
   fizer sentido (grupo que falhou, seguidor ferido, um botão que não funciona por falta de moedas, volta depois de
   muito tempo fora).
