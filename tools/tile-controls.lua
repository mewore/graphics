require "util/math-utils"

TileControls = {}
TileControls.__index = TileControls

local LEFT_MOUSE_BUTTON = 1
local RIGHT_MOUSE_BUTTON = 2

local mathUtils = MathUtils:create()

--- Tile controls allow the user to provide tile-based input (i.e. clicking in a grid). Basically a pencil.
-- @param colour {r: float, g: float, b: float} - The colour of the tile the user has hovered over
-- @param tileWidth {int} - The width of each column/tile, in pixels
-- @param tileHeight {int} - The height of each row/tile, in pixels
-- @param canvasWidth {int} - The total number of columns
-- @param canvasHeight {int} - The total number of rows
-- @param navigator {Navigator} - The navigator used for whatever is being edited with the tile controls
-- @param singular {boolean} - Whether the controls are meant only for single selection instead of drawing.
function TileControls:create(colour, tileWidth, tileHeight, canvasWidth, canvasHeight, navigator, singular)
   local this = {
      colour = colour,
      tileWidth = tileWidth,
      tileHeight = tileHeight,
      canvasWidth = canvasWidth,
      canvasHeight = canvasHeight,
      drawProgressHandler = function() end,
      drawDoneHandler = function() end,
      leftHoveredColumn = 0,
      topHoveredRow = 0,
      lastMouseDownPosition = nil,
      navigator = navigator,
      size = 1,
      singular = singular,
      drawingWith = nil,
      invisible = true,
   }
   setmetatable(this, self)

   return this
end

--- Add a handler for when the mouse is held down
-- @param handler {function}
function TileControls:onDrawProgress(handler)
   self.drawProgressHandler = handler
end

--- Add a handler when a set of draw operations are complete
-- @param handler {function}
function TileControls:onDrawDone(handler)
   self.drawDoneHandler = handler
end

function TileControls:zoom(mouseScrollDy)
   if mouseScrollDy ~= 0 then
      local sign = love.mouse.wheel.dy > 0 and 1 or -1
      local delta = -math.floor(math.abs(love.mouse.wheel.dy) * (self.size * 0.1 + 1)) * sign
      self.size = math.max(self.size + delta, 1)
   end
end

--- The number of cells that is omitted on the left side of each row of the circle from top to bottom (the same number
-- is on the right side)
local circleRowsByDiameter = { { 0 }, { 0, 0 } }

