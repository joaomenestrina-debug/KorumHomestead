# Masmorras e seguidores (S3 a S5, versões 2.2 e 2.3): especificação aprovada

*18/11/2026, por Claude. Ideias do dono: mandar os seguidores para masmorras, equipá-los, subir de nível e combinar
habilidades, na linha das missões de seguidores do WoW, "mas melhorado se possível"; mostrar a chance e os recomendados
ao escolher o grupo; chamados de defesa, ataque e outros; seguidores com raridade, novos seguidores e drops raros; e
**tudo sempre ligado à história do WoW Forever**. **Aprovada pelo dono em 18/11, com as decisões da §16 como
propostas.** Os
números finais ficam em `Balance.lua` e são conferidos pelos testes da seção 13.*

A mecânica segue o gênero das missões de seguidores; a tela, os nomes, as habilidades e a arte são nossos. Os nomes e
ícones de masmorras, itens e magias vêm do próprio jogo, como as ervas.

---

## 1. O que muda para o jogador

- As três missões de hoje (curta, média e longa) saem. No lugar, a Estalagem ganha o **Quadro de Masmorras**: as
  masmorras e raides do WoW Forever, as do Clássico e as novas.
- Cada masmorra mostra suas **ameaças**. Cada seguidor tem **habilidades** que anulam ameaças. Montar o grupo certo sobe
  a **chance de sucesso**, que aparece antes de enviar.
- Os seguidores **sobem do nível 1 ao 30**, mudam de **qualidade** (comum, raro, épico), escolhem **talentos**, têm
  **traços** de personalidade e usam **equipamento feito na Oficina**.
- Certas duplas de habilidades no mesmo grupo formam **combos** com efeito próprio, guardados num livro que se completa
  ao descobrir.
- Ninguém morre. O pior resultado é voltar com metade da recompensa e um seguidor **ferido**, que descansa algumas horas.
- Os seguidores têm **raridade** (Incomum, Raro, Épico, Lendário). Além dos seis de hoje, **novos seguidores** chegam
  como drop raro das masmorras e das raides, ou resgatados em chamados.
- **Chamados:** de vez em quando, enquanto você joga, um lugar do Forever pede ajuda (defesa, ataque, escolta, resgate,
  reconhecimento). Como os visitantes: aparecem, têm prazo e quem não atende só perde a chance.

### O que fica melhor que nas missões do WoD

| Problema conhecido | Aqui |
|---|---|
| Montar grupos era trabalho manual (só addons de terceiros resolviam) | Botão **Grupo sugerido**: o melhor grupo com um clique |
| Missões sorteadas que somem; a mesa vira obrigação | **Todas as masmorras ficam sempre disponíveis**; nada some. Uma por dia ganha bônus (Masmorra do dia), sem punir quem não vem |
| Equipamento vinha de fichas sem relação com a guarnição | **Equipamento feito na Oficina**, com o minério da Mina: a vila inteira alimenta as masmorras |
| Seguidor no máximo perdia a graça | No nível 30: **Maestria** (talento final) e **Título**, que dá um bônus permanente em casa |
| Chance acima de 100% desperdiçada | O que passa de 100% vira **bônus de recompensa**, até 150% |
| Ouro demais | Tudo dentro do teto da economia (seção 9) |
| Morte ou perda de seguidor | Não existe: só ferimento e descanso |
| Seguidor raro repetido não servia para nada | Repetido vira **Insígnia** para quem você já tem; e há **garantia**: depois de muitas masmorras sem seguidor novo, o próximo sucesso traz um |

## 2. Quando abre

- A Estalagem continua abrindo com a **Sede 5** (Vila 30). As masmorras são a camada de meio e fim de jogo da vila.
- Cada nível da Estalagem é um **quarto** (1 a 7). Quem está num quarto dá o bônus em casa e pode sair em masmorra ou
  chamado. Os outros seguidores esperam no **Alojamento** (até 20 no total) e trocam de lugar com quem está num quarto a
  qualquer momento, se os dois estiverem em casa. Assim um rol maior dá **escolha**, não mais renda.
- As masmorras abrem pelo **nível dos seguidores**, não da vila: a primeira está aberta desde o primeiro seguidor.
- As raides pedem de 4 a 6 seguidores no nível 30 (seção 5).

## 3. Os seguidores

Os seis de hoje, com os retratos que já existem, são **Incomuns**. Os novos estão na seção 3.5.

