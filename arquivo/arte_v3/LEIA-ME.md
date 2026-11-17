# Korum Homestead: pedido de arte, rodada 3

Você já entregou as construções em pixel art (`aprovadas_manter_estilo/`). **O estilo aprovado é esse**: pixel art detalhada,
luz quente de lanterna, madeira e pedra, bandeira turquesa do Korum, vegetação e acabamento rico. Tudo o que falta tem que
parecer feito pela mesma mão. Abaixo, o que precisa ser feito, com medidas exatas. O que está em `referencia_provisoria/` é
arte **temporária minha, só para mostrar tamanho, posição e função**; não copie o estilo dela, copie o das aprovadas.

## 1. O MAPA (o mais importante: ainda é o antigo, de formas lisas)
Arquivo `map.png`, **1024 x 512 px**, RGBA. Refazer inteiro no mesmo estilo das construções.
- Vista **de cima, levemente inclinada**, de uma aldeia de fantasia, como num jogo de estratégia de aldeia.
- Chão com textura (grama com variação, terra, pedras pequenas, flores), estradas de terra, árvores, pequenas águas. Nada de
  cores chapadas lisas. Escurecer e suavizar só as bordas (a janela do jogo é escura), com **cantos arredondados** (raio ~22 px).
- O jogo mostra o mapa a **664 x 332** (reduz a 65%). Detalhes menores que ~2 px somem; priorize formas legíveis.
- **Oito pontos fixos**, um por construção: espaço **plano, claro e livre** e uma **estrada** ligando todos. As coordenadas são
  do **pé da construção** (centro, em pixels do mapa 1024x512). Veja `mapa_com_as_oito_posicoes.png`:

  | construção | x | y |   | construção | x | y |
  |---|---|---|---|---|---|---|
  | pond (lagoa) | 140 | 214 |   | garden (horta) | 150 | 420 |
  | hall (sede) | 395 | 232 |   | market (mercado) | 395 | 424 |
  | workshop (oficina) | 650 | 222 |   | inn (estalagem) | 650 | 424 |
  | mine (mina) | 900 | 210 |   | barn (celeiro) | 900 | 410 |

- Duas fileiras de quatro. Estrada de cima: pond > hall > workshop > mine. Estrada de baixo: entrando pela esquerda, garden >
  market > inn > barn, saindo pela direita. Duas ligações entre as fileiras (hall-market e workshop-inn).
- Cada construção ocupa até ~160 px de largura e ~185 px de altura acima do ponto. **Abaixo do ponto, ~65 px (e 180 px de
  largura) ficam cobertos por uma placa do jogo** (nome e nível): não ponha nada importante ali.
- Sua Mina e sua Lagoa já trazem rochas e água no próprio desenho: no mapa, atrás delas, só um relevo ou margem **discretos**
  (um morro baixo atrás da mina, um trecho de água atrás da lagoa), para as construções não "brigarem" com o fundo.
- Não desenhe construções no mapa: elas são imagens separadas, colocadas por cima.

## 2. CONSTRUÇÕES NOVAS (mesmo formato das aprovadas)
`workshop1.png`, `workshop2.png`, `workshop3.png`  e  `inn1.png`, `inn2.png`, `inn3.png`
- **256 x 256 px, fundo transparente**, construção de pé no chão na **linha y = 216**, centrada, sombra suave embutida,
  base de pedra/grama como nas suas outras. Evolução 1 (simples) > 2 > 3 (final, imponente), crescendo no mesmo lugar.
- **Oficina (workshop):** casa de **alquimista**: caldeirão fumegante, frascos e potes coloridos, ervas secando, chaminé com
  fumaça, um mortário. Tons de roxo/azul no telhado para diferenciar da Sede (vermelha/turquesa), sempre com a bandeira
  turquesa. No nível 3, uma torre/laboratório com cristais.
- **Estalagem (inn):** **taverna** acolhedora: placa pendurada com uma caneca, janelas acesas, cavalos/carroça no pátio, barris,
  mesas do lado de fora. No nível 3, dois andares e um estábulo.
