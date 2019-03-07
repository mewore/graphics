require "math-utils"

TileControls = {}
TileControls.__index = TileControls

local mathUtils = MathUtils:create()

--- Tile controls allow the user to provide tile-based input (i.e. clicking in a grid)
-- @param colour {r: number, g: number, b: number} - The colour of the tile the user has hovered over
-- @param tileWidth {number} - The width of each tile, in pixels
-- @param tileHeight {number} - The height of each tile, in pixels
function TileControls:create(colour, tileWidth, tileHeight, navigator)
   local this = {
      colour = colour,
      tileWidth = tileWidth,
      tileHeight = tileHeight,
      mouseDownCallback = nil,
      hoveredColumn = 0,
      hoveredRow = 0,
      lastMouseDownPosition = nil,
      mouseIsDown = false,
      navigator = navigator,
   }
   setmetatable(this, self)

   return this
end

--- Add a handler for when the mouse is held down
-- @param callback {function}
function TileControls:onMouseDown(callback)
   self.mouseDownCallback = callback
end

--- LOVE update callback
function TileControls:update()
   local mouseAbsoluteX, mouseAbsoluteY = self.navigator:screenToAbsolute(love.mouse.getX(), love.mouse.getY())
   self.hoveredColumn = math.floor(mouseAbsoluteX / self.tileWidth) + 1
   self.hoveredRow = math.floor(mouseAbsoluteY / self.tileHeight) + 1

   local mouseIsDown = false
   for mouseButton = 1, 2 do
      if self.mouseDownCallback ~= nil and love.mouse.isDown(mouseButton) then
         if self.lastMouseDownPosition == nil or self.mouseIsDown == false then
            self.mouseDownCallback({ { x = self.hoveredColumn, y = self.hoveredRow } }, mouseButton)
         else
            local linePoints = mathUtils:getDiscreteLine(self.lastMouseDownPosition.x, self.lastMouseDownPosition.y,
               self.hoveredColumn, self.hoveredRow)
            self.mouseDownCallback(linePoints, mouseButton)
         end
         self.lastMouseDownPosition = { x = self.hoveredColumn, y = self.hoveredRow }
         mouseIsDown = true
      end
   end
   self.mouseIsDown = mouseIsDown
end

--- LOVE draw callback
function TileControls:draw()
   local leftX = (self.hoveredColumn - 1) * self.tileWidth
   local topY = (self.hoveredRow - 1) * self.tileHeight

   love.graphics.setColor(self.colour.r, self.colour.g, self.colour.b, 0.3)
   love.graphics.rectangle("fill", leftX, topY, self.tileWidth, self.tileHeight)
   love.graphics.setColor(self.colour.r, self.colour.g, self.colour.b, 1)
   love.graphics.rectangle("line", leftX, topY, self.tileWidth, self.tileHeight)
   love.graphics.reset()
end