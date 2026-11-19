# Korum Homestead: cronograma

*Reescrito em 18/11/2026, por Korum, depois da aprovação de [`masmorras.md`](masmorras.md). O plano antigo (S3
Personagem, S4 Coleção, S5 Temporadas, S6 Social) está no histórico do git; o que dele continua vale está na seção 6.*

Este documento diz **quem faz o quê e quando**. As regras de cada parte estão nas especificações:
[`economia.md`](economia.md), [`eventos.md`](eventos.md), [`masmorras.md`](masmorras.md) e
[`historia-forever.md`](historia-forever.md).

> **Tipo de arquivo no CurseForge.** O CurseForge decide o tipo pela tag: com `alpha` no nome vira **Alpha**, com
> `beta` vira Beta, **sem nenhum dos dois vira Release**. Versões de trabalho saem como `vX.Y.0-alphaN`; só a versão
> pronta sai sem sufixo. Nunca usar `-rc1` ou outro sufixo sem `alpha`: o CurseForge publicaria como Release.

---

## 1. Visão geral

| Versão | Conteúdo | Estado |
|---|---|---|
| **2.0.0** | Fundação, retorno diário (resumo ao voltar, encomenda do dia, sequência), economia nova (Vila 1–60, 27 ervas, Mercado 4 + 4, Oficina com 21 receitas) | ✅ **Release** em 17/11 |
| **2.1.0** | Visitantes (pedido urgente, mercador, caravana, peixe e veio raros), arte nova, teto da economia | Alpha (`alpha3`, 18/11); **Release quando o dono decidir** |
| **2.2.0** | Masmorras do Forever, níveis, talentos, Diário, equipamento, combos, raides, Aventura parte 1, Véu de Inverno | S3 + S4 (07/12 a 20/12); Release proposta no começo de janeiro |
| **2.3.0** | Raridade, 12 seguidores novos, drops raros, chamados, visitantes com origem no Forever, Aventura parte 2 | S5 (21/12 a 03/01); Release proposta em meados de janeiro |
| depois | Coleção, decorações, social, atributos, temporadas, conteúdo novo do Forever | seção 6 |

```mermaid
gantt
    title Korum Homestead
    dateFormat YYYY-MM-DD
    axisFormat %d/%m
    section Feito
    2.0.0 Release                     :done, 2026-11-17, 1d
    2.1 alpha (visitantes)            :done, 2026-11-18, 1d
    section Até a S3
    Folga: alpha, T3.0, briefings     :f0, 2026-11-19, 18d
    section 2.2
    S3 masmorras e níveis             :s3, 2026-12-07, 7d
    S4 equipamento, combos, raides    :s4, 2026-12-14, 7d
    section 2.3
    S5 raridade, seguidores, chamados :s5, 2026-12-21, 14d
    section Arte (paralelo)
    Véu de Inverno (decoração)        :a1, 2026-12-07, 5d
    12 retratos novos                 :a2, 2026-12-07, 12d
```

## 2. Papéis

| Quem | Papel | Responsável por |
|---|---|---|
| **Eu** | Dono do produto e testador no jogo | Decisões de produto, prioridades e equilíbrio; **todo teste dentro do jogo** (só você roda o WoW); confirmar no jogo os fatos do Forever; aprovar a arte; capturas de tela reais; tokens e acessos |
| **Claude** | Arquiteto, líder técnico, gestor e **todo o código** | Arquitetura, dados, migrações, lógica, telas, testes, simulador, textos EN e ptBR; briefings de arte e de revisão para o Codex; integrar; versões, tags e changelog; manter este cronograma |
| **Codex** | Arte e revisão de texto | **Só** arte (lugares, decorações, retratos) a partir do kit de arte, aprovada pelo dono, e revisão dos textos EN/ptBR que Claude escreve. Não escreve código |

## 3. Como trabalhamos

### Repositório
- O Homestead é desenvolvido neste repositório, com o addon na raiz; o CurseForge empacota daqui.
- Branch `main` sempre jogável. O Codex trabalha por pull request (`codex/...`).
- **GitHub Actions** roda os testes em todo push e pull request. Nada entra na `main` com teste falhando.
- O que é só para desenvolvimento (como o `/kh debug`) fica entre `--@debug@` e `--@end-debug@`.

