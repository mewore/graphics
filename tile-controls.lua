require "math-utils"

TileControls = {}
TileControls.__index = TileControls

local mathUtils = MathUtils:create()

function TileControls:create(colour, tileWidth, tileHeight)
   local this = {
      colour = colour,
      tileWidth = tileWidth,
      tileHeight = tileHeight,
      mouseDownCallback = nil,
      hoveredColumn = 0,
      hoveredRow = 0,
      lastMouseDownPosition = nil,
      mouseIsDown = false,
   }
   setmetatable(this, self)

   return this
end

function TileControls:onMouseDown(callback)
   self.mouseDownCallback = callback
end

function TileControls:update()
   self.hoveredColumn = math.floor(love.mouse.getX() / self.tileWidth) + 1
   self.hoveredRow = math.floor(love.mouse.getY() / self.tileHeight) + 1

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

function TileControls:render()
   local leftX = (self.hoveredColumn - 1) * self.tileWidth
   local topY = (self.hoveredRow - 1) * self.tileHeight

   love.graphics.setColor(self.colour.r, self.colour.g, self.colour.b, 0.3)
   love.graphics.rectangle("fill", leftX, topY, self.tileWidth, self.tileHeight)
   love.graphics.setColor(self.colour.r, self.colour.g, self.colour.b, 1)
   love.graphics.rectangle("line", leftX, topY, self.tileWidth, self.tileHeight)
   love.graphics.reset()
end