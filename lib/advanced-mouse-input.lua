--- Advanced Mouse Input
-- @version 1.0.5
-- @url https://raw.githubusercontent.com/mewore/ami/master/advanced-mouse-input.lua
-- @description A "wrapper" of the built-in LOVE mouse input handlers that allows for easier complex input handling.

AdvancedMouseInput = {}
AdvancedMouseInput.__index = AdvancedMouseInput

local DEBUG_TEXT_HEIGHT = 16
local NORMAL_CURSOR = love.mouse.getSystemCursor("arrow")

--- A view stack that handles the order in which to order the views and uptates only the top view
function AdvancedMouseInput:create()
   local this = {}
   setmetatable(this, self)
   return this
end

local mouse = love.mouse
mouse.wheel = { dx = 0, dy = 0 }
mouse.clicksPerButton = {}
local hasDrag = false
local updateCounter = 0

--- LOVE mouse wheel scroll handler
-- @param dx {int} - The horizontal movement of the wheel scroll
-- @param dy {int} - The vertical movement of the wheel scroll (positive ~ forwards, negative ~ backwards)
function love.wheelmoved(dx, dy)
   if mouse.horizontalScrollButtons then
      for _, button in ipairs(mouse.horizontalScrollButtons) do
         if love.keyboard.isDown(button) then
            dx = dx + dy
            dy = 0
            break
         end
      end
   end
   mouse.wheel.dx, mouse.wheel.dy = mouse.wheel.dx + dx, mouse.wheel.dy + dy
end

--- LOVE mouse click handler
-- @param x {int} - Mouse x position, in pixels
-- @param y {int} - Mouse y position, in pixels
-- @param button {int} - The button index that was pressed. 1 is the primary mouse button,
-- 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent
-- @param isTouch {boolean} - True if the mouse button press originated from a touchscreen touch-press
-- @param presses {int} - The number of presses in a short time frame and small area, used to simulate double, triple
-- clicks
function love.mousepressed(x, y, button, isTouch, presses)
   mouse.clicksPerButton[button] = mouse.clicksPerButton[button] or {}
   mouse.clicksPerButton[button][#mouse.clicksPerButton[button] + 1] = {
      x = x,
      y = y,
      isTouch = isTouch,
      presses = presses,
   }
end

local mouseHoverIsBlocked = false
local hoveredRectangleToDraw
local dragToDraw

local function isInside(x, y, leftX, topY, rightX, bottomY)
   return (leftX == nil or x >= leftX)
         and (rightX == nil or x <= rightX)
         and (topY == nil or y >= topY)
         and (bottomY == nil or y <= bottomY)
end

--- Whether the mouse (judging by its current position) is inside a rectangle
-- @param leftX {int | nil} - The leftmost (lowest) X of the rectangle
-- @param topY {int | nil} - The topmost (lowest) Y of the rectangle
-- @param rightX {int | nil} - The rightmost (highest) X of the rectangle
-- @param bottomY {int | nil} - The bottom-most (highest) Y of the rectangle
local function mouseIsInside(leftX, topY, rightX, bottomY)
   return not mouseHoverIsBlocked and isInside(mouse.getX(), mouse.getY(), leftX, topY, rightX, bottomY)
end