--- Calculate the number of empty cells a circle with a specified diameter has to its left. Imagine a black circle is in
-- a white square matrix and fits nicely in it, where each cell is 1 unit long and wide.
-- `circleRowsByDiameter[diameter][y]` shows how many white cells there are at the left at row `y`.
-- @param diameter {int} The diameter (width/height) of the cirzle
-- @returns circleRowsByDiameter[diameter]
local function getCircleRows(diameter)
   if circleRowsByDiameter[diameter] then
      return circleRowsByDiameter[diameter]
   end
   local circleLines = {}
   local radius = diameter / 2
   local radiusSquared = radius * radius
   local y = -radius + 0.5
   for i = 1, diameter do
      circleLines[#circleLines + 1] = (diameter - i + 1 > #circleLines) and circleLines[diameter - i + 1]
            or math.floor(radius - math.sqrt(radiusSquared - y * y) + 0.5)
      y = y + 1
   end
   circleRowsByDiameter[diameter] = circleLines
   return circleLines
end

--- Gets the points a circle with a specified size and coordinates, but only if they are contained within a canvas.
-- The canvas is assumed to be a rectangle with an upper left corner (1,1) and a lower right corner (width, height)
-- @param leftX {int}
-- @param topY {int}
-- @param size {int}
-- @param width {int}
-- @param height {int}
-- @returns {{x: int, y: int}[]} The points of the circle contained within the canvas
local function getCanvasCirclePoints(leftX, topY, size, width, height)
   local circlePoints = {}
   for y = 1, size do
      for x = circleRowsByDiameter[size][y] + 1, size - circleRowsByDiameter[size][y] do
         local pointX = leftX + x - 1
         local pointY = topY + y - 1
         -- Ignore points not in the canvas
         if pointX >= 1 and pointX <= width and pointY >= 1 and pointY <= height then
            circlePoints[#circlePoints + 1] = { x = pointX, y = pointY }
         end
      end
   end
   return circlePoints
end

--- Gets the points a circle with a specified size and coordinates would go through, EXCLUDING the cirlce itself, but
-- does not return them. Instead, calls a provided function with a set of points every time
-- @param initialLeftX {int}
-- @param initialTopY {int}
-- @param size {int}
-- @param path {{x: int, y: int}[]}
local function callForEachPointInPath(callback, initialLeftX, initialTopY, size, path)
   if not path or #path <= 1 then
      print((not path) or "The path is nil" or ("The path has only " .. #path .. " point(s)"))
      return
   end
   local leftX, topY = initialLeftX, initialTopY
   local rightX, bottomY = leftX + size - 1, topY + size - 1
   for i = 2, #path do
      local points = {}
      local dx = path[i].x - path[i - 1].x
      local dy = path[i].y - path[i - 1].y
      leftX, topY = leftX + dx, topY + dy
      rightX, bottomY = rightX + dx, bottomY + dy

      local startingY, targetY, incrementY
      if dx == 0 and dy > 0 then
         -- Down
         for x = 1, size do
            points[#points + 1] = { x = leftX + x - 1, y = bottomY - circleRowsByDiameter[size][x] }
         end
      elseif dx == 0 and dy < 0 then
         -- Up
         for x = 1, size do
            points[#points + 1] = { x = leftX + x - 1, y = topY + circleRowsByDiameter[size][x] }
         end
      elseif dx > 0 and dy == 0 then
         -- Right
         for y = 1, size do
            points[#points + 1] = { x = rightX - circleRowsByDiameter[size][y], y = topY + y - 1 }
         end
      elseif dx < 0 and dy == 0 then
         -- Left
         for y = 1, size do
            points[#points + 1] = { x = leftX + circleRowsByDiameter[size][y], y = topY + y - 1 }
         end
      else
         -- Both X and Y have changed
         -- Rest of the circle
         for y = 1, size do
            local y2 = y + dy
            local leftmostInRow = circleRowsByDiameter[size][y] + 1
            local rightmostInRow = size - circleRowsByDiameter[size][y]
            if y2 < 1 or y2 > size then
               -- All points in this row are surely worth drawing
               for x = leftmostInRow, rightmostInRow do
                  points[#points + 1] = { x = leftX + x - 1, y = topY + y - 1 }
               end
            else
               local minXToTryOnRightToLeft = 1
               for x = leftmostInRow, rightmostInRow do
                  minXToTryOnRightToLeft = x + 1
                  local x2 = x + dx
                  if x2 > circleRowsByDiameter[size][y2] and x2 <= size - circleRowsByDiameter[size][y2] then
                     break
                  end
                  points[#points + 1] = { x = leftX + x - 1, y = topY + y - 1 }
               end
               for x = rightmostInRow, minXToTryOnRightToLeft, -1 do
                  local x2 = x + dx
                  if x2 > circleRowsByDiameter[size][y2] and x2 <= size - circleRowsByDiameter[size][y2] then
                     break
                  end
                  points[#points + 1] = { x = leftX + x - 1, y = topY + y - 1 }
               end
            end
         end
      end
      callback(points)
   end
end

--- Set the canvas dimensions to new values
-- @param canvasWidth {int} The new width (number of tiles)
-- @param canvasHeight {int} The new height (number of tiles)
function TileControls:setCanvasDimensions(canvasWidth, canvasHeight)
   self.canvasWidth, self.canvasHeight = canvasWidth, canvasHeight
end

--- LOVE update handler
function TileControls:update()
   local mouseInfo = love.mouse.registerSolid(self, { isWholeScreen = true })
   self.invisible = not mouseInfo.isHovered
   if self.invisible or self.canvasWidth == nil or self.canvasHeight == nil then
      return
   end

   local mouseAbsoluteX, mouseAbsoluteY = self.navigator:screenToAbsolute(love.mouse.getX(), love.mouse.getY())
   local offset = (self.size - 1) / 2
   self.leftHoveredColumn = math.floor(mouseAbsoluteX / self.tileWidth - offset) + 1
   self.topHoveredRow = math.floor(mouseAbsoluteY / self.tileHeight - offset) + 1

   if mouseInfo.drag and (mouseInfo.drag.button == LEFT_MOUSE_BUTTON
         or mouseInfo.drag.button == RIGHT_MOUSE_BUTTON) then
      self.drawingWith = mouseInfo.drag.button

      if mouseInfo.dragStarted or self.lastMouseDownPosition == nil then
         self.drawProgressHandler(getCanvasCirclePoints(self.leftHoveredColumn, self.topHoveredRow, self.size,
            self.canvasWidth, self.canvasHeight), self.drawingWith)
      elseif not self.singular and (self.leftHoveredColumn ~= self.lastMouseDownPosition.x
            or self.topHoveredRow ~= self.lastMouseDownPosition.y) then

         local drawPath = mathUtils:getDiscreteLine(self.lastMouseDownPosition.x, self.lastMouseDownPosition.y,
            self.leftHoveredColumn, self.topHoveredRow)
         callForEachPointInPath(function(points) self.drawProgressHandler(points, self.drawingWith) end,
            self.lastMouseDownPosition.x, self.lastMouseDownPosition.y, self.size, drawPath)
      end

      self.drawDoneHandler()
      self.lastMouseDownPosition = { x = self.leftHoveredColumn, y = self.topHoveredRow }
   else
      self.drawingWith = nil
      self.lastMouseDownPosition = nil
   end
end

--- LOVE draw handler
function TileControls:draw()
   if self.invisible then
      return
   end

   local leftX = (self.leftHoveredColumn - 1) * self.tileWidth
   local topY = (self.topHoveredRow - 1) * self.tileHeight

   if self.size <= 3 then
      love.graphics.setColor(self.colour.r, self.colour.g, self.colour.b, 0.5)
      love.graphics.rectangle("fill", leftX, topY, self.tileWidth * self.size, self.tileHeight * self.size)
      love.graphics.setColor(self.colour.r, self.colour.g, self.colour.b, 1)
      love.graphics.rectangle("line", leftX, topY, self.tileWidth * self.size, self.tileHeight * self.size)
   else
      love.graphics.setColor(self.colour.r, self.colour.g, self.colour.b, 0.5)
      local circleLines = getCircleRows(self.size)
      local y = topY
      for i = 1, self.size do
         love.graphics.rectangle("fill", leftX + self.tileWidth * circleLines[i], y,
            self.tileWidth * (self.size - circleLines[i] * 2), self.tileHeight)
         y = y + self.tileHeight
      end
   end

   love.graphics.reset()
end