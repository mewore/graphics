require "map-editor"

local mapEditor = MapEditor:create(love.filesystem.getWorkingDirectory() .. "/tilesheets")

love.keyboard.keysPressed = {}
love.keyboard.keysReleased = {}

--- LOVE load callback
function love.load()
   love.graphics.setDefaultFilter("nearest", "nearest")
end

--- LOVE key pressed callback
-- @param key {string} - The pressed key
function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
   print("Pressed:", key)
   love.keyboard.keysPressed[key] = true
end

--- LOVE key released callback
-- @param key {string} - The released key
function love.keyreleased(key)
   print("Released:", key)
   love.keyboard.keysReleased[key] = true
end

--- LOVE update callback
function love.update()
   mapEditor:update()
   love.keyboard.keysPressed = {}
   love.keyboard.keysReleased = {}
end

--- LOVE draw callback
function love.draw()
   love.graphics.clear(1, 1, 1, 1)
   mapEditor:draw()
end
