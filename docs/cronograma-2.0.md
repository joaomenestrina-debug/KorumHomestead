# Korum Homestead: cronograma

*Reescrito em 22/11/2026, por Korum, depois da `v2.2.0-alpha1`. A S3, a S4 e a S5 saíram juntas, adiantadas (pedido do
dono em 19/11), e o que vinha depois mudou com os pedidos do teste. A versão anterior deste arquivo está no histórico
do git.*

Este documento diz **quem faz o quê e quando**. As regras de cada parte estão nas especificações:
[`economia.md`](economia.md), [`eventos.md`](eventos.md), [`masmorras.md`](masmorras.md) e
[`historia-forever.md`](historia-forever.md).

> **Tipo de arquivo no CurseForge.** O CurseForge decide o tipo pela tag: com `alpha` no nome vira **Alpha**, com
> `beta` vira Beta, **sem nenhum dos dois vira Release**. Versões de trabalho saem como `vX.Y.0-alphaN`; só a versão
> pronta sai sem sufixo. Nunca usar `-rc1` ou outro sufixo sem `alpha`: o CurseForge publicaria como Release.

> **Um pacote por semana (decisão do dono, 19/11; reforçada em 22/11).** Durante a semana as mudanças se juntam no ramo
> de trabalho e são instaladas na cópia do dono, com Novidades e CHANGELOG da próxima versão. **Nada vai ao CurseForge
> antes do domingo.** No domingo sai **uma** atualização com tudo o que a semana trouxe. Tag no meio da semana só se algo
> impedir de jogar.

---

## 1. Visão geral

| Versão | Conteúdo | Estado |
|---|---|---|
| **2.0.0** | Fundação, retorno diário, economia nova (Vila 1–60, 27 ervas, Mercado 4 + 4, Oficina) | ✅ Release 17/11 |
| **2.1.0** | Visitantes, arte nova, Véu de Inverno, logo no minimapa | ✅ Release 19/11 |
| **2.2.0-alpha1** | S3 + S4 + S5 juntas: masmorras, níveis, equipamento, combos, Onyxia, Aventura, 12 seguidores novos, quartos e Ranking, chamados, trabalho na Mina e na Lagoa, Celeiro com abas, lembrete no voo e na fila; textos revisados (T5.8) | ✅ Alpha 22/11 |
| **2.2.0-alpha2** | Equipamento na lista de seguidores, aba **Trabalho** (Horta, Oficina e Mercado), **Conquistas** | domingo **29/11** |
| **2.2.0-alpha3** | Amizade entre seguidores e a primeira etapa da **missão pessoal** (se aprovadas), datas das festas pelo calendário do jogo | domingo **06/12** |
| **2.2.0** | Release do que estiver testado | domingo **13/12**, se o teste do dono não tiver falha aberta |
| **2.3.0** | Missão pessoal completa (níveis 20 e 30), herbário, decorações no mapa, seguidores no mapa | 14/12 a 10/01 (festas no meio) |
| depois | Social na guilda, atributos, temporadas, conteúdo novo do Forever | seção 6 |

```mermaid
gantt
    title Korum Homestead
    dateFormat YYYY-MM-DD
    axisFormat %d/%m
    section Feito
    2.0.0 e 2.1.0 Release              :done, 2026-11-17, 3d
    S3 a S5 e 2.2.0-alpha1             :done, 2026-11-19, 4d
    section 2.2
    Semana 1: alpha2 (trabalho, conquistas) :w1, 2026-11-23, 7d
    Semana 2: alpha3 (amizade, missão 1)    :w2, 2026-11-30, 7d
    Semana 3: correções e 2.2.0 Release     :w3, 2026-12-07, 7d
    section 2.3
    Missão pessoal 2 e 3, herbário          :s6, 2026-12-14, 7d
    Decorações e seguidores no mapa         :s7, 2026-12-21, 21d
    section Arte (paralelo)
    A9 decorações                           :a9, 2026-12-07, 14d
    A10 seguidores no mapa                  :a10, 2026-12-14, 14d
```

## 2. Papéis

