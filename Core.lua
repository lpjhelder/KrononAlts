-- KrononAlts — painel cross-character de objetivos semanais do ecossistema Kronon.
-- Mostra, numa tabela, Grande Cofre, Mítica+ e lockouts de raide de cada personagem.
-- Core: i18n, SavedVariables, snapshot do char logado, detecção de reset e eventos.

local ADDON = "KrononAlts"
local KA_PREFIX = "|cff33ff33KrononAlts|r: "
local WEEK = 7 * 24 * 60 * 60
local SNAPSHOT_DELAY = 1 -- coalescência de snapshots (segundos)

-- ---------------------------------------------------------------------------
-- Moedas da season (EDITE AQUI a cada patch/season — bloco hardcoded fácil)
--   kind: "crest" (crests de upgrade, cap semanal) | "delve" (chave/fragmentos)
--   Validação em runtime: se GetCurrencyInfo der nil/sem nome, a moeda é ignorada.
--   Use `/kalts curr` in-game para LISTAR e confirmar os IDs desta season.
--   Midnight Season 1 (Interface 120007): Valorstones foram REMOVIDAS;
--   upgrade agora usa Dawncrest + ouro. São 5 tiers de crest (não 4).
-- ---------------------------------------------------------------------------
local SEASON_CURRENCIES = {
  { id = 3383, kind = "crest" }, -- Adventurer Dawncrest
  { id = 3341, kind = "crest" }, -- Veteran Dawncrest
  { id = 3343, kind = "crest" }, -- Champion Dawncrest
  { id = 3345, kind = "crest" }, -- Hero Dawncrest
  { id = 3347, kind = "crest" }, -- Myth Dawncrest
  { id = 3310, kind = "delve" }, -- Coffer Key Shards (cap semanal de Delve)
  { id = 3028, kind = "delve" }, -- Restored Coffer Key
}
-- Faixa varrida pelo `/kalts curr` p/ descobrir IDs de moeda nova (rede de segurança).
local CURRENCY_SCAN_MIN, CURRENCY_SCAN_MAX = 3300, 3400

-- ---------------------------------------------------------------------------
-- i18n inline (base EN + overlay ptBR/esES) — addon autocontido, sem libs
-- ---------------------------------------------------------------------------
local EN = {
  TITLE            = "KrononAlts",
  COL_CHAR         = "Character",
  COL_VAULT        = "Vault",
  COL_MPLUS        = "M+",
  COL_RATING       = "Rating",
  COL_CONQUEST     = "Conquest",
  COL_RAID         = "Raid",
  RESET_WEEKLY     = "Weekly reset:",
  ABBR_D           = "d",
  ABBR_H           = "h",
  ABBR_M           = "m",
  TRACK_MPLUS      = "Mythic+",
  TRACK_RAID       = "Raid",
  TRACK_WORLD      = "World",
  TT_VAULT_TITLE   = "Great Vault",
  VAULT_HAS_REWARDS= "Rewards waiting to be claimed!",
  TT_SLOT_ILVL     = "item level %d",
  TT_SLOT_READY    = "reward ready",
  TT_MPLUS_TITLE   = "Mythic+ this week",
  TT_RUNS          = "%d runs completed",
  TT_BEST          = "Best key: +%d",
  TT_NO_KEY        = "No keystone in bags",
  TT_RATING        = "Mythic+ rating: %d",
  TT_KEYSTONE      = "Keystone: +%d",
  TT_RAID_TITLE    = "Raid lockouts",
  TT_NO_RAID       = "No raid lockouts",
  TT_LEVEL_ILVL    = "Level %d  •  ilvl %d",
  TT_UPDATED       = "Updated %s ago",
  TT_REMOVE_HINT   = "Right-click for options (nickname, remove)",
  STALE            = "Snapshot is older than the current reset — log in on this character to refresh.",
  EMPTY            = "No characters yet. Log in on your alts to fill in the table.",
  NONE             = "—",
  DIFF_LFR         = "LFR",
  DIFF_N           = "N",
  DIFF_H           = "H",
  DIFF_M           = "M",
  REMOVE_CONFIRM   = "Remove %s from KrononAlts?",
  MSG_SNAPSHOT     = "snapshot updated.",
  COL_CREST        = "Crests",
  NEXT_TITLE       = "What's left:",
  NEXT_DONE        = "All vault slots filled.",
  NEXT_LINE        = "+%d to slot %d",
  HIDE_COMPLETED   = "Hide completed",
  MENU_SET_NICK    = "Set nickname",
  MENU_REMOVE      = "Remove",
  NICK_PROMPT      = "Nickname for %s:",
  TT_CREST_TITLE   = "Season currencies",
  TT_CREST_NONE    = "No tracked currencies yet — log in on this character.",
  TT_CREST_WEEKLY  = "this week",
  TT_SORT_HINT     = "Click to sort by this column",
  MM_TITLE         = "KrononAlts",
  MM_FULL          = "%d with a full vault",
  MM_REWARDS       = "%d with rewards waiting",
  MM_HINT          = "Left-click to open  •  drag to move",
  COL_ILVL         = "ilvl",
  COL_GOLD         = "Gold",
  SUMMARY          = "%d/%d vaults full  \194\183  %d with a reward waiting  \194\183  %d characters",
  SUMMARY_EMPTY    = "No characters yet — log in on your alts",
  DETAIL_VAULT     = "Great Vault",
  DETAIL_MPLUS     = "Mythic+ by dungeon",
  MPLUS_TODO       = "to do",
  DETAIL_RAID      = "Raid lockouts",
  DETAIL_CURR      = "Currencies & Crests",
  DETAIL_WEEKLY    = "Weeklies",
  DETAIL_PROF      = "Professions",
  WEEKLY_CONQUEST  = "Conquest",
  PROF_KNOWLEDGE   = "Knowledge",
  PROF_OPEN_HINT   = "open the profession in-game to refresh",
  CLICK_EXPAND     = "Click a row to expand  \194\183  right-click for options",
  NO_DATA          = "No data yet — log in on this character.",
  DETAIL_DELVES    = "Delves",
  DELVE_TIER       = "Vault delve tier",
  DELVE_NONE       = "No delve data yet — log in on this character.",
  SUMMARY_ACCT     = "%d/%d vaults ready  \194\183  %d at cap",
  SUMMARY_REWARDS  = "%d with a reward to collect",
  VAULT_HEADER_HINT= "Vault slots: M+ | Raid | Delve",
  MM_CATALYST      = "Catalyst: %d/%d",
  MM_GOLD          = "Total gold: %s",
  GROUP_BTN        = "Group: %s",
  GROUP_NONE       = "off",
  GROUP_REALM      = "realm",
  GROUP_FACTION    = "faction",
  MENU_OPEN_BAGS   = "Open bags (KrononBags)",
  REMINDER_VAULT   = "%d character(s) with a vault reward to collect!",
  REMINDER_RESET   = "%d character(s) with vault objectives left before reset (<24h)",
  REMINDER_ON      = "login reminder ON.",
  REMINDER_OFF     = "login reminder OFF.",
  -- v0.7.0 — config própria + modos PvP/PvE/Ambos + PvP tracking
  CFG_TITLE          = "KrononAlts — Settings",
  CFG_CAT_GENERAL    = "General",
  CFG_CAT_DISPLAY    = "Display",
  CFG_CAT_ABOUT      = "About",
  CFG_MODE_LABEL     = "Mode",
  CFG_MODE_PVE       = "PvE",
  CFG_MODE_PVP       = "PvP",
  CFG_MODE_BOTH      = "Both",
  CFG_MODE_HINT      = "Filters the per-character detail: PvE objectives, PvP, or everything.",
  CFG_SEC_BEHAVIOR   = "Behavior",
  CFG_SEC_ORGANIZE   = "Organization",
  CFG_SEC_COLUMNS    = "Columns & sections",
  CFG_RESET          = "Restore defaults",
  CFG_RESET_CONFIRM  = "Restore all KrononAlts settings to their default values?",
  CFG_RESET_DONE     = "settings restored to default.",
  CFG_ABOUT_DESC     = "Cross-character weekly panel for the Kronon ecosystem.",
  CFG_ABOUT_VERSION  = "Version",
  CFG_ABOUT_COMMANDS = "Commands",
  CFG_ABOUT_CMD_LIST = "/kalts — open  \194\183  /kalts config — settings  \194\183  /kalts snapshot — refresh  \194\183  /kalts curr — list currencies",
  OPT_REMINDER       = "Login reminder",
  OPT_REMINDER_DESC  = "On login, warn in chat about vaults to collect or objectives left before reset.",
  OPT_HIDE_DESC      = "Hide characters whose vault is full (3/3/3) and has no reward waiting.",
  OPT_GOLD           = "Show gold column",
  OPT_GOLD_DESC      = "Adds a gold column to the table. Account total is always in the minimap tooltip.",
  OPT_PROF           = "Show professions",
  OPT_PROF_DESC      = "Adds a Professions section (level and unspent knowledge) to the character detail.",
  OPT_GROUP          = "Group characters",
  OPT_GROUP_DESC     = "Group the list by realm or faction.",
  OPT_GROUP_BY       = "Group by",
  TIP_CONFIG         = "Settings",
  DETAIL_PVP         = "PvP",
  PVP_2V2            = "2v2",
  PVP_3V3            = "3v3",
  PVP_RBG            = "Rated BG",
  PVP_SOLO           = "Solo Shuffle",
  PVP_BLITZ          = "BG Blitz",
  PVP_HONOR          = "Honor level",
  PVP_NONE           = "No PvP data yet — log in on this character.",
  -- v0.8.0 — aba "Chaves" (recompensas de Mítica+ por nível de chave)
  VIEW_CHARS       = "Characters",
  VIEW_KEYS        = "Keys",
  VIEW_COACH       = "Progress",
  TRACK_CHAMP      = "Champion",
  TRACK_HERO       = "Hero",
  TRACK_MYTH       = "Myth",
  KEYS_TITLE       = "Mythic+ rewards  \194\183  Season 1",
  KEYS_YOUR_ILVL   = "Your ilvl: %d",
  KEYS_COL_KEY     = "Key",
  KEYS_COL_END     = "End of run",
  KEYS_COL_VAULT   = "Great Vault",
  KEYS_COL_CREST   = "Crests",
  VIEW_RAIDS       = "Raids",
  TRACK_VET        = "Veteran",
  RAIDS_TITLE      = "Raid rewards  \194\183  Season 1",
  RAIDS_COL_DIFF   = "Difficulty",
  RAIDS_COL_DROP   = "Boss drop",
  RAIDS_NOTE       = "Bosses drop higher ilvl later in the raid.  \194\183  Vault \226\137\136 highest boss killed.  \194\183  Crest tier follows the difficulty.",
  RAID_LFR         = "LFR",
  RAID_NORMAL      = "Normal",
  RAID_HEROIC      = "Heroic",
  RAID_MYTHIC      = "Mythic",
  KEYS_GUIDE       = "End-of-run rises from +%d  \194\183  Vault from +%d",
  KEYS_GUIDE_NONE  = "Log in on a character to see what's an upgrade for you.",
  KEYS_GUIDE_CAP   = "Your gear already beats every reward in this table.",
  KEYS_UPGRADE_COST= "Each upgrade costs %d crests/level  \194\183  full item (6 levels) = %d  \194\183  cap %d/week per type.",
  KEYS_UPGRADE_TIP = "+%d gives %d %s  \226\137\136  %s upgrade",
  -- v0.9.0 — coach de progressão ("O que fazer agora") no topo da aba Chaves
  KEYS_COACH_TITLE     = "What to do now",
  KEYS_COACH_GEAR      = "Gear: %s  \194\183  %d below max",
  KEYS_COACH_GEAR_NONE = "Gear: %d pieces equipped (no upgrade track detected)",
  KEYS_COACH_CRESTS    = "Crests: %s",
  KEYS_COACH_CRESTS_NONE = "Crests: data not available yet",
  KEYS_COACH_CREST_ITEM       = "%s: %d (%d/%d this week)",
  KEYS_COACH_CREST_ITEM_NOWEEK= "%s: %d",
  KEYS_COACH_SPEND_HAS = "%s: %d pieces \194\183 %d upgrade(s) now (%d crests) \194\183 %d to max",
  KEYS_COACH_SPEND_MAXALL = "%s: %d pieces \194\183 can max all now (%d crests)",
  KEYS_COACH_SPEND_LOW = "%s: %d pieces \194\183 gather +%d for 1 upgrade \194\183 %d to fully max",
  KEYS_COACH_SPEND_NONE= "No crests to spend right now \226\128\148 earn more from keys",
  KEYS_COACH_KEYS      = "Keys: %s  \194\183  %s",
  KEYS_COACH_KEY_GOAL  = "goal: Mythic Vault",
  KEYS_COACH_NK_NONE_K = "Mythic 0",
  KEYS_COACH_NK_NONE_M = "Run Mythic 0 first (gives Champion 246); start M+ afterwards",
  KEYS_COACH_NK_CHAMP_K= "+6/+7",
  KEYS_COACH_NK_CHAMP_M= "Run +6/+7 \226\128\148 Hero gear starts dropping",
  KEYS_COACH_NK_HERO_K = "+9/+10",
  KEYS_COACH_NK_HERO_M = "Run +9/+10 \226\128\148 Myth drops (Vault 272)",
  KEYS_COACH_NK_MYTH_K = "+10",
  KEYS_COACH_NK_MYTH_M = "+10 is the cap \226\128\148 farm Myth crests up to 289",
  KEYS_COACH_CAP_WARN  = "%s crests near weekly cap (%d/%d) \226\128\148 spend before reset",
  KEYS_COACH_WEAK      = "Focus: %s (%s)",
  KEYS_COACH_ILVL      = "Your ilvl: %d / %d (season cap)",
  KEYS_COACH_BIS_NONE  = "Mark BiS items in KeystoneLoot for a dungeon recommendation",
  KEYS_COACH_PRIO_BIS  = "Priority (by your BiS)",
  KEYS_COACH_PRIO_ESS  = "Priority (by your essentials)",
  KEYS_COACH_PRIO_MORE = "+%d more dungeons",
  KEYS_COACH_KL_ON     = "KeystoneLoot detected \226\128\148 BiS suggestions enabled.",
  KEYS_COACH_KL_OFF    = "Tip: install KeystoneLoot and mark your BiS to unlock dungeon suggestions.",
}

