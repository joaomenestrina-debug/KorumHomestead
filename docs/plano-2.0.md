# Korum Homestead 2.0: plano de desenvolvimento

## Objetivo

A 1.0 tem o ciclo completo (plantar, colher, vender, construir, fabricar, mandar seguidores), mas falta **motivo para
voltar amanhã** e **meta para as próximas semanas**. A 2.0 resolve isso com cinco ideias, algumas inspiradas no The Crims,
adaptadas para uma vila:

1. **Retorno diário:** resumo do que aconteceu enquanto o jogador esteve fora, encomenda do dia com sequência de dias.
2. **Disposição e Serviços:** uma energia que recarrega com o tempo e é gasta em serviços curtos, com chance de sucesso.
3. **Personagem:** atributos escolhidos a cada nível; seguidores com especialidade, risco e achados raros.
4. **Coleção:** herbário, conquistas e decorações que aparecem no mapa da vila.
5. **Temporadas:** quatro semanas com metas próprias e uma recompensa exclusiva no fim. A vila nunca é zerada.

## Princípios (valem para todas as fases)

- **Nunca castigar quem some.** Nada morre, nada se perde. Ficar dias fora só zera a sequência do dia, nunca o progresso.
- **Tudo por tela.** Toda função tem botão e explicação na janela; comandos são só atalhos.
- **Independente.** Nenhum outro addon, nem os Korum.
- **Ícones de itens do jogo** para tudo o que é item (ervas, produtos, recompensas). Pixel art própria só para lugares,
  decorações e retratos.
- **Inglês e português** em todo texto novo, com o cartão "como funciona" para cada tela nova.
- **Saves antigos continuam funcionando.** Toda mudança de dado tem migração e teste.
- Só WoW Forever (interface 16001).

## Visão geral das fases

| Fase | Conteúdo | Arte nova | Publicação |
|---|---|---|---|
| **F0** | Fundação técnica (UI em arquivos, versão do save, tabela de equilíbrio) | não | interna |
| **F1** | Resumo ao voltar, encomenda do dia, sequência | não | **2.0 alpha 1** |
| **F2** | Disposição e Serviços | não (ícones do jogo) | **2.0 alpha 2** |
| **F3** | Atributos, seguidores com especialidade, risco e achados | não | **2.0 alpha 3** |
| **F4** | Herbário, conquistas, decorações no mapa | **sim** (decorações) | **2.0 alpha 4** |
| **F5** | Temporadas | pouca (selos) | **2.0.0** |
| **F6** | Som e animações (polimento) | não | junto da F5 |
| **F7** | Social com amigos (opcional) | não | **2.1** |

> **Tipo de arquivo no CurseForge.** Toda versão de trabalho da 2.0 sai como **Alpha**, para não tomar o lugar da 1.0.1
> de quem usa a versão estável. O CurseForge decide o tipo pela tag: com `alpha` no nome vira Alpha, com `beta` vira
> Beta, e **sem nenhum dos dois vira Release**. Por isso as tags são `v2.0.0-alpha1`, `v2.0.0-alpha2`... e só a
> `v2.0.0` não tem sufixo. Nunca usar `-rc1` ou outro sufixo sem `alpha`: o CurseForge publicaria como Release.

Cada alpha vai para o CurseForge como **Alpha** (tag `v2.0.0-alpha1` etc.), para jogadores testarem antes da versão final.

---

## F0. Fundação técnica

O `UI.lua` tem ~2.100 linhas e 32 telas e funções. Antes de somar cinco sistemas, vale organizar.

- Dividir a interface: `UI.lua` (janela, navegação, ícone flutuante) e uma pasta `Screens/` com um arquivo por tela
  (`Village.lua`, `Garden.lua`, `Barn.lua`, `Market.lua`, `Hall.lua`, `Workshop.lua`, `Inn.lua`, `Source.lua`,
  `Guide.lua`, `Settings.lua`).
- **Versão do save** (`db.schema = 2`) e um `Migrate.lua` com uma função por versão. Teste: um save da 1.0 abre na 2.0.
- **`Balance.lua`:** todos os números de equilíbrio num lugar só (tempos, custos, chances, recompensas), para ajustar
  sem caçar pelo código.
- **Relógio do dia:** uma função `KH.Day()` (o dia local, virando à meia-noite) usada por tudo o que é diário.
- Simulador: uma cena para cada tela nova, e as capturas de tela do CurseForge refeitas no fim de cada fase.

**Pronto quando:** os testes atuais passam sem mudar, o save da 1.0 migra, nenhuma tela mudou de aparência.

## F1. Retorno diário

### Resumo ao voltar
- Ao abrir a janela depois de mais de 30 min fora (ou ao entrar no jogo), um cartão "Enquanto você esteve fora":
  canteiros prontos, minério e peixe produzidos, poções feitas, seguidores de volta, obras terminadas, Disposição cheia.
