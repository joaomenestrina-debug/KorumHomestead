# Contexto do projeto: onde estamos e para onde vamos

**Leia este arquivo antes de qualquer trabalho no Korum Homestead.** Ele existe para ninguém precisar reler o projeto
inteiro. Quem terminar uma tarefa atualiza as seções 1 e 2 no mesmo commit/pull request.

*Última atualização: 17/11/2026, por Codex (T2.0f revisão de textos pronta para revisão).*

---

## 1. Onde estamos

| | |
|---|---|
| **Versão publicada** | **1.0.1** no CurseForge (Release) — é a que os jogadores usam |
| **Em desenvolvimento** | **2.0** (plano em [plano-2.0.md](plano-2.0.md), cronograma em [cronograma-2.0.md](cronograma-2.0.md)) |
| **Sprint atual** | S0 concluída em 17/11; **S1 — Voltar todo dia** começa em 23/11 |
| **Próximo marco** | **2.0.0-alpha1** em 29/11 (M0 atingido em 17/11) |
| **`main`** | jogável, testes verdes; instalada no WoW Forever de teste |

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
| T1.10–T1.11 Correções e tag `v2.0.0-alpha1` | Claude + Eu | depois do teste: a alpha1 sai **com a economia nova** (decisão de 17/11) |

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
| T2.0h Teste no jogo | **Eu** | **agora**, junto da T1.9 (build único instalado em 17/11) |

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

- **Eu:** **testar o build único** (alpha1 + economia): Novidades, Mercado 4 + 4 e encomenda do dia, cartão "Enquanto você esteve fora", arrancar canteiro, Vila 1–60 e ervas novas, Oficina com receitas novas, custos dos prédios.
- **Codex:** **só arte e revisão de texto**. **T2.0f concluída**: textos EN/ptBR revisados em `Locales.lua`; PR para revisão. Não escrever código.
- **Claude:** correções do teste, revisão do Codex, tag `v2.0.0-alpha1`; depois o teste que simula um jogador (T2.0g) e os briefings da S2.

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
| 17/11 | A alpha1 e a economia (F2.0) saem **juntas** num build só (`main` desde e77d8d5). |
| 17/11 | **Papéis:** Claude faz **todo o código** (lógica, telas, testes, simulador, textos EN/ptBR). O Codex faz **só arte** (pixel art a partir do kit de arte, aprovada pelo dono) **e revisão de texto**. |
| 17/11 | **Economia da 2.0** aprovada (`docs/economia.md`): Nível da Vila 1–60; ervas na perícia do jogo ÷ 5; colher dá pouco XP; a Oficina sempre dá mais moedas e XP; Mercado 4 + 4; prédios pedem nível da vila e custam horas de renda. |
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

- **Ideia nova do dono (17/11): eventos aleatórios** (pedido urgente, caravana de troca, mercador generoso, peixe/mineral raro), avisados no ícone: descrita no `plano-2.0.md` (F-Eventos), falta encaixar no cronograma.
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
| alpha2 | 06/12 | Disposição e Serviços |
| alpha3 | 13/12 | Atributos, seguidores com especialidade |
| alpha4 | 20/12 | Herbário, conquistas, decorações |
| alpha5 | 03/01 | Temporadas, som, animação, equilíbrio (candidato final) |
| **2.0.0** | **05/01/2027** | Lançamento |