### Rotina semanal
| Quando | O quê | Quem |
|---|---|---|
| Segunda | Abertura do sprint: o que entra, briefings do Codex prontos | Claude (você aprova) |
| Terça a sexta | Implementação e revisões | Claude e Codex |
| Sexta | Build de teste instalado no Forever + lista do que conferir | Claude |
| Sábado | **Teste no jogo** (1 a 2 h) e relato do que falhou | Eu |
| Domingo | Correções, tag do alpha, publicação | Claude (tag) e Eu (conferir CurseForge) |

### Definição de pronto (vale para toda tarefa)
- Testes automáticos novos e antigos passando.
- Textos em inglês e português, sem chave faltando; linhas na tela **Novidades**.
- Toda função com controle na tela e cartão "como funciona" quando a tela é nova.
- Captura do simulador revisada.
- Saves antigos abrem sem erro e sem perder nada (teste de migração).
- Sem dependência de outro addon; nada que mude o personagem, a bolsa ou o ouro.
- Texto de evento só com fatos de `historia-forever.md`.

---

## 4. Até a S3 (19/11 a 06/12)

| ID | Tarefa | Quem | Data | Entrega / aceite |
|---|---|---|---|---|
| F.1 | Jogar a 2.1 alpha e relatar o que aparecer | **Eu** | contínuo | relato |
| F.2 | Correções da alpha | Claude | contínuo | alpha nova se preciso |
| F.3 | Decidir a **2.1.0 Release** | **Eu** | quando estiver estável | tag `v2.1.0` |
| T3.0a | Comando de depuração que registra os eventos do jogo (chefe, zona, fila, calendário) | Claude | até 22/11 | comando na cópia do repositório |
| T3.0b | Fazer uma masmorra, entrar numa fila e trocar de zona com o comando ligado | **Eu** | até 29/11 | registro dos eventos |
| T3.0c | Ajustar a §12 de `masmorras.md` ao que o Forever oferece | Claude | depois do T3.0b | especificação atualizada |
| T3.0d | Conferir no jogo os fatos de `historia-forever.md`: quem está em cada masmorra nova, o conflito de cada zona, os nomes ptBR | **Eu** | até 06/12 | fatos marcados ✅ |
| A.1 | Briefing da decoração do **Véu de Inverno** (kit, medidas, posições no mapa) | Claude | até 06/12 | `docs/tarefas/A7.md` |
| A.2 | Briefing dos **12 retratos novos** (no estilo dos seis de hoje, alta resolução) | Claude | até 06/12 | `docs/tarefas/A8.md` |

## 5. Sprints

### S3: masmorras, níveis e talentos (seg 07/12 a dom 13/12) → `v2.2.0-alpha1`

| ID | Tarefa | Quem | Data | Entrega / aceite |
|---|---|---|---|---|
| T3.1 | Especificação | **Eu** | — | ✅ aprovada em 18/11 |
| T3.2 | Dados em `Balance.lua` (seguidores, ameaças, habilidades, traços, masmorras); migração schema 4 | Claude | 07/12 | teste com os saves antigos |
| T3.3 | Motor: chance, envio, volta, recompensa, ferimento, nível e XP, qualidade e insígnias, talentos, Masmorra do dia | Claude | 08–09/12 | testes com sorteio fixo |
| T3.4 | Chance na hora, Recomendados e Grupo sugerido | Claude | 09/12 | testes: o sugerido é o melhor |
| T3.5 | Telas: abas Seguidores e Masmorras, ficha do seguidor, "Enquanto você esteve fora" | Claude | 10–11/12 | capturas |
| T3.6 | **Diário** dos seguidores (frases-modelo, ficha, "Contar no chat") | Claude | 10/12 | toda combinação gera linha nos dois idiomas |
| T3.7 | Testes de economia e de ritmo dos níveis | Claude | 11/12 | abaixo do teto; metas da §3.1 |
| T3.8 | Revisão dos textos EN/ptBR e nomes ptBR das masmorras | **Codex** | 11/12 | só valores do `Locales.lua` |
| T3.9 | Teste no jogo | **Eu** | 12/12 | relato |
| T3.10 | Correções, Novidades, changelog e tag | Claude | 13/12 | alpha publicada |

