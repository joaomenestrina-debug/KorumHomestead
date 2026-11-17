# Economia da 2.0 (T2.0): proposta para aprovação

*17/11/2026, por Claude. Pedidos do dono no mesmo dia: cuidar do excesso de moedas; nível máximo como o do jogo;
o nível é o da **Vila**, não de Herbalismo; Mercado pedindo também itens da Oficina, com mais opções (4 de erva + 4 de
Oficina); a Oficina paga mais; erva dá pouco XP, quem dá XP é a Oficina e a venda no Mercado.*

## 1. Onde estamos (medido na 1.0.1 / alpha1)

| | Nível 5 | Nível 10 | Nível 15 | Nível 20 (máx.) |
|---|---|---|---|---|
| Encomenda normal (média) | 208 | 872 | 3.584 | 10.111 |
| Horta vendendo a melhor erva (6 canteiros), por hora | 3.840 | 5.760 | 7.680 | 9.600 |

- A vila inteira (8 prédios no nível 7) custa **~194 mil**. No nível 20, isso são **~20 horas** de Horta: o jogo acaba
  rápido e as moedas sobram.
- O motivo: a renda cresce com o nível, mas os custos dos prédios são fixos e nada impede comprar tudo cedo.
- O XP vem quase todo da colheita, e o nível máximo (20) chega antes da vila.

## 2. As regras novas

1. **Nível da Vila, de 1 a 60** (o nível máximo de personagem do WoW Forever, cujas profissões vão a 300). Ele substitui
   o "Herbalismo" do cabeçalho.
2. **Cada erva abre no nível da vila = perícia de Herbalismo do jogo ÷ 5.** As 13 ervas de hoje mudam de nível, e entram
   14 ervas novas até o nível 58. A Lótus Negra (300 → 60) continua só como lembrança rara da sequência.
3. **De onde vem o XP:** colher dá **pouco** (~15% do XP de um jogador típico); **a Oficina ~35%**; **as entregas no
   Mercado ~50%**. Quem só planta e vende sobe devagar; quem fabrica e entrega sobe rápido.
4. **Mercado com 8 encomendas:** 4 de ervas e 4 de itens da Oficina (as de Oficina aparecem conforme as receitas abertas;
   sem Oficina, os 4 lugares mostram o que falta para abri-la). Mais a encomenda do dia, que pode pedir erva ou item.
5. **A Oficina sempre dá mais moedas e mais XP que a matéria-prima:** o preço de cada item = valor das matérias-primas
   × 1,5, mais um pouco pelo tempo de fabricação; o XP de fabricar e de entregar um item é sempre maior que o de colher
   e entregar as ervas que ele gastou. Um teste confere isso para **todas** as receitas.
6. **Os prédios andam com a vila:** cada nível de prédio pede um **nível mínimo da vila**, e o custo é
   **algumas horas da renda da Horta naquele nível**. Assim a renda nunca passa muito à frente dos custos (fim do excesso
   de moedas), e nada se compra cedo demais.
