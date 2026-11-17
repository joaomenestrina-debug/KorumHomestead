# Contexto do projeto: onde estamos e para onde vamos

**Leia este arquivo antes de qualquer trabalho no Korum Homestead.** Ele existe para ninguém precisar reler o projeto
inteiro. Quem terminar uma tarefa atualiza as seções 1 e 2 no mesmo commit/pull request.

*Última atualização: 17/11/2026, após a abertura das PRs T0.8 e T0.9.*

---

## 1. Onde estamos

| | |
|---|---|
| **Versão publicada** | **1.0.1** no CurseForge (Release) — é a que os jogadores usam |
| **Em desenvolvimento** | **2.0** (plano em [plano-2.0.md](plano-2.0.md), cronograma em [cronograma-2.0.md](cronograma-2.0.md)) |
| **Sprint atual** | **S0 — Fundação técnica** (17/11 a 22/11) |
| **Próximo marco** | M0 em 22/11 (nada muda para o jogador); depois **2.0.0-alpha1** em 29/11 |
| **`main`** | jogável, testes verdes; instalada no WoW Forever de teste |

### Sprint 0: andamento

| Tarefa | Quem | Estado |
|---|---|---|
| T0.1 Desenvolvimento no repositório próprio | Eu | ✅ |
| T0.2 Testes no GitHub Actions | Claude | ✅ |
| T0.3 Instalador lendo deste repositório | Claude | ✅ |
| T0.4 Amostra do save real (`KorumHomestead.lua` do WTF) | Eu | ✅ em `tests/fixtures/save-1.0.1.lua` |
| T0.5 Briefings T0.6, T0.8, T0.9 | Claude | ✅ |
| T0.6 `UI.lua` dividido em `UI/` | Codex | ✅ PR #1 integrado |
| T0.7 `db.schema` + `Migrate.lua` | Claude | ✅ PR #2 |
| T0.8 `Balance.lua` | **Codex** | 🔍 PR em revisão ([briefing](tarefas/T0.8.md)) |
| T0.9 `KH.Day()` | **Codex** | 🔍 PR em revisão ([briefing](tarefas/T0.9.md)) |
| T0.10 Revisão e integração | Claude | aguarda a revisão das PRs T0.8 e T0.9 |
| T0.11 Teste de regressão no jogo | **Eu** | sábado 21–22/11 |

## 2. O que fazer agora (por pessoa)

- **Eu:** T0.4 concluída; sábado: T0.11 (teste de regressão no jogo).
- **Codex:** T0.8 e T0.9 em revisão, uma pull request por tarefa.
- **Claude:** revisar os pull requests; T0.7 concluída; briefings da S1 até segunda 23/11.

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

## 4. Mapa do código

O addon está na **raiz**; a ordem de carga é a do `KorumHomestead.toc` (os testes e o simulador leem a lista de lá).

| Arquivo | Responsabilidade |
|---|---|
| `Kit.lua` | kit visual próprio (janela, botões, textos, cores, barras, animações) — cópia independente |
| `Core.lua` | `KH`, padrões do save `KorumHomesteadDB`, eventos, `KH.Now()`, `/kh` |
| `Migrate.lua` | `KH.SCHEMA` (versão do formato do save) e as migrações, aplicadas ao carregar, antes dos padrões |
| `Locales.lua` | todos os textos, `enUS` e `ptBR`, via `KH.T("chave")` |
| `Data.lua` | as 13 ervas (item id, nível, tempo, custo, venda, xp), nome e ícone vindos do jogo |
| `Farm.lua` | plantar, colher, vender ervas, encomendas do Mercado |
| `Village.lua` | construções, níveis, obras, Mina e Lagoa, produtos (`GOODS`, `ITEM` = ícones), Celeiro |
| `Works.lua` | Oficina (3 ofícios, fila) e Estalagem (seguidores, missões) |
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
