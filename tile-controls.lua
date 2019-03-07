require "math-utils"

TileControls = {}
TileControls.__index = TileControls

local mathUtils = MathUtils:create()

--- Tile controls allow the user to provide tile-based input (i.e. clicking in a grid). Basically a pencil.
-- @param colour {r: number, g: number, b: number} - The colour of the tile the user has hovered over
-- @param tileWidth {number} - The width of each tile, in pixels
-- @param tileHeight {number} - The height of each tile, in pixels
function TileControls:create(colour, tileWidth, tileHeight, canvasWidth, canvasHeight, navigator)
   local this = {
      colour = colour,
      tileWidth = tileWidth,
      tileHeight = tileHeight,
      canvasWidth = canvasWidth,
      canvasHeight = canvasHeight,
      drawProgressCallback = nil,
      drawDoneCallback = nil,
      leftHoveredColumn = 0,
      topHoveredRow = 0,
      lastMouseDownPosition = nil,
      navigator = navigator,
      size = 1,
   }
   setmetatable(this, self)

   return this
end

--- Add a handler for when the mouse is held down
-- @param callback {function}
function TileControls:onDrawProgress(callback)
   self.drawProgressCallback = callback
end

--- Add a handler for when the mouse is held down
-- @param callback {function}
function TileControls:onDrawDone(callback)
   self.drawDoneCallback = callback
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

--- Get the sign of x. If x is positive, returns +1, if x is 0, returns 0, if x is negative, returns -1.
-- @param x {number}
-- @returns {number} +1, 0 or -1
local function sign(x)
   return x > 0 and 1 or (x == 0 and 0 or -1)
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
-- @param width {int}
-- @param height {int}
local function callForEachPointInPath(callback, initialLeftX, initialTopY, size, path, width, height)
   if not path or #path <= 1 then
      print((not path) or "The path is nil" or ("The path has only " .. #path .. " point(s)"))
      return
   end
   local pointMap = {}
   for y = 1, size do
      pointMap[y] = {}
      local lastRowEmpty = circleRowsByDiameter[size][y]
      for x = 1, lastRowEmpty do
         pointMap[y][x] = false
      end
      local lastRowFull = size - lastRowEmpty
      for x = lastRowEmpty + 1, lastRowFull do
         pointMap[y][x] = true
      end
      for x = lastRowFull + 1, size do
         pointMap[y][x] = false
      end
   end
   -- Either X/Y or both X and Y will change at a given point. If totalDx > totalDy, then if one changes it's surely X
   -- and if totalDx < totalDy, then if one changes it's Y. And, if totalDx == totalDy, then only both will change.
   local offsets = { {}, {} } -- offsets[1] - one coordinate has changed. offsets[2] - both coordinates have changed
   local totalDx = path[#path].x - path[1].x
   local totalDy = path[#path].y - path[1].y
   if math.abs(totalDx) > math.abs(totalDy) then
      -- X is dominant
      for y = 1, size do
         offsets[1][#offsets[1] + 1] = {
            x = totalDx < 0 and (circleRowsByDiameter[size][y]) or (size - circleRowsByDiameter[size][y] - 1),
            y = y - 1,
         }
      end
   elseif math.abs(totalDy) > math.abs(totalDx) then
      -- Y is dominant
      for x = 1, size do
         offsets[1][#offsets[1] + 1] = {
            x = x - 1,
            y = totalDy < 0 and (circleRowsByDiameter[size][x]) or (size - circleRowsByDiameter[size][x] - 1),
         }
      end
   end
   if totalDx ~= 0 and totalDy ~= 0 then
      for y = 1, size do
         for x = 1, size do
            local nextY = y + sign(totalDy)
            local nextX = x + sign(totalDx)
            if nextY < 1 or nextY > size or nextX < 1 or nextX > size or not pointMap[nextY][nextX] then
               offsets[2][#offsets[2] + 1] = { x = x - 1, y = y - 1 }
            end
         end
      end
   end
   -- Finally calculate the points
   local leftX, topY = initialLeftX, initialTopY
   for i = 2, #path do
      local points = {}
      local dx = path[i].x - path[i - 1].x
      local dy = path[i].y - path[i - 1].y
      leftX, topY = leftX + dx, topY + dy
      local currentOffsets = offsets[(dx ~= 0 and 1 or 0) + (dy ~= 0 and 1 or 0)]
      for i = 1, #currentOffsets do
         local x = leftX + currentOffsets[i].x
         local y = topY + currentOffsets[i].y
         -- Ignore points not in the canvas
         if x >= 1 and x <= width and y >= 1 and y <= height then
            points[#points + 1] = { x = x, y = y }
         end
      end
      callback(points)
   end
end

--- LOVE update callback
function TileControls:update()
   local mouseAbsoluteX, mouseAbsoluteY = self.navigator:screenToAbsolute(love.mouse.getX(), love.mouse.getY())
   local offset = (self.size - 1) / 2
   self.leftHoveredColumn = math.floor(mouseAbsoluteX / self.tileWidth - offset) + 1
   self.topHoveredRow = math.floor(mouseAbsoluteY / self.tileHeight - offset) + 1

   local mouseIsDown = false
   for mouseButton = 1, 2 do
      if self.drawProgressCallback ~= nil and love.mouse.isDown(mouseButton) then
         if self.lastMouseDownPosition == nil then
            self.drawProgressCallback(getCanvasCirclePoints(self.leftHoveredColumn, self.topHoveredRow, self.size,
               self.canvasWidth, self.canvasHeight), mouseButton)
         elseif self.leftHoveredColumn ~= self.lastMouseDownPosition.x
               or self.topHoveredRow ~= self.lastMouseDownPosition.y then
            local drawPath = mathUtils:getDiscreteLine(self.lastMouseDownPosition.x, self.lastMouseDownPosition.y,
               self.leftHoveredColumn, self.topHoveredRow)
            callForEachPointInPath(function(points) self.drawProgressCallback(points, mouseButton) end,
               self.lastMouseDownPosition.x, self.lastMouseDownPosition.y, self.size, drawPath,
               self.canvasWidth, self.canvasHeight)
         end

         self.drawDoneCallback()
         mouseIsDown = true
      end
   end

   if mouseIsDown then
      self.lastMouseDownPosition = { x = self.leftHoveredColumn, y = self.topHoveredRow }
   else
      self.lastMouseDownPosition = nil
   end
end

--- LOVE draw callback
function TileControls:draw()
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