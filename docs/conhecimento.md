# Korum Homestead: base de conhecimento

*Criada em 22/11/2026, a pedido do dono: "as coisas principais num arquivo consolidado, para pensar nele antes de cada
trabalho e para gerar o cronograma". Este arquivo e toda a pasta `docs/` ficam **só no repositório**: o `.pkgmeta`
tira `docs/`, `tests/`, `ferramentas/`, `arquivo/`, `CLAUDE.md` e `AGENTS.md` do zip que os jogadores baixam.*

**Como usar.** Antes de qualquer trabalho, ler este arquivo e a seção 1 e 2 do [`CONTEXTO.md`](CONTEXTO.md) (onde o
projeto está agora). Quando algo for decidido ou feito, atualizar aqui no mesmo commit: o que existe (seção 3), as
regras (seções 4 a 6) e a lista do que falta (seção 8). O [`cronograma`](cronograma-2.0.md) é montado a partir da
seção 8.

---

## 1. O que é

Uma vila ociosa dentro do WoW Forever, para os momentos de espera do jogo (voo, fila, intervalo). O jogador é o
**dono da vila**: planta ervas, constrói, fabrica, vende, recebe visitantes e manda seguidores às masmorras do Forever.
Tudo corre pelo relógio, mesmo com o jogo fechado. Addon independente, Lua 5.1, interface 16001, só WoW Forever.

**Princípios do produto:**
- Nada castiga quem fica fora; progresso nunca se perde; saves antigos sempre abrem.
- Nada muda o personagem, a bolsa ou o ouro de verdade. A vila só **lê** o que o personagem faz (Aventura).
- Toda função tem controle na tela e explicação ("como funciona"); toda mudança perceptível ganha linha nas Novidades.
- Cuidado com o excesso de moedas: recompensa nova passa pela conta da economia ([`economia.md`](economia.md)).
- O que o Wowhead do Forever não tem ainda não existe no jogo.

## 2. Quem faz o quê

| Quem | Faz |
|---|---|
| **Dono (Korum)** | decide produto, prioridades e equilíbrio; testa no jogo; aprova arte e desenhos; publica no CurseForge depois do ok |
| **Claude** | todo o código, testes, simulador, textos de sistema EN/ptBR, briefings, integração, versões, este arquivo e o cronograma |
| **Codex** | arte (a partir do kit, aprovada pelo dono), revisão dos textos e, desde 22/11, as falas dos personagens. Não escreve código |

## 3. O que existe hoje (no ramo `claude/masmorras`)

