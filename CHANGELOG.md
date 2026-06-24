# Changelog

## 0.5.0

**Português**

- **Novo: Delves & chave do cofre** — seção própria no painel de detalhe com o tier de delve do cofre da semana, a Chave do Cofre Restaurada / Fragmentos de Chave e a trilha de Delves do Grande Cofre (trilha Mundo).
- **Novo: lembrete ao logar** — alguns segundos após entrar, avisa no chat se há personagens com recompensa de Cofre pra coletar ou com objetivos faltando a menos de 24h do reset. Liga/desliga com `/kalts reminder` (ligado por padrão).
- **Novo: resumo consolidado da conta** no topo da janela — cofres prontos, personagens no cap de crests e ouro total.
- **Novo: agrupar por reino ou facção** — botão de 3 estados (não agrupar / reino / facção), com a ordenação por coluna preservada dentro de cada grupo. Também em `/kalts group`.
- **Novo: chefes mundiais** — a seção Semanais mostra os chefes mundiais já derrotados na semana.
- **Novo: atalho para o KrononBags** — clique-direito num personagem traz "Abrir inventário (KrononBags)" quando o KrononBags está instalado.

**English**

- **New: Delves & coffer key** — dedicated section in the detail panel with this week's vault delve tier, the Restored Coffer Key / Coffer Key Shards and the Great Vault's Delve track (World track).
- **New: login reminder** — a few seconds after logging in, a short chat notice if any character has a vault reward to collect or objectives left within 24h of reset. Toggle with `/kalts reminder` (on by default).
- **New: consolidated account summary** at the top of the window — vaults ready, characters at crest cap and total gold.
- **New: group by realm or faction** — 3-state button (off / realm / faction), with column sorting preserved within each group. Also `/kalts group`.
- **New: world bosses** — the Weeklies section shows the world bosses already defeated this week.
- **New: KrononBags shortcut** — right-clicking a character offers "Open bags (KrononBags)" when KrononBags is installed.

**Español**

- **Nuevo: Profundidades y llave de la cámara** — sección propia en el panel de detalle con el nivel de profundidad de la cámara de la semana, la Llave de Cámara Restaurada / Fragmentos de Llave y la vía de Profundidades de la Gran Cámara (vía Mundo).
- **Nuevo: recordatorio al iniciar sesión** — unos segundos tras entrar, un aviso breve en el chat si algún personaje tiene recompensa de cámara por reclamar u objetivos pendientes a menos de 24h del reinicio. Se activa/desactiva con `/kalts reminder` (activado por defecto).
- **Nuevo: resumen consolidado de la cuenta** en la parte superior de la ventana — cámaras listas, personajes en el tope de crests y oro total.
- **Nuevo: agrupar por reino o facción** — botón de 3 estados (no agrupar / reino / facción), conservando el orden por columna dentro de cada grupo. También con `/kalts group`.
- **Nuevo: jefes de mundo** — la sección Semanales muestra los jefes de mundo ya derrotados esta semana.
- **Nuevo: acceso directo a KrononBags** — el clic derecho sobre un personaje ofrece "Abrir inventario (KrononBags)" cuando KrononBags está instalado.

## 0.4.0

**Português**

- **API pública** (`KrononAlts`): outros addons do ecossistema (ex.: KrononBags) já podem ler o resumo da conta e abrir o painel.
  - `KrononAlts.GetSummary()` — resumo da conta: nº de personagens, cofres com recompensa pendente, cofres cheios (3/3/3) e a próxima ação mais relevante.
  - `KrononAlts.GetChars()` — lista somente-leitura dos personagens com os dados do snapshot.
  - `KrononAlts.Toggle()` / `KrononAlts.Open()` — alterna / abre a janela.
  - `KrononAlts.RegisterForUpdate(fn)` — registra um callback chamado a cada atualização dos snapshots.
- **Novo**: animação de **fade-in** suave ao abrir a janela.
- **Novo**: **brilho dourado sutil** pulsando na linha de quem está com o Grande Cofre cheio (3/3/3).

**English**

- **Public API** (`KrononAlts`): other ecosystem addons (e.g. KrononBags) can now read the account summary and open the panel.
  - `KrononAlts.GetSummary()` — account summary: number of characters, vaults with a reward waiting, full vaults (3/3/3) and the most relevant next action.
  - `KrononAlts.GetChars()` — read-only list of characters with their snapshot data.
  - `KrononAlts.Toggle()` / `KrononAlts.Open()` — toggle / open the window.
  - `KrononAlts.RegisterForUpdate(fn)` — register a callback fired whenever the snapshots update.
- **New**: smooth **fade-in** animation when the window opens.
- **New**: **subtle golden glow** pulsing on the row of any character with a full Great Vault (3/3/3).

**Español**

