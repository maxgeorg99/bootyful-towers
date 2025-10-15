-- Configuration file for LÖVE
function love.conf(t)
  t.title = "Bootyful Towers"
  t.version = "11.4" -- The LÖVE version this game was made for
  t.window.width = 1600
  t.window.height = 900
  t.window.resizable = false
  t.window.vsync = true

  t.modules.audio = true
  t.modules.event = true
  t.modules.graphics = true
  t.modules.image = true
  t.modules.keyboard = true
  t.modules.math = true
  t.modules.mouse = true
  t.modules.physics = false
  t.modules.sound = true
  t.modules.system = true
  t.modules.timer = true
  t.modules.window = true
  t.modules.video = true
end