### S4: equipamento, combos, raides e Aventura (seg 14/12 a dom 20/12) → `v2.2.0-alpha2`

| ID | Tarefa | Quem | Data | Entrega / aceite |
|---|---|---|---|---|
| T4.1 | Equipamento: aba Equipamento na Oficina, equipar e trocar, nível na chance | Claude | 14–15/12 | toda peça vale mais que suas barras |
| T4.2 | Consumíveis (poção e comida) | Claude | 15/12 | testes |
| T4.3 | Combos, Livro de Combos e troféus | Claude | 16/12 | cada combo com seu efeito |
| T4.4 | Raides semanais, Núcleo, Maestria e Título | Claude | 16–17/12 | testes com o relógio adiantado |
| T4.5 | **Aventura**, parte 1: fila abre a vila, chefe inspira, masmorra feita confirma as ameaças | Claude | 17/12 | testes com o cliente simulado |
| T4.6 | **Véu de Inverno** na vila (calendário do jogo e decoração) | Claude | 18/12 | no ar enquanto a festa durar (até 02/01) |
| T4.7 | Revisão dos textos EN/ptBR | **Codex** | 18/12 | chaves completas |
| T4.8 | Teste no jogo | **Eu** | 19/12 | relato |
| T4.9 | Correções, Novidades, changelog e tag | Claude | 20/12 | alpha publicada |

### S5: raridade, seguidores novos e chamados (seg 21/12 a dom 03/01, com festas) → `v2.3.0-alpha1`

| ID | Tarefa | Quem | Data | Entrega / aceite |
|---|---|---|---|---|
| T5.1 | Aprovar os 12 seguidores novos (nomes, classes, habilidades) e as ameaças das masmorras novas | **Eu** | 21/12 | decisão |
| T5.2 | Rol de 20, quartos e Alojamento, raridade, Poder, Ranking; drops raros e garantia | Claude | 22–23/12 | testes de drop e de garantia |
| T5.3 | Seguidores novos com os retratos do Codex | Claude | 23/12 | capturas |
| T5.4 | **Chamados** (defesa, ataque, escolta, resgate, reconhecimento) no motor dos eventos | Claude | 28–29/12 | testes; visitantes e chamados abaixo do teto |
| T5.5 | Visitantes de hoje com origem no Forever (só texto) | Claude | 29/12 | todo texto aponta para um fato confirmado |
| T5.6 | **Aventura**, parte 2: zona visitada abre os chamados do lugar; raide feita dá insígnia | Claude | 30/12 | testes |
| T5.7 | Revisão dos textos EN/ptBR | **Codex** | 30/12 | chaves completas |
| T5.8 | Teste no jogo | **Eu** | 02/01 | relato |
| T5.9 | Correções, Novidades, changelog e tag | Claude | 03/01 | alpha publicada |

### Arte (em paralelo)

| ID | Tarefa | Quem | Data | Entrega / aceite |
|---|---|---|---|---|
| A7 | Decoração do Véu de Inverno no mapa | **Codex** (você aprova) | 07–11/12 | PNG em alta resolução; importada até 16/12 |
| A8 | 12 retratos dos seguidores novos | **Codex** (você aprova) | 07–18/12 | PNG em alta resolução; importados até 22/12 |

### Versões Release (propostas)

| Versão | Quando | Condição |
|---|---|---|
| 2.1.0 | quando você decidir | visitantes estáveis no seu jogo |
| 2.2.0 | começo de janeiro | S4 testada sem falha aberta |
| 2.3.0 | meados de janeiro | S5 testada sem falha aberta |

O Véu de Inverno só chega a todos os jogadores se uma Release com ele sair antes de 02/01; decidir no teste da S4.

