# KrononAlts

Painel **cross-character** de objetivos semanais para o ecossistema **Kronon**. Mostra, numa tabela única, o que falta de **Grande Cofre**, **Mítica+** e **lockouts de raide** em cada um dos seus personagens — core e alts.

## O que mostra

| Coluna | Conteúdo |
|--------|----------|
| **Personagem** | Nome em cor de classe + ilvl. Selo `(!)` quando o snapshot é anterior ao reset atual. |
| **Cofre** | As 3 trilhas do Grande Cofre — Mítica+ · Raide · Mundo — como slots preenchidos (`X/3` cada). `!` dourado quando há recompensa não coletada. |
| **M+** | Número de runs concluídas nesta semana. |
| **Chave** | Sua keystone atual (nível + masmorra). |
| **Rating** | Rating geral de Mítica+ da season. |
| **Crests** | Moeda de upgrade do tier mais alto que você tem; tooltip lista todas as crests da season e fragmentos de Delve com totais e progresso semanal. |
| **Raide** | Lockout mais relevante (bosses mortos/total por dificuldade). |

Passe o mouse em qualquer célula para o **detalhe** (tooltip de 2 camadas): o breakdown das 3 trilhas do cofre com ilvl previsto por slot **e o que falta pro próximo slot de cada trilha**, a lista completa de lockouts de raide, a maior chave da semana, as moedas da season, etc.

**Clique nos cabeçalhos** (Personagem, Cofre, M+, Rating, Crests, Raide) para **ordenar** a tabela; a seta indica a direção. O personagem logado fica **destacado** na tabela. Marque **"Ocultar concluídos"** no topo para esconder personagens com cofre 3/3/3 e sem recompensa pendente.

## Como funciona

KrononAlts tira um **snapshot** do personagem logado automaticamente (login, mudança de zona, atualização do cofre, conclusão de Mítica+, mudança nas bolsas e logout) e guarda tudo em **SavedVariables account-wide**. Assim, ao abrir o painel em qualquer personagem, você vê os dados de **todos** que já logou.

- **Detecção de reset:** ao logar, o addon varre todos os personagens e zera a semana dos que já passaram do reset (logar em um zera a semana de todos). A virada de season zera cofre/runs/rating.
- **Reset countdown** semanal e diário ficam no topo da janela.

## Limitação importante

Alt **offline** mostra sempre o **último snapshot** — o WoW não permite ler dados de um personagem sem estar nele. Se o snapshot é anterior ao reset atual, o personagem recebe o selo **"precisa logar"** `(!)`: entre nele uma vez para atualizar. O personagem **logado** atualiza ao vivo.

## Comandos

- `/kalts` ou `/ka` — abre/fecha o painel.
- `/kalts snapshot` — força uma releitura do personagem atual.
- `/kalts curr` — lista no chat as moedas da season (id + nome + quantidade/cap) e faz uma varredura de descoberta. Útil pra confirmar/ajustar os IDs quando uma season nova chega.

Há também um **botão de minimapa** (clique-esquerdo abre/fecha; arraste para reposicionar no anel; o tooltip resume quantos alts têm cofre cheio ou recompensa pendente).

Dentro da tabela, **clique-direito** num personagem abre um **menu de contexto**: definir um **apelido** (exibido no lugar do nome) ou **remover** o personagem do banco.

## Ecossistema

Parte do **Kronon**, junto com o KrononBags e o KrononMarket. Autocontido (sem dependências externas) e trilíngue PT/EN/ES nativo.