--- Returns the elements of an array that meet a condition and removes them from the original array. Retains its order.
-- @param array {any[]} - The array to extract elements from.
-- @param predicate {function} - The filtering function that evaluates whether an element should be taken.
-- @return The resulting array, or nil if no elements have been found.
local function extractFrom(array, predicate)
   local extractedElements = 0
   local result
   local size = #array

   for i = 1, size do
      local currentElement = array[i]
      if predicate(currentElement) then
         extractedElements = extractedElements + 1
         result = result or {}
         result[#result + 1] = currentElement
         array[i] = nil
      else
         if extractedElements > 0 then
            array[i - extractedElements] = currentElement
            array[i] = nil
         end
      end
   end

   return result
end

local mouseInfoPerSolid = {}

--- Considers a rectangle solid.
function mouse.registerSolid(object, options)
   if mouseInfoPerSolid[tostring(object)] then return mouseInfoPerSolid[tostring(object)] end

   local leftX, topY, rightX, bottomY
   if options and options.isWholeScreen then
      leftX, topY, rightX, bottomY = nil, nil, nil, nil
   elseif options and options.shape then
      local shape = options.shape
      leftX, topY, rightX, bottomY = shape.leftX, shape.topY, shape.rightX, shape.bottomY
   else
      leftX, topY, rightX, bottomY = object.x, object.y, object.x + object.width, object.y + object.height
   end

   local isHovered = mouseIsInside(leftX, topY, rightX, bottomY)
   if isHovered then
      mouseHoverIsBlocked = true
      hoveredRectangleToDraw = { leftX = leftX, topY = topY, rightX = rightX, bottomY = bottomY }
   end

   local clickCount = 0
   local clicksPerButtonInObject = {}
   for button, clicks in pairs(mouse.clicksPerButton) do
      clicksPerButtonInObject[button] = extractFrom(clicks, function(click)
         return isInside(click.x, click.y, leftX, topY, rightX, bottomY)
      end)
      if clicksPerButtonInObject[button] ~= nil then
         clickCount = clickCount + #clicksPerButtonInObject[button]
      end
   end

   local result = {
      isHovered = isHovered,
      clicksPerButton = clicksPerButtonInObject,
      clickCount = clickCount,
   }

   local drag = object.__mouseDrag
   if drag ~= nil then
      local hasClickedAnotherButton = false
      for button, _ in pairs(clicksPerButtonInObject) do
         if button ~= drag.button then
            hasClickedAnotherButton = true
         end
         break
      end

      if not love.mouse.isDown(drag.button) then
         -- Confirm
         result.dragConfirmed = drag
         drag = nil
      elseif hasDrag or hasClickedAnotherButton or drag.lastUpdateCounter < updateCounter - 1 then
         -- Cancel
         result.dragCancelled = drag
         drag = nil
      end
   else
      -- Start
      if not hasDrag then
         for button, clicks in pairs(clicksPerButtonInObject) do
            drag = {
               button = button,
               fromX = clicks[1].x,
               fromY = clicks[1].y,
               objectXOnDragStart = leftX,
               objectYOnDragStart = topY,
               maxDx = 0,
               maxDy = 0,
               maxSquaredDistance = 0,
            }
            result.dragStarted = drag
            break
         end
      end
   end

   hasDrag = hasDrag or (drag ~= nil)

   result.drag = drag
   object.__mouseDrag = drag
   result.dragFinished = result.dragCancelled or result.dragConfirmed

   if drag ~= nil then
      drag.toX, drag.toY = love.mouse.getPosition()
      drag.lastUpdateCounter = updateCounter
      drag.dx = drag.toX - drag.fromX
      drag.dy = drag.toY - drag.fromY
      drag.squaredDistance = drag.dx * drag.dx + drag.dy * drag.dy
      drag.maxDx = math.max(drag.maxDx, math.abs(drag.dx))
      drag.maxDy = math.max(drag.maxDy, math.abs(drag.dy))
      drag.maxSquaredDistance = math.max(drag.maxSquaredDistance, math.abs(drag.squaredDistance))
      dragToDraw = drag
   end

   mouseInfoPerSolid[tostring(object)] = result
   return result
end

--- Must be called at the very beginning of the LOVE update handler
function AdvancedMouseInput:beforeUpdate()
   mouseInfoPerSolid = {}
   dragToDraw = nil
   updateCounter = updateCounter + 1
   mouseHoverIsBlocked = false
   mouse.cursor = NORMAL_CURSOR
   mouse.importantCursor = nil
end

--- Must be called at the very end of the LOVE update handler
function AdvancedMouseInput:afterUpdate()
   mouse.wheel.dx, mouse.wheel.dy = 0, 0
   mouse.clicksPerButton = {}
   mouse.setCursor(mouse.importantCursor or mouse.cursor)
   hasDrag = false
end

--- LOVE draw handler (used only for debugging purposes)
function AdvancedMouseInput:draw()
   if hoveredRectangleToDraw then
      love.graphics.setColor(0, 1, 0.5, 0.8)
      local rectX, rectY = hoveredRectangleToDraw.leftX, hoveredRectangleToDraw.topY
      rectX, rectY = rectX ~= nil and rectX or 1, rectY ~= nil and rectY or 1
      local rectRightX, rectBottomY = hoveredRectangleToDraw.rightX, hoveredRectangleToDraw.bottomY
      rectRightX = rectRightX == nil and love.graphics.getWidth() - 1 or rectRightX
      rectBottomY = rectBottomY == nil and love.graphics.getHeight() - 1 or rectBottomY
      local rectWidth, rectHeight = rectRightX - rectX, rectBottomY - rectY

      love.graphics.rectangle("line", rectX, rectY, rectWidth, rectHeight)
      love.graphics.setColor(0, 0.3, 0.1, 1)
      love.graphics.print("Hovered", rectX, math.max(rectY - DEBUG_TEXT_HEIGHT, 0))

      hoveredRectangleToDraw = nil
   end

   if dragToDraw then
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.line(dragToDraw.fromX, dragToDraw.fromY, dragToDraw.toX, dragToDraw.toY)
   end

   love.graphics.reset()
end