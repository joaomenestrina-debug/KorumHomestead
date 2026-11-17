# Contexto do projeto: onde estamos e para onde vamos

**Leia este arquivo antes de qualquer trabalho no Korum Homestead.** Ele existe para ninguém precisar reler o projeto
inteiro. Quem terminar uma tarefa atualiza as seções 1 e 2 no mesmo commit/pull request.

*Última atualização: 17/11/2026, por Claude (Sprint 0 concluída; tela Novidades; briefings da S1 prontos).*

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
| T1.5 Telas: cartão "Enquanto você esteve fora", encomenda do dia no Mercado, ponto no ícone | Claude | **em andamento** |
| T1.6 Textos EN/ptBR da F1 + Novidades | Codex | depois de T1.5 |
| T1.7 Cenas do simulador da F1 | Codex | depois de T1.5 |
| T1.8–T1.11 Integração, teste no jogo, correções, tag alpha1 | Claude + Eu | 27–29/11 |

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

- **Eu:** nada até o teste da alpha1 no jogo (T1.9, 28/11).
- **Codex:** nada até a T1.5 entrar na `main`; depois **T1.6** e **T1.7** (podem ser juntas, arquivos diferentes).
- **Claude:** **T1.5** (telas).

## 3. Decisões tomadas (não reabrir sem motivo novo)

| Data | Decisão |
|---|---|
| 17/11 | O Homestead é desenvolvido **neste repositório** (`C:\AI\Code\KorumHomestead`, GitHub público). O monorepo dos outros addons não tem cópia; o instalador de lá lê daqui. |
| 17/11 | Só **WoW Forever** (interface 16001). |
| 17/11 | Licença **All Rights Reserved**. |
| 17/11 | **Ícones de itens do jogo** para tudo o que é item; pixel art própria (feita pelo dono com o ChatGPT) só para lugares, mapa, decorações, retratos e logo. |
| 17/11 | Versões de trabalho da 2.0 saem como **Alpha** no CurseForge (tag `v2.0.0-alphaN`). Só `v2.0.0` sem sufixo. Nunca `-rc`. |
| 17/11 | Tudo público sai assinado como **Korum**: autor dos commits `Korum`, sem `Co-Authored-By`, sem citar IA. |
| 17/11 | O "What's new" do CurseForge vem do `CHANGELOG.md` (`manual-changelog` no `.pkgmeta`). |
| 17/11 | Nada castiga quem fica fora; progresso nunca se perde. Saves antigos sempre abrem. |
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
| `UI/Bubble.lua` | ícone flutuante e notificações |
| `UI/Minimap.lua` | botão do minimapa |
| `Media/` | `Village/` (construções, mapa, seguidores), `Icons/` (formas do Kit), `logo.tga` |
| `tests/` | `test_homestead.py`, `test_migrate.py` (saves antigos), `client_mock.py` (cliente falso), `fixtures/` (saves reais de versões antigas) |
| `ferramentas/` | `simulador_ui.py` (capturas), `importar_arte_homestead.py`, `curse_homestead.py` |
| `arquivo/arte_v3/` | fontes da pixel art (PNG) |
| `docs/` | este arquivo, plano, cronograma, `tarefas/` (briefings do Codex) |

## 5. Como trabalhamos (resumo)

- **Regras de código e do projeto:** [AGENTS.md](../AGENTS.md) (vale para todos, não só para o Codex).
- **Fluxo:** briefing em `docs/tarefas/T-x.y.md` → branch `codex/...` ou `claude/...` → pull request → testes verdes no
  GitHub → revisão de Claude → integração na `main` → teste no jogo no sábado.
- **Comandos:** `python -m pytest tests -q` · `python ferramentas/simulador_ui.py` ·
  instalar no jogo: `python "C:\AI\Code\Addons WOW\ferramentas\instalar.py" --apply forever`.
- **Publicar:** só Claude cria tags. Tag `v2.0.0-alphaN` → webhook → CurseForge empacota como Alpha.
- **Pasta compartilhada:** Codex e Claude podem trabalhar nesta mesma pasta. Antes de commitar, conferir o branch
  (`git branch --show-current`) e não usar `git add -A` com arquivos de outro.

## 6. Pendências e riscos conhecidos

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
