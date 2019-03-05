require 'map-editor'

local mapEditor = MapEditor:create('tiles')

love.keyboard.keysPressed = {}
love.keyboard.keysReleased = {}

function love.load()
   love.graphics.setDefaultFilter('nearest', 'nearest')
end

function love.keypressed(key)
   if key == 'escape' then
      love.event.quit()
   end
   print('Pressed:', key)
   love.keyboard.keysPressed[key] = true
end

function love.keyreleased(key)
   print('Released:', key)
   love.keyboard.keysReleased[key] = true
end

function love.update()
   love.keyboard.keysPressed = {}
   love.keyboard.keysReleased = {}
end

function love.draw()
   love.graphics.clear(0.4, 0.66, 0.95, 1.0)
   mapEditor:render()
end