| Quem | Papel | Responsável por |
|---|---|---|
| **Eu** | Dono do produto e testador no jogo | Decisões de produto, prioridades e equilíbrio; **todo teste dentro do jogo**; aprovar a arte e os desenhos novos; tokens e acessos |
| **Claude** | Arquiteto, líder técnico, gestor e **todo o código** | Arquitetura, dados, migrações, lógica, telas, testes, simulador, textos EN e ptBR; briefings para o Codex; integrar; versões, tags e changelog; manter este cronograma |
| **Codex** | Arte e textos | Arte (a partir do kit de arte, aprovada pelo dono), revisão dos textos EN/ptBR e, desde 22/11, as falas do Prefeito. Não escreve código |

## 3. Como trabalhamos

### Repositório
- O Homestead é desenvolvido neste repositório, com o addon na raiz; o CurseForge empacota daqui.
- O trabalho da semana fica no ramo `claude/masmorras` e entra na `main` no domingo, junto com a tag.
- O Codex trabalha por pull request (`codex/...`) para o ramo de trabalho.
- **GitHub Actions** roda os testes em todo push e pull request. Nada entra na `main` com teste falhando.
- O que é só para desenvolvimento (como o `/kh debug`) fica entre `--@debug@` e `--@end-debug@`.

### Rotina semanal
| Quando | O quê | Quem |
|---|---|---|
| Segunda | O que entra na semana; briefings do Codex prontos | Claude (você aprova) |
| Terça a sexta | Implementação, revisões, cada mudança instalada na sua cópia | Claude e Codex |
| Sábado | **Teste no jogo** e relato do que falhou | Eu |
| Domingo | Correções, `main`, tag e publicação (depois do seu ok) | Claude (tag) e Eu (conferir CurseForge) |

### Definição de pronto (vale para toda tarefa)
- Testes automáticos novos e antigos passando.
- `python ferramentas/conferir_textos.py` dá **0 problema(s)** e as telas mudadas foram olhadas.
- Textos em inglês e português, sem chave faltando; linhas na tela **Novidades** e no CHANGELOG.
- Saves antigos abrem sem erro e sem perder nada.
- Ícones de itens e do jogo conferidos com `ferramentas/icones_do_jogo.py` e o CASCConsole.
- Sem dependência de outro addon; nada que mude o personagem, a bolsa ou o ouro.
- Texto de história só com fatos de `historia-forever.md`.

---

## 4. As próximas semanas

### Semana 1 (seg 23/11 a dom 29/11) → `v2.2.0-alpha2`

| ID | Tarefa | Quem | Data | Entrega / aceite |
|---|---|---|---|---|
| T6.1 | Equipamento na lista de seguidores | Claude | 22/11 | ✅ feito |
| T6.2 | Aba **Trabalho**: Horta, Oficina e Mercado com uma vaga; Jardineiro, Artesão e Negociante | Claude | 22/11 | ✅ feito |
| T6.3 | **Conquistas**: 55 marcos em nove categorias, todos visíveis com o que falta, cartão ao conseguir, Mestre do Homestead | Claude | 22/11 | ✅ feito |
| T6.4 | Aprovar o desenho da **missão pessoal** e da **amizade** (proposto em 22/11) | **Eu** | 25/11 | ✅ aprovado em 22/11 |
| T6.5 | Confirmar as **decisões provisórias** da S5: origem de Tazu, Faelan e Shalendra; novos chegam no nível do lugar; ataque dá Insígnia de Mérito; raide sem Épico próprio | **Eu** | 25/11 | ✅ confirmadas em 22/11 |
| T6.6 | Revisão dos textos novos desde a alpha1 (trabalho, conquistas, Novidades) | **Codex** | 27/11 | PR para o ramo de trabalho; verificador em 0 |
| T6.11 | **Prefeito Ambrósio**: código pronto (fala nos avisos, liga e desliga nos Ajustes); personalidade em `prefeito.md` | Claude | 22/11 | ✅ feito |
| T6.12 | Falas do Prefeito em todos os avisos, EN e PT ([`tarefas/T6.11.md`](tarefas/T6.11.md)) | **Codex** | 27/11 | PR; verificador em 0 |
| T6.7 | README e página do CurseForge com as masmorras, o trabalho e as conquistas | Claude | 27/11 | texto EN/ptBR |
| T6.8 | Atualizar `masmorras.md` com o que mudou no teste (trabalho, conquistas, Celeiro, lembrete) | Claude | 27/11 | especificação igual ao jogo |
| T6.9 | Teste no jogo (conquistas de um save antigo, aba Trabalho, Horta e Oficina mais rápidas) | **Eu** | 28/11 | relato |
| T6.10 | Correções, `main`, tag | Claude | 29/11 | alpha publicada (depois do seu ok) |

