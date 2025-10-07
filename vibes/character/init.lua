---@class vibes.Character.Starter
---@field deck vibes.Card[]
---@field gold number
---@field energy number

---@class vibes.Character.Avatar
---@field full vibes.Texture
---@field thumbnail vibes.Texture
---@field background vibes.Texture

---@class vibes.Character.Opts
---@field kind CharacterKind
---@field name string
---@field description string
---@field starter vibes.Character.Starter
---@field avatar vibes.Character.Avatar

---@class (exact) vibes.Character
---@field new fun(opts: vibes.Character.Opts)
---@field init fun(self: vibes.Character, opts: vibes.Character.Opts)
---@field kind CharacterKind
---@field name string
---@field description string
---@field starter vibes.Character.Starter
---@field avatar vibes.Character.Avatar
local Character = class "vibes.Character"

function Character:init(opts)
  validate(opts, {
    kind = "CharacterKind",
    name = "string",
    description = "string",
    starter = "vibes.Character.Starter",
    avatar = "vibes.Character.Avatar",
  })

  self.kind = opts.kind
  self.name = opts.name
  self.description = opts.description
  self.starter = opts.starter
  self.avatar = opts.avatar
end

return Character
