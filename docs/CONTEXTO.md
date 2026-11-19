# Contexto do projeto: onde estamos e para onde vamos

**Leia este arquivo antes de qualquer trabalho no Korum Homestead.** Ele existe para ninguém precisar reler o projeto
inteiro. Quem terminar uma tarefa atualiza as seções 1 e 2 no mesmo commit/pull request.

*Última atualização: 19/11/2026, por Korum (A7 e A8 aprovados e na `main`).*

---

## 1. Onde estamos

| | |
|---|---|
| **Versão publicada** | **2.0.0** no CurseForge (Release, 17/11) — é a que os jogadores usam. A **2.1** (eventos aleatórios + arte A6) saiu como **`v2.1.0-alpha1`**, **`v2.1.0-alpha2`** **`v2.1.0-alpha3`** em 18/11 e **`v2.1.0-alpha4`** em 19/11 (Alpha no CurseForge; a alpha3 tira o `/kh debug` do zip; a alpha4 traz o minimapa com o logo e o mesmo resumo do ícone) |
| **Em desenvolvimento** | **2.2 e 2.3: masmorras e seguidores** (especificação **aprovada em 18/11** em [masmorras.md](masmorras.md); fatos do Forever em [historia-forever.md](historia-forever.md)). Cronograma em [cronograma-2.0.md](cronograma-2.0.md) (reescrito em 18/11); plano antigo em [plano-2.0.md](plano-2.0.md) |
| **Sprint atual** | **S2 — Eventos aleatórios**: motor, telas e arte na `v2.1.0-alpha1`; T2.10 (economia) feita em 18/11; T2.8 (textos) integrada; **`v2.1.0-alpha2`** publicada em 18/11 |
| **Próximo marco** | S3 abre em **07/12** (`v2.2.0-alpha1` em 13/12) |
| **`main`** | jogável, testes verdes; instalada no WoW Forever de teste |
| **Arte A6** | Aprovada e no jogo, a partir de `arquivo/arte_v5/*@hd.png`, reduzida para perto do tamanho de tela (prédios 256, retratos 128, mapa 1024×512); o logo segue o antigo em pixel (ícones pequenos: simples, poucas cores) |
| **T2.8** | Textos EN/ptBR de eventos revisados; PR aguardando revisão |
| **A7** | Véu de Inverno **aprovado em 19/11** e na `main` (`arquivo/arte_v6/`: `map_winter`, `winter_tree`, `snowman`, `gifts`); **no jogo desde 19/11** (`Festivals.lua`: de 15/12 a 02/01 a vila usa `map_winter` e mostra o pinheiro, o boneco e o trenó; `/kh festa` com o debug ligado mostra fora da data) |
| **A8** | Doze retratos dos novos seguidores **aprovados em 19/11** e na `main` (`arquivo/arte_v6/follower7..18@hd.png`); Claude importa para o jogo na S5, quando o código usar |

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

- **Eu:** conferir no jogo os fatos de `docs/historia-forever.md` (quem está em cada masmorra nova, o conflito de cada zona, os nomes ptBR). Jogar a alpha3 e relatar o que aparecer. A S3 (F3, Personagem) fica para a data do cronograma (07/12), por decisão de 18/11.
- **Codex:** **A7** e **A8** aprovados e integrados em 19/11; nenhuma tarefa de arte aberta. Não escrever código.
- **Claude:** T2.10 feita (teto de 20 min de Horta no pedido urgente e no mercador, `docs/eventos.md` §8). T2.8 integrada, com "XP" padronizado e o peixe raro com chave própria (`firefin`). Tag `v2.1.0-alpha2` criada em 18/11; `v2.1.0-alpha3` também, só para tirar o `/kh debug` e o `/kh evento` do zip (entre `--@debug@`, o empacotador comenta). Especificação das masmorras e seguidores escrita em 18/11 (`docs/masmorras.md`, com `docs/historia-forever.md`). Aprovada em 18/11; a Aventura (a vila reage ao que o personagem faz) e o Diário dos seguidores entraram depois (§12 e §13). Tag `v2.1.0-alpha4` criada em 19/11 (logo no minimapa, dica e número iguais aos do ícone, caminho do topo no inglês). Comando do T3.0 pronto: `/kh debug` e depois `/kh eventos` (`Probe.lua`, só na cópia do repositório). Briefings A7 e A8 escritos em 19/11. Próximo: o dono testa o T3.0 numa masmorra, numa fila e numa troca de zona; A7 no jogo em 19/11 (vai na próxima alpha); correções da alpha.

## 3. Decisões tomadas (não reabrir sem motivo novo)

| Data | Decisão |
|---|---|
| 17/11 | O Homestead é desenvolvido **neste repositório** (`C:\AI\Code\KorumHomestead`, GitHub público). O monorepo dos outros addons não tem cópia; o instalador de lá lê daqui. |
| 17/11 | Só **WoW Forever** (interface 16001). |
| 17/11 | Licença **All Rights Reserved**. |
| 17/11 | **Ícones de itens do jogo** para tudo o que é item; pixel art própria (do dono com o ChatGPT, ou do Codex, sempre aprovada pelo dono) só para lugares, mapa, decorações, retratos e logo. |
| 17/11 | Versões de trabalho da 2.0 saem como **Alpha** no CurseForge (tag `v2.0.0-alphaN`). Só `v2.0.0` sem sufixo. Nunca `-rc`. |
| 17/11 | Tudo público sai assinado como **Korum**: autor dos commits `Korum`, sem `Co-Authored-By`, sem citar IA. |
| 17/11 | O "What's new" do CurseForge vem do `CHANGELOG.md` (`manual-changelog` no `.pkgmeta`). |
| 17/11 | Nada castiga quem fica fora; progresso nunca se perde. Saves antigos sempre abrem. |
| 17/11 | **Cuidar do excesso de moedas.** A encomenda do dia paga 2,5× uma encomenda normal (o dobro de ervas × 1,25 por erva); os prêmios da sequência são XP e Lótus Negra, **nunca moedas**. Nenhuma recompensa nova dá moedas sem passar pela conta da economia (T2.0). |
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
| 19/11 | **Trocar de zona não gera eventos** (`docs/masmorras.md` §12): a zona só conta depois de 5 min nela; entrar nunca cria evento na hora, só dá prioridade no próximo sorteio, no máximo uma vez a cada 2 h por zona e com 30 min de recarga geral; a fila abre a vila no máximo a cada 10 min; inspiração de chefe não acumula. |
| 18/11 | **Todo evento tem relação com a história do WoW Forever.** Fonte única: `docs/historia-forever.md`; texto de evento só usa fato que está lá, confirmado no jogo ou em anúncio oficial. |
| 18/11 | O `/kh debug` e o `/kh evento` ficam entre `--@debug@` e `--@end-debug@`: só existem na cópia do repositório. |
| 17/11 | Toda mudança que o jogador percebe ganha linha na tela **Novidades** (`News.lua` + `news<id>_<n>` no `Locales.lua`). A tela abre sozinha uma vez ao logar depois da atualização; save novo não vê novidades antigas. A entrada 1 é a `2.0.0-alpha1`: as tarefas da S1 acrescentam linhas nela. |

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
- `python ferramentas/conferir_textos.py` confere se algum texto sai da janela ou se sobrepõe (fonte do jogo ~18% mais larga que a do simulador); rodar antes de cada build.
- Ainda não visto no jogo: ícones de itens nos produtos (1.0.1), Celeiro com muitos itens, fila da Oficina com "+N".
- Capturas do CurseForge vêm do simulador (ícones de ervas desenhados por ele); trocar por capturas reais na S5 (T5.16).
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