local PT = {
  COL_CHAR         = "Personagem",
  COL_VAULT        = "Cofre",
  COL_RATING       = "Rating",
  COL_CONQUEST     = "Conquista",
  COL_RAID         = "Raide",
  RESET_WEEKLY     = "Reset semanal:",
  TRACK_MPLUS      = "Mítica+",
  TRACK_RAID       = "Raide",
  TRACK_WORLD      = "Mundo",
  TT_VAULT_TITLE   = "Grande Cofre",
  VAULT_HAS_REWARDS= "Há recompensas esperando para serem coletadas!",
  TT_SLOT_ILVL     = "nível de item %d",
  TT_SLOT_READY    = "recompensa pronta",
  TT_MPLUS_TITLE   = "Mítica+ desta semana",
  TT_RUNS          = "%d runs concluídas",
  TT_BEST          = "Maior chave: +%d",
  TT_NO_KEY        = "Sem chave nas bolsas",
  TT_RATING        = "Rating de Mítica+: %d",
  TT_KEYSTONE      = "Chave: +%d",
  TT_RAID_TITLE    = "Lockouts de raide",
  TT_NO_RAID       = "Nenhum lockout de raide",
  TT_LEVEL_ILVL    = "Nível %d  •  ilvl %d",
  TT_UPDATED       = "Atualizado há %s",
  TT_REMOVE_HINT   = "Clique-direito: opções (apelido, remover)",
  STALE            = "O snapshot é anterior ao reset atual — logue neste personagem para atualizar.",
  EMPTY            = "Nenhum personagem ainda. Logue nos seus alts para preencher a tabela.",
  REMOVE_CONFIRM   = "Remover %s do KrononAlts?",
  MSG_SNAPSHOT     = "snapshot atualizado.",
  NEXT_TITLE       = "O que falta:",
  NEXT_DONE        = "Todos os slots do cofre preenchidos.",
  NEXT_LINE        = "+%d p/ slot %d",
  HIDE_COMPLETED   = "Ocultar concluídos",
  MENU_SET_NICK    = "Definir apelido",
  MENU_REMOVE      = "Remover",
  NICK_PROMPT      = "Apelido para %s:",
  TT_CREST_TITLE   = "Moedas da season",
  TT_CREST_NONE    = "Nenhuma moeda rastreada ainda — logue neste personagem.",
  TT_CREST_WEEKLY  = "esta semana",
  TT_SORT_HINT     = "Clique para ordenar por esta coluna",
  MM_FULL          = "%d com cofre cheio",
  MM_REWARDS       = "%d com recompensa pendente",
  MM_HINT          = "Clique-esquerdo abre  •  arraste para mover",
  COL_GOLD         = "Ouro",
  SUMMARY          = "%d/%d cofres prontos  \194\183  %d com recompensa esperando  \194\183  %d personagens",
  SUMMARY_EMPTY    = "Nenhum personagem ainda — logue nos seus alts",
  DETAIL_VAULT     = "Grande Cofre",
  DETAIL_MPLUS     = "Mítica+ por masmorra",
  MPLUS_TODO       = "a fazer",
  DETAIL_RAID      = "Lockouts de raide",
  DETAIL_CURR      = "Moedas & Crests",
  DETAIL_WEEKLY    = "Semanais",
  DETAIL_PROF      = "Profissões",
  WEEKLY_CONQUEST  = "Conquista",
  PROF_KNOWLEDGE   = "Conhecimento",
  PROF_OPEN_HINT   = "abra a profissão no jogo para atualizar",
  CLICK_EXPAND     = "Clique numa linha para expandir  \194\183  clique-direito: opções",
  NO_DATA          = "Sem dados ainda — logue neste personagem.",
  DETAIL_DELVES    = "Delves",
  DELVE_TIER       = "Tier de delve do cofre",
  DELVE_NONE       = "Sem dados de delve ainda — logue neste personagem.",
  SUMMARY_ACCT     = "%d/%d cofres prontos  \194\183  %d no cap",
  SUMMARY_REWARDS  = "%d com recompensa a coletar",
  VAULT_HEADER_HINT= "Slots do cofre: M+ | Raide | Delve",
  MM_CATALYST      = "Catalisador: %d/%d",
  MM_GOLD          = "Ouro total: %s",
  GROUP_BTN        = "Agrupar: %s",
  GROUP_NONE       = "não",
  GROUP_REALM      = "reino",
  GROUP_FACTION    = "facção",
  MENU_OPEN_BAGS   = "Abrir inventário (KrononBags)",
  REMINDER_VAULT   = "%d personagem(ns) com recompensa de Cofre pra coletar!",
  REMINDER_RESET   = "%d personagem(ns) com objetivos do Cofre faltando antes do reset (<24h)",
  REMINDER_ON      = "lembrete de login LIGADO.",
  REMINDER_OFF     = "lembrete de login DESLIGADO.",
  CFG_TITLE          = "KrononAlts — Configurações",
  CFG_CAT_GENERAL    = "Geral",
  CFG_CAT_DISPLAY    = "Exibição",
  CFG_CAT_ABOUT      = "Sobre",
  CFG_MODE_LABEL     = "Modo",
  CFG_MODE_BOTH      = "Ambos",
  CFG_MODE_HINT      = "Filtra o detalhe de cada personagem: objetivos PvE, PvP ou tudo.",
  CFG_SEC_BEHAVIOR   = "Comportamento",
  CFG_SEC_ORGANIZE   = "Organização",
  CFG_SEC_COLUMNS    = "Colunas & seções",
  CFG_RESET          = "Restaurar padrões",
  CFG_RESET_CONFIRM  = "Restaurar todas as configurações do KrononAlts para os valores padrão?",
  CFG_RESET_DONE     = "configurações restauradas para o padrão.",
  CFG_ABOUT_DESC     = "Painel cross-character semanal do ecossistema Kronon.",
  CFG_ABOUT_VERSION  = "Versão",
  CFG_ABOUT_COMMANDS = "Comandos",
  CFG_ABOUT_CMD_LIST = "/kalts — abre  \194\183  /kalts config — configurações  \194\183  /kalts snapshot — atualiza  \194\183  /kalts curr — lista moedas",
  OPT_REMINDER       = "Lembrete ao logar",
  OPT_REMINDER_DESC  = "Ao logar, avisa no chat sobre cofres a coletar ou objetivos faltando antes do reset.",
  OPT_HIDE_DESC      = "Oculta personagens com o cofre cheio (3/3/3) e sem recompensa pendente.",
  OPT_GOLD           = "Mostrar coluna de ouro",
  OPT_GOLD_DESC      = "Adiciona uma coluna de ouro à tabela. O total da conta fica sempre no tooltip do minimapa.",
  OPT_PROF           = "Mostrar profissões",
  OPT_PROF_DESC      = "Adiciona uma seção de Profissões (nível e conhecimento não-gasto) ao detalhe do personagem.",
  OPT_GROUP          = "Agrupar personagens",
  OPT_GROUP_DESC     = "Agrupa a lista por reino ou facção.",
  OPT_GROUP_BY       = "Agrupar por",
  TIP_CONFIG         = "Configurações",
  DETAIL_PVP         = "PvP",
  PVP_RBG            = "BG Pontuado",
  PVP_SOLO           = "Combate Singular",
  PVP_BLITZ          = "BG Relâmpago",
  PVP_HONOR          = "Nível de honra",
  PVP_NONE           = "Sem dados de PvP ainda — logue neste personagem.",
  VIEW_CHARS       = "Personagens",
  VIEW_KEYS        = "Chaves",
  VIEW_COACH       = "Progresso",
  TRACK_CHAMP      = "Campeão",
  TRACK_HERO       = "Herói",
  TRACK_MYTH       = "Mítico",
  KEYS_TITLE       = "Recompensas de Mítica+  \194\183  Temporada 1",
  KEYS_YOUR_ILVL   = "Seu ilvl: %d",
  KEYS_COL_KEY     = "Chave",
  KEYS_COL_END     = "Fim da dg",
  KEYS_COL_VAULT   = "No Cofre",
  KEYS_COL_CREST   = "Brasão",
  VIEW_RAIDS       = "Raides",
  TRACK_VET        = "Veterano",
  RAIDS_TITLE      = "Recompensas de Raide  \194\183  Temporada 1",
  RAIDS_COL_DIFF   = "Dificuldade",
  RAIDS_COL_DROP   = "Drop do boss",
  RAIDS_NOTE       = "Bosses dropam ilvl maior quanto mais pro fim da raid.  \194\183  Cofre \226\137\136 boss mais alto que você matou.  \194\183  O tier do brasão segue a dificuldade.",
  RAID_LFR         = "LFR",
  RAID_NORMAL      = "Normal",
  RAID_HEROIC      = "Heroico",
  RAID_MYTHIC      = "Mítico",
  KEYS_GUIDE       = "Fim sobe a partir de +%d  \194\183  Cofre a partir de +%d",
  KEYS_GUIDE_NONE  = "Logue num personagem para ver o que é upgrade pra você.",
  KEYS_GUIDE_CAP   = "Seu equipamento já supera todas as recompensas desta tabela.",
  KEYS_UPGRADE_COST= "Cada melhoria custa %d brasões/nível  \194\183  item inteiro (6 níveis) = %d  \194\183  limite %d/semana por tipo.",
  KEYS_UPGRADE_TIP = "+%d dá %d %s  \226\137\136  %s melhoria",
  KEYS_COACH_TITLE     = "O que fazer agora",
  KEYS_COACH_GEAR      = "Equipamento: %s  \194\183  %d abaixo do máximo",
  KEYS_COACH_GEAR_NONE = "Equipamento: %d peças equipadas (sem trilha de melhoria detectada)",
  KEYS_COACH_CRESTS    = "Brasões: %s",
  KEYS_COACH_CRESTS_NONE = "Brasões: dados ainda indisponíveis",
  KEYS_COACH_CREST_ITEM       = "%s: %d (%d/%d esta semana)",
  KEYS_COACH_CREST_ITEM_NOWEEK= "%s: %d",
  KEYS_COACH_SPEND_HAS = "%s: %d peças \194\183 %d upgrade(s) já (%d brasões) \194\183 faltam %d pra maxar",
  KEYS_COACH_SPEND_MAXALL = "%s: %d peças \194\183 dá pra maxar tudo agora (%d brasões)",
  KEYS_COACH_SPEND_LOW = "%s: %d peças \194\183 junte +%d pra 1 upgrade \194\183 faltam %d pra maxar tudo",
  KEYS_COACH_SPEND_NONE= "Sem brasões para gastar agora \226\128\148 ganhe mais nas chaves",
  KEYS_COACH_KEYS      = "Chaves: %s  \194\183  %s",
  KEYS_COACH_KEY_GOAL  = "objetivo: Cofre Mítico",
  KEYS_COACH_NK_NONE_K = "Mítica 0",
  KEYS_COACH_NK_NONE_M = "Faça Mítica 0 primeiro (dá Campeão 246); comece o M+ depois",
  KEYS_COACH_NK_CHAMP_K= "+6/+7",
  KEYS_COACH_NK_CHAMP_M= "Faça +6/+7 \226\128\148 começa a dropar Herói",
  KEYS_COACH_NK_HERO_K = "+9/+10",
  KEYS_COACH_NK_HERO_M = "Faça +9/+10 \226\128\148 dropa Mítico (Cofre 272)",
  KEYS_COACH_NK_MYTH_K = "+10",
  KEYS_COACH_NK_MYTH_M = "+10 é o teto \226\128\148 farme brasão Mítico até 289",
  KEYS_COACH_CAP_WARN  = "Brasão %s quase no cap (%d/%d) \226\128\148 gaste antes do reset",
  KEYS_COACH_WEAK      = "Foco: %s (%s)",
  KEYS_COACH_ILVL      = "Seu ilvl: %d / %d (teto da season)",
  KEYS_COACH_BIS_NONE  = "Marque itens BiS no KeystoneLoot para uma recomendação de dungeon",
  KEYS_COACH_PRIO_BIS  = "Prioridade (pelos seus BiS)",
  KEYS_COACH_PRIO_ESS  = "Prioridade (pelos seus essenciais)",
  KEYS_COACH_PRIO_MORE = "+%d outras dungeons",
  KEYS_COACH_KL_ON     = "KeystoneLoot detectado \226\128\148 sugestões de BiS ativadas.",
  KEYS_COACH_KL_OFF    = "Dica: instale o KeystoneLoot e marque seus BiS para liberar sugestões de dungeon.",
}

