-- TODO: One thing I just thought about is that it might matter the ordering of
-- these requires. In the sense that some may expect some globals to be loaded
-- before others. If that's the case, that's fine. We will just make sure that
-- they stay nicely ordered. Until them I'll do roughly alphabetical.

F = {
  if_nil = function(value, default, backup)
    if value ~= nil then
      return value
    end

    if backup ~= nil then
      return backup
    end

    return default
  end,
}

TIME = require "vibes.engine.time"

require "vendor.print"
require "vendor.table"
V = require "vibes.V"
E = require "vibes.ease"

-- Helper Prelude
class = require "vibes.class"
logger = require "vibes.logger"
Encodable = require "vibes.encodable"

Enum = require "vibes.enum"

validate = require "vibes.validate"
inspect = require "vendor.inspect"

do -- Enum Prelude
  ActionResult = require "vibes.enum.action-result"
  ActionState = require "vibes.enum.action-state"
  CardAfterPlay = require "vibes.enum.card-after-play"
  CardKind = require "vibes.enum.card-kind"
  CharacterKind = require "vibes.enum.character-kind"
  DamageKind = require "vibes.enum.damage-kind"
  DeckState = require "vibes.enum.deck-state"
  DropzoneStatus = require "vibes.enum.dropzone-status"
  EffectDuration = require "vibes.enum.effect-duration"
  ElementKind = require "vibes.enum.element-kind"
  EnemyStatField = require "vibes.enum.enemy-stat-field"
  EnemyStatus = require "vibes.enum.enemy-status"
  EnemyType = require "vibes.enum.enemy-type"
  Enhancement = require "vibes.enum.enhancement"
  ForgeCraftState = require "vibes.enum.forge-craft-state"
  GearKind = require "vibes.enum.gear-kind"
  GearSlot = require "vibes.enum.gear-slot"
  IconType = require "vibes.enum.icon-type"
  LevelUpRewardKind = require "vibes.enum.level-up-reward-kind"
  ModeName = require "vibes.enum.mode-name"
  PackKind = require "vibes.enum.pack-kind"
  Rarity = require "vibes.enum.rarity"
  RoundLifecycle = require "vibes.enum.round-lifecycle"
  StatOperationKind = require "vibes.enum.stat-operation-kind"
  TextControl = require "vibes.enum.text-control"
  TooltipPlacement = require "vibes.enum.tooltip-placement"
  TowerKind = require "vibes.enum.tower-kind"
  TowerStatField = require "vibes.enum.tower-stat-field"
  UIAction = require "vibes.enum.u-i-action"
  UpgradeHint = require "vibes.enum.upgrade-hint"
  Z = require "vibes.enum.z"
end

function NOOP() end

Position = require "vibes.data.position"

-- Shaders, must load before asset
Shader = require "vibes.shader"
ShaderBoundaryOutline = require "vibes.shader.boundary-outline"
ShaderCard3DTilt = require "vibes.shader.card-3d-tilt"
ShaderCloud = require "vibes.shader.cloud"
ShaderColorSwap = require "vibes.shader.color-swap"
ShaderEdgeGlowThrob = require "vibes.shader.edge-glow-throb"
ShaderEdgeOutline = require "vibes.shader.edge-outline"
ShaderMapFadeOut = require "vibes.shader.map-fade-out"
ShaderShine = require "vibes.shader.shine"
ShaderRewind = require "vibes.shader.rewind"
ShaderShadow = require "vibes.shader.shadow"
ShaderGrassNoise = require "vibes.shader.grass-noise"

-- Load Globals
Config = require "vibes.config"
EventBus = require "vibes.event-bus"
Asset = require "vibes.asset"

-- Load sound assets now
SoundManager = require "vibes.sound-manager"

-- Speed Manager
SpeedManager = require "vibes.speed-manager"

-- Data Prelude
Stat = require "vibes.data.stat"
StatOperation = require "vibes.data.stat-operation"
TowerStats = require "vibes.data.tower-stats"
TowerStatOperation = require "vibes.data.tower-stats-operation"
EnemyStats = require "vibes.data.enemy-stats"
EnemyStatOperation = require "vibes.data.enemy-stats-operation"
Cell = require "vibes.data.cell"
Path = require "vibes.data.path"

-- UI
Animation = require "vibes.systems.animation-system"
Box = require "ui.components.box"
Element = require "ui.components.element"
Button = require "ui.components.inputs.button"
Icon = require "ui.components.elements.icon"
Layout = require "ui.components.layout"

-- Card Prelude
Card = require "vibes.card.base"
EffectCard = require "vibes.card.base-effect-card"
EnhancementCard = require "vibes.card.enhancement"
AuraCard = require "vibes.card.base-aura-card"

-- ActionQueue Prelude
ActionQueue = require "vibes.systems.action-queue"

-- Systems
PoisonPoolSystem = require "vibes.systems.poison-pool-system"
FirePoolSystem = require "vibes.systems.fire-pool-system"

-- Tooltip Manager
TooltipManager = require "vibes.tooltip-manager"

-- ColorSchema
require "utils.colors"

-- Initialize Global Events
require "vibes.global_events"

require "vibes.data.tower-stats-operation-helper"

GAME = require "vibes.modes.game" --[[@as vibes.GameMode]]
GEAR = require "gear.state"

-- Random useful for stuff that does not need to be reproducible.
Timer = require "vibes.timer"
TrueRandom = require("vibes.engine.random").new { name = "true-random" }
GameAnimationSystem = require "vibes.systems.game-animation"