- **API pública** (`KrononAlts`): otros addons del ecosistema (p. ej. KrononBags) ya pueden leer el resumen de la cuenta y abrir el panel.
  - `KrononAlts.GetSummary()` — resumen de la cuenta: número de personajes, cámaras con recompensa pendiente, cámaras llenas (3/3/3) y la próxima acción más relevante.
  - `KrononAlts.GetChars()` — lista de solo lectura de los personajes con los datos de la instantánea.
  - `KrononAlts.Toggle()` / `KrononAlts.Open()` — alterna / abre la ventana.
  - `KrononAlts.RegisterForUpdate(fn)` — registra una función llamada en cada actualización de las instantáneas.
- **Nuevo**: animación de **fundido de entrada** suave al abrir la ventana.
- **Nuevo**: **brillo dorado sutil** que pulsa en la fila de quien tiene la Gran Cámara llena (3/3/3).

## 0.3.0

**Português**

- **Nova janela**: painel escuro flat redesenhado, com titlebar (ícone, título e countdown de reset semanal/diário) que também é a alça de arrastar.
- **Posição salva**: a janela lembra onde você a deixou entre sessões e relogs.
- **Linha de resumo**: "X/Y cofres prontos · N com recompensa esperando · M personagens" no topo.
- **Tabela compacta** com rolagem para muitos alts: ícone + nome em cor de classe, ilvl, rating de M+ (cor por faixa), chave, cofre em mini-pips (3 M+ + 3 raide) e a nova coluna de **Ouro**.
- **Linha expansível**: clique num personagem para abrir um painel de detalhe com Grande Cofre por slot, **Mítica+ por masmorra**, lockouts de raide, moedas & crests, **semanais** (Conquista, Catalisador) e **profissões** (conhecimento).
- **Personagem logado** destacado com acento azul; quem tem recompensa de cofre pronta ganha realce dourado.
- **Novo**: captura de ouro, melhor chave por masmorra da season, semanais e profissões (defensivo — mostra "—" quando o dado ainda não está disponível).

**English**