7. **Recompensas de hábito não dão moedas** (já valendo desde a PR #11). No nível 60, o XP que sobraria vira Lótus
   Negra (a cada tanto XP acumulado no máximo): o jogador do topo também ganha algo.

## 3. As ervas

| Erva | Perícia no jogo | Nível da Vila | Hoje |
|---|---|---|---|
| Botão-da-paz | 1 | 1 | 1 |
| Folha-prata | 1 | 1 | 1 |
| Raiz-telúrica | 15 | 3 | 2 |
| Magi-real | 50 | 10 | 3 |
| Cardo-farpado | 70 | 14 | 4 |
| Alga-estranguladora *(nova)* | 85 | 17 | — |
| Erva-moura | 100 | 20 | 6 |
| Aço-flor Selvagem | 115 | 23 | 7 |
| Musgo-de-túmulo | 120 | 24 | 19 |
| Sangue-real | 125 | 25 | 9 |
| Raiz-da-vida | 150 | 30 | 11 |
| Folha-pálida | 160 | 32 | 13 |
| Espinheira-dourada | 170 | 34 | 15 |
| Bigode-de-hadgar | 185 | 37 | 17 |
| Mordida-do-inverno *(nova)* | 195 | 39 | — |
| Flor-de-fogo *(nova)* | 205 | 41 | — |
| Lótus Roxo *(nova)* | 210 | 42 | — |
| Lágrimas-de-Arthas *(nova)* | 220 | 44 | — |
| Capim-do-sol *(nova)* | 230 | 46 | — |
| Erva-cega *(nova)* | 235 | 47 | — |
| Cogumelo-fantasma *(nova)* | 245 | 49 | — |
| Sangue-de-grom *(nova)* | 250 | 50 | — |
| Sansam Dourado *(nova)* | 260 | 52 | — |
| Folha-de-sonho *(nova)* | 270 | 54 | — |
| Sálvia-prateada *(nova)* | 280 | 56 | — |
| Flor-da-peste *(nova)* | 285 | 57 | — |
| Gelo-espinho *(nova)* | 290 | 58 | — |
| Lótus Negra | 300 | 60 | só lembrança rara |

Nomes e ícones vêm do jogo (`C_Item`); a tabela usa os nomes ptBR do cliente quando ele os tiver.

**Tempo de crescer:** de 45 s (Botão-da-paz) a ~4 h (Gelo-espinho), ×1,25 de uma erva para a seguinte: as ervas altas
combinam com voltar algumas vezes por dia. **Colheita:** 3 a 7 por canteiro.

## 4. As metas dos números (o que os testes vão conferir)

| Meta | Valor proposto |
|---|---|
| Renda da Horta (melhor erva, todos os canteiros) | ~320/h no nível 1 → ~7.000/h no nível 55 (+6% por nível) |
| Nível de prédio → nível mínimo da vila | 1 → 1, 2 → 5, 3 → 12, 4 → 20, 5 → 30, 6 → 42, 7 → 55 |
| Custo de um nível de prédio | 0,5 h, 1,5 h, 3 h, 5 h, 8 h, 12 h da renda da Horta no nível mínimo (× peso do prédio: Celeiro 0,6 ... Estalagem 1,3) |
| Vila inteira no máximo | **~250 horas de Horta** (contando o tempo com o jogo fechado), ou seja, semanas de jogo, não ~20 horas |
| Do nível 1 ao 60 | ~120 horas de Horta para quem só planta; bem menos para quem usa Oficina e Mercado |
| Encomenda normal | ~1,6× o preço de venda do que pede |
| Encomenda do dia | 2,5× uma encomenda normal (como na PR #11), prêmios em XP e Lótus Negra |

Um teste novo simula um jogador e falha se a vila inteira sair em menos de ~200 horas de Horta, ou se alguma atividade
render mais por hora que a Horta na mesma fase (serviços, Estalagem).

## 5. Os saves que já existem

- **Nível:** o Herbalismo antigo vira o nível da vila em que **todas as ervas que o jogador já tinha** continuam
  abertas. Herbalismo 20 (todas as 13) → **Vila 37**. O XP dentro do nível volta a 0.
- **Prédios:** ficam no nível em que estão, mesmo acima do mínimo novo (nada se perde).
- **Moedas, ervas, itens, seguidores, encomendas:** ficam. As encomendas antigas são refeitas com os preços novos.
- Migração `schema 3` em `Migrate.lua`, testada com o seu save real (`tests/fixtures/save-1.0.1.lua`).

## 6. Como entra no cronograma

Tudo isso é a **F2.0 (Economia)**, antes dos Serviços. Proposta de divisão, depois da sua aprovação:

| Tarefa | Quem |
|---|---|
| Tabela das 27 ervas no `Balance.lua` (gerada pelas fórmulas), nível da vila 1–60, curva de XP | Claude |
| Migração `schema 3` e testes com o save real | Claude |
| Mercado com 4 + 4 encomendas (lógica) e pagamento dos itens da Oficina | Codex (briefing de Claude) |
| Telas: cabeçalho "Vila N", Mercado com 8 encomendas (duas colunas ou abas), Guia e cartões | Claude |
| Textos EN/ptBR e Novidades | Codex |
| Teste de simulação da economia | Claude |
| Aprovar os números e testar no jogo | **Eu** |

A alpha1 pode sair antes (com a economia atual e a encomenda do dia já corrigida), ou esperar a F2.0 e sair junto.
