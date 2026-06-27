# Changelog

## 0.7.2
**Português**
- **Novo:** no modo **PvP**, o tooltip ao passar o mouse num personagem mostra o rating por modalidade (2v2/3v3/RBG/Solo Shuffle/Blitz), a Conquista e a honra — antes mostrava só o M+.

**English**
- **New:** in **PvP** mode, hovering a character now shows rating per bracket (2v2/3v3/RBG/Solo Shuffle/Blitz), Conquest and honor — it used to show only M+.

**Español**
- **Nuevo:** en modo **PvP**, al pasar el ratón por un personaje ahora muestra la clasificación por modalidad (2c2/3c3/CBC/Combate Singular/Blitz), Conquista y honor — antes mostraba solo M+.

## 0.7.1

No modo PvP, a tabela principal agora mostra Rating e Conquista. / In PvP mode, the main table now shows Rating and Conquest. / En modo PvP, la tabla principal ahora muestra Rating y Conquista.

**Português**

- **Modo PvP na linha recolhida** — ao escolher **PvP** na config, a tabela principal troca duas colunas sem precisar expandir: **M+ vira Rating** (o maior rating de PvP do personagem, colorido por faixa) e **Crest vira Conquista** (ganho/cap da semana, com **✓** no cap). Personagem sem dados de PvP mostra **—**.
- **Cabeçalhos e ordenação acompanham** — os títulos dessas colunas viram **Rating** e **Conquista** no modo PvP, e clicar para ordenar passa a ordenar por rating de PvP e por Conquista.
- **Inalterado** — nos modos **PvE** e **Ambos** a tabela continua exatamente como antes; pips do cofre, ilvl, nome e ouro não mudam em nenhum modo. Trocar de modo atualiza a tabela na hora.

**English**

