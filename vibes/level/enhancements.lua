-- TODO: Prime?  What is happening in this file?
-- local Random = require "vibes.engine.random"
-- local random = Random.new { name = "level-enhancements" }

-- local function get_random_enhancements(level)
--   local enhancement_level = level - 2
--   if enhancement_level < 0 then return {} end

--   local enhancements = {}
--   local enhancement_percent = enhancement_level * 0.25
--   while enhancement_percent > 0 do
--   if enhancement_percent > 1 then
--     table.insert(enhancements, random_enhancement())
--   else
--     if random:dec() < enhancement_percent then
--       table.insert(enhancements, random_enhancement())
--     end
--   end
--   enhancement_percent = enhancement - 1
-- end

-- return {
--   get_random_enhancements = get_random_enhancements,
-- }