### Semana 2 (seg 30/11 a dom 06/12) → `v2.2.0-alpha3`

| ID | Tarefa | Quem | Data | Entrega / aceite |
|---|---|---|---|---|
| T7.1 | **Amizade**: laço de 1 a 3 com as idas juntos, bônus de chance e de combo, linha no Diário, melhores amigos na ficha | Claude | 01–02/12 | testes; depende do T6.4 |
| T7.2 | **Missão pessoal**, etapa 1 (nível 10): uma ida ao lugar de origem, história no Diário, traço pessoal | Claude | 02–04/12 | 18 histórias; depende do T6.4 |
| T7.3 | Conquistas novas da amizade e da missão pessoal | Claude | 04/12 | o Mestre do Homestead passa a pedir também essas |
| T7.10 | Importar os ícones das conquistas e o retrato do Prefeito (A11); retrato no cartão das conquistas e no lembrete; momentos novos do Prefeito | Claude | 05/12 | capturas |
| T7.4 | Datas das festas pelo calendário do jogo (`C_Calendar`), no lugar das datas fixas | Claude | 03/12 | Véu de Inverno abre e fecha com o jogo |
| T7.5 | Teste do T3.0 (`/kh debug` e `/kh eventos`: uma masmorra, uma fila, trocas de zona) | **Eu** | até 05/12 | registro dos eventos |
| T7.6 | Ajustar a §12 de `masmorras.md` ao que o Forever oferece | Claude | depois do T7.5 | especificação atualizada |
| T7.7 | Revisão das histórias da missão pessoal | **Codex** | 04/12 | só valores do `Locales.lua`; fatos de `historia-forever.md` |
| T7.8 | Teste no jogo | **Eu** | 05/12 | relato |
| T7.9 | Correções, `main`, tag | Claude | 06/12 | alpha publicada |

### Semana 3 (seg 07/12 a dom 13/12) → **2.2.0 Release**

| ID | Tarefa | Quem | Data | Entrega / aceite |
|---|---|---|---|---|
| T8.1 | Teste de economia com tudo ligado (trabalho, Mercado, masmorras, conquistas) | Claude | 08/12 | abaixo do teto |
| T8.2 | Polimento do que o teste das alphas apontar | Claude | 07–11/12 | — |
| T8.3 | Briefing A9 (decorações no mapa) e A10 (seguidores andando na vila) | Claude | 08/12 | `docs/tarefas/A9.md`, `A10.md` |
| T8.4 | Teste final no jogo e decisão da Release | **Eu** | 12/12 | ok ou lista de falhas |
| T8.5 | `instalar.py` dos outros addons volta a apontar para a pasta principal; pasta principal na `main` | Claude | 13/12 | instalação sem trocar de pasta |
| T8.6 | Release `v2.2.0`, página e imagens do CurseForge | Claude | 13/12 | Release publicada |

### 2.3 (seg 14/12 a dom 10/01, com as festas)

| ID | Tarefa | Quem | Data | Entrega / aceite |
|---|---|---|---|---|
| T9.1 | Missão pessoal, etapas 2 e 3 (níveis 20 e 30): peça com nome própria e o Título | Claude | 14–18/12 | 36 histórias; testes |
| T9.2 | **Herbário** (coleção das ervas colhidas, com conquistas) | Claude | 21–23/12 | tela e conquistas |
| T9.3 | Decorações no mapa da vila (arte A9) | Claude | depois do A9 | capturas |
| T9.4 | Seguidores no mapa, perto de onde trabalham (arte A10) | Claude | depois do A10 | capturas |
| T9.5 | Trabalho para mais de um seguidor por construção nos níveis altos (se o teste mostrar gente parada) | Claude | a decidir | decisão do dono |
| T9.6 | Revisão dos textos | **Codex** | antes de cada alpha | PR |
| T9.7 | Alphas semanais e Release 2.3.0 | Claude | domingos; Release proposta em 10/01 | — |

### Arte (em paralelo)

| ID | Tarefa | Quem | Data | Entrega / aceite |
|---|---|---|---|---|
| A11 | **9 ícones das conquistas**, um por categoria, no estilo do addon (cinza até conseguir), e **retrato do Prefeito** ([`tarefas/A11.md`](tarefas/A11.md)) | **Codex** (você aprova) | 23/11–30/11 | PNG em alta resolução |
| A9 | Decorações para o mapa da vila | **Codex** (você aprova) | 07–20/12 | PNG em alta resolução |
| A10 | Seguidores pequenos andando na vila | **Codex** (você aprova) | 14–27/12 | PNG em alta resolução |