| Seguidor | Classe | Habilidade inicial | No Raro, escolhe uma | Traço inicial |
|---|---|---|---|---|
| **Mira** | arqueira | Rajada de Flechas (Horda) | Olho de Águia (Armadilhas) **ou** Tiro Certeiro (Chefe brutal) | Filha da floresta: +10% em ambiente natural |
| **Tobin** | ferreiro | Martelo Pesado (Blindados) | Mestre das Fechaduras (Armadilhas) **ou** Armas de Prata (Mortos-vivos) | Mãos de ferro: o equipamento dele conta 1 nível a mais |
| **Elda** | herborista | Ervas Curativas (Veneno e doença) | Água Benta (Mortos-vivos) **ou** Bálsamo Calmante (Medo) | Velha sábia: +10% de XP para o grupo todo |
| **Garrick** | guerreiro | Escudo Erguido (Chefe brutal) | Grito de Guerra (Medo) **ou** Redemoinho (Horda) | Medo de mortos-vivos: −10% contra eles (some no nível 20) |
| **Sela** | maga | Contrafeitiço (Magia hostil) | Bola de Fogo (Mortos-vivos) **ou** Nevasca (Horda) | Curiosa: +5% de chance de achado raro |
| **Bram** | bardo | Canção da Coragem (Medo) | Distração (Armadilhas) **ou** Canção Dissonante (Magia hostil) | Boa companhia: +5% de chance para cada outro seguidor no grupo |

- O bônus em casa de cada um (plano F3: Tobin na Ferraria, Elda na Horta, Sela na Alquimia, Bram nas encomendas) continua:
  vale **só enquanto o seguidor está em casa**. Mira e Garrick passam a dar bônus em casa ligados às masmorras (Mira:
  +5% de chance de troféu; Garrick: −10% de chance de ferimento para todos).
- Os ícones das habilidades e das ameaças são ícones de magias do jogo (`Interface\Icons\...`). Nenhuma arte nova.

### 3.1 Nível (1 a 30)

- O seguidor ganha XP em toda masmorra: cheia no sucesso, metade na falha.
- Contra uma masmorra de nível maior que o dele, perde chance (seção 6). Contra uma bem menor, ganha pouco XP.
- **Metas de ritmo** (conferidas por simulação, mandando o seguidor ~3 vezes por dia): nível 10 em ~1 semana, 20 em ~3
  semanas, 30 em ~6 a 8 semanas.

### 3.2 Qualidade e talentos

| Qualidade | Como chega | O que abre |
|---|---|---|
| **Incomum** (verde) | começo dos seis de hoje | 1 habilidade, 1 traço |
| **Raro** (azul) | nível 10 + 1 **Insígnia de Mérito** | escolhe a 2ª habilidade (uma de duas) |
| **Épico** (roxo) | nível 20 + 1 **Insígnia Épica** | escolhe o 2º traço (um de dois, tabela 3.3) |
| **Lendário** (laranja) | só de nascença (seção 3.5) | habilidade de **assinatura** (anula duas ameaças) e um 3º traço |
| **Maestria** | nível 30 | escolhe uma de duas: **Mestre de Casa** (bônus em casa em dobro) ou **Veterano** (+10% de chance em toda masmorra); ganha um **Título** ("Garrick, o Inabalável") |

- As insígnias vêm das masmorras (seção 8). Com o ícone de um item do jogo.
- Um seguidor que já nasce Raro ou Épico chega com as escolhas daquela qualidade em aberto, para o jogador fazer.
- Trocar uma escolha custa moedas (o custo sobe a cada troca), como estava previsto para os atributos.

### 3.3 Traços que se escolhe no Épico

Cada seguidor escolhe um de dois, na lista abaixo (a combinação de cada um fica em `Balance.lua`):

| Traço | Efeito |
|---|---|
| Passos ligeiros | masmorras 15% mais curtas |
| Sortudo | +10% de chance de achado raro |
| Resistente | nunca volta ferido |
| Aprende rápido | +25% de XP para si |
| Parceiro de (outro seguidor) | +10% de chance quando os dois vão juntos |
| Gosta de (ambiente) | +10% de chance em criptas, cavernas, fortalezas ou ruínas |

### 3.4 Ferimento

- Na falha, cada seguidor do grupo tem 30% de chance de voltar ferido: descansa **2 horas** na Estalagem (não sai em
  masmorra, mas dá o bônus em casa).
- Comida da Oficina, o combo Muralha e Cura e o traço Resistente reduzem ou evitam.

### 3.5 Raridade, ranking e seguidores novos

- **Raridade de nascença:** Incomum, Raro, Épico ou Lendário, nas cores dos itens do jogo. Ela é a qualidade com que o
  seguidor chega. Incomuns e Raros sobem até Épico com insígnias; Lendário só de nascença.
