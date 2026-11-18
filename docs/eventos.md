# Eventos aleatórios (S2, alpha2): especificação para aprovação (T2.1)

*17/11/2026, por Claude. Ideia e regras do dono: eventos de vez em quando (pedido urgente, caravana de troca, mercador
que paga mais, peixe diferente na Lagoa, mineral raro na Mina), avisados no ícone como alerta; quem não atende perde a
oportunidade e o XP do evento, e nada além disso.*

## 1. Quando acontecem

- **Só com o jogo aberto.** Um evento aparece a cada **45 a 120 minutos** de jogo (sorteado). Com o jogo fechado não
  surge nenhum: assim ninguém volta e encontra uma fila de eventos perdidos.
- **No máximo 2 ao mesmo tempo.** Com 2 abertos, o próximo espera.
- **O prazo corre pelo relógio**, também com o jogo fechado: quem sai com um evento aberto pode perdê-lo.
- **Ao expirar:** o evento vai embora com a recompensa e o XP dele. Nada do que o jogador já tem é tirado.
- O sorteio usa `KH.Rand` (os testes repetem sempre o mesmo resultado).

## 2. Os tipos

Os valores abaixo são relativos à economia aprovada (`docs/economia.md`): "encomenda normal" = o que uma encomenda de
ervas paga no nível do jogador. Nenhum evento dá mais moedas por hora do que ~20% do que a Horta rende na mesma hora.

| Tipo | O que é | Prazo | Recompensa |
|---|---|---|---|
| **Pedido urgente** | Um NPC pede uma erva ou um item da Oficina do nível do jogador, em quantidade 1,5× uma encomenda normal | 45 min | 2× as moedas de uma encomenda normal desse tamanho e **3× o XP** |
| **Mercador generoso** | Compra **uma** erva ou item específico pelo **dobro** do preço, até 20 unidades | 2 h | as moedas da venda (o dobro do normal) e XP de entrega |
| **Caravana de troca** | Oferece 3 trocas: dê X de uma coisa, receba Y de outra (ervas, minério, peixe, itens da Oficina) | 3 h | o que recebe vale até 30% mais que o que dá; **nunca moedas** |
| **Peixe raro na Lagoa** | Um peixe diferente para recolher (item do jogo: ex. Lagosta-garra-negra, Enguia-pedra-escamosa) | 4 h | o peixe vai para o Celeiro (vale ~12 min de Horta na venda) + XP |
| **Veio raro na Mina** | Um minério raro para recolher (item do jogo: ex. Minério de Prata-real, Minério de Ferro Negro, Cristal Arcano) | 4 h | o minério vai para o Celeiro (vale ~12 min de Horta na venda) + XP |

**Pesos do sorteio:** pedido urgente 30%, mercador 25%, caravana 20%, peixe raro 12,5%, veio raro 12,5%. Peixe raro só
com Lagoa; veio raro só com Mina; pedido de item só com Oficina.

Os peixes e minérios raros também entram no Herbário quando ele chegar (F4).

## 3. Onde aparecem

- **Alerta no ícone** (o que já existe): "Um mercador quer Folha-pálida · 1h 20m", com o tempo que falta. Clique abre o
  evento.
- **Na vila:** um **carrinho** aparece no mapa enquanto há evento aberto (arte nova, Codex); clicar abre a tela
  **Visitantes**.
- **Tela Visitantes:** um cartão por evento aberto, com o retrato de quem veio, o pedido, o prazo, a recompensa e o
  botão de agir (Entregar, Vender, Trocar, Recolher).
- **"Enquanto você esteve fora":** mostra os eventos que **expiraram** enquanto a janela estava fechada ("O mercador foi
  embora") e os que ainda estão abertos.
- **Novidades:** linhas da alpha2 sobre os eventos.

## 4. Arte (Codex, você aprova)

- Um carrinho de visitante para o mapa da vila (mesmo estilo e tamanho das construções).
- Três retratos: mercador, caravaneiro, mensageiro do pedido urgente (mesmo estilo dos seguidores).
- Os itens (peixes e minérios raros, ervas, poções) usam os ícones do jogo, como sempre.

## 5. Dados salvos

`db.events = {open = {...}, nextAt = hora do próximo, seen = contagem por tipo}`, preenchido pelos padrões (não precisa
de migração).

## 6. O que vai ser testado

- Com o relógio adiantado: aparece só com o jogo aberto, no máximo 2, expira no prazo e some sem tirar nada.
- Cada tipo: a ação funciona e paga o que diz; a caravana nunca cria moedas; o mercador respeita o limite de 20.
- Economia: o ganho médio dos eventos por hora fica abaixo de 20% da Horta, em todos os níveis.
- Telas: `conferir_textos.py` limpo em português e em inglês.

## 7. Ajuste na implementação (17/11)

O teste de economia mostrou que, no nível 50, os achados valendo ~30 min de Horta levavam os eventos a 24% da Horta.
Os achados passaram a valer ~12 min de Horta; pedido urgente (2×) e mercador (até 20) ficaram como aprovados. Resultado:
abaixo de 20% em todos os níveis (teste `tests/test_events.py`).