local ES = {
  COL_CHAR         = "Personaje",
  COL_VAULT        = "Cámara",
  COL_RATING       = "Rating",
  COL_CONQUEST     = "Conquista",
  COL_RAID         = "Banda",
  RESET_WEEKLY     = "Reinicio semanal:",
  TRACK_MPLUS      = "Mítica+",
  TRACK_RAID       = "Banda",
  TRACK_WORLD      = "Mundo",
  TT_VAULT_TITLE   = "Gran Cámara",
  VAULT_HAS_REWARDS= "¡Hay recompensas esperando a ser reclamadas!",
  TT_SLOT_ILVL     = "nivel de objeto %d",
  TT_SLOT_READY    = "recompensa lista",
  TT_MPLUS_TITLE   = "Mítica+ de esta semana",
  TT_RUNS          = "%d carreras completadas",
  TT_BEST          = "Mejor piedra: +%d",
  TT_NO_KEY        = "Sin piedra angular en las bolsas",
  TT_RATING        = "Puntuación de Mítica+: %d",
  TT_KEYSTONE      = "Piedra: +%d",
  TT_RAID_TITLE    = "Bloqueos de banda",
  TT_NO_RAID       = "Sin bloqueos de banda",
  TT_LEVEL_ILVL    = "Nivel %d  •  ilvl %d",
  TT_UPDATED       = "Actualizado hace %s",
  TT_REMOVE_HINT   = "Clic derecho: opciones (apodo, eliminar)",
  STALE            = "La instantánea es anterior al reinicio actual — entra con este personaje para actualizar.",
  EMPTY            = "Aún no hay personajes. Entra con tus alts para llenar la tabla.",
  REMOVE_CONFIRM   = "¿Eliminar %s de KrononAlts?",
  MSG_SNAPSHOT     = "instantánea actualizada.",
  NEXT_TITLE       = "Lo que falta:",
  NEXT_DONE        = "Todas las ranuras de la cámara llenas.",
  NEXT_LINE        = "+%d para ranura %d",
  HIDE_COMPLETED   = "Ocultar completados",
  MENU_SET_NICK    = "Definir apodo",
  MENU_REMOVE      = "Eliminar",
  NICK_PROMPT      = "Apodo para %s:",
  TT_CREST_TITLE   = "Monedas de la temporada",
  TT_CREST_NONE    = "Aún no hay monedas rastreadas — entra con este personaje.",
  TT_CREST_WEEKLY  = "esta semana",
  TT_SORT_HINT     = "Clic para ordenar por esta columna",
  MM_FULL          = "%d con cámara llena",
  MM_REWARDS       = "%d con recompensas pendientes",
  MM_HINT          = "Clic izquierdo abre  •  arrastra para mover",
  COL_GOLD         = "Oro",
  SUMMARY          = "%d/%d cámaras listas  \194\183  %d con recompensa esperando  \194\183  %d personajes",
  SUMMARY_EMPTY    = "Aún no hay personajes — entra con tus alts",
  DETAIL_VAULT     = "Gran Cámara",
  DETAIL_MPLUS     = "Mítica+ por mazmorra",
  MPLUS_TODO       = "por hacer",
  DETAIL_RAID      = "Bloqueos de banda",
  DETAIL_CURR      = "Monedas y Crests",
  DETAIL_WEEKLY    = "Semanales",
  DETAIL_PROF      = "Profesiones",
  WEEKLY_CONQUEST  = "Conquista",
  PROF_KNOWLEDGE   = "Conocimiento",
  PROF_OPEN_HINT   = "abre la profesión en el juego para actualizar",
  CLICK_EXPAND     = "Clic en una fila para expandir  \194\183  clic derecho: opciones",
  NO_DATA          = "Aún sin datos — entra con este personaje.",
  DETAIL_DELVES    = "Profundidades",
  DELVE_TIER       = "Nivel de profundidad de la cámara",
  DELVE_NONE       = "Aún sin datos de profundidades — entra con este personaje.",
  SUMMARY_ACCT     = "%d/%d cámaras listas  \194\183  %d en tope",
  SUMMARY_REWARDS  = "%d con recompensa por reclamar",
  VAULT_HEADER_HINT= "Ranuras de la cámara: M+ | Banda | Profundidad",
  MM_CATALYST      = "Catalizador: %d/%d",
  MM_GOLD          = "Oro total: %s",
  GROUP_BTN        = "Agrupar: %s",
  GROUP_NONE       = "no",
  GROUP_REALM      = "reino",
  GROUP_FACTION    = "facción",
  MENU_OPEN_BAGS   = "Abrir inventario (KrononBags)",
  REMINDER_VAULT   = "¡%d personaje(s) con recompensa de cámara por reclamar!",
  REMINDER_RESET   = "%d personaje(s) con objetivos de cámara pendientes antes del reinicio (<24h)",
  REMINDER_ON      = "recordatorio de inicio de sesión ACTIVADO.",
  REMINDER_OFF     = "recordatorio de inicio de sesión DESACTIVADO.",
  CFG_TITLE          = "KrononAlts — Configuración",
  CFG_CAT_GENERAL    = "General",
  CFG_CAT_DISPLAY    = "Visualización",
  CFG_CAT_ABOUT      = "Acerca de",
  CFG_MODE_LABEL     = "Modo",
  CFG_MODE_BOTH      = "Ambos",
  CFG_MODE_HINT      = "Filtra el detalle de cada personaje: objetivos PvE, PvP o todo.",
  CFG_SEC_BEHAVIOR   = "Comportamiento",
  CFG_SEC_ORGANIZE   = "Organización",
  CFG_SEC_COLUMNS    = "Columnas y secciones",
  CFG_RESET          = "Restaurar valores",
  CFG_RESET_CONFIRM  = "¿Restaurar toda la configuración de KrononAlts a los valores predeterminados?",
  CFG_RESET_DONE     = "configuración restaurada a los valores predeterminados.",
  CFG_ABOUT_DESC     = "Panel semanal multipersonaje del ecosistema Kronon.",
  CFG_ABOUT_VERSION  = "Versión",
  CFG_ABOUT_COMMANDS = "Comandos",
  CFG_ABOUT_CMD_LIST = "/kalts — abre  \194\183  /kalts config — configuración  \194\183  /kalts snapshot — actualiza  \194\183  /kalts curr — lista monedas",
  OPT_REMINDER       = "Recordatorio al iniciar sesión",
  OPT_REMINDER_DESC  = "Al iniciar sesión, avisa en el chat sobre cámaras por reclamar u objetivos pendientes antes del reinicio.",
  OPT_HIDE_DESC      = "Oculta personajes con la cámara llena (3/3/3) y sin recompensa pendiente.",
  OPT_GOLD           = "Mostrar columna de oro",
  OPT_GOLD_DESC      = "Añade una columna de oro a la tabla. El total de la cuenta siempre está en el tooltip del minimapa.",
  OPT_PROF           = "Mostrar profesiones",
  OPT_PROF_DESC      = "Añade una sección de Profesiones (nivel y conocimiento sin gastar) al detalle del personaje.",
  OPT_GROUP          = "Agrupar personajes",
  OPT_GROUP_DESC     = "Agrupa la lista por reino o facción.",
  OPT_GROUP_BY       = "Agrupar por",
  TIP_CONFIG         = "Configuración",
  DETAIL_PVP         = "PvP",
  PVP_RBG            = "BG Clasificatoria",
  PVP_SOLO           = "Combate Singular",
  PVP_BLITZ          = "BG Relámpago",
  PVP_HONOR          = "Nivel de honor",
  PVP_NONE           = "Aún sin datos de PvP — entra con este personaje.",
  VIEW_CHARS       = "Personajes",
  VIEW_KEYS        = "Llaves",
  VIEW_COACH       = "Progreso",
  TRACK_CHAMP      = "Campeón",
  TRACK_HERO       = "Héroe",
  TRACK_MYTH       = "Mítico",
  KEYS_TITLE       = "Recompensas de Mítica+  \194\183  Temporada 1",
  KEYS_YOUR_ILVL   = "Tu ilvl: %d",
  KEYS_COL_KEY     = "Llave",
  KEYS_COL_END     = "Fin de mazm.",
  KEYS_COL_VAULT   = "Cámara",
  KEYS_COL_CREST   = "Blasón",
  VIEW_RAIDS       = "Bandas",
  TRACK_VET        = "Veterano",
  RAIDS_TITLE      = "Recompensas de banda  \194\183  Temporada 1",
  RAIDS_COL_DIFF   = "Dificultad",
  RAIDS_COL_DROP   = "Botín de jefe",
  RAIDS_NOTE       = "Los jefes sueltan más ilvl cuanto más avanzada la banda.  \194\183  Cámara \226\137\136 jefe más alto que mataste.  \194\183  El tier del blasón sigue la dificultad.",
  RAID_LFR         = "LFR",
  RAID_NORMAL      = "Normal",
  RAID_HEROIC      = "Heroico",
  RAID_MYTHIC      = "Mítico",
  KEYS_GUIDE       = "El fin sube desde +%d  \194\183  Cámara desde +%d",
  KEYS_GUIDE_NONE  = "Entra con un personaje para ver qué es mejora para ti.",
  KEYS_GUIDE_CAP   = "Tu equipo ya supera todas las recompensas de esta tabla.",
  KEYS_UPGRADE_COST= "Cada mejora cuesta %d blasones/nivel  \194\183  objeto completo (6 niveles) = %d  \194\183  límite %d/semana por tipo.",
  KEYS_UPGRADE_TIP = "+%d da %d %s  \226\137\136  %s mejora",
  KEYS_COACH_TITLE     = "Qué hacer ahora",
  KEYS_COACH_GEAR      = "Equipo: %s  \194\183  %d por debajo del máx.",
  KEYS_COACH_GEAR_NONE = "Equipo: %d piezas equipadas (sin vía de mejora detectada)",
  KEYS_COACH_CRESTS    = "Blasones: %s",
  KEYS_COACH_CRESTS_NONE = "Blasones: datos aún no disponibles",
  KEYS_COACH_CREST_ITEM       = "%s: %d (%d/%d esta semana)",
  KEYS_COACH_CREST_ITEM_NOWEEK= "%s: %d",
  KEYS_COACH_SPEND_HAS = "%s: %d piezas \194\183 %d mejora(s) ya (%d blasones) \194\183 faltan %d para maximizar",
  KEYS_COACH_SPEND_MAXALL = "%s: %d piezas \194\183 puedes maximizar todo ya (%d blasones)",
  KEYS_COACH_SPEND_LOW = "%s: %d piezas \194\183 reúne +%d para 1 mejora \194\183 faltan %d para maximizar todo",
  KEYS_COACH_SPEND_NONE= "Sin blasones para gastar ahora \226\128\148 consigue más en las llaves",
  KEYS_COACH_KEYS      = "Llaves: %s  \194\183  %s",
  KEYS_COACH_KEY_GOAL  = "objetivo: Cámara Mítica",
  KEYS_COACH_NK_NONE_K = "Mítica 0",
  KEYS_COACH_NK_NONE_M = "Haz Mítica 0 primero (da Campeón 246); empieza M+ después",
  KEYS_COACH_NK_CHAMP_K= "+6/+7",
  KEYS_COACH_NK_CHAMP_M= "Haz +6/+7 \226\128\148 empieza a soltar Héroe",
  KEYS_COACH_NK_HERO_K = "+9/+10",
  KEYS_COACH_NK_HERO_M = "Haz +9/+10 \226\128\148 suelta Mítico (Cámara 272)",
  KEYS_COACH_NK_MYTH_K = "+10",
  KEYS_COACH_NK_MYTH_M = "+10 es el tope \226\128\148 farmea blasón Mítico hasta 289",
  KEYS_COACH_CAP_WARN  = "Blasón %s casi en el tope (%d/%d) \226\128\148 gasta antes del reinicio",
  KEYS_COACH_WEAK      = "Enfoque: %s (%s)",
  KEYS_COACH_ILVL      = "Tu ilvl: %d / %d (tope de temporada)",
  KEYS_COACH_BIS_NONE  = "Marca objetos BiS en KeystoneLoot para una recomendación de mazmorra",
  KEYS_COACH_PRIO_BIS  = "Prioridad (por tus BiS)",
  KEYS_COACH_PRIO_ESS  = "Prioridad (por tus esenciales)",
  KEYS_COACH_PRIO_MORE = "+%d mazmorras más",
  KEYS_COACH_KL_ON     = "KeystoneLoot detectado \226\128\148 sugerencias de BiS activadas.",
  KEYS_COACH_KL_OFF    = "Consejo: instala KeystoneLoot y marca tus BiS para desbloquear sugerencias de mazmorra.",
}