- **Poder:** um número por seguidor (nível, qualidade e equipamento). A aba **Ranking** lista o rol inteiro pelo Poder,
  com a cor da raridade, e mostra quantos dos seguidores do jogo o jogador já tem ("9 de 18").
- **Como chegam os novos:**

| De onde | Chance | Raridade |
|---|---|---|
| Masmorra, no sucesso | 1% (nível 1 a 10), 2% (11 a 20), 3% (21 a 30) | Raro; Épico só nas de nível 21 ou mais |
| Raide, no sucesso | 10% | Épico; **Lendário** 2% |
| Chamado de resgate, no sucesso | 25% | quem foi resgatado (Raro ou Épico) |
| **Garantia** | depois de 40 masmorras sem seguidor novo, o próximo sucesso traz um | Raro |

- Cada seguidor novo **é de um lugar do Forever** e só pode vir de lá: das masmorras ou dos chamados daquele lugar. A
  ficha dele diz de onde veio.
- **Repetido:** se cair alguém que o jogador já tem, vira uma Insígnia (Mérito para Raro, Épica para Épico e Lendário).
- Seguidores novos propostos (nomes, classes e habilidades finais com o dono; cada um precisa de um retrato novo):

| Raridade | Seguidor (arquétipo) | Vem de | Habilidades |
|---|---|---|---|
| Raro | Patrulheira Skyborne | chamados de Zephras Isle | Rajada de Vento (Horda) / Passo Leve (Armadilhas) |
| Raro | Xamã anão | Hall of Thanes | Totem Purificador (Veneno) / Escudo de Terra (Chefe brutal) |
| Raro | Paladino Renegado | Ruins of Lordaeron | Luz Profana (Mortos-vivos) / Aura de Devoção (Blindados) |
| Raro | Escavador | Excavation Site | Mestre das Ruínas (Armadilhas) / Saber Antigo (Magia hostil) |
| Raro | Caçador Darkspear | chamados de Darkspear Island | Vodu (Medo) / Lança Farpada (Horda) |
| Épico | Mago do Kirin Tor | City of Dalaran | Contrafeitiço Maior (Magia hostil) / Teleporte (masmorra 20% mais curta) |
| Épico | Guardião de Hyjal (druida) | chamados de Mount Hyjal | Rejuvenescer (Veneno) / Forma de Urso (Chefe brutal) |
| Épico | Fugitivo de Alcaz (ladino) | Alcaz Island Prison (resgate) | Furtividade (Armadilhas) / Golpe Baixo (Chefe brutal) |
| Épico | Caçador de Blackmaw | Blackmaw Hold | Armadilha Congelante (Horda) / Tiro Sereno (Medo) |
| Lendário | Anciã dos Ventos Skyborne | Hyjal Summit | **Tempestade de Zephras:** anula Horda e Magia hostil |
| Lendário | Thane de Ironforge | Barrow Deeps | **Bastião:** anula Chefe brutal e Blindados |
| Lendário | Vigia de Hyjal | Hyjal Summit | **Luz Ancestral:** anula Mortos-vivos e Medo |

- Os arquétipos vêm do que o Forever confirmou: a raça nova Skyborne de Zephras Isle, os paladinos Renegados e os xamãs
  anões, Dalaran, Hyjal depois de Archimonde, Darkspear Island e as masmorras novas (seção 11). Quem são de fato, com
  nome e história, sai do que o jogo conta.
- Os novos também trazem combos novos com os seis de hoje (definidos junto com as habilidades finais).

## 4. Equipamento

Dois espaços por seguidor: **arma** e **armadura**. Cada peça tem um **nível de equipamento** que soma à chance.

- **Feito na Oficina**, na Ferraria, numa aba nova "Equipamento": cada peça pede barras (as receitas de barra que já
  existem: Cobre, Bronze, Mithril, Tório, Arcanita) e um pouco de minério.
- Cada nível da Oficina abre uma peça de arma e uma de armadura, como as receitas de hoje (1 a 7). As de nível 7
  (Arcanita) pedem também um **Núcleo** que só cai nas raides.
- Ícones de armas e armaduras reais do jogo, do material de cada nível (escolhidos na implementação e conferidos com
  `C_Item`).
- **Equipar não gasta a peça**; trocar devolve a anterior ao Celeiro. Peças sobrando podem ser vendidas no Mercado pelo
  valor da Oficina.