| Parte | Resumo | Regras em |
|---|---|---|
| **Vila** | nível 1–60 (XP de tudo), 8 construções até o nível 7: Sede, Horta, Celeiro, Mercado, Mina, Lagoa, Oficina, Estalagem; uma obra por vez | `economia.md` |
| **Horta** | 27 ervas do jogo, até 8 canteiros, plantar e colher; no nível 60 o XP vira Lótus Negra | `economia.md` |
| **Celeiro** | abas (Ervas, Recursos, um por ofício); cada aba tem seu espaço; aviso aos 80%; colheita guarda o que couber; venda por quantidade; bolinha + legenda no que uma encomenda ou obra pede | `CONTEXTO.md` §3 |
| **Mercado** | 4 encomendas de ervas + 4 de itens; encomenda do dia e sequência (prêmios em XP e Lótus, nunca moedas) | `economia.md` |
| **Oficina** | Alquimia, Culinária, Ferraria e Equipamento; receitas em cards lado a lado; uma fila por ofício, todas ao mesmo tempo, com rolagem | `economia.md`, `masmorras.md` |
| **Mina e Lagoa** | minério e peixe por hora, achados raros | `economia.md` |
| **Visitantes** | mensageiro urgente, mercador, caravana, peixe raro, veio raro e **chamados** (defesa, ataque, escolta, resgate, reconhecimento); só com o jogo aberto | `eventos.md`, `masmorras.md` |
| **Estalagem** | 18 seguidores (6 da vila + 12 achados), quartos (um por nível, até 7) e Alojamento; Ranking por Poder; ficha | `masmorras.md` |
| **Masmorras** | 21 masmorras do Forever + Onyxia semanal; ameaças e habilidades; chance na hora; grupo sugerido; poção (+10%) e comida (+5%); chefe opcional; ninguém morre; resultado de cada grupo; Diário | `masmorras.md` |
| **Seguidores** | nível 1–30, qualidade (Incomum, Raro, Épico, Lendário) com insígnias, traços, equipamento (arma e armadura), combos e Livro, troféus, Maestria e Título; achados em masmorras, raides e resgates (garantia depois de 40 idas) | `masmorras.md` |
| **Trabalho** | uma vaga em Mina, Lagoa, Horta, Oficina e Mercado (aba Trabalho da Estalagem); qualquer um +10%, o ofício certo +25% (Mercado ×0,4); quem trabalha não sai | `CONTEXTO.md` §3 |
| **Aventura** | chefe do personagem inspira seguidores; raide dá Insígnia Épica; zona visitada chama mais; lembrete pequeno no voo e na fila | `masmorras.md` §12 |
| **Conquistas** | 55 em 9 categorias, todas visíveis com o que pedem e quanto falta; pontos; cartão ao conseguir; Mestre do Homestead pede todas | `Achievements.lua` |
| **Personagens** | 5 vozes comentam os avisos (Intendente, Capataz, Escrivão, Mordomo, Conselheira); o Intendente ensina os primeiros passos; o Mordomo anuncia cada versão nas Novidades; desligável | [`personagens.md`](personagens.md) |
| **Resto** | Novidades, "Enquanto você esteve fora", Guia, Ajustes, ícone na tela com aviso, botão do minimapa, zoom 60–150%, Véu de Inverno, ptBR/EN | — |

## 4. Regras de texto

- Todo texto em `Locales.lua`, inglês e português do Brasil, sem chave faltando.
- Português natural de jogador; curto; **sem travessão**; os dois idiomas dizem o mesmo fato.
- Mesmo nome para a mesma coisa (seguidor, masmorra, raide, chamado, quarto, Alojamento, insígnia, Celeiro, Oficina...).
- Códigos (`%s`, `%d`) iguais e na mesma ordem; `%` literal é `%%` quando o texto tem códigos.
- Nada sai do lugar na tela: `python ferramentas/conferir_textos.py` tem de dar **0** e as telas mudadas são olhadas.
- História do Forever só com fatos de [`historia-forever.md`](historia-forever.md) ou do Wowhead do Forever.
- Falas dos personagens: [`personagens.md`](personagens.md) (tom, limites, nada do Portal).

## 5. Regras de arte

- Item do jogo usa **o ícone do jogo** (conferido com `ferramentas/icones_do_jogo.py` e o CASCConsole). Arquivos da
  Blizzard só em `C:\AI\Tools\wowf_extract`, nunca no repositório.
- Arte própria (lugares, mapa, retratos, decorações, ícones das conquistas, personagens) no estilo de
  `arquivo/arte_v5`, em alta resolução (`nome@hd.png`), feita pelo Codex e aprovada pelo dono; Claude importa.
- Ícones das conquistas: **um por categoria** (9), coloridos; o jogo deixa cinza até conseguir.

## 6. Regras de projeto

- Commits, CHANGELOG e notas assinados **Korum**, sem `Co-Authored-By`, sem citar IA.
- **Um pacote por semana, no domingo.** Durante a semana tudo fica no ramo e na cópia do dono; nada vai ao CurseForge
  antes. Tag no meio da semana só se algo impedir de jogar. Merge na `main` e tag só com o ok do dono.
- Tags `vX.Y.0-alphaN` viram Alpha no CurseForge; sem sufixo vira Release; nunca `-rc`.
- CHANGELOG: inglês e depois `### Em português`.
- **Toda versão nova** tem uma fala do Mordomo Fenwick anunciando o patch (`say_patch<id>_1` em EN e PT, `<id>` da
  entrada nova de `News.lua`), escrita por Claude ou pelo Codex e revisada na semana.