- Um botão "Coletar tudo" que colhe o que está pronto e recolhe os seguidores.
- Dado novo: `db.lastSeen` (hora da última vez que a janela foi vista) e uma fotografia dos contadores.

### Encomenda do dia e sequência
- Uma encomenda especial por dia, no topo do Mercado, com recompensa maior (moedas, XP e, a cada 7 dias, um item raro).
- **Sequência:** dias seguidos entregando a encomenda do dia. Prêmio extra no dia 3, 7, 14 e 30. Perder um dia volta a
  sequência para zero; o recorde fica guardado.
- O ícone flutuante mostra um ponto quando a encomenda do dia está esperando.
- Dados: `db.daily = {day, order, done, streak, best}`.

**Pronto quando:** a encomenda troca à meia-noite, a sequência conta e zera certo (testes com o relógio adiantado), o
resumo mostra os números certos depois de 8 h fora.

## F2. Disposição e Serviços

O segundo ritmo do jogo, mais curto que o das plantas, pensado para a fila de masmorra.

- **Disposição:** barra no cabeçalho, ao lado das moedas. Máximo 10, recarrega 1 a cada 12 min (cheia em 2 h), também
  com o jogo fechado. Nível de vila mais alto aumenta o máximo.
- **Quadro de Serviços** (botão no cabeçalho e cartão na Sede): 6 serviços, 3 visíveis por vez, trocando de hora em hora.

| Serviço | Disposição | Chance base | Recompensa |
|---|---|---|---|
| Ajudar na colheita do vizinho | 1 | 90% | moedas e ervas |
| Caçar pragas no bosque | 2 | 75% | moedas, XP |
| Escoltar uma carroça | 3 | 65% | moedas, minério |
| Pescar no rio grande | 2 | 80% | peixe |
| Entregar remédios na vila vizinha | 3 | 70% | XP, chance de receita |
| Explorar uma ruína | 5 | 50% | chance de item raro |

- Falhar gasta a Disposição e paga um consolo pequeno (nunca tira nada).
- A chance cresce com os atributos (F3); antes disso, com o nível de Herbalismo.
- Ícones: itens do jogo (ex.: foice, espada, carroça, vara de pesca, poção, mapa).
- Dados: `db.energy = {value, at}`, `db.board = {seed, at}`.

**Pronto quando:** a barra recarrega certo com o jogo fechado, as chances batem com a tabela (teste com sorteio fixo), o
cabeçalho cabe com a barra nova.

## F3. Personagem

### Atributos
- A cada nível de Herbalismo, 1 ponto para distribuir em quatro atributos:
  - **Mãos verdes:** colheitas maiores, plantas mais rápidas.
  - **Lábia:** encomendas pagam mais, vendas melhores.
  - **Ofício:** Oficina mais rápida, chance de fabricar em dobro.
  - **Liderança:** seguidores pagam mais e se machucam menos.
- Cada ponto vale pouco (+2% a +3%); a graça é a soma ao longo dos níveis.
- Redistribuir custa moedas (sobe a cada vez), na tela do personagem.
- Saves antigos recebem os pontos dos níveis que já têm.

### Seguidores com especialidade
- Cada um dos seis tem um ofício que dá um bônus enquanto está **em casa**:

| Seguidor | Especialidade | Bônus em casa |
|---|---|---|
| Mira | arqueira | serviços de caça +10% de chance |
| Tobin | ferreiro | Ferraria 10% mais rápida |
| Elda | herborista | Horta 5% mais rápida |
| Garrick | guerreiro | escolta +10% de chance |
| Sela | maga | Alquimia 10% mais rápida |
| Bram | bardo | encomendas +5% de moedas |

- Mandar em missão vira escolha: o seguidor traz moedas, mas o bônus some enquanto ele está fora.
- **Risco:** a missão longa tem 15% de chance de o seguidor voltar ferido e descansar 2 h na Estalagem (Liderança
  diminui). Ele volta com o pagamento normal; ferido só não pode sair de novo.
- **Achados raros:** 5% (média) e 12% (longa) de voltar com um item raro da coleção (F4) ou uma receita.

**Pronto quando:** os bônus aparecem nas telas (o número já com o bônus e de onde vem), a migração dá os pontos certos.

## F4. Coleção, conquistas e decorações

### Herbário
- Uma tela-álbum com tudo o que existe: as 13 ervas, as 9 receitas, os 11 produtos, os itens raros. O que ainda não foi
  visto aparece em silhueta. Contador "34 de 52".
- **Itens raros** (~12): ervas douradas (chance pequena na colheita), achados de missão e de serviços. Ícones do jogo.

### Conquistas
- ~40 marcos em grupos (Horta, Mercado, Construção, Oficina, Estalagem, Serviços, Sequência). Exemplos: "Colha 100
  Botão-da-paz", "Sede no nível 7", "Sequência de 14 dias", "Todos os ofícios no máximo".
