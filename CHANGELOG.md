# Changelog

## 0.10.0

Nova aba **Raides** com a tabela de recompensas de raid por dificuldade. / New **Raids** tab with the raid reward table by difficulty. / Nueva pestaña **Bandas** con la tabla de recompensas de banda por dificultad.

**Português**

- **Nova aba "Raides"** — ao lado de **Personagens**, **Chaves** e **Progresso**, uma tabela de **recompensas de raid por dificuldade** (LFR / Normal / Heroico / Mítico): a faixa de **ilvl que os bosses dropam** (do 1º ao último boss), a **trilha** (Veterano / Campeão / Herói / Mítico, coloridas), o **Cofre** e o **tier de brasão** de cada dificuldade. Cada linha tem um acento na cor do tier.
- Os **ilvls espelham os dados do KeystoneLoot** (LFR 233–243 · Normal 246–256 · Heroico 259–269 · Mítico 272–282). A aba some no modo **somente PvP**, como Chaves e Progresso. Trilíngue.

**English**

- **New "Raids" tab** — alongside **Characters**, **Keys** and **Progress**, a table of **raid rewards by difficulty** (LFR / Normal / Heroic / Mythic): the **ilvl range bosses drop** (first to last boss), the **track** (Veteran / Champion / Hero / Myth, color-coded), the **Great Vault** and the **crest tier** of each difficulty. Each row has a tier-colored accent.
- Item levels **mirror the KeystoneLoot data** (LFR 233–243 · Normal 246–256 · Heroic 259–269 · Mythic 272–282). The tab hides in **PvP-only** mode, like Keys and Progress. Trilingual.

**Español**

- **Nueva pestaña "Bandas"** — junto a **Personajes**, **Llaves** y **Progreso**, una tabla de **recompensas de banda por dificultad** (LFR / Normal / Heroico / Mítico): el rango de **ilvl que sueltan los jefes** (del primero al último), la **vía** (Veterano / Campeón / Héroe / Mítico, con color), la **Cámara** y el **tier de blasón** de cada dificultad. Cada fila tiene un acento del color del tier.
- Los niveles de objeto **reflejan los datos de KeystoneLoot** (LFR 233–243 · Normal 246–256 · Heroico 259–269 · Mítico 272–282). La pestaña se oculta en modo **solo PvP**, como Llaves y Progreso. Trilingüe.

## 0.9.1

Moldura da janela mais elaborada. / More elaborate window frame. / Marco de la ventana más elaborado.

**Português**

- **Moldura nativa do WoW** — a janela passou a usar a **moldura dourada nativa** (borda elaborada com cantos, barra de título e botão de fechar) com um **portrait circular exibindo a logo do Kronon**. Vale para as três abas. É só aparência — arraste, posição salva, minimapa, config e conteúdo continuam iguais.
- **Banners de dungeon** — na tabela de prioridade (aba **Progresso**), cada dungeon agora mostra a **arte da masmorra** como fundo, com um leve **fade** à direita, deixando a lista mais viva.

**English**

- **Native WoW frame** — the window now uses the **native gold frame** (elaborate corner border, title bar and close button) with a **circular portrait showing the Kronon logo**. Applies to all three tabs. Visual only — dragging, saved position, minimap, settings and content are unchanged.
- **Dungeon banners** — in the priority table (**Progress** tab), each dungeon now shows its **instance art** as a background with a subtle right-side **fade**, making the list livelier.

**Español**

- **Marco nativo de WoW** — la ventana ahora usa el **marco dorado nativo** (borde elaborado con esquinas, barra de título y botón de cerrar) con un **retrato circular que muestra el logo de Kronon**. Aplica a las tres pestañas. Solo apariencia — arrastrar, posición guardada, minimapa, configuración y contenido no cambian.
- **Banners de mazmorra** — en la tabla de prioridad (pestaña **Progreso**), cada mazmorra ahora muestra el **arte de la instancia** como fondo con un sutil **difuminado** a la derecha, dando más vida a la lista.

## 0.9.0

Nova aba **Progresso** ("O que fazer agora") com um coach de upgrade. / New **Progress** tab ("What to do now") with an upgrade coach. / Nueva pestaña **Progreso** ("Qué hacer ahora") con un coach de mejora.

**Português**

