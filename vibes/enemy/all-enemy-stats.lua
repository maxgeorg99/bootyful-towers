---@type table<EnemyType, enemy.Properties>
local stats = {}

stats[EnemyType.BAT] = {
  health = 10,
  speed = 64,
  gold_reward = 1, -- Keeping at minimum
  xp_reward = 10,
  enemy_type = EnemyType.BAT,
  animation = Asset.animations.bat_fly,
  texture = Asset.sprites.enemy_bat,
  origin = Position.new(0, 48),

  scale_x = 1,
}

stats[EnemyType.BAT_ELITE] = {
  health = 250,
  speed = 35,
  damage = 25,
  gold_reward = 3,
  xp_reward = 20,
  enemy_type = EnemyType.BAT_ELITE,
  texture = Asset.sprites.enemy_bat_red,
  animation = Asset.animations.bat_fly,
  rank = "elite",
}

stats[EnemyType.GOBLIN] = {
  health = 40,
  speed = 20,
  gold_reward = 1, -- Keeping at minimum
  xp_reward = 20,
  enemy_type = EnemyType.GOBLIN,
  animation = Asset.animations.mine_goblin_walk,
  texture = Asset.sprites.enemy_mine_goblin,
}

stats[EnemyType.MINE_GOBLIN] = {
  health = 100,
  speed = 35,
  gold_reward = 3,
  xp_reward = 25,
  enemy_type = EnemyType.MINE_GOBLIN,
  texture = Asset.sprites.enemy_mine_goblin,
  animation = Asset.animations.mine_goblin_walk,
}

stats[EnemyType.ORC] = {
  health = 120,
  speed = 30,
  gold_reward = 5,
  xp_reward = 100,
  enemy_type = EnemyType.ORC,
  texture = Asset.sprites.enemy_orc,
  animation = Asset.animations.orc_warrior_walk,
}

stats[EnemyType.SNAIL] = {
  health = 100,
  shield = 100,
  speed = 10,
  texture = Asset.sprites.enemy_snail,
  gold_reward = 2,
  xp_reward = 15,
  enemy_type = EnemyType.SNAIL,
  animation = Asset.sprites.enemy_snail_walk,
}

stats[EnemyType.WOLF] = {
  health = 150,
  speed = 60,
  gold_reward = 4,
  xp_reward = 100,
  enemy_type = EnemyType.WOLF,
  texture = Asset.sprites.enemy_wolf,
  animation = Asset.animations.wolf_walk,
}

stats[EnemyType.ORC_CHIEF] = {
  health = 800,
  speed = 25,
  damage = 30,
  gold_reward = 6,
  xp_reward = 75,
  enemy_type = EnemyType.ORC_CHIEF,
  animation = Asset.animations.orc_chief_walk,
  texture = Asset.sprites.enemy_orc_chief,
  origin = Position.new(0, 0),
  rank = "elite",

  scale_x = 1,
}

stats[EnemyType.ORC_WHEELER] = {
  health = 15,
  speed = 100,
  gold_reward = 1, -- Keeping at minimum
  xp_reward = 15,
  damage = 50,
  enemy_type = EnemyType.ORC_WHEELER,
  animation = Asset.animations.orc_wheeler_walk,
  texture = Asset.sprites.enemy_orc_wheeler,
  origin = Position.new(0, 0),

  orc_wheeler_explosion_radius = 10,
}

stats[EnemyType.ORC_SHAMAN] = {
  health = 500,
  speed = 20,
  damage = 35,
  gold_reward = 6,
  xp_reward = 20,
  enemy_type = EnemyType.ORC_SHAMAN,
  animation = Asset.animations.orc_shaman_walk,
  texture = Asset.sprites.enemy_orc_shaman,

  shaman_heal_amount = 5,
  shaman_heal_range_in_cells = 3,
}

stats[EnemyType.ORCA] = {
  health = 5000,
  speed = 40,
  damage = 50,
  gold_reward = 13,
  xp_reward = 100,
  enemy_type = EnemyType.ORCA,
  texture = Asset.sprites.enemy_orca,
  animation = Asset.animations.orca_walk,

  orca_boss_eat_multiplier = 2,
  orca_boss_low_health_multiplier = 2,
  orca_boss_low_health_threshold = 0.25,
}

stats[EnemyType.WYVERN] = {
  health = 2500,
  speed = 100,
  damage = 50,
  gold_reward = 10,
  xp_reward = 100,
  enemy_type = EnemyType.WYVERN,
  texture = Asset.sprites.enemy_wyvern,
  animation = Asset.animations.wyvern_fly,
}

stats[EnemyType.KING] = {
  health = 25000,
  speed = 24,
  damage = 100,
  gold_reward = 3,
  xp_reward = 100,
  enemy_type = EnemyType.KING,
  texture = Asset.sprites.enemy_king,
  animation = Asset.animations.king_walk,

  scale_x = 1,
}

stats[EnemyType.CAT_TATUS] = {
  health = 15000,
  speed = 30,
  damage = 75,
  gold_reward = 10,
  xp_reward = 100,
  enemy_type = EnemyType.CAT_TATUS,
  texture = Asset.sprites.enemy_cat_tatus or Asset.sprites.enemy_bat,
  animation = Asset.animations.cat_tatus_walk,

  -- List of start and end cells for teleporting
  cat_tatus_teleport_cells = {
    { start_row = 3, start_col = 2, end_row = 3, end_col = 5 },
  },

  scale_x = 1,
}

stats[EnemyType.TAUNTOISE] = {
  health = 8000,
  speed = 25,
  damage = 60,
  gold_reward = 8,
  xp_reward = 80,
  enemy_type = EnemyType.TAUNTOISE,
  texture = Asset.sprites.enemy_tauntoise,
  animation = Asset.animations.tauntoise_walk,

  tauntoise_taunt_duration = 3000,
  tauntoise_taunt_cells = {
    { row = 3, col = 1 },
    { row = 3, col = 5 },
  },

  scale_x = 1,
}

return stats