- Nunca tocar no token do CurseForge nem publicar dado pessoal.
- O Codex pode estar na pasta principal (`C:\AI\Code\KorumHomestead`); Claude trabalha no worktree
  `C:\AI\Code\KorumHomestead-claude`. Nunca `git add -A` sobre arquivos de outros.
- Instalar na cópia do dono: `instalar.py --apply forever` no repositório dos outros addons, apontando para o worktree
  enquanto o ramo não estiver na `main`.

## 7. Decisões que não se reabrem sem motivo novo

Estão na seção 3 do [`CONTEXTO.md`](CONTEXTO.md), com data. As mais recentes: sem ranking online (22/11); trabalho em
todas as construções (22/11); conquistas (22/11); missão pessoal e amizade aprovadas (22/11); decisões provisórias da
S5 confirmadas (22/11); cinco personagens no lugar de um prefeito (22/11).

## 8. O que falta (a fonte do cronograma)

| # | Item | Quem | Depende de | Estado |
|---|---|---|---|---|
| 1 | Falas dos cinco personagens ([`tarefas/T6.11.md`](tarefas/T6.11.md)) | Codex | — | briefing pronto |
| 2 | 9 ícones das conquistas e 5 retratos ([`tarefas/A11.md`](tarefas/A11.md)) | Codex | — | briefing pronto |
| 3 | Revisão dos textos novos desde a alpha1 (trabalho, conquistas) | Codex | — | a pedir |
| 4 | README e página do CurseForge (masmorras, trabalho, conquistas, personagens) | Claude | — | a fazer |
| 5 | `masmorras.md` igual ao jogo (trabalho, Celeiro, lembrete, conquistas) | Claude | — | a fazer |
| 6 | Importar ícones e retratos; retrato de quem fala no cartão das conquistas e no lembrete | Claude | 2 | a fazer |
| 7 | Momentos novos dos personagens (grupo que falhou, seguidor ferido, falta de moedas, volta depois de muito tempo) | Claude + Codex | 1 | a fazer |
| 8 | **Amizade** entre seguidores (laço 1–3 com 5/15/30 idas, +2% por nível, combo +50% por nível, Diário, melhores amigos na ficha) | Claude | — | aprovada |
| 9 | **Missão pessoal** etapa 1 (nível 10: ida ao lugar de origem, história, traço pessoal) | Claude + Codex (histórias) | — | aprovada |
| 10 | Missão pessoal etapas 2 e 3 (nível 20: peça com nome; nível 30: Título) | Claude + Codex | 9 | aprovada |
| 11 | Conquistas da amizade e da missão pessoal | Claude | 8, 9 | a fazer |
| 12 | Datas das festas pelo calendário do jogo (`C_Calendar`) | Claude | — | a fazer |
| 13 | Teste do T3.0 (`/kh debug`, `/kh eventos`) e ajuste da §12 de `masmorras.md` | Dono, depois Claude | — | a fazer |
| 14 | Teste de economia com tudo ligado, antes da Release | Claude | — | a fazer |
| 15 | Herbário (coleção das ervas colhidas, com conquistas) | Claude | — | ideia aprovada no plano |
| 16 | Decorações no mapa (arte A9) | Codex, depois Claude | — | a pedir |
| 17 | Seguidores andando na vila, perto de onde trabalham (arte A10) | Codex, depois Claude | — | a pedir |
| 18 | Mais de uma vaga de trabalho por construção nos níveis altos | Claude | teste do dono | a decidir |
| 19 | `instalar.py` volta para a pasta principal; pasta principal na `main` | Claude | Release 2.2.0 | a fazer |
| 20 | Social na guilda ("Lendário encontrado!", ver a vila dos outros) | Claude | testar mensagens de addon no Forever | depois |
| 21 | Atributos do personagem, temporadas, mais festas, som e animação | Claude | — | depois |
| sempre | Conteúdo novo do Forever (masmorras, chamados, seguidores) quando aparecer no Wowhead | Claude | o jogo | contínuo |
