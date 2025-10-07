local function is_action_canceled()
  return love.keyboard.isDown "escape" or love.mouse.isDown(2)
end

local function is_action_confirmed() return love.mouse.isDown(1) end

return {
  is_action_canceled = is_action_canceled,
  is_action_confirmed = is_action_confirmed,
}