- Cada conquista dá pontos de vila; marcos de pontos liberam decorações e títulos.

### Decorações no mapa
- ~10 decorações em pontos fixos do mapa (fora das oito construções): poço, cerca florida, estátua, lanternas, carroça,
  espantalho, fonte, árvore grande, banca de flores, bandeira de outra cor.
- Uma tela simples para ligar e desligar cada uma.
- **Arte:** pedido ao ChatGPT no mesmo estilo das construções (kit com medidas, como nas rodadas anteriores) e as
  posições no mapa definidas antes.

**Pronto quando:** coleção e conquistas contam desde o save antigo (o que já foi feito conta), as decorações aparecem no
mapa nas posições certas.

## F5. Temporadas

- Temporadas de **28 dias**, num calendário fixo (contado a partir de uma data, sem servidor).
- Cada temporada tem **metas semanais** (3 por semana, sorteadas pelo número da temporada) que dão **pontos de temporada**.
- Faixas de prêmio por pontos: título, uma decoração **exclusiva daquela temporada** e um selo no perfil.
- No fim, a temporada vai para o histórico. A vila, as moedas e as coleções continuam; só os pontos recomeçam.
- O cabeçalho mostra "Temporada 3 · faltam 9 dias".

**Pronto quando:** a virada de temporada funciona com o relógio adiantado, as metas da semana trocam certo, os prêmios
são dados uma vez só.

## F6. Som e animação (polimento)

- Sons do próprio jogo (kits de som) para colher, vender, terminar obra, subir de nível, serviço bem e mal sucedido.
  Opção para desligar.
- Animações: moedas voando para o contador, brilho na construção que terminou a obra, comemoração ao subir de nível.

## F7. Social com amigos (opcional, 2.1)

- Por mensagens de addon do próprio jogo, entre jogadores que têm o Homestead: ver o resumo da vila de um amigo, mandar
  uma ajuda por dia (uma semente rara) e comparar os pontos da temporada.
- Antes de começar, confirmar no jogo que o Forever aceita mensagens de addon e o limite de envio.

---

## Testes e verificação

- Testes automáticos para cada sistema, com o relógio controlado (dias, temporadas, recarga com o jogo fechado).
- Teste de migração: um save da 1.0 (gravado agora como amostra) abre em cada alpha.
- Simulador: capturas de todas as telas novas, revisadas antes de cada alpha.
- **No jogo**, antes de cada alpha: lista curta do que conferir (o que o simulador não mostra: ícones do jogo, sons,
  fontes, desempenho).

## F-Eventos. Visitas e achados aleatórios (ideia do dono, 17/11; a encaixar no cronograma)

De vez em quando acontece algo na vila, avisado **no ícone flutuante como alerta** (e no cartão "Enquanto você esteve
fora"):

- **Pedido urgente:** um NPC aparece com uma encomenda de prazo curto que paga bem.
- **Caravana de troca:** troca itens por outros (ervas por minério, peixe por poções...), por algumas horas.
- **Mercador generoso:** paga mais por um item específico enquanto está na vila.
- **Achados raros:** um peixe diferente na Lagoa, um mineral raro na Mina, uma erva rara num canteiro (itens do jogo,
  com ícone do jogo; vão para o Celeiro e para o Herbário da F4).

Regras: perder um evento não castiga (ele só vai embora); as recompensas passam pela conta da economia (trocas, XP e
itens antes de moedas); frequência baixa, sorteada com semente fixa para os testes (`KH.Rand`).

## Equilíbrio

Os números deste plano são o ponto de partida. A rodada de ajuste foi **adiantada para o início da S2 (T2.0)**: a soma de
quanto se ganha por hora em cada atividade e em cada nível, contra o custo da vila (~194 mil moedas para tudo no máximo).

Medido em 17/11: no Herbalismo 20, uma encomenda normal paga ~10 mil moedas e a Horta rende ~9.600 por hora, ou seja, a
vila inteira sai em ~20 horas. Regra a partir de agora: **excesso de moedas é o risco nº 1 de equilíbrio**. Recompensas de
hábito (sequência, conquistas, temporadas) dão XP, itens e enfeites, não moedas; serviços não rendem mais que a Horta.

## Riscos

- **Interface cheia:** cinco sistemas novos numa janela de 720 x 600. Cada um entra por um lugar só (cabeçalho, Sede ou
  Mercado), e as telas novas seguem o mesmo padrão das atuais.
- **Arte das decorações:** depende da rodada com o ChatGPT. As outras fases não dependem dela.
- **APIs do Forever:** som e mensagens de addon precisam ser conferidos no jogo antes da F6 e da F7.

## Ordem de trabalho sugerida

F0 → F1 (alpha 1) → F2 (alpha 2) → F3 (alpha 3) → pedido de arte das decorações em paralelo → F4 (alpha 4) → F5 + F6
(2.0.0) → F7 (2.1).