-- Base EN + overlay do locale do cliente; esMX cai em esES; chave inexistente
-- retorna a própria chave.
local L = {}
for k, v in pairs(EN) do L[k] = v end
local loc = GetLocale()
if loc == "esMX" then loc = "esES" end
local ov = (loc == "ptBR" and PT) or (loc == "esES" and ES) or nil
if ov then for k, v in pairs(ov) do L[k] = v end end
setmetatable(L, { __index = function(_, k) return k end })

-- ---------------------------------------------------------------------------
-- EventBus inline (mesma API: bus:Register(fn) / bus:Fire(...)) — notifica a UI
-- ---------------------------------------------------------------------------
local function NewEventBus()
  local cbs = {}
  return {
    Register = function(self, fn)
      if type(fn) == "function" then cbs[#cbs + 1] = fn end
    end,
    Fire = function(self, ...)
      for i = 1, #cbs do pcall(cbs[i], ...) end
    end,
  }
end

-- ---------------------------------------------------------------------------
-- Namespace público + barramento de eventos (notifica a UI)
-- ---------------------------------------------------------------------------
KrononAlts = KrononAlts or {}
local KA = KrononAlts
KA.L = L
KA.bus = NewEventBus()

-- ---------------------------------------------------------------------------
-- SavedVariables (account-wide)
--   KrononAltsDB = { version = 1, chars = { [charKey] = {...} } }
-- ---------------------------------------------------------------------------
local DB
local function InitDB()
  if type(KrononAltsDB) ~= "table" then KrononAltsDB = {} end
  if type(KrononAltsDB.chars) ~= "table" then KrononAltsDB.chars = {} end
  -- migração v2: a captura antiga de profissões pegava TODAS as do jogo; limpa as
  -- listas corrompidas (>2 entradas) pra re-capturar só as 2 do char ao logar nele.
  if KrononAltsDB.version ~= 2 then
    for _, c in pairs(KrononAltsDB.chars) do
      if type(c) == "table" and type(c.professions) == "table" and #c.professions > 2 then
        c.professions = nil
      end
    end
  end
  KrononAltsDB.version = 2
  if type(KrononAltsDB.minimap) ~= "table" then KrononAltsDB.minimap = { angle = 215, hide = false } end
  if KrononAltsDB.hideCompleted == nil then KrononAltsDB.hideCompleted = false end
  if KrononAltsDB.loginReminder == nil then KrononAltsDB.loginReminder = true end
  if type(KrononAltsDB.groupBy) ~= "string" then KrononAltsDB.groupBy = "none" end
  if KrononAltsDB.showGold == nil then KrononAltsDB.showGold = false end          -- coluna de ouro: OFF por padrão
  if KrononAltsDB.showProfessions == nil then KrononAltsDB.showProfessions = false end -- seção de profissões: OFF por padrão
  -- v0.7.0: settings da config própria (modo de detalhe + estado da janela de config)
  if type(KrononAltsDB.settings) ~= "table" then KrononAltsDB.settings = {} end
  if type(KrononAltsDB.settings.mode) ~= "string" then KrononAltsDB.settings.mode = "pve" end -- pve | pvp | both
  if type(KrononAltsDB.settings.cfgLastTab) ~= "string" then KrononAltsDB.settings.cfgLastTab = "general" end
  if type(KrononAltsDB.settings.view) ~= "string" then KrononAltsDB.settings.view = "chars" end -- "chars" | "keys"
  -- KrononAltsDB.sort = { key, dir } — nil = ordenação padrão (logado primeiro)
  DB = KrononAltsDB
end

-- ---------------------------------------------------------------------------
-- Identidade / utilidades
-- ---------------------------------------------------------------------------
local function CurrentKey()
  local name = UnitName("player")
  local realm = GetNormalizedRealmName()
  if not name or name == "" or not realm or realm == "" then return nil end
  return name .. "-" .. realm
end
KA.CurrentKey = CurrentKey

-- pcall que só aceita retorno numérico (defensivo p/ APIs que podem não ter carregado)
local function safeNum(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, v = pcall(fn, ...)
  if ok and type(v) == "number" then return v end
  return nil
end

local function GetWeeklySeconds()
  return safeNum(C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset) or 0
end

local function GetDailySeconds()
  return safeNum(C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset) or 0
end

local function GetSeason()
  local s = safeNum(C_MythicPlus and C_MythicPlus.GetCurrentSeason)
  if s and s >= 0 then return s end
  return nil
end

-- Reset info ao vivo (usado pela UI no countdown e na detecção de "precisa logar")
function KA.GetResetInfo()
  local now = time()
  local w = GetWeeklySeconds()
  local d = GetDailySeconds()
  return {
    weeklySeconds = w,
    dailySeconds  = d,
    weeklyResetAt = now + w,
    dailyResetAt  = now + d,
  }
end

-- Snapshot anterior ao reset semanal atual? (alt offline → não dá pra reler)
function KA.IsStale(rec)
  if type(rec) ~= "table" then return true end
  local info = KA.GetResetInfo()
  return (rec.updatedAt or 0) < (info.weeklyResetAt - WEEK)
end

-- ---------------------------------------------------------------------------
-- Coletores de snapshot (cada um totalmente defensivo)
-- ---------------------------------------------------------------------------
local function SnapshotVault()
  local vault = { mplus = nil, raid = nil, world = nil, hasRewards = false }
  if not (C_WeeklyRewards and C_WeeklyRewards.GetActivities) then return vault end

  local ok, activities = pcall(C_WeeklyRewards.GetActivities)
  if not ok or type(activities) ~= "table" then return vault end

  local groups = {} -- [type] = { filled, total, slots = { {progress, threshold, unlocked, ilvl, level} } }
  for _, a in ipairs(activities) do
    if type(a) == "table" and type(a.threshold) == "number" and a.threshold > 0 then
      local t = a.type
      if t ~= nil then
        local g = groups[t]
        if not g then
          g = { filled = 0, total = 0, slots = {} }
          groups[t] = g
        end
        local progress = a.progress or 0
        local unlocked = progress >= a.threshold
        local ilvl = nil
        if unlocked and a.id and C_WeeklyRewards.GetExampleRewardItemHyperlinks then
          local ok2, link = pcall(C_WeeklyRewards.GetExampleRewardItemHyperlinks, a.id)
          if ok2 and link and C_Item and C_Item.GetDetailedItemLevelInfo then
            local ok3, ilv = pcall(C_Item.GetDetailedItemLevelInfo, link)
            if ok3 and type(ilv) == "number" and ilv > 0 then ilvl = ilv end
          end
        end
        g.total = g.total + 1
        if unlocked then g.filled = g.filled + 1 end
        g.slots[#g.slots + 1] = {
          progress  = progress,
          threshold = a.threshold,
          unlocked  = unlocked,
          ilvl      = ilvl,
          level     = a.level,
        }
      end
    end
  end

  for _, g in pairs(groups) do
    table.sort(g.slots, function(s1, s2) return (s1.threshold or 0) < (s2.threshold or 0) end)
  end

  local TYPE = Enum and Enum.WeeklyRewardChestThresholdType
  local function pick(enumKey, fallback)
    local idx = fallback
    if TYPE and TYPE[enumKey] ~= nil then idx = TYPE[enumKey] end
    return groups[idx]
  end
  vault.mplus = pick("Activities", 1)
  vault.raid  = pick("Raid", 3)
  vault.world = pick("World", 6)

  if C_WeeklyRewards.HasAvailableRewards then
    local okr, hr = pcall(C_WeeklyRewards.HasAvailableRewards)
    vault.hasRewards = (okr and hr) and true or false
  end

  return vault
end

local function SnapshotMythicPlus()
  local m = { runs = 0, best = 0, rating = 0, keystoneLevel = nil, keystoneMap = nil }

  local rating = safeNum(C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore)
  if rating then m.rating = rating end

  if C_MythicPlus and C_MythicPlus.GetRunHistory then
    -- (semana atual, só concluídas)
    local ok, runs = pcall(C_MythicPlus.GetRunHistory, false, false)
    if ok and type(runs) == "table" then
      m.runs = #runs
      for _, r in ipairs(runs) do
        if type(r) == "table" and type(r.level) == "number" and r.level > m.best then
          m.best = r.level
        end
      end
    end
  end

  local lvl = safeNum(C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel)
  if lvl and lvl > 0 then
    m.keystoneLevel = lvl
    local mapID = safeNum(C_MythicPlus and C_MythicPlus.GetOwnedKeystoneChallengeMapID)
    if mapID and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
      local ok, name = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
      if ok and type(name) == "string" and name ~= "" then m.keystoneMap = name end
    end
  end

  return m
end

local function SnapshotRaids()
  local raids = {}
  if type(GetNumSavedInstances) ~= "function" or type(GetSavedInstanceInfo) ~= "function" then
    return raids
  end
  local okN, n = pcall(GetNumSavedInstances)
  if not okN or type(n) ~= "number" then return raids end

  for i = 1, n do
    local ok, name, lockoutId, reset, difficultyId, locked, extended,
          instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress
          = pcall(GetSavedInstanceInfo, i)
    if ok and isRaid and name and (numEncounters or 0) > 0 and (encounterProgress or 0) > 0 then
      raids[#raids + 1] = {
        name           = name,
        difficultyId   = difficultyId,
        difficultyName = difficultyName,
        total          = numEncounters or 0,
        progress       = encounterProgress or 0,
        maxPlayers     = maxPlayers,
      }
    end
  end

  table.sort(raids, function(a, b)
    local da, db = a.difficultyId or 0, b.difficultyId or 0
    if da ~= db then return da > db end
    return (a.name or "") < (b.name or "")
  end)
  return raids
end

-- Moedas da season (account-wide por char): validadas em runtime, defensivas.
local function SnapshotCurrencies()
  local out = {}
  if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then return out end
  for _, def in ipairs(SEASON_CURRENCIES) do
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, def.id)
    if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
      out[#out + 1] = {
        id        = def.id,
        kind      = def.kind,
        name      = info.name,
        quantity  = info.quantity or 0,
        max       = info.maxQuantity or 0,
        total     = info.totalEarned or 0,
        weekly    = info.quantityEarnedThisWeek or 0,
        weeklyMax = info.maxWeeklyQuantity or 0,
      }
    end
  end
  return out
end

-- Ouro do char (em cobre). PLAYER_MONEY força recaptura; 0 é tratado como
-- "ainda não pronto" e NÃO sobrescreve o valor salvo (evita zerar o alt).
local function SnapshotGold()
  if type(GetMoney) ~= "function" then return nil end
  local ok, money = pcall(GetMoney)
  if ok and type(money) == "number" and money > 0 then return money end
  return nil
end

-- Nome da spec ativa (defensivo — usado no painel de detalhe)
local function SnapshotSpec()
  if type(GetSpecialization) ~= "function" or type(GetSpecializationInfo) ~= "function" then
    return nil
  end
  local ok, idx = pcall(GetSpecialization)
  if not ok or type(idx) ~= "number" then return nil end
  local ok2, _, name = pcall(GetSpecializationInfo, idx)
  if ok2 and type(name) == "string" and name ~= "" then return name end
  return nil
end

-- Melhor chave POR MASMORRA NESTA SEMANA (não o recorde da season). Uma masmorra
-- sem run concluída na semana fica SEM nível (a UI mostra como "falta fazer"), pra
-- o jogador saber o que ainda dá pra correr antes do reset.
local function SnapshotMythicPlusByMap()
  local out = {}
  if not (C_ChallengeMode and C_ChallengeMode.GetMapTable) then return out end
  local ok, maps = pcall(C_ChallengeMode.GetMapTable)
  if not ok or type(maps) ~= "table" then return out end

  -- melhor nível CONCLUÍDO por masmorra NESTA SEMANA — GetRunHistory(false=só esta semana)
  local weekBest = {}
  if C_MythicPlus and C_MythicPlus.GetRunHistory then
    local ok0, runs = pcall(C_MythicPlus.GetRunHistory, false, false)
    if ok0 and type(runs) == "table" then
      for _, r in ipairs(runs) do
        if type(r) == "table" and type(r.mapChallengeModeID) == "number" and type(r.level) == "number" then
          local id = r.mapChallengeModeID
          if not weekBest[id] or r.level > weekBest[id] then weekBest[id] = r.level end
        end
      end
    end
  end

  for _, mapID in ipairs(maps) do
    if type(mapID) == "number" then
      local entry = { mapID = mapID }
      if C_ChallengeMode.GetMapUIInfo then
        local ok2, name, _, _, texture = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
        if ok2 then
          if type(name) == "string" and name ~= "" then entry.name = name end
          if type(texture) == "number" and texture > 0 then entry.texture = texture end
        end
      end
      local lvl = weekBest[mapID]
      if type(lvl) == "number" and lvl > 0 then entry.level = lvl; entry.done = true end
      out[#out + 1] = entry
    end
  end
  -- as que FALTAM (sem nível esta semana) primeiro, depois por nível desc, depois nome
  table.sort(out, function(a, b)
    local la, lb = a.level or 0, b.level or 0
    if (la == 0) ~= (lb == 0) then return la == 0 end
    if la ~= lb then return la > lb end
    return (a.name or "") < (b.name or "")
  end)
  return out
end

-- Semanais lidas a frio (leitura via C_CurrencyInfo). Defensivo: só grava o que
-- vier com nome válido. IDs do Midnight S1 podem variar — validar com /kalts curr.
local function SnapshotWeeklies()
  local out = {}
  if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then return out end
  local function read(id)
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
    if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
      return info
    end
  end
  local conq = read(1602) -- Conquest (cap semanal de PvP)
  if conq then
    out.conquest = {
      name   = conq.name,
      earned = conq.quantityEarnedThisWeek or 0,
      cap    = conq.maxWeeklyQuantity or 0,
      total  = conq.quantity or 0,
    }
  end
  local cat = read(2167) -- Catalyst Charges (Warband-wide)
  if cat then
    out.catalyst = {
      name     = cat.name,
      quantity = cat.quantity or 0,
      max      = cat.maxQuantity or 0,
    }
  end
  return out
end

-- ---------------------------------------------------------------------------
-- PvP (rating por modalidade + Conquista semanal + honra). Totalmente defensivo.
--   bracketIndex confirmados (retail TWW 11.x / Midnight 12.x), via
--   CONQUEST_BRACKET_INDEXES = { 7, 9, 1, 2, 4 } (Blizzard_FrameXMLBase/Constants):
--     1 = 2v2 Arena | 2 = 3v3 Arena | 4 = Rated BG | 7 = Solo Shuffle | 9 = BG Blitz
--     (3 = 5v5, removida — buraco na sequência, pulado).
--   GetPersonalRatedInfo(idx) -> rating, seasonBest, weeklyBest, seasonPlayed,
--     seasonWon, weeklyPlayed, weeklyWon, ...  (usamos rating/seasonBest/weeklyBest/semana).
-- ---------------------------------------------------------------------------
local PVP_BRACKETS = {
  { index = 1, key = "PVP_2V2"   }, -- 2v2 Arena
  { index = 2, key = "PVP_3V3"   }, -- 3v3 Arena
  { index = 7, key = "PVP_SOLO"  }, -- Solo Shuffle
  { index = 9, key = "PVP_BLITZ" }, -- Rated BG Blitz
  { index = 4, key = "PVP_RBG"   }, -- Rated Battleground
}

local function SnapshotPvP()
  local out = { ratings = {} }

  local getRated = (type(GetPersonalRatedInfo) == "function" and GetPersonalRatedInfo)
    or (C_PvP and type(C_PvP.GetPersonalRatedInfo) == "function" and C_PvP.GetPersonalRatedInfo)
  if getRated then
    for _, b in ipairs(PVP_BRACKETS) do
      local ok, rating, seasonBest, weeklyBest, _, _, weeklyPlayed, weeklyWon =
        pcall(getRated, b.index)
      if ok and type(rating) == "number" then
        out.ratings[#out.ratings + 1] = {
          bracket      = b.index,
          key          = b.key,
          rating       = rating,
          seasonBest   = (type(seasonBest) == "number") and seasonBest or 0,
          weeklyBest   = (type(weeklyBest) == "number") and weeklyBest or 0,
          weeklyPlayed = (type(weeklyPlayed) == "number") and weeklyPlayed or 0,
          weeklyWon    = (type(weeklyWon) == "number") and weeklyWon or 0,
        }
      end
    end
  end

  -- Conquista (cap semanal de PvP) — reusa a leitura da currency 1602.
  if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, 1602)
    if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
      out.conquest = {
        name   = info.name,
        earned = info.quantityEarnedThisWeek or 0,
        cap    = info.maxWeeklyQuantity or 0,
        total  = info.quantity or 0,
      }
    end
  end

  -- Honra (nível) — opcional, defensivo.
  local hl = safeNum(UnitHonorLevel, "player") or safeNum(GetHonorLevel)
  if hl and hl > 0 then out.honorLevel = hl end

  return out
end

-- Profissões: nível + conhecimento não-gasto (leitura fria) e concentração
-- quando disponível. Só lê se as tradeskills estiverem carregadas; caso vazio,
-- mantém o snapshot anterior (não sobrescreve). Totalmente defensivo.
local function SnapshotProfessions()
  local out = {}
  if not (GetProfessions and GetProfessionInfo) then return out end
  -- GetProfessions() devolve os índices SÓ das profissões que o personagem TEM
  -- (prof1, prof2, arqueologia, pesca, culinária). Pegamos só as 2 PRINCIPAIS.
  local profIdx = { GetProfessions() }
  for i = 1, 2 do
    local idx = profIdx[i]
    if type(idx) == "number" then
      local name, _, skillLevel, maxSkillLevel, _, _, skillLine = GetProfessionInfo(idx)
      if type(name) == "string" and name ~= "" then
        local entry = { name = name, skillLine = skillLine }
        if type(skillLevel) == "number" then entry.skillLevel = skillLevel end
        if type(maxSkillLevel) == "number" then entry.maxSkillLevel = maxSkillLevel end
        -- Conhecimento não-gasto da season (currency oculta por profissão) — defensivo
        if type(skillLine) == "number" and C_ProfSpecs and C_ProfSpecs.GetCurrencyInfoForSkillLine then
          local ok3, ci = pcall(C_ProfSpecs.GetCurrencyInfoForSkillLine, skillLine)
          if ok3 and type(ci) == "table" then
            local cid = ci.currencyID or ci.numKnowledgeID or ci.currencyType
            if type(cid) == "number" and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
              local ok4, kinfo = pcall(C_CurrencyInfo.GetCurrencyInfo, cid)
              if ok4 and type(kinfo) == "table" and type(kinfo.quantity) == "number" then
                entry.knowledge = kinfo.quantity
              end
            end
          end
        end
        out[#out + 1] = entry
      end
    end
  end
  return out
end

-- Facção do char (Alliance/Horde/Neutral) — usada no agrupamento. Defensivo.
local function SnapshotFaction()
  if type(UnitFactionGroup) ~= "function" then return nil end
  local ok, f = pcall(UnitFactionGroup, "player")
  if ok and type(f) == "string" and f ~= "" then return f end
  return nil
end

-- World bosses MORTOS nesta semana (lockout salvo). GetSavedWorldBossInfo só
-- devolve os que você já está salvo (matou); não sabemos os disponíveis, então
-- listamos apenas os concluídos. Totalmente defensivo.
local function SnapshotWorldBosses()
  local out = {}
  if type(GetNumSavedWorldBosses) ~= "function" or type(GetSavedWorldBossInfo) ~= "function" then
    return out
  end
  local okN, n = pcall(GetNumSavedWorldBosses)
  if not okN or type(n) ~= "number" then return out end
  for i = 1, n do
    local ok, name, id = pcall(GetSavedWorldBossInfo, i)
    if ok and type(name) == "string" and name ~= "" then
      out[#out + 1] = { name = name, id = id }
    end
  end
  return out
end

-- Delves: a trilha de Delves do Grande Cofre é a trilha "Mundo" (World). O maior
-- tier desta semana é derivado do maior `level` entre os slots Mundo DESBLOQUEADOS
-- (guarda contra confundir tier de delve com ilvl: tier de delve <= 20). As moedas
-- da chave do cofre (Restored Coffer Key / Coffer Key Shards) já entram em
-- rec.currencies (kind="delve"). Defensivo: sem dados, fica tier 0 e a UI esconde.
local function SnapshotDelves(vault)
  local out = { tier = 0 }
  if type(vault) == "table" and type(vault.world) == "table" and type(vault.world.slots) == "table" then
    for _, s in ipairs(vault.world.slots) do
      if s and s.unlocked and type(s.level) == "number"
         and s.level > 0 and s.level <= 20 and s.level > out.tier then
        out.tier = s.level
      end
    end
  end
  return out
end

-- ---------------------------------------------------------------------------
-- Zeragem (reset semanal e virada de season)
-- ---------------------------------------------------------------------------
local function ZeroWeekly(c)
  c.vault = nil
  if type(c.mplus) == "table" then
    c.mplus.runs = 0
    c.mplus.best = 0
  end
  c.raids = {}
  -- progresso semanal das moedas (crests/shards) também zera no reset
  if type(c.currencies) == "table" then
    for _, cur in ipairs(c.currencies) do
      if type(cur) == "table" then cur.weekly = 0 end
    end
  end
  -- world bosses e tier de delve da semana zeram no reset
  c.worldBosses = {}
  if type(c.delves) == "table" then c.delves.tier = 0 end
  -- PvP: progresso SEMANAL zera (conquista ganha, jogos da semana); rating e melhor
  -- da season permanecem até a próxima leitura no char.
  if type(c.pvp) == "table" then
    if type(c.pvp.conquest) == "table" then c.pvp.conquest.earned = 0 end
    if type(c.pvp.ratings) == "table" then
      for _, r in ipairs(c.pvp.ratings) do
        if type(r) == "table" then r.weeklyPlayed = 0; r.weeklyWon = 0; r.weeklyBest = 0 end
      end
    end
  end
end

local function ZeroSeason(c)
  c.vault = nil
  c.mplus = { runs = 0, best = 0, rating = 0 }
  c.raids = {}
end

-- No login: varre TODOS os chars e zera a semana dos vencidos (logar em 1 zera a semana de todos)
local function ApplyWeeklyResets()
  if not (DB and DB.chars) then return end
  local w = GetWeeklySeconds()
  if w <= 0 then return end -- API de reset ainda não pronta no login; não zerar a semana prematuramente
  local now = time()
  local weeklyResetAt = now + w
  for _, c in pairs(DB.chars) do
    if type(c) == "table" and c.weeklyResetAt and now >= c.weeklyResetAt then
      ZeroWeekly(c)
      c.weeklyResetAt = weeklyResetAt
    end
  end
end

-- Virada de season: zera vault/runs/rating dos chars cuja season salva difere da atual
local function ApplySeasonResets(season, currentKey)
  if not season or not (DB and DB.chars) then return end
  for key, c in pairs(DB.chars) do
    if type(c) == "table" and key ~= currentKey and c.season and c.season ~= season then
      ZeroSeason(c)
      c.season = season
    end
  end
end

-- ---------------------------------------------------------------------------
-- Snapshot idempotente do char logado
-- ---------------------------------------------------------------------------
local function Snapshot()
  if not DB then InitDB() end
  local key = CurrentKey()
  if not key then return end

  local name  = UnitName("player")
  local realm = GetNormalizedRealmName()
  local _, classFile = UnitClass("player")
  local level = UnitLevel("player")
  local overall, equipped = GetAverageItemLevel()

  local season = GetSeason()
  ApplySeasonResets(season, key)

  local now = time()
  local rec = DB.chars[key] or {}
  rec.name  = name
  rec.realm = realm
  rec.class = classFile
  if type(level) == "number" and level > 0 then rec.level = level end
  local il = equipped or overall
  if type(il) == "number" and il > 0 then rec.ilvl = math.floor(il + 0.5) end

  rec.vault = SnapshotVault()
  rec.mplus = SnapshotMythicPlus()
  rec.raids = SnapshotRaids()
  rec.currencies = SnapshotCurrencies()
  rec.worldBosses = SnapshotWorldBosses()
  rec.delves = SnapshotDelves(rec.vault)
  local faction = SnapshotFaction(); if faction then rec.faction = faction end

  -- Campos que dependem de dados que podem não estar carregados ainda:
  -- só sobrescrevem o snapshot anterior quando há valor novo (não zeram o alt).
  local gold = SnapshotGold(); if gold then rec.gold = gold end
  local spec = SnapshotSpec(); if spec then rec.spec = spec end
  local maps = SnapshotMythicPlusByMap(); if #maps > 0 then rec.mplusMaps = maps end
  rec.professions = SnapshotProfessions() -- sempre reflete o char logado (limpa lista antiga)
  local weeklies = SnapshotWeeklies(); if next(weeklies) then rec.weeklies = weeklies end
  -- PvP: só sobrescreve quando há algo (rating ou conquista) — não zera o alt se a
  -- API de PvP ainda não carregou no login.
  local pvp = SnapshotPvP()
  if pvp and (#pvp.ratings > 0 or pvp.conquest or pvp.honorLevel) then rec.pvp = pvp end

  if season then rec.season = season end
  local wsec = GetWeeklySeconds(); if wsec > 0 then rec.weeklyResetAt = now + wsec end -- só grava com a API pronta (evita reset prematuro)
  local dsec = GetDailySeconds(); if dsec > 0 then rec.dailyResetAt = now + dsec end
  rec.updatedAt     = now

  DB.chars[key] = rec
  KA.bus:Fire()
end

-- ---------------------------------------------------------------------------
-- Derivações para a UI (próxima ação, conclusão, resumo, métricas de sort)
-- ---------------------------------------------------------------------------
local function vaultFull(d)
  local v = d and d.vault
  if type(v) ~= "table" then return false end
  local function full(t) return t and (t.filled or 0) >= 3 end
  return full(v.mplus) and full(v.raid) and full(v.world)
end
-- exposto p/ a UI (glow da linha com cofre 3/3/3) e p/ a API pública
KA.IsVaultFull = vaultFull

-- "Completo" = cofre 3/3/3 e sem recompensa pendente (usado pelo "ocultar concluídos")
function KA.IsComplete(d)
  if type(d) ~= "table" then return false end
  if d.vault and d.vault.hasRewards then return false end
  return vaultFull(d)
end

-- Próxima ação por trilha: 1º slot ainda não desbloqueado → quanto falta + nº do slot
function KA.GetNextActions(v)
  local out = {}
  if type(v) ~= "table" then return out end
  local function scan(t, label)
    if type(t) ~= "table" or type(t.slots) ~= "table" then return end
    for i, s in ipairs(t.slots) do
      if not s.unlocked then
        local need = (s.threshold or 0) - (s.progress or 0)
        if need < 0 then need = 0 end
        out[#out + 1] = { track = label, need = need, slot = i }
        return
      end
    end
  end
  scan(v.mplus, L.TRACK_MPLUS)
  scan(v.raid,  L.TRACK_RAID)
  scan(v.world, L.TRACK_WORLD)
  return out
end

-- Contagens da conta (cofre cheio / recompensa pendente / total) — usado pela UI
-- (linha-resumo + tooltip do minimapa) e como base da API pública GetSummary.
function KA.GetCounts()
  local full, rewards, total = 0, 0, 0
  if DB and DB.chars then
    for _, c in pairs(DB.chars) do
      if type(c) == "table" then
        total = total + 1
        if vaultFull(c) then full = full + 1 end
        if c.vault and c.vault.hasRewards then rewards = rewards + 1 end
      end
    end
  end
  return { full = full, rewards = rewards, total = total }
end

local function crestSum(d)
  local s = 0
  if type(d.currencies) == "table" then
    for _, c in ipairs(d.currencies) do
      if c.kind == "crest" and type(c.quantity) == "number" then s = s + c.quantity end
    end
  end
  return s
end

-- "No cap de crests": atingiu o teto SEMANAL de pelo menos uma crest rastreada.
local function crestCapped(d)
  if type(d.currencies) ~= "table" then return false end
  for _, c in ipairs(d.currencies) do
    if c.kind == "crest" and (c.weeklyMax or 0) > 0 and (c.weekly or 0) >= c.weeklyMax then
      return true
    end
  end
  return false
end

-- Consolidado da CONTA p/ a linha-resumo do topo: cofres cheios, recompensas
-- pendentes, chars no cap de crests e ouro total (em cobre). Defensivo.
function KA.GetAccountSummary()
  local out = { full = 0, rewards = 0, total = 0, crestCapped = 0, goldCopper = 0 }
  if DB and DB.chars then
    for _, c in pairs(DB.chars) do
      if type(c) == "table" then
        out.total = out.total + 1
        if vaultFull(c) then out.full = out.full + 1 end
        if c.vault and c.vault.hasRewards then out.rewards = out.rewards + 1 end
        if crestCapped(c) then out.crestCapped = out.crestCapped + 1 end
        if type(c.gold) == "number" and c.gold > 0 then out.goldCopper = out.goldCopper + c.gold end
      end
    end
  end
  return out
end

-- Catalisador (Warband-wide: mesmo valor em todo char). Pega o snapshot mais
-- recente entre os chars (evita exibir um valor desatualizado). Defensivo.
function KA.GetCatalyst()
  if not (DB and DB.chars) then return nil end
  local best, bestAt
  for _, c in pairs(DB.chars) do
    if type(c) == "table" and type(c.weeklies) == "table" and type(c.weeklies.catalyst) == "table" then
      local at = c.updatedAt or 0
      if not bestAt or at > bestAt then best, bestAt = c.weeklies.catalyst, at end
    end
  end
  if type(best) ~= "table" then return nil end
  return { name = best.name, quantity = best.quantity or 0, max = best.max or 0 }
end

-- Coluna de ouro: opcional (OFF por padrão). Persistido. /kalts gold alterna.
function KA.GetShowGold() return (DB and DB.showGold) == true end
function KA.ToggleShowGold()
  if not DB then return end
  DB.showGold = not (DB.showGold == true)
  KA.bus:Fire()
end

-- Seção de profissões no detalhe: opcional (OFF por padrão). /kalts prof alterna.
function KA.GetShowProfessions() return (DB and DB.showProfessions) == true end
function KA.ToggleProfessions()
  if not DB then return end
  DB.showProfessions = not (DB.showProfessions == true)
  KA.bus:Fire()
end

-- Agrupamento da lista (3 estados): "none" | "realm" | "faction". Persistido.
function KA.GetGroupBy() return (DB and DB.groupBy) or "none" end

function KA.CycleGroupBy()
  if not DB then return end
  local cur = DB.groupBy or "none"
  DB.groupBy = (cur == "none" and "realm") or (cur == "realm" and "faction") or "none"
  KA.bus:Fire()
end

-- Define o agrupamento diretamente (usado pela config). Aceita "none"|"realm"|"faction".
function KA.SetGroupBy(mode)
  if not DB then return end
  if mode ~= "none" and mode ~= "realm" and mode ~= "faction" then mode = "none" end
  DB.groupBy = mode
  KA.bus:Fire()
end

-- Modo de detalhe (filtra as seções do painel por personagem): "pve" | "pvp" | "both".
-- Fonte da verdade em DB.settings.mode; default "pve". Persistido.
function KA.GetMode()
  return (DB and DB.settings and DB.settings.mode) or "pve"
end

function KA.SetMode(mode)
  if not (DB and DB.settings) then return end
  if mode ~= "pve" and mode ~= "pvp" and mode ~= "both" then mode = "pve" end
  DB.settings.mode = mode
  KA.bus:Fire()
end

-- ---------------------------------------------------------------------------
-- View da janela (toggle de abas): "chars" (tabela de personagens) | "keys"
-- (tabela de recompensas de Mítica+). Fonte da verdade em DB.settings.view;
-- default "chars". Persistido. Dispara o bus → a UI alterna a view.
-- ---------------------------------------------------------------------------
function KA.GetView()
  return (DB and DB.settings and DB.settings.view) or "chars"
end

function KA.SetView(view)
  if not (DB and DB.settings) then return end
  if view ~= "chars" and view ~= "keys" and view ~= "coach" and view ~= "raids" then view = "chars" end
  DB.settings.view = view
  KA.bus:Fire()
end

-- ---------------------------------------------------------------------------
-- Tabela de recompensas de Mítica+ — Midnight Season 1 (bloco hardcoded, fácil
-- de editar a cada season). 9 linhas SEM PULAR (+2..+10). Para cada nível de
-- chave: ilvl + trilha do item de FIM da masmorra e do GRANDE COFRE, e a
-- quantidade + tier do BRASÃO (crest) ganho.
--   tier: "C" = Campeão | "H" = Herói | "M" = Mítico
--   rank: posição "x/6" dentro da trilha (cada trilha tem 6 níveis de upgrade)
-- A UI (UI.lua) localiza os tiers e colore por faixa; nada aqui depende de API.
-- ---------------------------------------------------------------------------
KA.KEY_REWARDS = {
  { key = 2,  endI = 250, endT = "C", endR = "2/6", vaultI = 259, vaultT = "H", vaultR = "1/6", crest = 12, crestT = "C" },
  { key = 3,  endI = 250, endT = "C", endR = "2/6", vaultI = 259, vaultT = "H", vaultR = "1/6", crest = 14, crestT = "C" },
  { key = 4,  endI = 253, endT = "C", endR = "3/6", vaultI = 263, vaultT = "H", vaultR = "2/6", crest = 10, crestT = "H" },
  { key = 5,  endI = 256, endT = "C", endR = "4/6", vaultI = 263, vaultT = "H", vaultR = "2/6", crest = 12, crestT = "H" },
  { key = 6,  endI = 259, endT = "H", endR = "1/6", vaultI = 266, vaultT = "H", vaultR = "3/6", crest = 14, crestT = "H" },
  { key = 7,  endI = 259, endT = "H", endR = "1/6", vaultI = 269, vaultT = "H", vaultR = "4/6", crest = 16, crestT = "H" },
  { key = 8,  endI = 263, endT = "H", endR = "2/6", vaultI = 269, vaultT = "H", vaultR = "4/6", crest = 18, crestT = "H" },
  { key = 9,  endI = 263, endT = "H", endR = "2/6", vaultI = 269, vaultT = "H", vaultR = "4/6", crest = 10, crestT = "M" },
  { key = 10, endI = 266, endT = "H", endR = "3/6", vaultI = 272, vaultT = "M", vaultR = "1/6", crest = 12, crestT = "M" },
}

-- Recompensas de RAID — Midnight Season 1. Por DIFICULDADE (não por chave): os
-- bosses dropam numa FAIXA de ilvl (1º boss -> último boss), na trilha da
-- dificuldade; o Cofre dá até o ilvl do boss mais alto que você matou; o brasão
-- segue a dificuldade. ilvls espelham KeystoneLoot.UpgradeTracks.raid. EDITE a
-- cada season junto com KEY_REWARDS.
--   diff: chave i18n  ·  endLo/endHi: faixa de drop dos bosses  ·  tier V/C/H/M
KA.RAID_REWARDS = {
  { diff = "RAID_LFR",    endLo = 233, endHi = 243, endT = "V", vaultI = 243, vaultT = "V", crestT = "V" },
  { diff = "RAID_NORMAL", endLo = 246, endHi = 256, endT = "C", vaultI = 256, vaultT = "C", crestT = "C" },
  { diff = "RAID_HEROIC", endLo = 259, endHi = 269, endT = "H", vaultI = 269, vaultT = "H", crestT = "H" },
  { diff = "RAID_MYTHIC", endLo = 272, endHi = 282, endT = "M", vaultI = 282, vaultT = "M", crestT = "M" },
}

-- Custo de upgrade (Midnight Season 1): cada nível de upgrade de um item custa
-- `perRank` brasões; um item inteiro (6 níveis) custa `perItem`; o ganho semanal
-- de cada TIPO de brasão tem teto `weeklyCap`. Usado pelo rodapé da aba Chaves.
KA.UPGRADE_COST = { perRank = 20, perItem = 120, weeklyCap = 100 }

-- Mapa bonusId -> trilha/rank do item EQUIPADO (Midnight Season 1). Espelha os
-- bonusIds de upgrade do cliente (os mesmos de KeystoneLoot.UpgradeTracks.dungeon)
-- para o COACH da aba Chaves ler a trilha de cada peça SEM depender de addon externo.
--   code: "C" Campeão | "H" Herói | "M" Mítico   ·   rank x/maxRank   ·   ilvl da peça
-- O coach prefere a tabela viva do KeystoneLoot quando ela existir; este bloco é o
-- fallback autocontido. EDITE a cada season junto com KEY_REWARDS.
KA.UPGRADE_BONUS = {
  -- Campeão (maxRank 6)
  [12785] = { code = "C", rank = 1, maxRank = 6, ilvl = 246 },
  [12786] = { code = "C", rank = 2, maxRank = 6, ilvl = 250 },
  [12787] = { code = "C", rank = 3, maxRank = 6, ilvl = 253 },
  [12788] = { code = "C", rank = 4, maxRank = 6, ilvl = 256 },
  [12789] = { code = "C", rank = 5, maxRank = 6, ilvl = 259 },
  [12790] = { code = "C", rank = 6, maxRank = 6, ilvl = 263 },
  -- Herói (maxRank 6)
  [12793] = { code = "H", rank = 1, maxRank = 6, ilvl = 259 },
  [12794] = { code = "H", rank = 2, maxRank = 6, ilvl = 263 },
  [12795] = { code = "H", rank = 3, maxRank = 6, ilvl = 266 },
  [12796] = { code = "H", rank = 4, maxRank = 6, ilvl = 269 },
  [12797] = { code = "H", rank = 5, maxRank = 6, ilvl = 272 },
  [12798] = { code = "H", rank = 6, maxRank = 6, ilvl = 276 },
  -- Mítico (greatvault) (maxRank 6)
  [12801] = { code = "M", rank = 1, maxRank = 6, ilvl = 272 },
  [12802] = { code = "M", rank = 2, maxRank = 6, ilvl = 276 },
  [12803] = { code = "M", rank = 3, maxRank = 6, ilvl = 279 },
  [12804] = { code = "M", rank = 4, maxRank = 6, ilvl = 282 },
  [12805] = { code = "M", rank = 5, maxRank = 6, ilvl = 285 },
  [12806] = { code = "M", rank = 6, maxRank = 6, ilvl = 289 },
}

-- Teto de ilvl por trilha de upgrade (Midnight S1) e teto geral da season. O coach
-- (aba Progresso) usa p/ saber se uma peça ainda pode subir e dar contexto ao ilvl
-- atual ("X / 289"). EDITE a cada season junto com UPGRADE_BONUS/KEY_REWARDS.
KA.TRACK_CAP_ILVL  = { champion = 263, hero = 276, myth = 289 }
KA.SEASON_MAX_ILVL = 289

-- Design system compartilhado (estilo inspirado no KeystoneLoot) — tokens visuais
-- reutilizados por TODAS as abas (Personagens/Chaves/Progresso) p/ consistência.
-- Apenas APARÊNCIA; nenhuma lógica/dado depende disto.
KA.STYLE = {
  bgRow    = { 0, 0, 0, 0.16 },        -- zebra: fundo da linha par
  divider  = { 1, 1, 1, 0.07 },        -- linha divisória fina entre linhas
  titlebar = { 0.10, 0.10, 0.10, 1 },  -- titlebar escura
  card     = { 0, 0, 0, 0.12 },        -- fundo sutil de área (card)
  tabActive= { 1, 1, 1, 0.06 },        -- realce de fundo da aba ativa
}

-- Recomendação de chave conforme a trilha PREDOMINANTE do gear (refs Icy Veins /
-- Wowhead / Method — Midnight S1). keyL/msgL são CHAVES de i18n (resolvidas em L na
-- UI) p/ manter trilíngue. Faixa de brasão por chave: +2-3 Campeão · +4-8 Herói · +9+ Mítico.
KA.TRACK_NEXT_KEY = {
  none     = { keyL = "KEYS_COACH_NK_NONE_K",  msgL = "KEYS_COACH_NK_NONE_M"  },
  champion = { keyL = "KEYS_COACH_NK_CHAMP_K", msgL = "KEYS_COACH_NK_CHAMP_M" },
  hero     = { keyL = "KEYS_COACH_NK_HERO_K",  msgL = "KEYS_COACH_NK_HERO_M"  },
  myth     = { keyL = "KEYS_COACH_NK_MYTH_K",  msgL = "KEYS_COACH_NK_MYTH_M"  },
}

-- Banner de fundo por dungeon (challengeModeId -> fileID da arte de fundo). São os
-- mesmos bgTexture do KeystoneLoot (data/dungeons.lua, Season 16). Usado pela tabela
-- de prioridade do coach. Fallback: a `texture` do C_ChallengeMode.GetMapUIInfo.
-- EDITE a cada season (os IDs mudam com as dungeons do pool).
KA.DUNGEON_BG = {
  [161] = 1041999, -- Die Himmelsnadel / The Azure Vault-like
  [239] = 1718213, -- Sitz des Triumvirats
  [402] = 4742929, -- Akademie von Algeth'ar
  [556] = 608210,  -- Grube von Saron
  [557] = 7464937, -- Windläuferturm
  [558] = 7467174, -- Terrasse der Magister
  [559] = 7570501, -- Nexuspunkt Xenas
  [560] = 7478529, -- Maisarakavernen
}

local function vaultFilledSum(d)
  local v = d.vault
  if type(v) ~= "table" then return 0 end
  local function f(t) return (t and t.filled) or 0 end
  return f(v.mplus) + f(v.raid) + f(v.world)
end

local function raidMetric(d)
  local top = d.raids and d.raids[1]
  if not top then return -1 end
  return (top.difficultyId or 0) * 1000 + (top.progress or 0)
end

-- ---------------------------------------------------------------------------
-- Preferências persistidas (ordenação + ocultar concluídos)
-- ---------------------------------------------------------------------------
function KA.GetSort() return (DB and DB.sort) or nil end

function KA.SetSort(key)
  if not (DB and key) then return end
  local s = DB.sort
  if type(s) ~= "table" then s = {}; DB.sort = s end
  if s.key == key then
    s.dir = (s.dir == "asc") and "desc" or "asc"
  else
    s.key = key
    s.dir = (key == "name") and "asc" or "desc"
  end
  KA.bus:Fire()
end

function KA.GetHideCompleted() return DB and DB.hideCompleted end

function KA.SetHideCompleted(on)
  if not DB then return end
  DB.hideCompleted = on and true or false
  KA.bus:Fire()
end

function KA.SetNick(key, nick)
  if not (DB and DB.chars and DB.chars[key]) then return end
  if type(nick) == "string" then nick = nick:gsub("^%s+", ""):gsub("%s+$", "") end
  if not nick or nick == "" then nick = nil end
  DB.chars[key].nick = nick
  KA.bus:Fire()
end

-- ---------------------------------------------------------------------------
-- API interna p/ a UI
-- ---------------------------------------------------------------------------
-- Métricas de PvP p/ ordenação no modo PvP (linha recolhida mostra Rating/Conquista
-- em vez de M+/Crest, então a coluna "rating" ordena por maior rating PvP e a
-- coluna "crest" por Conquista ganha). Defensivo: 0 quando sem dado de PvP.
local function pvpBestRatingMetric(d)
  local pvp = d and d.pvp
  local best = 0
  if type(pvp) == "table" and type(pvp.ratings) == "table" then
    for _, r in ipairs(pvp.ratings) do
      if type(r) == "table" and (r.rating or 0) > best then best = r.rating end
    end
  end
  return best
end

local function pvpConquestMetric(d)
  local pvp = d and d.pvp
  if type(pvp) == "table" and type(pvp.conquest) == "table" then
    return pvp.conquest.earned or 0
  end
  return 0
end

local SortMetrics = {
  vault  = function(d) return vaultFilledSum(d) end,
  mplus  = function(d) return (d.mplus and d.mplus.runs) or 0 end,
  rating = function(d) return (d.mplus and d.mplus.rating) or 0 end,
  crest  = function(d) return crestSum(d) end,
  raid   = function(d) return raidMetric(d) end,
  ilvl   = function(d) return d.ilvl or 0 end,
  gold   = function(d) return d.gold or 0 end,
}

-- Métricas alternativas usadas quando o modo é PvP (mesmas chaves de coluna).
local SortMetricsPvP = {
  rating = pvpBestRatingMetric,
  crest  = pvpConquestMetric,
}

-- Ordenação padrão (sem critério escolhido): char logado primeiro, depois nível/ilvl/nome
local function legacyLess(a, b)
  if a.isCurrent ~= b.isCurrent then return a.isCurrent end
  local la, lb = a.data.level or 0, b.data.level or 0
  if la ~= lb then return la > lb end
  local ia, ib = a.data.ilvl or 0, b.data.ilvl or 0
  if ia ~= ib then return ia > ib end
  return (a.data.name or "") < (b.data.name or "")
end

-- Lista filtrada (ocultar concluídos) + ordenada pelo critério salvo.
-- O char logado nunca é ocultado e mantém o destaque visual (na UI).
function KA.GetChars()
  local list = {}
  if not (DB and DB.chars) then return list end
  local cur = CurrentKey()
  local hide = DB.hideCompleted
  for key, c in pairs(DB.chars) do
    if type(c) == "table" then
      local isCurrent = (key == cur)
      if not (hide and not isCurrent and KA.IsComplete(c)) then
        list[#list + 1] = { key = key, data = c, isCurrent = isCurrent }
      end
    end
  end

  local sort = DB.sort
  if type(sort) == "table" and sort.key then
    local asc = (sort.dir == "asc")
    if sort.key == "name" then
      table.sort(list, function(a, b)
        local na = (a.data.nick or a.data.name or ""):lower()
        local nb = (b.data.nick or b.data.name or ""):lower()
        if na == nb then return legacyLess(a, b) end
        if asc then return na < nb end
        return na > nb
      end)
    else
      -- no modo PvP, as colunas "rating"/"crest" passam a ordenar por dados de PvP
      local mode = (KA.GetMode and KA.GetMode()) or "pve"
      local metric = (mode == "pvp" and SortMetricsPvP[sort.key]) or SortMetrics[sort.key]
      if metric then
        table.sort(list, function(a, b)
          local va, vb = metric(a.data), metric(b.data)
          if va == vb then return legacyLess(a, b) end
          if asc then return va < vb end
          return va > vb
        end)
      else
        table.sort(list, legacyLess)
      end
    end
  else
    table.sort(list, legacyLess)
  end
  return list
end

function KA.RemoveChar(key)
  if DB and DB.chars and key then
    DB.chars[key] = nil
    KA.bus:Fire()
  end
end

-- Lista as moedas configuradas + varredura de descoberta (debug: /kalts curr)
function KA.PrintCurrencies()
  if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
    print(KA_PREFIX .. "C_CurrencyInfo indisponível.")
    return
  end
  print(KA_PREFIX .. "SEASON_CURRENCIES (configuradas):")
  for _, def in ipairs(SEASON_CURRENCIES) do
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, def.id)
    if ok and type(info) == "table" and info.name and info.name ~= "" then
      print(string.format("  [%d] %s — %s/%s  (semana %s/%s) <%s>",
        def.id, info.name,
        tostring(info.quantity or 0), tostring(info.maxQuantity or 0),
        tostring(info.quantityEarnedThisWeek or 0), tostring(info.maxWeeklyQuantity or 0),
        def.kind or "?"))
    else
      print(string.format("  [%d] sem dados — ID pode estar errado nesta season", def.id))
    end
  end
  print(string.format("%sDescoberta (IDs %d-%d com cap semanal):",
    KA_PREFIX, CURRENCY_SCAN_MIN, CURRENCY_SCAN_MAX))
  local found = 0
  for id = CURRENCY_SCAN_MIN, CURRENCY_SCAN_MAX do
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
    if ok and type(info) == "table" and info.name and info.name ~= ""
       and (info.maxWeeklyQuantity or 0) > 0 then
      print(string.format("  [%d] %s — %s/%s (semana %s/%s)",
        id, info.name,
        tostring(info.quantity or 0), tostring(info.maxQuantity or 0),
        tostring(info.quantityEarnedThisWeek or 0), tostring(info.maxWeeklyQuantity or 0)))
      found = found + 1
    end
  end
  if found == 0 then print("  (nada encontrado nessa faixa)") end
end

-- ===========================================================================
-- API PÚBLICA — namespace GLOBAL `KrononAlts` (consumida por outros addons do
-- ecossistema, ex.: KrononBags). Read-only, defensiva e disponível JÁ no load
-- (não dependem da janela existir/estar aberta). KA == KrononAlts (mesma tabela),
-- então estas globais reutilizam os helpers KA.* internos.
-- ===========================================================================

-- Próxima ação mais relevante da CONTA, como string curta (ou nil).
-- Prioridade: 1) cofre com recompensa pendente; 2) 1º slot de cofre faltando.
-- Reutiliza KA.GetChars (lista ordenada) e KA.GetNextActions (slots faltando).
local function ComputeNextAction()
  local ok, chars = pcall(KA.GetChars)
  if not ok or type(chars) ~= "table" then return nil end
  -- 1) recompensa pendente no Grande Cofre = ação mais urgente
  for _, e in ipairs(chars) do
    local d = e and e.data
    if type(d) == "table" and d.vault and d.vault.hasRewards then
      return (d.nick or d.name or "?") .. ": " .. L.VAULT_HAS_REWARDS
    end
  end
  -- 2) primeiro slot de cofre ainda não preenchido de algum personagem
  for _, e in ipairs(chars) do
    local d = e and e.data
    local nexts = (type(d) == "table") and KA.GetNextActions(d.vault) or nil
    if type(nexts) == "table" and nexts[1] then
      local na = nexts[1]
      return string.format("%s: %s %s",
        d.nick or d.name or "?", na.track or "?",
        string.format(L.NEXT_LINE, na.need or 0, na.slot or 0))
    end
  end
  return nil
end

--- KrononAlts.GetSummary() -> table
--  Resumo da CONTA inteira. SEMPRE retorna uma tabela:
--    { chars = number, vaultReady = number, vaultFull = number, nextAction = string|nil }
--    chars      = nº de personagens rastreados
--    vaultReady = nº com Grande Cofre com recompensa pendente (a coletar)
--    vaultFull  = nº com Grande Cofre cheio (3/3/3)
--    nextAction = string curta da próxima ação mais relevante da conta, ou nil
function KrononAlts.GetSummary()
  local okc, counts = pcall(KA.GetCounts)
  if not okc or type(counts) ~= "table" then counts = { full = 0, rewards = 0, total = 0 } end
  local nextAction
  local okn, na = pcall(ComputeNextAction)
  if okn then nextAction = na end
  return {
    chars      = counts.total or 0,
    vaultReady = counts.rewards or 0,
    vaultFull  = counts.full or 0,
    nextAction = nextAction,
  }
end

--- KrononAlts.GetChars() -> table (lista)
--  Lista read-only dos personagens com os dados do snapshot. Cada item:
--    { key = string, data = <snapshot do char>, isCurrent = boolean }
--  Já é uma global pública: KA == KrononAlts, e KA.GetChars (definida acima) É
--  KrononAlts.GetChars — mesma função, mesma tabela. NÃO mutar `data` (referência
--  ao registro salvo). Por isso não a redefinimos aqui (evita sobrescrever o
--  helper interno / recursão); apenas documentamos o contrato público.

--- KrononAlts.RegisterForUpdate(fn) -> boolean
--  Registra `fn` para ser chamada quando os snapshots atualizarem (via KA.bus).
--  Cada callback roda isolado em pcall. Ignora `fn` que não seja função.
--  Retorna true se registrou, false caso contrário.
function KrononAlts.RegisterForUpdate(fn)
  if type(fn) ~= "function" then return false end
  KA.bus:Register(fn)
  return true
end

-- KrononAlts.Toggle() e KrononAlts.Open() são definidas em UI.lua (precisam da
-- janela): Toggle alterna, Open garante a janela aberta. Ambas reutilizam KA.Toggle.

-- ---------------------------------------------------------------------------
-- Eventos + debounce (snapshots coalescidos com C_Timer)
-- ---------------------------------------------------------------------------
local pending = false
local function ScheduleSnapshot()
  if pending then return end
  pending = true
  C_Timer.After(SNAPSHOT_DELAY, function()
    pending = false
    pcall(Snapshot)
  end)
end

local function RequestData()
  if C_MythicPlus then
    if C_MythicPlus.RequestMapInfo then pcall(C_MythicPlus.RequestMapInfo) end
    if C_MythicPlus.RequestRewards then pcall(C_MythicPlus.RequestRewards) end
  end
  if type(RequestRaidInfo) == "function" then pcall(RequestRaidInfo) end
end

-- Lembrete no login (1x por sessão, alguns segundos após logar): avisa se algum
-- char tem recompensa de Cofre pendente ou está a <24h do reset com objetivos
-- faltando. Desligável (DB.loginReminder). Totalmente defensivo.
local reminderDone = false
local function LoginReminder()
  if reminderDone then return end
  reminderDone = true
  if not DB or DB.loginReminder == false then return end
  local oks, s = pcall(KA.GetAccountSummary)
  if not oks or type(s) ~= "table" then return end
  local msgs = {}
  if (s.rewards or 0) > 0 then
    msgs[#msgs + 1] = string.format(L.REMINDER_VAULT, s.rewards)
  end
  local w = GetWeeklySeconds()
  if w > 0 and w < 86400 and DB.chars then
    local missing = 0
    for _, c in pairs(DB.chars) do
      if type(c) == "table" and not vaultFull(c) then missing = missing + 1 end
    end
    if missing > 0 then msgs[#msgs + 1] = string.format(L.REMINDER_RESET, missing) end
  end
  if #msgs > 0 then print(KA_PREFIX .. table.concat(msgs, "  ")) end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("WEEKLY_REWARDS_UPDATE")
f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
f:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("UPDATE_INSTANCE_INFO")
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 == ADDON then InitDB() end
  elseif event == "PLAYER_LOGIN" then
    InitDB()
    ApplyWeeklyResets()
    RequestData()
    ScheduleSnapshot()
    if KA.InitMinimap then pcall(KA.InitMinimap) end
    if C_Timer and C_Timer.After then
      C_Timer.After(8, function() pcall(LoginReminder) end)
    end
  elseif event == "PLAYER_LOGOUT" then
    pcall(Snapshot)
  else
    ScheduleSnapshot()
  end
end)

-- ---------------------------------------------------------------------------
-- Slash: /kalts e /ka (abre/fecha a janela; "snapshot" força uma releitura)
-- ---------------------------------------------------------------------------
SLASH_KRONONALTS1 = "/kalts"
SLASH_KRONONALTS2 = "/ka"
SlashCmdList["KRONONALTS"] = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "snapshot" or msg == "refresh" then
    pcall(Snapshot)
    print(KA_PREFIX .. L.MSG_SNAPSHOT)
    return
  elseif msg == "curr" or msg == "currency" or msg == "currencies" then
    KA.PrintCurrencies()
    return
  elseif msg == "reminder" or msg == "lembrete" or msg == "recordatorio" then
    if DB then
      DB.loginReminder = not (DB.loginReminder ~= false)
      print(KA_PREFIX .. (DB.loginReminder and L.REMINDER_ON or L.REMINDER_OFF))
    end
    return
  elseif msg == "group" or msg == "agrupar" or msg == "grupo" then
    if KA.CycleGroupBy then KA.CycleGroupBy() end
    return
  elseif msg == "gold" or msg == "ouro" or msg == "oro" then
    if KA.ToggleShowGold then KA.ToggleShowGold() end
    return
  elseif msg == "prof" or msg == "profs" or msg == "profissoes" or msg == "profesiones" then
    if KA.ToggleProfessions then KA.ToggleProfessions() end
    return
  elseif msg == "config" or msg == "options" or msg == "settings"
      or msg == "opcoes" or msg == "opções" or msg == "opciones" then
    if KA.OpenConfig then KA.OpenConfig() end
    return
  end
  if KA.Toggle then KA.Toggle() end
end
