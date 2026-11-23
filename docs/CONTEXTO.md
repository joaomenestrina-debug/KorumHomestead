# Contexto do projeto: onde estamos e para onde vamos

**Leia antes [`conhecimento.md`](conhecimento.md) (a base de conhecimento) e depois este arquivo, antes de qualquer trabalho no Korum Homestead.** Ele existe para ninguém precisar reler o projeto
inteiro. Quem terminar uma tarefa atualiza as seções 1 e 2 no mesmo commit/pull request.

*Última atualização: 22/11/2026, falas T6.11 e arte A11 preparadas para análise.*

---

## 1. Onde estamos

| | |
|---|---|
| **Versão publicada** | **2.1.0** no CurseForge (Release, 19/11, a pedido do dono) — visitantes, arte nova, Véu de Inverno, minimapa com o logo. Antes: 2.0.0 (Release, 17/11) e as alphas `v2.1.0-alpha1` a `alpha6` (18–19/11). Próximo pacote: domingo, como `v2.2.0-alphaN` ou `v2.1.1` |
| **Em desenvolvimento** | **2.2 e 2.3: masmorras e seguidores** (especificação **aprovada em 18/11** em [masmorras.md](masmorras.md); fatos do Forever em [historia-forever.md](historia-forever.md)). Cronograma em [cronograma-2.0.md](cronograma-2.0.md) (reescrito em 18/11); plano antigo em [plano-2.0.md](plano-2.0.md) |
| **Sprint atual** | **S3 a S5 adiantadas no ramo `claude/masmorras`** (pedido do dono em 19/11: fazer as três, testar na cópia dele e soltar tudo numa alpha só, `v2.2.0-alpha1`). **S3 feita no ramo:** `Dungeons.lua` (seguidores 1–30, qualidade, insígnias, chance, grupo sugerido, masmorra do dia, ferimento), `Journal.lua` (Diário), `UI/Inn.lua` (abas Seguidores e Masmorras, ficha, montagem do grupo), schema 4. A `main` segue com a 2.1.0. **S4 feita no ramo:** equipamento (aba Equipamento da Oficina), poção e comida, combos e Livro, troféus, chefe opcional, Onyxia semanal com Núcleo, Maestria (Veterano ou Mentor) e Título, Aventura parte 1 (`Adventure.lua`: fila abre a vila, chefe inspira, opção nos Ajustes). **S5 feita no ramo (19/11):** rol com quartos (um por nível da Estalagem, até 7) e Alojamento; aba Ranking (Poder, "N de 18", mover e trocar); os 12 seguidores novos do A8 (`B.FOLLOWERS` com `from`), que só vêm do seu lugar: masmorra (1%/2%/3%), raide (Lendário 2%) ou chamado de resgate (25%), garantia de um Raro depois de 40 masmorras, repetido vira insígnia, cartão de chegada; peças com nome da Onyxia (Quel'Serrar e Manto de Escamas de Onyxia, +9); chamados (defesa, ataque, escolta, resgate, reconhecimento) no motor dos eventos (`Events.lua`, `B.CALLS`, `B.PLACES`); visitantes com origem no Forever; Aventura parte 2 (zona conta depois de 5 min, 2 h por zona, 30 min geral; raide morta dá +10% de seguidor novo). **Decisões provisórias a confirmar com o dono:** Tazu sai do resgate na Cidade Afogada, Faelan e Shalendra do resgate na Gruta Bocanera (o conflito de Monte Hyjal e das Ilhas Lançanegra não está no Wowhead); os novos chegam no nível do lugar de onde vieram; o ataque dá chance de Insígnia de Mérito (não há peça com nome fora da Onyxia); a raide não tem Épico próprio (só a Lendária Ilyanna); o Deathbringer e os elmos T2 não existem no Wowhead do Forever. **Falta:** teste do dono e a alpha única. **Ajustes do teste do dono (19/11):** a chance da lista é a da montagem (opções não passam de uma masmorra para outra); ameaça sem resposta tira 10/15/20 nas masmorras até o nível 3/6/9; **trabalho**: a Mina e a Lagoa têm uma vaga para um seguidor em casa (+10%; Mineiro ou Pescador +25%; `B.JOBS`, `Inn:Work`), que não sai enquanto trabalha. Horta, Oficina e Mercado ficam para depois. **Mais pedidos do dono em 20/11:** o Celeiro avisa a partir de 80% e a colheita guarda o que couber (o resto espera no canteiro); cartão de **resultado** de cada grupo que volta (`Dungeons.results`, na Estalagem); **lembrete** num voo ou numa fila (`UI/Reminder.lua`, `Adventure:Remind`): um cartão pequeno com o que espera, no lugar de a janela abrir sozinha. O `instalar.py` dos outros addons aponta temporariamente para `KorumHomestead-claude`: voltar para a pasta principal quando o ramo entrar na `main`. Também em 20/11: comida soma +5% à chance; depois de enviar, a lista de masmorras fica aberta; Oficina com as receitas em cards lado a lado, uma fila por ofício (todas ao mesmo tempo) e fila com rolagem; Celeiro com abas (Ervas, Recursos e um por ofício), o botão grande vende a aba, e a lista rola |
| **Próximo marco** | **`v2.2.0-alpha1`** em 22/11 (S3 a S5 juntas, testadas pelo dono). Próximo pacote: domingo 29/11 |
| **`main`** | jogável, testes verdes; instalada no WoW Forever de teste |
| **Arte A6** | Aprovada e no jogo, a partir de `arquivo/arte_v5/*@hd.png`, reduzida para perto do tamanho de tela (prédios 256, retratos 128, mapa 1024×512); o logo segue o antigo em pixel (ícones pequenos: simples, poucas cores) |
| **T2.8** | Textos EN/ptBR de eventos revisados; PR aguardando revisão |
| **A7** | Véu de Inverno **aprovado em 19/11** e na `main` (`arquivo/arte_v6/`: `map_winter`, `winter_tree`, `snowman`, `gifts`); **no jogo desde 19/11** (`Festivals.lua`: de 15/12 a 02/01 a vila usa `map_winter` e mostra o pinheiro, o boneco e o trenó; `/kh festa` com o debug ligado mostra fora da data) |
| **A8** | Doze retratos dos novos seguidores **aprovados em 19/11** e na `main` (`arquivo/arte_v6/follower7..18@hd.png`); Claude importa para o jogo na S5, quando o código usar |
| **T6.11** | Falas EN/ptBR dos cinco personagens prontas na branch `codex/T6.11-voices`; PR para `claude/masmorras` aguarda análise |
| **A11** | 9 ícones de conquistas e 5 retratos aprovados pelo dono e no jogo (22/11, PR 24) |

### Sprint 1: andamento (alpha1 em 29/11)

| Tarefa | Quem | Estado |
|---|---|---|
| T1.1 Especificação e briefings T1.4, T1.6, T1.7 | Claude | ✅ em `docs/tarefas/` |
| T1.2 Aprovar prêmios da sequência | Eu | ✅ 17/11: aprovada a proposta de `T1.4.md` (`B.DAILY`) como está |
| T1.3 Resumo ao voltar (lógica, `Away.lua`) | Claude | ✅ |
| T1.4 Encomenda do dia e sequência (`Daily.lua`) | Codex | ✅ PR #7 |
| T1.5 Telas: cartão "Enquanto você esteve fora", encomenda do dia no Mercado, ponto no ícone | Claude | ✅; textos ptBR revisados na T1.6 |
| T1.6 Textos EN/ptBR da F1 + Novidades | Codex | ✅ PR #9 |
| T1.7 Cenas do simulador da F1 | Codex | ✅ PR #10 |
| T1.8 Revisão, integração e build no jogo | Claude | ✅ 17/11 |
| T1.9 Teste no jogo da F1 | **Eu** | **agora** (era 28/11) |
| T1.10–T1.11 Correções e tag `v2.0.0-alpha1` | Claude + Eu | ✅ 17/11: testada pelo dono, tag criada (com a economia nova) |

### F2.0 Economia: andamento (proposta aprovada em `docs/economia.md`)

| Tarefa | Quem | Estado |
|---|---|---|
| T2.0 / T2.0b Proposta e aprovação | Claude + Eu | ✅ 17/11 |
| T2.0a Nível da Vila 1–60 e as 27 ervas | Claude | ✅ PR (branch `claude/T2.0a-vila`; entra na `main` depois da tag alpha1) |
| T2.0b2 Migração `schema 3` | Claude | ✅ junto da T2.0a (save real → Vila 37) |
| T2.0c Mercado 4 + 4 e Oficina pagando mais | Claude | ✅ PR #15 (empilhada na T2.0a) |
| T2.0d Prédios com nível mínimo e custos pela renda + escada de 21 receitas (aprovada 17/11) | Claude | ✅ PR (empilhada na T2.0c) |
| T2.0e Telas | Claude | quase pronta: Mercado 4 + 4, sementes, Guia e Oficina com janela, "Vila N"; falta revisar no jogo |
| T2.0f Revisão dos textos | Codex | ✅ revisão EN/ptBR pronta para revisão |
| T2.0g Teste de simulação | Claude | depois da T2.0d |
| T2.0h Teste no jogo | Eu | ✅ 17/11 |

### Sprint 0: concluída

| Tarefa | Quem | Estado |
|---|---|---|
| T0.1 Desenvolvimento no repositório próprio | Eu | ✅ |
| T0.2 Testes no GitHub Actions | Claude | ✅ |
| T0.3 Instalador lendo deste repositório | Claude | ✅ |
| T0.4 Amostra do save real (`KorumHomestead.lua` do WTF) | Eu | ✅ em `tests/fixtures/save-1.0.1.lua` |
| T0.5 Briefings T0.6, T0.8, T0.9 | Claude | ✅ |
| T0.6 `UI.lua` dividido em `UI/` | Codex | ✅ PR #1 integrado |
| T0.7 `db.schema` + `Migrate.lua` | Claude | ✅ PR #2 |
| T0.8 `Balance.lua` | Codex | ✅ PR #4 |
| T0.9 `KH.Day()` | Codex | ✅ PR #3 |
| T0.10 Revisão e integração | Claude | ✅ |
| T0.11 Teste de regressão no jogo | Eu | ✅ 17/11: save migrado para schema 2, nada perdido, telas ok |

## 2. O que fazer agora (por pessoa)

- **Eu:** 28/11: testar a alpha2 na sua cópia; até 05/12: o teste do T3.0 (`/kh debug`, `/kh eventos`). Respostas de 25/11 já dadas (sim para tudo).
- **Codex:** T6.11 concluída: falas EN/ptBR dos cinco personagens na branch `codex/T6.11-voices`, PR para `claude/masmorras` aguardando análise; as duas verificações que esperam o comportamento anterior sem falas foram registradas no PR. A11 pronta: 9 ícones de conquistas e 5 retratos em `arquivo/arte_v7/`, branch `codex/A11-achievements`, PR para `claude/masmorras` aguarda aprovação do dono. Não escrever código.
- **Claude:** T2.10 feita (teto de 20 min de Horta no pedido urgente e no mercador, `docs/eventos.md` §8). T2.8 integrada, com "XP" padronizado e o peixe raro com chave própria (`firefin`). Tag `v2.1.0-alpha2` criada em 18/11; `v2.1.0-alpha3` também, só para tirar o `/kh debug` e o `/kh evento` do zip (entre `--@debug@`, o empacotador comenta). Especificação das masmorras e seguidores escrita em 18/11 (`docs/masmorras.md`, com `docs/historia-forever.md`). Aprovada em 18/11; a Aventura (a vila reage ao que o personagem faz) e o Diário dos seguidores entraram depois (§12 e §13). Tag `v2.1.0-alpha4` criada em 19/11 (logo no minimapa, dica e número iguais aos do ícone, caminho do topo no inglês). Comando do T3.0 pronto: `/kh debug` e depois `/kh eventos` (`Probe.lua`, só na cópia do repositório). Briefings A7 e A8 escritos em 19/11. Próximo: o dono testa o T3.0 numa masmorra, numa fila e numa troca de zona; A7 no jogo e tag `v2.1.0-alpha5` em 19/11 (Véu de Inverno); tag `v2.1.0-alpha6` em 19/11 (pedidos só de itens da tela da Oficina, trenó maior); **2.1.0 publicada como Release em 19/11** a pedido do dono (as novidades das alphas aparecem sob um título só, "Versão 2.1.0").

## 3. Decisões tomadas (não reabrir sem motivo novo)

| Data | Decisão |
|---|---|
| 17/11 | O Homestead é desenvolvido **neste repositório** (`C:\AI\Code\KorumHomestead`, GitHub público). O monorepo dos outros addons não tem cópia; o instalador de lá lê daqui. |
| 17/11 | Só **WoW Forever** (interface 16001). |
| 17/11 | Licença **All Rights Reserved**. |
| 17/11 | **Ícones de itens do jogo** para tudo o que é item; pixel art própria (do dono com o ChatGPT, ou do Codex, sempre aprovada pelo dono) só para lugares, mapa, decorações, retratos e logo. |
| 17/11 | Versões de trabalho da 2.0 saem como **Alpha** no CurseForge (tag `v2.0.0-alphaN`). Só `v2.0.0` sem sufixo. Nunca `-rc`. |
| 17/11 | Tudo público sai assinado como **Korum**: autor dos commits `Korum`, sem `Co-Authored-By`, sem citar IA. |
| 17/11 | O "What's new" do CurseForge vem do `CHANGELOG.md` (`manual-changelog` no `.pkgmeta`). Desde 19/11 cada versão tem o texto em inglês e, logo abaixo, `### Em português` com o mesmo conteúdo. |
| 17/11 | Nada castiga quem fica fora; progresso nunca se perde. Saves antigos sempre abrem. |
| 17/11 | **Cuidar do excesso de moedas.** A encomenda do dia paga 2,5× uma encomenda normal (o dobro de ervas × 1,25 por erva); os prêmios da sequência são XP e Lótus Negra, **nunca moedas**. Nenhuma recompensa nova dá moedas sem passar pela conta da economia (T2.0). |
| 19/11 | **2.1.0 publicada como Release** a pedido do dono. Na tela de Novidades, entradas da mesma versão ficam sob um título só (as alphas guardam seus ids, quem testou vê só o que veio depois). |
| 17/11 | **2.0.0 publicada como Release** a pedido do dono (alpha1 + economia + correções). O que vem depois sai como **2.1** (eventos: `v2.1.0-alphaN`, depois `v2.1.0`). |
| 17/11 | **Arte em alta resolução** (pedido do dono): nada de reduzir à grade antiga. Entrega como `nome@hd.png` (construções 512x512, mapa 1024x512, retratos 256x256); o importador põe no jogo como está. |
| 17/11 | **Eventos** aprovados (`docs/eventos.md`): só com o jogo aberto, 1 a cada 45–120 min, no máximo 2; 5 tipos; carrinho no mapa + tela Visitantes. |
| 17/11 | **Eventos aleatórios** entram na S2 no lugar dos Serviços (a Disposição fica suspensa). Evento não atendido: perde a oportunidade e o XP, nada além disso. |
| 17/11 | A alpha1 e a economia (F2.0) saem **juntas** num build só (`main` desde e77d8d5). |
| 17/11 | **Papéis:** Claude faz **todo o código** (lógica, telas, testes, simulador, textos EN/ptBR). O Codex faz **só arte** (pixel art a partir do kit de arte, aprovada pelo dono) **e revisão de texto**. |
| 17/11 | **Economia da 2.0** aprovada (`docs/economia.md`): Nível da Vila 1–60; ervas na perícia do jogo ÷ 5; colher dá pouco XP; a Oficina sempre dá mais moedas e XP; Mercado 4 + 4; prédios pedem nível da vila e custam horas de renda. |
| 18/11 | **Masmorras e seguidores** no lugar da F3 original (especificação aprovada, decisões da §18 como propostas; regras em `docs/masmorras.md`): masmorras do WoW Forever, ameaças e habilidades, nível 1–30, qualidade e talentos, equipamento da Oficina, combos, raides, raridade e seguidores novos, chamados. S3 e S4 → 2.2; S5 → 2.3. Atributos do personagem, temporadas, coleção e decorações ficam para depois. |
| 18/11 | **A vila acompanha a aventura do personagem** (só lendo eventos do jogo, nunca mudando nada nele; tudo é bônus e pode ser desligado) e os seguidores têm um **Diário**; a vila se enfeita nas festas do jogo (`docs/masmorras.md` §12 e §13). |
| 19/11 | **Wowhead do Forever** (https://www.wowhead.com/forever/pt) é fonte válida para qualquer informação do jogo (nomes ptBR, quem está em cada masmorra, raças). |
| 19/11 | **Simulador com a fonte e os ícones do jogo:** `ferramentas/icones_do_jogo.py` lista o que o addon mostra e dá o comando que copia do WoW Forever instalado (CASCConsole) para `C:/AI/Tools/wowf_extract`; `simulador_ui.py` usa essa pasta. Os arquivos da Blizzard ficam só no PC do dono, nunca no repositório. As telas servem também para a página do CurseForge. |
| 19/11 | **Um pacote de atualização por semana:** as mudanças se juntam na `main` (com News e CHANGELOG da próxima versão) e sai uma tag só, no domingo, com tudo da semana. Tag no meio da semana só para problema que impede jogar ou risco real. |
| 19/11 | **O que o Wowhead do Forever não tem ainda não existe no jogo:** masmorras, raides e fatos sem dados lá ficam fora do addon até aparecerem; ninguém confere no jogo (T3.0d dispensado). |
| 19/11 | **Origens provisórias** de 4 seguidores novos enquanto o conteúdo deles não sai: Elandor no resgate de Alcaz, Ilyanna na raide Onyxia, Shalendra nos chamados da zona Monte Hyjal, Hargrim como drop raro no Salão dos Thanes (`masmorras.md` §3.5). |
| 19/11 | **Trocar de zona não gera eventos** (`docs/masmorras.md` §12): a zona só conta depois de 5 min nela; entrar nunca cria evento na hora, só dá prioridade no próximo sorteio, no máximo uma vez a cada 2 h por zona e com 30 min de recarga geral; a fila abre a vila no máximo a cada 10 min; inspiração de chefe não acumula. |
| 18/11 | **Todo evento tem relação com a história do WoW Forever.** Fonte única: `docs/historia-forever.md`; texto de evento só usa fato que está lá, confirmado no jogo ou em anúncio oficial. |
| 18/11 | O `/kh debug` e o `/kh evento` ficam entre `--@debug@` e `--@end-debug@`: só existem na cópia do repositório. |
| 17/11 | Toda mudança que o jogador percebe ganha linha na tela **Novidades** (`News.lua` + `news<id>_<n>` no `Locales.lua`). A tela abre sozinha uma vez ao logar depois da atualização; save novo não vê novidades antigas. A entrada 1 é a `2.0.0-alpha1`: as tarefas da S1 acrescentam linhas nela. |
| 22/11 | **Sem ranking online** por enquanto (decisão do dono). Pesquisa feita: addon não acessa a internet; os caminhos seriam mensagens de addon (guilda; canal próprio a testar no Forever; contas trial não enviam), código de exportação para um site, ou programa no PC como o Raider.IO. Qualquer pontuação do save pode ser editada. Retomar só se o dono pedir. |
| 22/11 | **Trabalho em todas as construções** (pedido do dono): Mina, Lagoa, Horta (planta mais rápido), Oficina (fabrica mais rápido) e Mercado (vendas e encomendas pagam mais, bônus ×0,4) têm uma vaga cada, na aba Trabalho da Estalagem. Qualquer seguidor dá +10%, quem tem o ofício +25% (Jardineiro: Elda, Faelan, Shalendra; Artesão: Hoderik, Elandor; Negociante: Corvo, Sela). Quem está no Alojamento pode trabalhar. Próximos, a especificar: missão pessoal (níveis 10/20/30) e amizade que cresce. |
| 22/11 | **Conquistas** como as do WoW (pedido do dono): 55 marcos em nove categorias, todas visíveis com o que pedem e quanto falta; um save antigo ganha as suas em silêncio, com uma linha no chat; o Mestre do Homestead pede todas. Tudo feito depois da alpha1 sai no domingo 29/11 (`v2.2.0-alpha2`). Cronograma reescrito. |
| 22/11 | O dono **aprovou** a missão pessoal (níveis 10/20/30: traço, peça com nome, Título) e a amizade (laço 1–3 com 5/15/30 idas, +2% por nível, combo +50% por nível), e **confirmou** as decisões provisórias da S5. **Cinco personagens** no lugar de um prefeito, porque o jogador é o dono da vila (`docs/personagens.md`): Intendente Ambrósio, Capataz Dorota, Escrivão Tibério, Mordomo Fenwick e Conselheira Marga comentam os avisos da sua parte (`KH.Say`, `Voices.lua`, chaves `say_<momento>_N`), desligável nos Ajustes; o Codex escreve as falas (T6.11) e desenha um ícone por categoria de conquista (9) e os cinco retratos (A11). **Base de conhecimento** em `docs/conhecimento.md` (fora do zip, como toda a `docs/`). |

## 4. Mapa do código

O addon está na **raiz**; a ordem de carga é a do `KorumHomestead.toc` (os testes e o simulador leem a lista de lá).

| Arquivo | Responsabilidade |
|---|---|
| `Kit.lua` | kit visual próprio (janela, botões, textos, cores, barras, animações) — cópia independente |
| `Core.lua` | `KH`, padrões do save `KorumHomesteadDB`, eventos, `KH.Now()`, `KH.Day()` (dia local), `KH.UntilNextDay()`, `/kh` |
| `Migrate.lua` | `KH.SCHEMA` (versão do formato do save) e as migrações, aplicadas ao carregar, antes dos padrões |
| `Locales.lua` | todos os textos, `enUS` e `ptBR`, via `KH.T("chave")` |
| `News.lua` | as entradas da tela Novidades (`KH.NEWS`), `db.newsSeen`; `UI/News.lua` é a tela e a abertura ao logar |
| `Balance.lua` | **todos os números do jogo** (ervas, encomendas, construções, produtos, receitas, Estalagem, início): ajuste de equilíbrio é aqui |
| `Data.lua` | as ervas (tabela vem do `Balance.lua`), nome e ícone vindos do jogo |
| `Farm.lua` | plantar, colher, vender ervas, encomendas do Mercado |
| `Daily.lua` | encomenda do dia e sequência (`db.daily`, prêmios em `B.DAILY`) |
| `Village.lua` | construções, níveis, obras, Mina e Lagoa, produtos (`GOODS`, `ITEM` = ícones), Celeiro |
| `Works.lua` | Oficina (3 ofícios, fila) e Estalagem (seguidores, missões) |
| `Away.lua` | resumo "Enquanto você esteve fora": `db.lastSeen` + `db.snapshot`, `Away:Mark/Summary/CollectAll` |
| `UI/Common.lua` | `KH.UI`, helpers compartilhados em `UI.P` (Screen, Notice, GoodTex, BuildingArt...) |
| `UI/Window.lua` | a janela, navegação, cabeçalho, cartão "como funciona", `UI:Tick` |
| `UI/<Tela>.lua` | uma tela cada: Village (mapa), Garden, Barn, Market, Hall (+ Mina/Lagoa), Workshop, Inn, Guide, Settings; cada uma registra `P.builders.<id>` |
| `UI/Away.lua` | o cartão "Enquanto você esteve fora" (abre ao abrir a janela; fechar a janela marca a hora) |
| `UI/Bubble.lua` | ícone flutuante e notificações |
| `UI/Minimap.lua` | botão do minimapa |
| `Media/` | `Village/` (construções, mapa, seguidores), `Icons/` (formas do Kit), `logo.tga` |
| `tests/` | `test_homestead.py`, `test_migrate.py` (saves antigos), `client_mock.py` (cliente falso), `fixtures/` (saves reais de versões antigas) |
| `ferramentas/` | `simulador_ui.py` (capturas), `importar_arte_homestead.py`, `curse_homestead.py` |
| `arquivo/arte_v3/` | fontes da pixel art (PNG) |
| `docs/` | este arquivo, plano, cronograma, economia, `tarefas/` (especificações das tarefas e pedidos de arte/revisão) |

## 5. Como trabalhamos (resumo)

- **Regras de código e do projeto:** [AGENTS.md](../AGENTS.md) (vale para todos, não só para o Codex).
- **Fluxo:** briefing em `docs/tarefas/T-x.y.md` → branch `codex/...` ou `claude/...` → pull request → testes verdes no
  GitHub → revisão de Claude → integração na `main` → teste no jogo no sábado.
- **Comandos:** `python -m pytest tests -q` · `python ferramentas/simulador_ui.py` ·
  instalar no jogo: `python "C:\AI\Code\Addons WOW\ferramentas\instalar.py" --apply forever`.
- **Publicar:** só Claude cria tags. Tag `v2.0.0-alphaN` → webhook → CurseForge empacota como Alpha.
- **Papéis:** Claude escreve todo o código e os textos; o Codex só faz arte e revisa textos (ver `AGENTS.md`).
- **Pasta compartilhada:** Codex e Claude podem trabalhar nesta mesma pasta. Antes de commitar, conferir o branch
  (`git branch --show-current`) e não usar `git add -A` com arquivos de outro.

## 6. Pendências e riscos conhecidos

- **Ideia nova do dono (17/11): eventos aleatórios** (pedido urgente, caravana de troca, mercador generoso, peixe/mineral raro), avisados no ícone: descrita no `plano-2.0.md` (F-Eventos), entra na S2 (alpha2) no lugar dos Serviços (decisão de 17/11).
- `python ferramentas/conferir_textos.py` confere se algum texto sai da janela, do seu botão ou da sua linha, se é cortado com reticências ou se sobrepõe a outro (fonte do jogo ~18% mais larga que a do simulador). Roda as cenas do simulador e mais ~120 estados (vila no topo com números enormes, mouse em cada construção, cada ofício, cada ficha em cada escolha, cada masmorra com grupo, cada visitante, cada lição), nas duas línguas. **Tem de dar 0 antes de cada instalação e de cada build**; uma tela ou um estado novo ganha cena em `extras()`. `python ferramentas/conferir_textos.py PASTA` guarda as imagens dos estados extras. Texto em lugar de largura fixa usa `Kit.Fit` (encolhe a letra); os rótulos dos botões já passam por ele.
- Ainda não visto no jogo: ícones de itens nos produtos (1.0.1), Celeiro com muitos itens, fila da Oficina com "+N".
- Imagens da página do CurseForge: `python ferramentas/simulador_ui.py pagina` gera `docs/pagina/en` e `docs/pagina/pt` (mesmas 7 telas, janela no idioma de cada metade de `docs/curseforge.md`), com a fonte e os ícones do jogo. Gerar de novo a cada pacote de domingo.
- Histórico antigo do GitHub ainda tem commits com "João Menestrina" e "Co-Authored-By: Claude": reescrever só com
  autorização e depois de nenhum branch do Codex aberto.
- `docs/tarefas/T0.6-*.png` são capturas anexadas pelo Codex; podem sair quando não forem mais úteis.

## 7. Próximos marcos

| Marco | Data | Conteúdo |
|---|---|---|
| M0 | 22/11 | Fundação técnica |
| alpha1 | 29/11 | Resumo ao voltar, encomenda do dia, sequência |
| alpha2 | 06/12 | Eventos aleatórios (no lugar dos Serviços) |
| alpha3 | 13/12 | Atributos, seguidores com especialidade |
| alpha4 | 20/12 | Herbário, conquistas, decorações |
| alpha5 | 03/01 | Temporadas, som, animação, equilíbrio (candidato final) |
| **2.0.0** | **05/01/2027** | Lançamento |