- **New window**: redesigned flat dark panel with a titlebar (icon, title and weekly/daily reset countdown) that doubles as the drag handle.
- **Saved position**: the window now remembers where you left it across sessions and relogs.
- **Summary line**: "X/Y vaults full · N with a reward waiting · M characters" at the top.
- **Compact table** with scrolling for many alts: class icon + class-colored name, ilvl, M+ rating (color by bracket), keystone, vault mini-pips (3 M+ + 3 raid) and the new **Gold** column.
- **Expandable row**: click a character to open a detail panel with per-slot Great Vault, **Mythic+ by dungeon**, raid lockouts, currencies & crests, **weeklies** (Conquest, Catalyst) and **professions** (knowledge).
- **Logged character** highlighted with a blue accent; characters with a ready vault reward get a golden highlight.
- **New**: capture of gold, season best key per dungeon, weeklies and professions (defensive — shows "—" when the data isn't available yet).

**Español**

- **Nueva ventana**: panel oscuro plano rediseñado, con una barra de título (icono, título y cuenta atrás del reinicio semanal/diario) que también sirve para arrastrar.
- **Posición guardada**: la ventana ahora recuerda dónde la dejaste entre sesiones y reconexiones.
- **Línea de resumen**: "X/Y cámaras listas · N con recompensa esperando · M personajes" arriba.
- **Tabla compacta** con desplazamiento para muchos personajes: icono + nombre en color de clase, ilvl, puntuación de M+ (color por rango), piedra, cámara en mini-pips (3 M+ + 3 banda) y la nueva columna de **Oro**.
- **Fila expandible**: haz clic en un personaje para abrir un panel de detalle con la Gran Cámara por ranura, **Mítica+ por mazmorra**, bloqueos de banda, monedas y crests, **semanales** (Conquista, Catalizador) y **profesiones** (conocimiento).
- **Personaje conectado** destacado con un acento azul; los personajes con recompensa de cámara lista reciben un realce dorado.
- **Nuevo**: captura de oro, mejor piedra por mazmorra de la temporada, semanales y profesiones (defensivo — muestra "—" cuando el dato aún no está disponible).

## 0.2.0

**Português**

- **Próxima ação no Cofre**: o tooltip do Grande Cofre agora mostra o que falta para o próximo slot de cada trilha (ex.: "Mítica+: +1 p/ slot 2").
- **Botão de minimapa**: arrastável no anel do minimapa; clique-esquerdo abre/fecha o painel; tooltip resume quantos alts têm cofre cheio ou recompensa pendente.
- **Personagem ativo destacado**: a linha do personagem logado ganha um acento sutil.
- **Ocultar concluídos**: opção no topo que esconde personagens com cofre 3/3/3 e sem recompensa pendente.
- **Apelidos**: clique-direito no nome abre um menu de contexto para definir um apelido ou remover o personagem.
- **Ordenação por coluna**: clique nos cabeçalhos (Personagem, Cofre, M+, Rating, Crests, Raide) para ordenar, com seta de direção.
- **Crests da season**: nova coluna com as moedas de upgrade (Dawncrest) e fragmentos de Delve, com totais e progresso semanal no tooltip. Comando `/kalts curr` lista os IDs in-game.

**English**

- **Vault next action**: the Great Vault tooltip now shows what's left for each track's next slot (e.g. "Mythic+: +1 to slot 2").
- **Minimap button**: draggable around the minimap ring; left-click toggles the panel; tooltip summarizes how many alts have a full vault or pending reward.
- **Active character highlight**: the logged character's row gets a subtle accent.
- **Hide completed**: a top toggle hides characters with a 3/3/3 vault and no pending reward.
- **Nicknames**: right-click a name for a context menu to set a nickname or remove the character.
- **Column sorting**: click headers (Character, Vault, M+, Rating, Crests, Raid) to sort, with a direction arrow.
- **Season crests**: new column with the upgrade currencies (Dawncrest) and Delve shards, with totals and weekly progress in the tooltip. The `/kalts curr` command lists the IDs in-game.

**Español**

- **Próxima acción de la Cámara**: la información de la Gran Cámara ahora muestra lo que falta para la siguiente ranura de cada vía (p. ej. "Mítica+: +1 para ranura 2").
- **Botón de minimapa**: arrastrable por el anillo del minimapa; clic izquierdo abre/cierra el panel; la información resume cuántos personajes tienen la cámara llena o recompensa pendiente.
- **Personaje activo destacado**: la fila del personaje conectado recibe un acento sutil.
- **Ocultar completados**: opción superior que esconde personajes con cámara 3/3/3 y sin recompensa pendiente.
- **Apodos**: clic derecho en el nombre abre un menú contextual para definir un apodo o eliminar el personaje.
- **Ordenación por columna**: haz clic en los encabezados (Personaje, Cámara, M+, Punt., Crests, Banda) para ordenar, con flecha de dirección.
- **Crests de la temporada**: nueva columna con las monedas de mejora (Dawncrest) y fragmentos de Cavernas, con totales y progreso semanal en la información. El comando `/kalts curr` lista los IDs en el juego.

## 0.1.1

**Português**

- Ajustes internos de empacotamento para a publicação.

**English**

- Internal packaging adjustments for release.

**Español**

- Ajustes internos de empaquetado para la publicación.

## 0.1.0

**Português**

- **Painel cross-character** (`/kalts` ou `/ka`): vê numa única tabela o que falta de objetivos semanais em todos os seus personagens.
- **Grande Cofre**: as 3 trilhas (Mítica+, Raide, Mundo) com slots preenchidos e o nível de item previsto no tooltip; aviso quando há recompensa não coletada.
- **Mítica+**: runs da semana, maior chave da semana, rating geral e a chave atual (nível + masmorra).
- **Lockouts de raide**: bosses mortos/total por dificuldade, com a lista completa no tooltip.
- **Reset countdown** semanal e diário no topo; **selo "precisa logar"** nos personagens com snapshot anterior ao reset atual.
- Trilíngue (PT/EN/ES), cor semântica sempre acompanhada de número/glifo, e atualização ao vivo do personagem logado.

**English**

- **Cross-character panel** (`/kalts` or `/ka`): see in a single table what's left of your weekly goals across all characters.
- **Great Vault**: the 3 tracks (Mythic+, Raid, World) with filled slots and predicted item level in the tooltip; warning when a reward is uncollected.
- **Mythic+**: runs this week, best key of the week, overall rating and your current keystone (level + dungeon).
- **Raid lockouts**: bosses killed/total per difficulty, with the full list in the tooltip.
- **Reset countdown** for weekly and daily at the top; **"needs login" seal** on characters whose snapshot predates the current reset.
- Trilingual (PT/EN/ES), semantic color always paired with a number/glyph, and live refresh for the logged character.

**Español**

- **Panel multipersonaje** (`/kalts` o `/ka`): mira en una sola tabla lo que falta de tus objetivos semanales en todos tus personajes.
- **Gran Cámara**: las 3 vías (Mítica+, Banda, Mundo) con las ranuras llenas y el nivel de objeto previsto en la información; aviso cuando hay una recompensa sin reclamar.
- **Mítica+**: carreras de la semana, mejor piedra de la semana, puntuación general y tu piedra angular actual (nivel + mazmorra).
- **Bloqueos de banda**: jefes muertos/total por dificultad, con la lista completa en la información.
- **Cuenta atrás de reinicio** semanal y diario arriba; **sello "necesita entrar"** en los personajes cuya instantánea es anterior al reinicio actual.
- Trilingüe (PT/EN/ES), color semántico siempre acompañado de un número/glifo, y actualización en vivo del personaje conectado.
