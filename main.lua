require "views/main-menu"
require "lib/advanced-mouse-input"
require "util/view-stack"

love.keyboard.keysPressed = {}
love.keyboard.keysReleased = {}
love.keyboard.input = ""

--- LOVE load handler
function love.load()
   love.graphics.setDefaultFilter("nearest", "nearest")
end

--local focusDelta

--- LOVE key pressed handler
-- @param key {string} - The pressed key
function love.keypressed(key)
   print("Pressed:", key)
   --   if key == "tab" then
   --      focusDelta = focusDelta + (love.keyboard.isDown("rshift") or love.keyboard.isDown("lshift")) and -1 or 1
   --   end
   love.keyboard.keysPressed[key] = true
end

--- LOVE key released handler
-- @param key {string} - The released key
function love.keyreleased(key)
   print("Released:", key)
   love.keyboard.keysReleased[key] = true
end

--- LOVE text input handler
-- @param text {string} - The input
function love.textinput(text)
   love.keyboard.input = love.keyboard.input .. text
end

local focusedOnto, previouslyFocusedOnto
function love.keyboard.focus(element)
   love.keyboard.focusedSince = love.timer.getTime()
   focusedOnto = element
end

--local firstRegisteredFocusable
function love.keyboard.registerFocusable(element)
   --   firstRegisteredFocusable = firstRegisteredFocusable or element
   if love.mouse.registerSolid(element).clickCount > 0 then
      love.keyboard.focusedSince = love.timer.getTime()
      focusedOnto = element
   end
   if focusedOnto == nil and previouslyFocusedOnto == element then focusedOnto = element end
   return focusedOnto == element
end

local advancedMouseInput = AdvancedMouseInput:create()
local mainMenu = MainMenu:create()
viewStack = ViewStack:create(mainMenu)
local background = {}

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function love.update(dt)
   advancedMouseInput:beforeUpdate()
   love.keyboard.controlIsDown = love.keyboard.isDown("rctrl") or love.keyboard.isDown("lctrl")
   love.keyboard.shiftIsDown = love.keyboard.isDown("rshift") or love.keyboard.isDown("lshift")
   love.keyboard.altIsDown = love.keyboard.isDown("ralt") or love.keyboard.isDown("lalt")
   love.keyboard.commandIsDown = love.keyboard.isDown("rgui") or love.keyboard.isDown("lgui")
   love.keyboard.escapeIsPressed = love.keyboard.keysPressed["escape"]
   love.keyboard.returnIsPressed = love.keyboard.keysPressed["return"]
   love.keyboard.closeIsPressed = love.keyboard.keysPressed["w"] and love.keyboard.controlIsDown
   previouslyFocusedOnto, focusedOnto = focusedOnto, nil

   viewStack:update(dt)

   local backgroundMouseInfo = love.mouse.registerSolid(background, { isWholeScreen = true })
   if backgroundMouseInfo.clickCount > 0 then
      love.keyboard.focus(nil)
   end

   love.keyboard.keysPressed = {}
   love.keyboard.keysReleased = {}
   love.keyboard.input = ""
   advancedMouseInput:afterUpdate()
end

--- Draw an outline around this object if it is focused
-- @param object {table} - The object to draw the outline around.
function love.graphics.drawFocusOutline(object)
   if focusedOnto == object and object.x and object.y and object.width and object.height then
      local radius = 1 + (object.outlineRadius or 0)
      love.graphics.setColor(0.2, 0.6, 1, 0.5)
      love.graphics.setLineWidth(4)
      local OFFSET = -1
      love.graphics.rectangle("line", object.x + OFFSET, object.y + OFFSET, object.width - OFFSET * 2,
         object.height - OFFSET * 2, radius, radius, radius)
      love.graphics.reset()
   end
end

--- LOVE draw handler
function love.draw()
   viewStack:draw()
end