- **Nova aba "Progresso"** — uma terceira view, ao lado de **Personagens** e **Chaves**, que lê o personagem logado e diz **o que fazer agora** para subir de item level.
- **Resumo de equipamento + diagnóstico** — varre o gear equipado, identifica a **trilha** de cada peça (**Campeão** / **Herói** / **Mítico**, coloridas), mostra **quantas peças ainda dá pra melhorar**, aponta o **elo mais fraco** (slot onde focar primeiro) e seu **ilvl / 289** (teto da season).
- **Brasões com cap semanal** — mostra quanto você tem de cada brasão e o **progresso do limite da semana** (ex.: "Herói: 64 (40/100 esta semana)"), usando o teto **real** da API (respeita o catch-up que acumula com as semanas), e **avisa quando um brasão está perto do cap** — gaste antes do reset.
- **Sugestões acionáveis + tabela de prioridade** — **Gastar brasões** por trilha (quantos upgrades já dá pra fazer, quantos brasões faltam pra maxar); **qual chave** fazer conforme seu equipamento (Mítica 0 → +6/+7 → +9/+10 → +10) com o objetivo **+10 (Cofre Mítico)**; e uma **tabela de prioridade de dungeons** que mostra, por dungeon (com ícone), os seus favoritos **como ícones** (tooltip ao passar o mouse, estrela de **BiS**/**essencial**), ordenada pela quantidade.
- **Visual renovado** — o addon inteiro ganhou um estilo coeso (linhas zebradas, divisórias finas, abas com destaque do ativo, ícones de dungeon/item) inspirado no KeystoneLoot. É só aparência: dados, ordenação, cálculos e comportamento continuam idênticos.
- **Integração opcional com o KeystoneLoot** — as sugestões de BiS por dungeon usam seus favoritos do KeystoneLoot quando ele está instalado; sem ele, o resto do coach continua funcionando normalmente.
- **Respeita o modo** — as abas **Chaves** e **Progresso** ficam ocultas no modo **somente PvP** (recompensas de M+ não fazem sentido ali).

**English**

- **New "Progress" tab** — a third view, alongside **Characters** and **Keys**, that reads your logged-in character and tells you **what to do now** to raise your item level.
- **Gear summary + diagnostic** — scans your equipped gear, identifies each piece's **track** (**Champion** / **Hero** / **Myth**, color-coded), shows **how many pieces can still be upgraded**, points out your **weakest link** (the slot to focus first) and your **ilvl / 289** (season cap).
- **Crests with weekly cap** — shows how much of each crest you have plus the **weekly cap progress** (e.g. "Hero: 64 (40/100 this week)"), using the API's **real** cap (honors the catch-up that grows week over week), and **warns when a crest is near the cap** — spend before reset.
- **Actionable suggestions + priority table** — **Spend crests** per track (how many upgrades you can do now, how many crests left to max); **which key** to run based on your gear (Mythic 0 → +6/+7 → +9/+10 → +10) with the **+10 (Mythic Vault)** goal; and a **dungeon priority table** showing, per dungeon (with icon), your favorites **as item icons** (hover tooltip, **BiS**/**essential** star), ordered by count.
- **Refreshed look** — the whole addon got a cohesive style (zebra rows, thin dividers, active-tab highlight, dungeon/item icons) inspired by KeystoneLoot. Visual only: data, sorting, calculations and behavior are unchanged.
- **Optional KeystoneLoot integration** — the per-dungeon BiS suggestions use your KeystoneLoot favorites when it is installed; without it, the rest of the coach keeps working.
- **Mode-aware** — the **Keys** and **Progress** tabs are hidden in **PvP-only** mode (M+ rewards do not apply there).

**Español**