## 6. Depois da 2.3 (sem datas ainda)

| Ordem sugerida | Conteúdo | Observação |
|---|---|---|
| 1 | **Coleção:** herbário, troféus das masmorras, conquistas | os troféus já existem desde a S4 |
| 2 | **Decorações** no mapa da vila | arte do Codex |
| 3 | **Social:** amigos e guilda vendo a vila uns dos outros; "Lendário encontrado!" para a guilda | antes, testar no jogo se o Forever aceita mensagens de addon (ponto de decisão) |
| 4 | Atributos do personagem, temporadas, mais festas, polimento (som, animação) | do plano antigo |
| sempre | Conteúdo novo do Forever (atualizações de primavera e verão de 2027): masmorras, chamados, seguidores | acompanha o jogo |

## 7. Carga por pessoa (estimada)

| Período | Eu | Claude | Codex |
|---|---|---|---|
| Até a S3 | ~4 h (jogar, T3.0, fatos do Forever) | ~6 h | — |
| S3 | ~2 h | ~20 h | ~1,5 h |
| S4 | ~2 h | ~18 h | ~1,5 h |
| S5 | ~3 h | ~20 h | ~1,5 h |
| Arte | ~1 h (aprovar) | ~2 h (briefings, importar) | ~12 h |
| **Total** | **~12 h** | **~66 h** | **~16 h** |

## 8. Riscos

| Risco | Prob. | Impacto | Resposta |
|---|---|---|---|
| O cliente do Forever não oferece eventos de chefe ou de fila | média | Aventura menor | o T3.0 responde antes da S3; o que não existir sai da §12 sem afetar o resto |
| Fatos das masmorras novas do Forever não confirmados a tempo | média | S3 sem as masmorras novas | a S3 sai com as do Clássico; as novas entram quando confirmadas |
| Retratos ou decoração do Véu atrasam | média | seguidores novos ou festa sem arte | Véu tem prazo (16/12); retratos podem entrar na alpha seguinte |
| S5 cheia demais | média | 2.3 escorrega | chamados ou parte dos seguidores novos passam para a alpha seguinte |
| Masmorras rendem demais | baixa | economia quebra | teste de economia em todo pull request (teto da §9 de `masmorras.md`) |
| Save antigo quebra na migração (schema 4) | baixa | alto | teste com saves reais; migração nunca apaga campos |
| Teste no jogo atrasa (sábado sem tempo) | média | alpha escorrega uma semana | o alpha sai no domingo seguinte; o sprint seguinte começa mesmo assim |
| Webhook do CurseForge falha numa tag | baixa | alpha não sai | conferir a entrega; reenviar a tag |
| Festas de fim de ano | alta | S5 mais lenta | S5 já tem duas semanas |

## 9. Lista de verificação de cada versão

- [ ] GitHub Actions verde na `main`
- [ ] `## Version` do `.toc`, `CHANGELOG.md` e **Novidades** atualizados
- [ ] Saves antigos abrem no jogo sem perder nada
- [ ] Teste de sábado sem falha aberta
- [ ] Nada de depuração no zip (`--@debug@`)
- [ ] Tag enviada e arquivo no CurseForge com o tipo certo (Alpha ou Release)
- [ ] Página do CurseForge e imagens atualizadas (nas Releases)

## 10. Histórico

| Sprint | O que entrou | Quando |
|---|---|---|
| S0 Fundação | repositório próprio, testes no GitHub Actions, `UI/` dividida, `Balance.lua`, `KH.Day()`, migração com schema | 17/11 |
| S1 Retorno diário | "Enquanto você esteve fora", encomenda do dia e sequência, Novidades | 17/11 |
| F2.0 Economia | Vila 1–60, 27 ervas, Mercado 4 + 4, Oficina com 21 receitas, prédios pelo nível da vila | 17/11 (2.0.0 Release) |
| S2 Visitantes | motor de eventos, cinco tipos, carrinho na vila, tela Visitantes, arte A6, teto de 20 min de Horta, textos revisados | 18/11 (2.1.0-alpha1 a alpha3) |
