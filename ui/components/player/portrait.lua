---@class (exact) ui.components.player.Portrait : Element
---@field new fun(box: ui.components.Box): ui.components.player.Portrait
---@field init fun(self: ui.components.player.Portrait, box: ui.components.Box)
---@field super Element
---@field health number
---@field energy number
---@field discards number
---@field scale number
---@field portrait_texture love.Image|love.Drawable
---@field hud_texture love.Image|love.Drawable
---@field hud_zero_energy_texture love.Image|love.Drawable
---@field discard_icon ui.components.Icon
local Portrait = class("ui.components.player.Portrait", { super = Element })

---@param box ui.components.Box
function Portrait:init(box)
  Element.init(self, box)

  -- Calculate scale to fit the portrait within the provided box
  local asset_width = Asset.sprites.player_hud:getWidth()
  local asset_height = Asset.sprites.player_hud:getHeight()
  local scale_x = box.width / asset_width
  local scale_y = box.height / asset_height
  local scale = math.min(scale_x, scale_y) -- Use the smaller scale to maintain aspect ratio

  self.name = "Portrait"
  self.scale = scale
  self.hud_texture = Asset.sprites.player_hud
  self.hud_zero_energy_texture = Asset.sprites.player_hud_zero_energy
  self.portrait_texture = Asset.sprites.player_hud_portrait_default

  -- Position discard icon relative to the scaled portrait size
  local scaled_width = asset_width * scale
  local scaled_height = asset_height * scale
  local icon_x = scaled_width * 0.85 -- Position near the right edge
  local icon_y = scaled_height * 0.6 -- Position in the lower portion

  self.discard_icon = Icon.new({
    type = IconType.DISCARD,
    label = { value = State.player.discards, placement = "right" },
    scale = 0.35,
    background = Colors.black:opacity(0.5),
    padding = 10,
    rounded = 10,
  }, Position.new(icon_x, icon_y))

  self:append_child(self.discard_icon)
end

function Portrait:_update(_)
  self.discard_icon.label.value = State.player.discards
end

function Portrait:_render()
  love.graphics.push()
  local x, y = self:get_geo()
  local scale = self.scale
  local opacity = self:get_opacity()
  if State.player.energy > 0 then
    love.graphics.draw(self.hud_texture, x, y, 0, scale, scale)
  else
    love.graphics.draw(self.hud_zero_energy_texture, x, y, 0, scale, scale)
  end
  love.graphics.draw(self.portrait_texture, x - 3, y + 3, 0, scale, scale)

  if State.debug then
    love.graphics.setColor(1, 1, 1, opacity)
    love.graphics.circle("line", x, y, 4)
  end

  -- Position energy text relative to the scaled portrait
  local energy_y = y + (112 * scale / 1.75) -- Scale the original offset
  local energy_x = x + (6 * scale / 1.75) -- Scale the original offset
  love.graphics.setFont(Asset.fonts.default_14)
  love.graphics.printf(State.player.energy, energy_x, energy_y, 30, "center")

  love.graphics.pop()
  love.graphics.setColor(1, 1, 1, 1)
end

return Portrait