- **Nueva pestaña "Progreso"** — una tercera vista, junto a **Personajes** y **Llaves**, que lee tu personaje conectado y te dice **qué hacer ahora** para subir tu nivel de objeto.
- **Resumen de equipo + diagnóstico** — escanea tu equipo, identifica la **vía** de cada pieza (**Campeón** / **Héroe** / **Mítico**, con color), muestra **cuántas piezas se pueden mejorar todavía**, señala el **eslabón más débil** (la ranura en la que enfocarte primero) y tu **ilvl / 289** (tope de temporada).
- **Blasones con tope semanal** — muestra cuánto tienes de cada blasón y el **progreso del tope de la semana** (p. ej. "Héroe: 64 (40/100 esta semana)"), usando el tope **real** de la API (respeta el catch-up que se acumula semana a semana), y **avisa cuando un blasón está cerca del tope** — gasta antes del reinicio.
- **Sugerencias accionables + tabla de prioridad** — **Gastar blasones** por vía (cuántas mejoras puedes hacer ya, cuántos blasones faltan para maximizar); **qué llave** hacer según tu equipo (Mítica 0 → +6/+7 → +9/+10 → +10) con el objetivo **+10 (Cámara Mítica)**; y una **tabla de prioridad de mazmorras** que muestra, por mazmorra (con icono), tus favoritos **como iconos** (tooltip al pasar el ratón, estrella de **BiS**/**esencial**), ordenada por cantidad.
- **Aspecto renovado** — todo el addon recibió un estilo coherente (filas cebra, divisores finos, resalte de la pestaña activa, iconos de mazmorra/objeto) inspirado en KeystoneLoot. Solo apariencia: datos, orden, cálculos y comportamiento no cambian.
- **Integración opcional con KeystoneLoot** — las sugerencias de BiS por mazmorra usan tus favoritos de KeystoneLoot cuando está instalado; sin él, el resto del coach sigue funcionando.
- **Respeta el modo** — las pestañas **Llaves** y **Progreso** se ocultan en modo **solo PvP** (las recompensas de M+ no aplican ahí).

## 0.8.0

Nova aba **Chaves** com a tabela de recompensas de Mítica+. / New **Keys** tab with the Mythic+ rewards table. / Nueva pestaña **Llaves** con la tabla de recompensas de Mítica+.

**Português**

- **Nova aba "Chaves"** — dois botões de view no topo da janela alternam entre **Personagens** (a tabela de sempre) e **Chaves**. A escolha é salva entre sessões.
- **Tabela de recompensas de Mítica+ · Temporada 1** — todas as 9 linhas de **+2 a +10**, com o item de **fim da masmorra** e do **Grande Cofre** (ilvl + trilha) e o **brasão** ganho (quantidade + tier). As trilhas são coloridas por tier: **Campeão** verde, **Herói** azul, **Mítico** dourado.
- **Destaque dos saltos** — as linhas onde o brasão muda de tier (**+4** vira Herói, **+9** vira Mítico) e onde o Cofre vira Mítico (**+10**) ganham realce e um acento na cor do novo tier.
- **No contexto do seu personagem** — mostra o **seu ilvl equipado** e marca com **✓** as chaves cujo Fim/Cofre já são upgrade; um guia curto resume "Fim sobe a partir de +X · Cofre a partir de +Y".
- **Rodapé de upgrade** — lembra o custo (20 brasões por nível, 120 por item inteiro, limite de 100/semana por tipo) com uma dica derivada da própria tabela.

**English**

- **New "Keys" tab** — two view buttons at the top of the window switch between **Characters** (the usual table) and **Keys**. The choice is saved across sessions.
- **Mythic+ rewards table · Season 1** — all 9 rows from **+2 to +10**, with the **end-of-run** and **Great Vault** item (ilvl + track) and the **crest** earned (amount + tier). Tracks are colored by tier: **Champion** green, **Hero** blue, **Myth** gold.
- **Tier-jump highlights** — the rows where the crest changes tier (**+4** becomes Hero, **+9** becomes Myth) and where the Vault turns Myth (**+10**) get a highlight and an accent in the new tier's color.
- **In your character's context** — shows your **equipped ilvl** and flags with **✓** the keys whose End/Vault reward is already an upgrade; a short guide sums up "End-of-run rises from +X · Vault from +Y".
- **Upgrade footer** — recaps the cost (20 crests per level, 120 for a full item, 100/week cap per type) with a tip derived from the table itself.

**Español**

- **Nueva pestaña "Llaves"** — dos botones de vista en la parte superior de la ventana alternan entre **Personajes** (la tabla de siempre) y **Llaves**. La elección se guarda entre sesiones.
- **Tabla de recompensas de Mítica+ · Temporada 1** — las 9 filas de **+2 a +10**, con el objeto de **fin de mazmorra** y de la **Gran Cámara** (ilvl + nivel) y el **blasón** obtenido (cantidad + nivel). Los niveles se colorean por tier: **Campeón** verde, **Héroe** azul, **Mítico** dorado.
- **Resalte de saltos** — las filas donde el blasón cambia de tier (**+4** pasa a Héroe, **+9** pasa a Mítico) y donde la Cámara pasa a Mítico (**+10**) reciben un resalte y un acento en el color del nuevo tier.
- **En el contexto de tu personaje** — muestra tu **ilvl equipado** y marca con **✓** las llaves cuyo Fin/Cámara ya son mejora; una guía corta resume "El fin sube desde +X · Cámara desde +Y".
- **Pie de mejora** — recuerda el coste (20 blasones por nivel, 120 por objeto completo, límite de 100/semana por tipo) con un consejo derivado de la propia tabla.

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