- **Consumíveis** (gastos numa masmorra):
  - **Poção** (Alquimia, qualquer poção que já existe): +10% de chance.
  - **Comida** (Culinária, qualquer prato que já existe): +20% de XP e metade do risco de ferimento.
  - No máximo uma poção e uma comida por grupo.

## 5. As masmorras

As masmorras são as do **WoW Forever**: as do Clássico que existem nele e as **nove novas do Forever** (marcadas com ★),
na ordem de nível do jogo. Nível = nível de seguidor recomendado (cerca de metade do nível do jogo). Grupo = quantos
seguidores ela pede (pode ir com menos, com chance menor).

| # | Masmorra (EN) | Onde | Nível | Grupo | Duração | Ameaças | Ambiente |
|---|---|---|---|---|---|---|---|
| 1 | Ragefire Chasm | Orgrimmar | 1 | 1 | 1 h | Horda, Magia hostil | caverna |
| 2 | ★ Hall of Thanes | Ironforge | 2 | 1 | 1 h | *a conferir* | fortaleza |
| 3 | ★ Ruins of Lordaeron | Tirisfal | 3 | 1 | 1 h | *a conferir* | ruínas |
| 4 | Wailing Caverns | Barrens | 4 | 1 | 1 h 30 | Veneno, Medo | caverna |
| 5 | The Deadmines | Westfall | 5 | 2 | 1 h 30 | Horda, Armadilhas | caverna |
| 6 | Shadowfang Keep | Silverpine | 6 | 2 | 1 h 30 | Mortos-vivos, Magia hostil | fortaleza |
| 7 | ★ Excavation Site | Wetlands | 7 | 2 | 2 h | *a conferir* | ruínas |
| 8 | Blackfathom Deeps | Ashenvale | 8 | 2 | 2 h | Horda, Veneno | ruínas |
| 9 | ★ City of Dalaran | Alterac | 9 | 2 | 2 h | *a conferir* | fortaleza |
| 10 | Gnomeregan | Dun Morogh | 10 | 2 | 2 h 30 | Armadilhas, Blindados, Horda | fortaleza |
| 11 | Scarlet Monastery | Tirisfal | 12 | 3 | 2 h 30 | Horda, Magia hostil, Chefe brutal | fortaleza |
| 12 | ★ Drowned City | Stranglethorn | 13 | 3 | 3 h | *a conferir* | ruínas |
| 13 | ★ Krol'dok Stronghold | *a conferir* | 15 | 3 | 3 h | *a conferir* | fortaleza |
| 14 | Uldaman | Badlands | 17 | 3 | 3 h 30 | Blindados, Armadilhas, Magia hostil | ruínas |
| 15 | Zul'Farrak | Tanaris | 19 | 3 | 3 h 30 | Horda, Veneno, Chefe brutal | ruínas |
| 16 | ★ Alcaz Island Prison | Dustwallow | 20 | 3 | 4 h | *a conferir* | fortaleza |
| 17 | Maraudon | Desolace | 22 | 3 | 4 h | Veneno, Blindados, Medo | caverna |
| 18 | Sunken Temple | Swamp of Sorrows | 24 | 3 | 4 h 30 | Magia hostil, Veneno, Medo, Horda | ruínas |
| 19 | Blackrock Depths | Blackrock | 26 | 3 | 5 h | Blindados, Magia hostil, Horda, Chefe brutal | fortaleza |
| 20 | ★ Blackmaw Hold | Azshara | 28 | 3 | 5 h | *a conferir* | caverna |
| 21 | ★ Shaper's Terrace | Un'Goro | 29 | 3 | 5 h 30 | *a conferir* | ruínas |
| 22 | Scholomance | Western Plaguelands | 30 | 3 | 6 h | Mortos-vivos, Magia hostil, Medo, Veneno | cripta |
| 23 | Stratholme | Eastern Plaguelands | 30 | 3 | 6 h | Mortos-vivos, Horda, Chefe brutal, Medo | cripta |
| R1 | ★ Barrow Deeps | *a conferir* | 30 | 4 | 12 h | *a conferir* | cripta |
| R2 | ★ Hyjal Summit | Mount Hyjal | 30 | 5 | 18 h | *a conferir* | natural |
| R3 | Onyxia's Lair | Dustwallow | 30 | 6 | 24 h | Chefe brutal, Magia hostil, Medo, Horda, Blindados | caverna |

- **As ameaças e o ambiente das masmorras novas do Forever saem do jogo, não de suposição:** o dono, que joga o Forever,
  confirma quem está lá dentro (ou um guia oficial), e só então elas ganham ameaças. Até lá, ficam fora da lista do jogo.
  O mesmo vale para a masmorra de Krol'dok e a raide Barrow Deeps, cujo lugar ainda não foi confirmado.