## 5. Decisões já tomadas nesta fase

| Data | Decisão |
|---|---|
| 19/11 | S3, S4 e S5 numa alpha só, testada na cópia do dono |
| 20/11 | Celeiro cheio: só avisar antes (80%) e guardar o que couber |
| 22/11 | Sem ranking online por enquanto (pesquisa no `CONTEXTO.md`) |
| 22/11 | Tudo o que for feito depois da alpha1 sai só no domingo 29/11 |
| 22/11 | Trabalho em todas as construções; conquistas como as do WoW, todas visíveis |
| 22/11 | Missão pessoal e amizade aprovadas como propostas; decisões provisórias da S5 confirmadas |
| 22/11 | Prefeito Ambrósio fala os avisos, com humor seco (`prefeito.md`); o Codex escreve as falas e desenha os ícones das conquistas |

## 6. Depois da 2.3 (sem datas ainda)

| Ordem sugerida | Conteúdo | Observação |
|---|---|---|
| 1 | **Social na guilda:** "Lendário encontrado!" e a vila dos outros | antes, testar se o Forever aceita mensagens de addon na guilda; ranking online fica fora (decisão de 22/11) |
| 2 | Atributos do personagem, temporadas, mais festas | do plano antigo |
| 3 | Polimento: som, animação | — |
| sempre | Conteúdo novo do Forever (masmorras, chamados, seguidores) | acompanha o jogo; o que o Wowhead do Forever não tem ainda não existe |

## 7. Riscos

| Risco | Prob. | Impacto | Resposta |
|---|---|---|---|
| O desenho da missão pessoal não é aprovado na semana 1 | média | alpha3 só com amizade | a missão passa para a semana seguinte |
| 54 histórias da missão pessoal com fatos do Forever | média | textos fracos ou sem fonte | só fatos de `historia-forever.md`; Codex revisa; etapa 1 primeiro |
| Muitas conquistas de uma vez num save antigo | baixa | chat cheio | já resolvido: uma linha só na primeira vez |
| Bônus novos (Mercado, Horta, Oficina) rendem demais | baixa | economia quebra | T8.1, teste de economia antes da Release |
| Teste no jogo atrasa | média | alpha escorrega uma semana | sai no domingo seguinte |
| Festas de fim de ano | alta | 2.3 mais lenta | 2.3 já tem quatro semanas |

## 8. Lista de verificação de cada versão

- [ ] GitHub Actions verde na `main`
- [ ] `## Version` do `.toc`, `CHANGELOG.md` e **Novidades** atualizados
- [ ] `conferir_textos` em 0 e telas olhadas
- [ ] Saves antigos abrem no jogo sem perder nada
- [ ] Teste de sábado sem falha aberta
- [ ] Nada de depuração no zip (`--@debug@`)
- [ ] Tag enviada no domingo e arquivo no CurseForge com o tipo certo (Alpha ou Release)
- [ ] Página do CurseForge e imagens atualizadas (nas Releases)

## 9. Histórico

| Sprint | O que entrou | Quando |
|---|---|---|
| S0 Fundação | repositório próprio, testes no GitHub Actions, `UI/` dividida, `Balance.lua`, `KH.Day()`, migração com schema | 17/11 |
| S1 Retorno diário | "Enquanto você esteve fora", encomenda do dia e sequência, Novidades | 17/11 |
| F2.0 Economia | Vila 1–60, 27 ervas, Mercado 4 + 4, Oficina com 21 receitas | 17/11 (2.0.0 Release) |
| S2 Visitantes | motor de eventos, cinco tipos, carrinho na vila, arte A6, teto de 20 min de Horta | 18/11 (2.1.0-alpha1 a alpha3) |
| A7, A8 | Véu de Inverno e 12 retratos novos | 19/11 (2.1.0 Release) |
| S3 a S5 | masmorras, níveis, equipamento, combos, Onyxia, Aventura, 12 seguidores, quartos, Ranking, chamados, trabalho na Mina e na Lagoa, Celeiro com abas, lembrete, revisão T5.8 | 22/11 (2.2.0-alpha1) |
| Semana 1 | equipamento na lista, aba Trabalho, Conquistas | 22/11 (no ramo; sai em 29/11) |