- Posições no mapa: workshop (650,222) e inn (650,424).
- Referência de tamanho e silhueta (provisória, feia de propósito): `referencia_provisoria/workshop*.png`, `inn*.png`.

## 3. ÍCONES NOVOS  (64 x 64 px, fundo transparente, mesmo estilo)
- `heal.png` **poção de cura** (vermelha), `mana.png` **poção de mana** (azul), `agil.png` **poção de agilidade** (dourada/amarela).
  Frasco redondo com rolha, brilho e líquido; 3 cores bem distintas, legíveis a 22 px.
- Seguidores, **retratos redondos** (arte dentro de um círculo, fundo transparente fora dele), 64 x 64: `follower1.png` a
  `follower6.png`. São os seis aventureiros da estalagem; nomes: **Mira, Tobin, Elda, Garrick, Sela, Bram**. Variar
  idade, gênero, roupa e ofício (arqueira, ferreiro, herborista, guerreiro, maga, bardo ou ladino), todos com um detalhe turquesa
  na roupa. Rosto legível a 40 px.

## 4. AJUSTES NAS APROVADAS
- **Pixels soltos nas bordas** (limpar): garden1/2/3, lot, hall1, works, mine1, barn1, market1.
- **`works.png` (andaime de obra):** hoje é um quadro avulso que esconde a construção. Refazer como **moldura de andaime
  vazada** (só madeira, cordas, tábuas e uma bandeira de obra), 256x256 transparente, com o interior **transparente** para a
  construção aparecer por baixo, cobrindo a área de 160 x 190 px acima da linha y=216.
- **`lot.png` (terreno vazio)** da Mina, da Lagoa, da Oficina e da Estalagem antes de construídas: está bom; só limpar as bordas e
  deixar a placa de "à venda" sem texto.
- **`logo.png`** (64x64): **sem texto**, só um **broto** turquesa e dourado sobre disco escuro com aro turquesa. A de hoje com
  "KORUM" é ilegível nesse tamanho.
- `ore.png` e `fish.png` estão ótimos: manter.

## 5. TÉCNICA (para ficar nítido dentro do jogo)
O jogo reduz as imagens (construção 256 px vira 104 px no mapa, e 38 px na lista da Sede). Pixel art reduzida com filtro suave
perde nitidez. Para o melhor resultado, **desenhe numa grade real de pixels** e entregue **dois arquivos de cada imagem**:
- `nome.png` na grade nativa (construções **128 x 128**, ícones **32 x 32**, mapa **512 x 256**), paleta limitada (até ~48 cores
  por imagem), bordas **sem anti-aliasing** (alfa só 0 ou 255);
- `nome@2x.png` o mesmo ampliado **2x por vizinho mais próximo** (256x256, 64x64, 1024x512), sem suavizar.

Assim eu uso a nativa com filtro "nearest" (nitidez total) e tenho a ampliada como segurança.

## 6. LISTA DE ENTREGA (nomes exatos)
`map`, `workshop1`, `workshop2`, `workshop3`, `inn1`, `inn2`, `inn3`, `heal`, `mana`, `agil`, `follower1`..`follower6`, `works`,
`lot`, `logo`, e as aprovadas já limpas: `hall1..3`, `garden1..3`, `barn1..3`, `market1..3`, `mine1..3`, `pond1..3`, `ore`, `fish`.
Um único zip, PNG com transparência (RGBA), exceto o mapa que preenche tudo (cantos arredondados transparentes).

## 7. Cores do jogo, para combinar
Turquesa `#40D9CC` (destaque do Korum, bandeiras e detalhes), ouro `#FFD14D`, fundo da janela `#0A0D10`. A janela em volta é
escura e minimalista: a arte é o que traz cor e vida.

## 8. Como você verá (pasta `como_fica_no_jogo/`)
Capturas do jogo com a arte provisória, e `suas_construcoes_sobre_o_mapa_antigo.png`, que mostra suas construções sobre o mapa
antigo no tamanho real: o contraste de estilo com o mapa liso é o que o novo mapa tem que resolver.