- Masmorras e raides que o Forever ainda vai lançar (as de primavera e verão de 2027) entram aqui quando saírem, como
  atualização do addon.
- As raides pedem 4, 5 e 6 seguidores: a Covil de Onyxia, a maior, leva a Estalagem inteira.
- Os nomes em português seguem os do cliente ptBR do jogo; o Codex confere na revisão de textos.
- **Chefe opcional** (todas as masmorras): uma ameaça a mais e +25% de duração, em troca de chance de troféu raro.
- **Raides:** cada uma uma vez a cada 7 dias (contados de quando foi feita, sem depender do reinício do servidor).
- **Masmorra do dia:** uma masmorra sorteada por dia (`KH.Day`) dá +50% de XP. Quem não faz não perde nada.

### As 8 ameaças

Horda (muitos inimigos), Chefe brutal, Magia hostil, Veneno e doença, Armadilhas, Mortos-vivos, Medo, Blindados.

## 6. Chance de sucesso

Mostrada antes de enviar, e já com o motivo de cada parte (a tela lista de onde vem cada ponto):

1. **Ameaças:** cada ameaça não anulada tira **25 pontos** de 100. Uma habilidade anula uma ameaça; duas iguais anulam
   duas ameaças iguais.
2. **Nível:** para cada nível que a média do grupo estiver abaixo da masmorra, −5 pontos; acima, +2 (no máximo +10).
3. **Grupo incompleto:** −20 pontos por seguidor faltando.
4. **Equipamento:** +1 a +7 pontos por peça, pelo nível da peça.
5. **Traços, combos e poção:** os bônus de cada um.

- Abaixo de 5%: o botão Enviar avisa, mas deixa.
- **Acima de 100%:** o que passa vira bônus de recompensa, até 150% (150% = recompensa ×1,5).
- O sorteio usa `KH.Rand` (os testes repetem sempre o mesmo resultado).

### Ao escolher os seguidores (pedido do dono, 18/11)

- **A chance muda na hora** a cada seguidor posto ou tirado do grupo, com o detalhe de onde vem cada ponto e as ameaças
  que ficam riscadas.
- **Recomendados:** na lista de seguidores livres, os que mais ajudam naquela masmorra têm um selo **Recomendado**, e
  cada um mostra quanto a chance sobe se entrar no grupo ("+25%", e qual ameaça ele anula). A lista vem ordenada por
  isso. Ferido ou fora aparece apagado, com o tempo que falta.
- **Grupo sugerido:** monta, entre os seguidores livres dos quartos, o grupo com a maior chance (empatando, o de menor
  nível médio, para os fortes ficarem livres para masmorras mais altas). Com até 7 nos quartos e grupos de até 3 são no
  máximo 63 combinações; a conta é imediata. O jogador pode trocar qualquer um depois.
