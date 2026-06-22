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
| **Raide** | Lockout mais relevante (bosses mortos/total por dificuldade). |

Passe o mouse em qualquer célula para o **detalhe** (tooltip de 2 camadas): o breakdown das 3 trilhas do cofre com ilvl previsto por slot, a lista completa de lockouts de raide, a maior chave da semana, etc.

## Como funciona

KrononAlts tira um **snapshot** do personagem logado automaticamente (login, mudança de zona, atualização do cofre, conclusão de Mítica+, mudança nas bolsas e logout) e guarda tudo em **SavedVariables account-wide**. Assim, ao abrir o painel em qualquer personagem, você vê os dados de **todos** que já logou.

- **Detecção de reset:** ao logar, o addon varre todos os personagens e zera a semana dos que já passaram do reset (logar em um zera a semana de todos). A virada de season zera cofre/runs/rating.
- **Reset countdown** semanal e diário ficam no topo da janela.

## Limitação importante

Alt **offline** mostra sempre o **último snapshot** — o WoW não permite ler dados de um personagem sem estar nele. Se o snapshot é anterior ao reset atual, o personagem recebe o selo **"precisa logar"** `(!)`: entre nele uma vez para atualizar. O personagem **logado** atualiza ao vivo.

## Comandos

- `/kalts` ou `/ka` — abre/fecha o painel.
- `/kalts snapshot` — força uma releitura do personagem atual.

Dentro da tabela, **clique-direito** num personagem (que não o atual) para removê-lo do banco.

## Ecossistema

Parte do **Kronon**, junto com o KrononBags e o KrononMarket. Autocontido (sem dependências externas) e trilíngue PT/EN/ES nativo.
