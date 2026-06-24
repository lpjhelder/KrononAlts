# KrononAlts

Painel **cross-character** de objetivos semanais para o ecossistema **Kronon**. Mostra, numa janela única, o que falta de **Grande Cofre**, **Mítica+**, **lockouts de raide**, **moedas** e **ouro** em cada um dos seus personagens — core e alts.

## A janela

Painel escuro flat com uma **titlebar** (ícone, título e o countdown de reset semanal/diário) que também é a alça de arrastar — **a posição é salva** entre sessões. Abaixo, uma **linha de resumo** ("X/Y cofres prontos · N com recompensa esperando · M personagens") e a **tabela** (com rolagem para muitos alts).

## Colunas

| Coluna | Conteúdo |
|--------|----------|
| **Personagem** | Ícone de classe + nome em cor de classe. Selo `(!)` quando o snapshot é anterior ao reset atual. |
| **ilvl** | Nível de item equipado. |
| **Rating** | Rating geral de Mítica+ da season, colorido por faixa. |
| **Chave** | Sua keystone atual (masmorra abreviada + nível). |
| **Cofre** | As 6 mini-*pips* do Grande Cofre — 3 da trilha de Mítica+ e 3 da raide — preenchidas (cor de qualidade) ou em contorno. |
| **Crests** | Moeda de upgrade do tier mais alto que você tem; dourada quando o cap semanal foi atingido. |
| **Ouro** | Ouro do personagem. |

**Clique numa linha** para **expandir** um painel de detalhe: retrato (classe/spec/realm) + próxima ação, Grande Cofre por slot, **Mítica+ por masmorra**, lockouts de raide, **moedas & crests**, **semanais** (Conquista, Catalisador) e **profissões** (conhecimento). Apenas uma linha fica aberta por vez.

**Clique nos cabeçalhos** (Personagem, ilvl, Rating, Cofre, Crests, Ouro) para **ordenar** a tabela; a seta indica a direção. O personagem logado fica **destacado** com acento azul; quem tem recompensa de cofre pronta ganha realce dourado. Marque **"Ocultar concluídos"** no topo para esconder personagens com cofre 3/3/3 e sem recompensa pendente.

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