- **Do Alojamento:** se alguém que está no Alojamento ajudaria mais, a tela avisa ("Paladino Renegado anula Mortos-vivos:
  traga-o para um quarto").

## 7. Combos

Duas habilidades de **seguidores diferentes** no mesmo grupo:

| Combo | Habilidades | Efeito |
|---|---|---|
| Muralha e Cura | Escudo Erguido + Ervas Curativas | ninguém volta ferido |
| Fogo Cruzado | Rajada de Flechas + Bola de Fogo ou Nevasca | +15 pontos de chance |
| Entrada pelos Fundos | Mestre das Fechaduras + Distração | masmorra 25% mais curta |
| Aço Abençoado | Armas de Prata + Água Benta | +20 pontos contra mortos-vivos e troféu garantido em cripta |
| Coro de Batalha | Canção da Coragem + Grito de Guerra | +25% de XP para os seguidores |
| Olhos na Escuridão | Olho de Águia + Contrafeitiço | dobra a chance de achado raro |
| Tempestade | Nevasca + Redemoinho | +25% de moedas |
| Tiro e Escudo | Tiro Certeiro + Escudo Erguido | +10 pontos de chance e +10% contra chefe opcional |

- **Livro de Combos** na Estalagem: os descobertos aparecem com nome e efeito; os outros, como "???" com uma dica
  ("Dizem que um bardo e um ferreiro abrem qualquer porta").
- Um combo é descoberto na primeira vez que um grupo com ele volta de uma masmorra. A tela de envio já mostra o combo
  quando o grupo o forma (depois de descoberto); antes disso mostra "algo especial pode acontecer".

## 8. Recompensas

| | Sucesso | Falha |
|---|---|---|
| Moedas | pela conta da seção 9 | metade |
| XP da vila | pela conta da seção 9 | metade |
| XP dos seguidores | cheio | metade |
| Achados | chance de **troféu** (5% a 20%, maior com o chefe opcional), **insígnia** e **peça de equipamento** | nenhum |

### Drops raros

| Drop | Onde | Para que serve |
|---|---|---|
| **Seguidor novo** | masmorras, raides, resgates (tabela da seção 3.5) | entra no rol |
| **Insígnia de Mérito** | 10% nas masmorras de nível 8 ou mais; seguidor Raro repetido | Incomum → Raro |
| **Insígnia Épica** | 5% nas de nível 19 ou mais; garantida nas raides; Épico ou Lendário repetido | Raro → Épico |
| **Peça com nome** | 2% nas masmorras novas do Forever e 10% nas raides | arma ou armadura única, acima da da Oficina, com o ícone e o nome de um item que cai ali no jogo |
| **Núcleo** | só nas raides | equipamento de nível 7 da Oficina |
| **Troféu** | 5% a 20% em cada masmorra (mais com o chefe opcional) | coleção |

- Toda chance de drop raro sobe com o traço Sortudo, com Sela (Curiosa) e com o combo Olhos na Escuridão.
- **Troféus:** cada masmorra tem 1 ou 2, com o ícone de um item real que cai nela no jogo. Vão para a coleção (S5); até
  lá, aparecem numa lista "Troféus" na Estalagem.
- O custo da viagem continua em peixe: 2 peixes por seguidor por hora de masmorra.

## 9. Economia

As regras da `docs/economia.md` valem: nenhuma atividade rende mais por hora que a Horta.

- **Moedas:** por seguidor e por hora de masmorra, **6% do que a Horta rende por hora** no nível atual da vila. Com os 6
  seguidores sempre fora e sempre com sucesso, as masmorras dão no máximo ~36% da Horta (bônus de 150% e combos
  incluídos, o teto do teste é 50%).
- **XP da vila:** por seguidor e por hora, **0,5% do XP do nível atual**. Uma noite de 8 h com 6 seguidores dá ~24% de um
  nível.
- **Equipamento** custa barras, e as barras custam minério e tempo da Oficina: o valor de mercado das peças segue a regra
  5 (sempre mais que a matéria-prima).
- Hoje uma missão longa paga ~750 moedas fixas, em qualquer nível. Com a regra nova, a recompensa acompanha a vila.
- **Um rol maior não rende mais:** só quem está nos quartos sai, e os quartos são no máximo 7.
- **Chamados:** contam junto com os visitantes no teto dos eventos (`B.EVENTS.capMinutes`); os dois juntos ficam abaixo
  de 20% da Horta.

## 10. Chamados: defesa, ataque, escolta, resgate, reconhecimento

Eventos para os seguidores, no mesmo motor dos visitantes (`Events.lua`): só com o jogo aberto, prazo pelo relógio,
**quem não atende perde só a chance**. Aparecem com a Estalagem aberta, no lugar de alguns visitantes (no máximo 2
eventos abertos, somando os dois).

| Tipo | O que é | Grupo | Duração | Prazo para aceitar | Recompensa |
|---|---|---|---|---|---|
| **Defesa** | um lugar do Forever está sob ataque e pede reforço | 1 a 3 | 30 a 90 min | 45 min | moedas e XP ×1,5 de uma masmorra do mesmo tempo |
| **Ataque** | tomar um acampamento ou uma posição inimiga | 2 a 3 | 1 a 2 h | 2 h | ×2, chance de **peça com nome** |
| **Escolta** | levar uma caravana em segurança | 1 a 2 | 1 h | 2 h | ×1,5, e no sucesso a caravana passa pela vila (um visitante Caravana extra) |
| **Resgate** | tirar alguém de uma prisão ou de um cerco | 2 a 3 | 1 a 2 h | 3 h | ×1,5, e 25% de chance de quem foi salvo virar seguidor |
| **Reconhecimento** | espiar uma masmorra | 1 | 30 min | 2 h | XP, e a masmorra espiada ganha +10 pontos de chance na próxima ida |

- A chance de sucesso funciona como nas masmorras (ameaças, nível, recomendados, grupo sugerido).
- Na falha: metade da recompensa, como nas masmorras. Ninguém perde nada além disso.
- **Cada chamado é de um lugar e de um conflito do Forever** (seção 11). Exemplo do formato: *Defesa · Ruins of
  Lordaeron: "Os Renegados pedem reforço nas ruínas. 1h 20m para aceitar."* O lugar, quem pede e contra quem saem da
  história confirmada; nada é inventado.
- A lista de chamados cresce quando o Forever lança conteúdo novo (as atualizações de primavera e verão de 2027).

## 11. A história do WoW Forever

Regra do dono (18/11): **todo evento tem relação com a história do Forever**. Vale para os chamados, os seguidores
novos, as masmorras e também para os **visitantes que já existem**.

- **Fonte única:** `docs/historia-forever.md` guarda os fatos usados (lugar, povo, conflito), cada um com a fonte: o
  próprio jogo (o dono, que joga o Forever, confirma) ou o anúncio oficial da Blizzard. Guias de fãs servem de pista,
  não de fonte. Texto de evento só usa fato que está lá.
- **O que já se sabe** (anúncio da BlizzCon 2026 e guias, a conferir no jogo): a raça Skyborne, de Zephras Isle;
  paladinos Renegados e xamãs anões; as zonas Riverglades e Mount Hyjal (depois da derrota de Archimonde); as
  masmorras Hall of Thanes, Ruins of Lordaeron, Excavation Site, City of Dalaran, Drowned City, Krol'dok Stronghold,
  Alcaz Island Prison, Blackmaw Hold e Shaper's Terrace; as raides Barrow Deeps e Hyjal Summit, e Onyxia's Lair; o
  campo de batalha Darkspear Island.
- **Visitantes de hoje:** o texto ganha origem no Forever, sem mudar regra nenhuma. Por exemplo, o mercador diz de que
  lugar do Forever vem; a caravana atravessa Riverglades; o mensageiro do pedido urgente vem de um lugar com conflito
  confirmado.
- Quando o Forever lançar conteúdo novo, o addon acompanha numa atualização: masmorras, chamados e seguidores novos.


## 12. Saves que já existem (schema 4)

- Cada seguidor vira **nível = 2 × nível antigo − 1** (o antigo ia de 1 a 5; vira 1 a 9), qualidade Comum, com a
  habilidade e o traço iniciais e sem equipamento.
- Seguidor em missão antiga: volta no horário marcado e recebe a recompensa antiga, como se nada tivesse mudado.
- Os seis de hoje viram Incomuns e ficam nos quartos que a Estalagem já tem.
- Nada mais muda. O teste de migração usa `tests/fixtures/save-1.0.1.lua` e um save da 2.1.

## 13. Testes

- Chance: cada parte da seção 6 com um caso; acima de 100% vira bônus; grupo sugerido escolhe o melhor.
- Combos: cada um aplica seu efeito; o livro registra a descoberta uma vez.
- Economia: simulação de 30 dias com 6 seguidores, em vários níveis da vila: moedas e XP das masmorras abaixo do teto da
  seção 9.
- Ritmo: simulação dos níveis dos seguidores (metas da seção 3.1).
- Ferimento, raide semanal, masmorra do dia, migração.
- Equipamento: toda peça vale mais que suas barras.
- Seguidores novos: chances de drop, garantia depois de 40 masmorras, repetido vira insígnia, rol de no máximo 20.
- Chamados: cada tipo, prazo e expiração; visitantes e chamados juntos abaixo do teto da economia.
- História: todo chamado e todo seguidor novo aponta para um fato de `docs/historia-forever.md`.

## 14. Telas

- **Estalagem**, com quatro abas:
  - **Seguidores:** um cartão por seguidor com retrato (borda na cor da qualidade), nível e barra de XP, habilidades,
    traços, equipamento, estado (em casa, fora, ferido) e o bônus em casa. Clique abre a ficha: talentos, equipar,
    trocar escolhas.
  - **Masmorras:** a lista por nível (as fechadas mostram o nível que pedem). Ao escolher uma: ameaças (anuladas ficam
    riscadas), espaços do grupo, a lista de seguidores livres com o selo **Recomendado** e o "+N%" de cada um,
    **Grupo sugerido**, poção e comida, chefe opcional, a chance (que muda na hora a cada escolha) com o detalhe, a
    recompensa e **Enviar**.
  - Na lista de masmorras, cada uma já mostra a chance do melhor grupo livre agora, para o jogador ver de longe onde
    vale ir.
  - **Ranking:** o rol inteiro pelo Poder, com a cor da raridade, quem está nos quartos e no Alojamento, e "N de 18".
  - **Livro:** combos e troféus.
- **Chamados:** aparecem como os visitantes (alerta no ícone, cartão na tela Visitantes), com o lugar do Forever, quem
  pede, os recomendados e a chance.
- **Seguidor novo:** um cartão de chegada com o retrato, a raridade, de onde veio e um botão "Levar a um quarto".
- **Enquanto você esteve fora:** "Mira e Garrick voltaram de Minas Mortas: sucesso (112%), troféu!".
- **Ícone na tela:** o aviso de quem voltou, como hoje.
- Cartão "como funciona" novo para o Quadro de Masmorras.
- Tudo em EN e ptBR; Novidades da versão.

## 15. Divisão em sprints

### S3 (07/12 a 13/12): masmorras, níveis e talentos → `v2.2.0-alpha1`

| ID | Tarefa | Quem |
|---|---|---|
| T3.1 | Aprovar esta especificação | **Eu** |
| T3.2 | Dados: seguidores, ameaças, habilidades, traços, masmorras em `Balance.lua`; migração schema 4 | Claude |
| T3.3 | Motor: chance, envio, volta, recompensa, ferimento, nível e XP, qualidade e insígnias, talentos, masmorra do dia | Claude |
| T3.4 | Grupo sugerido | Claude |
| T3.5 | Telas: abas Seguidores e Masmorras, ficha do seguidor, linhas do "Enquanto você esteve fora" | Claude |
| T3.6 | Testes de chance, economia e ritmo | Claude |
| T3.7 | Revisão dos textos EN/ptBR (e nomes das masmorras no cliente ptBR) | **Codex** |
| T3.8 | Teste no jogo | **Eu** |
| T3.9 | Correções, Novidades e tag | Claude |

### S4 (14/12 a 20/12): equipamento, combos e raides → `v2.2.0-alpha2`

| ID | Tarefa | Quem |
|---|---|---|
| T4.1 | Equipamento: receitas da aba Equipamento, equipar e trocar, nível na chance | Claude |
| T4.2 | Consumíveis (poção e comida) | Claude |
| T4.3 | Combos e Livro de Combos; troféus | Claude |
| T4.4 | Raides (semanal, Núcleo), Maestria e Título | Claude |
| T4.5 | Testes (equipamento vale mais que as barras, combos, raides) | Claude |
| T4.6 | Revisão dos textos EN/ptBR | **Codex** |
| T4.7 | Teste no jogo | **Eu** |
| T4.8 | Correções, Novidades e tag | Claude |

### S5 (21/12 a 03/01): raridade, seguidores novos e chamados → `v2.3.0-alpha1`

| ID | Tarefa | Quem |
|---|---|---|
| T5.1 | `docs/historia-forever.md`: os fatos do Forever com fonte | Claude + **Eu** (confirma no jogo) |
| T5.2 | Aprovar os seguidores novos (nomes, classes, habilidades) e as ameaças das masmorras novas | **Eu** |
| T5.3 | Retratos dos seguidores novos (no estilo dos seis de hoje, alta resolução) | **Codex** (você aprova), a partir de 07/12 |
| T5.4 | Rol, quartos e Alojamento, raridade, Poder, Ranking; drops e garantia | Claude |
| T5.5 | Chamados (os cinco tipos) no motor dos eventos | Claude |
| T5.6 | Textos dos visitantes de hoje com origem no Forever | Claude |
| T5.7 | Testes (drops, garantia, chamados, teto, história) | Claude |
| T5.8 | Revisão dos textos EN/ptBR | **Codex** |
| T5.9 | Teste no jogo | **Eu** |
| T5.10 | Correções, Novidades e tag | Claude |

Depois da 2.3: coleção (os troféus entram nela), decorações, os quatro atributos do personagem e as temporadas.

## 16. Decisões do dono (aprovadas em 18/11, como propostas)

1. **Estalagem na Vila 30.** Hoje ela abre com a Sede 5. Manter (as masmorras são a camada de meio e fim de jogo) ou
   abrir mais cedo? **Mantida na Vila 30.**
2. **Nível máximo 30 dos seguidores** e as metas de ritmo da seção 3.1.
3. **Raides semanais** (7 dias contados de quando foi feita).
4. **Rol de até 20 seguidores**, com quartos (1 a 7, pelo nível da Estalagem) e Alojamento.
5. **Os 12 seguidores novos** da seção 3.5: arquétipos, raridades e de onde vêm (12 retratos novos para o Codex).
6. **Chances de drop** e garantia de 40 masmorras.
7. **As masmorras novas do Forever** só entram no jogo quando suas ameaças forem confirmadas no jogo.