- **PvP mode in the collapsed row** — picking **PvP** in settings swaps two columns in the main table without expanding: **M+ becomes Rating** (the character's highest PvP rating, colored by tier) and **Crest becomes Conquest** (weekly earned/cap, with **✓** at cap). A character with no PvP data shows **—**.
- **Headers and sorting follow** — those column titles become **Rating** and **Conquest** in PvP mode, and clicking to sort now sorts by PvP rating and by Conquest.
- **Unchanged** — in **PvE** and **Both** modes the table stays exactly as before; vault pips, ilvl, name and gold never change in any mode. Switching mode updates the table instantly.

**Español**

- **Modo PvP en la fila contraída** — al elegir **PvP** en la configuración, la tabla principal cambia dos columnas sin expandir: **M+ pasa a Rating** (la puntuación PvP más alta del personaje, coloreada por nivel) y **Crest pasa a Conquista** (ganado/tope de la semana, con **✓** al tope). Un personaje sin datos de PvP muestra **—**.
- **Encabezados y orden acompañan** — esos títulos de columna pasan a **Rating** y **Conquista** en modo PvP, y al ordenar ahora se ordena por puntuación PvP y por Conquista.
- **Sin cambios** — en los modos **PvE** y **Ambos** la tabla sigue igual que antes; los pips de la cámara, ilvl, nombre y oro no cambian en ningún modo. Cambiar de modo actualiza la tabla al instante.

## 0.7.0

Janela de configurações própria, modo PvP/PvE/Ambos e rastreio de PvP. / Dedicated settings window, PvP/PvE/Both mode and PvP tracking. / Ventana de configuración propia, modo PvP/PvE/Ambos y seguimiento de PvP.

**Português**

- **Novo: janela de configurações** — abre pela engrenagem no topo do painel ou por `/kalts config`. Sidebar de categorias (Geral, Exibição, Sobre) com barra de acento na ativa, painel rolável com seções douradas e toggles tipo switch (verde ligado / cinza desligado) com descrição. Lembra a última categoria e a posição; botão **Restaurar padrões** no rodapé.
- **Migrado para a config** — mostrar **Ouro**, mostrar **Profissões**, **agrupar** por reino/facção (cascata liga/critério), **lembrete ao logar** e **ocultar concluídos**. Os atalhos `/kalts gold` e `/kalts prof` continuam funcionando.
- **Novo: modo PvE / PvP / Ambos** — seletor no topo da config filtra as seções do detalhe de cada personagem. **PvE**: Grande Cofre, M+ por masmorra, lockouts, Delves, moedas. **PvP**: só a seção PvP. **Ambos**: tudo.
- **Novo: rastreio de PvP** — seção **PvP** no detalhe com **rating por modalidade** (2v2, 3v3, Combate Singular, BG Relâmpago, BG Pontuado), **Conquista** (ganho vs. cap semanal) e **nível de honra**. O progresso semanal zera no reset.

**English**

- **New: settings window** — opens from the gear at the top of the panel or via `/kalts config`. Category sidebar (General, Display, About) with an accent bar on the active one, a scrollable panel with golden sections and switch-style toggles (green on / gray off) with descriptions. Remembers the last category and position; **Restore defaults** button in the footer.
- **Moved into settings** — show **Gold**, show **Professions**, **group** by realm/faction (toggle + criterion cascade), **login reminder** and **hide completed**. The `/kalts gold` and `/kalts prof` shortcuts still work.
- **New: PvE / PvP / Both mode** — a selector at the top of settings filters the per-character detail sections. **PvE**: Great Vault, M+ by dungeon, lockouts, Delves, currencies. **PvP**: only the PvP section. **Both**: everything.
- **New: PvP tracking** — a **PvP** section in the detail with **rating per bracket** (2v2, 3v3, Solo Shuffle, BG Blitz, Rated BG), **Conquest** (earned vs. weekly cap) and **honor level**. Weekly progress resets on reset.

**Español**

- **Nuevo: ventana de configuración** — se abre con el engranaje en la parte superior del panel o con `/kalts config`. Barra lateral de categorías (General, Visualización, Acerca de) con barra de acento en la activa, panel desplazable con secciones doradas e interruptores (verde activado / gris desactivado) con descripción. Recuerda la última categoría y la posición; botón **Restaurar valores** en el pie.
- **Movido a la configuración** — mostrar **Oro**, mostrar **Profesiones**, **agrupar** por reino/facción (interruptor + criterio en cascada), **recordatorio al iniciar sesión** y **ocultar completados**. Los atajos `/kalts gold` y `/kalts prof` siguen funcionando.
- **Nuevo: modo PvE / PvP / Ambos** — un selector en la parte superior de la configuración filtra las secciones del detalle de cada personaje. **PvE**: Gran Cámara, M+ por mazmorra, bloqueos, Profundidades, monedas. **PvP**: solo la sección PvP. **Ambos**: todo.
- **Nuevo: seguimiento de PvP** — una sección **PvP** en el detalle con **puntuación por modalidad** (2c2, 3c3, Combate Singular, BG Relámpago, BG Clasificatoria), **Conquista** (ganado vs. tope semanal) y **nivel de honor**. El progreso semanal se reinicia con el reinicio.

## 0.6.0

Redesenho "menos é mais": o painel agora destaca o que importa e corta repetição. / "Less is more" redesign: the panel now highlights what matters and cuts repetition. / Rediseño "menos es más": el panel ahora resalta lo importante y elimina repeticiones.

**Português**

- **Pips do cofre com 3 trilhas** — agora **M+ | Raide | Delve** (9 pips). Um alt que só fez delves deixa de parecer vazio.
- **Coluna M+ unificada** — mostra **"+N"** da chave colorido pela faixa de rating; o rating exato vai pro tooltip da linha.
- **Crests por cap semanal** — a coluna mostra **✓** quando no cap (senão o progresso curto); os 5 tiers em número ficam no detalhe.
- **Resumo do topo acionável** — troca o ouro por **"X com recompensa a coletar"**.
- **Detalhe enxuto** — Delves promovido pro topo, lockouts de raide em 1 linha, e fim das repetições (sem "Trilha de Delves" duplicada nem "falta +N" repetido).
- **Cortes** — removidos o countdown diário (fica só o semanal, em destaque) e a seção de chefes mundiais.
- **Opcionais (OFF por padrão)** — coluna de **Ouro** (`/kalts gold`) e seção de **Profissões** (`/kalts prof` ou toggle no detalhe). Ouro total e **Catalisador** (Warband) agora no tooltip do minimapa.
- **Visual mais calmo** — dourado reservado só pra recompensa pronta / cofre 3/3/3; demais números em cinza neutro; brilho estático quando vários cofres estão cheios.

**English**

- **Vault pips with 3 tracks** — now **M+ | Raid | Delve** (9 pips). An alt that only ran delves no longer looks empty.
- **Unified M+ column** — shows the keystone **"+N"** colored by rating tier; the exact rating moves to the row tooltip.
- **Crests by weekly cap** — the column shows **✓** when at cap (otherwise short progress); the 5 tiers in numbers stay in the detail.
- **Actionable top summary** — swaps gold for **"X with a reward to collect"**.
- **Leaner detail** — Delves promoted to the top, raid lockouts down to a single line, and no more duplication (no duplicated "Delve track", no repeated "+N to go").
- **Cuts** — removed the daily countdown (only the weekly remains, highlighted) and the world bosses section.
- **Optional (OFF by default)** — **Gold** column (`/kalts gold`) and **Professions** section (`/kalts prof` or the detail toggle). Total gold and **Catalyst** (Warband) now live in the minimap tooltip.
- **Calmer visuals** — gold reserved for a ready reward / full 3/3/3 vault; other numbers in neutral gray; static glow when several vaults are full.

**Español**

- **Pips de la cámara con 3 vías** — ahora **M+ | Banda | Profundidad** (9 pips). Un alt que solo hizo profundidades deja de parecer vacío.
- **Columna M+ unificada** — muestra el **"+N"** de la piedra coloreado por el nivel de puntuación; la puntuación exacta pasa al tooltip de la fila.
- **Crests por tope semanal** — la columna muestra **✓** al llegar al tope (si no, el progreso corto); los 5 niveles en número quedan en el detalle.
- **Resumen superior accionable** — cambia el oro por **"X con recompensa por reclamar"**.
- **Detalle más limpio** — Profundidades promovido arriba, bloqueos de banda en 1 línea, y sin repeticiones (sin "Vía de Profundidades" duplicada ni "+N" repetido).
- **Recortes** — eliminados la cuenta atrás diaria (solo queda la semanal, resaltada) y la sección de jefes de mundo.
- **Opcionales (OFF por defecto)** — columna de **Oro** (`/kalts gold`) y sección de **Profesiones** (`/kalts prof` o el toggle del detalle). Oro total y **Catalizador** (Hermandad de guerra) ahora en el tooltip del minimapa.
- **Visual más tranquilo** — el dorado se reserva para recompensa lista / cámara 3/3/3; los demás números en gris neutro; brillo estático cuando varias cámaras están llenas.

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
