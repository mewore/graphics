require "controls/text-input"
require "controls/dialog"
require "controls/button"

PointEditor = {}
PointEditor.__index = PointEditor

local CARLITO_FONT_PATH = 'fonts/carlito.ttf'
local POINT_ID_FONT_SIZE = 14
local POINT_ID_FONT = love.graphics.newFont(CARLITO_FONT_PATH, POINT_ID_FONT_SIZE)

local POINT_PHANTOM_COLOUR = { r = 0.3, g = 0.3, b = 0.3, a = 0.7 }
local POINT_PHANTOM_OUTLINE_COLOUR = { r = 0, g = 0, b = 0, a = 0.7 }
local POINT_WITH_NO_ID_COLOUR = { r = 1, g = 0.3, b = 0.3, a = 1 }
local POINT_COLOUR = { r = 0.4, g = 0.6, b = 0.9, a = 1 }
local POINT_OUTLINE_COLOUR = { r = 0, g = 0, b = 0 }
local POINT_RADIUS = 10

local BOX_COLOUR = { r = 0, g = 0, b = 0, a = 0.8 }
local BOX_INACTIVE_COLOUR = { r = 0, g = 0, b = 0, a = 0.5 }
local BOX_PADDING = 1
local BOX_RADIUS = 3
local BOX_WIDTH = 100
local TEXT_INACTIVE = { r = 0.8, g = 0.8, b = 0.8 }
local TEXT_ACTIVE = { r = 1, g = 1, b = 0.1 }

local POINT_SELECTION_CURSOR = love.mouse.getSystemCursor("hand")
local POINT_DRAG_CURSOR = love.mouse.getSystemCursor("sizeall")
local POINT_CREATION_CURSOR = love.mouse.getSystemCursor("crosshair")
local LEFT_MOUSE_BUTTON = 1
local RIGHT_MOUSE_BUTTON = 2

local DRAG_START_DISTANCE = 5 -- [px]
local DRAG_START_DISTANCE_SQUARED = DRAG_START_DISTANCE * DRAG_START_DISTANCE -- [px ^ 2]
local ACTIVATION_DISTANCE = POINT_RADIUS -- [px]
local ACTIVATION_DISTANCE_SQUARED = ACTIVATION_DISTANCE * ACTIVATION_DISTANCE -- [px ^ 2]

--- A container and editor of points
-- @param navigator {Navigator} - The navigator instance used for the canvas which this point editor applies to
function PointEditor:create(navigator)
   local this = {
      points = {},
      navigator = navigator,
      pointIdText = {},
      dialog = nil,
      activeIndex = -1,
      pointDragInfo = nil,
      isDragging = false,
      hasBeenDragged = false,
      isSidebarHovered = false,
   }
   setmetatable(this, self)

   this:setPoints()

   return this
end

--- Change the points
-- @param newPoints {{x: number, y: number, id: string, description: string}}
function PointEditor:setPoints(newPoints)
   self.points = newPoints or {}

   for i = 1, #self.points do
      self.pointIdText[i] = love.graphics.newText(POINT_ID_FONT, self.points[i].id)
   end
end

local function getSquaredDistance(fromX, fromY, toX, toY)
   local dx = toX - fromX
   local dy = toY - fromY
   return dx * dx + dy * dy
end

--- LOVE update handler
function PointEditor:update()
   local mouseInfo = love.mouse.registerSolid(self, { isWholeScreen = true })
   if not mouseInfo.isHovered then
      self.activeIndex = -1
      return
   end

   if mouseInfo.dragStarted and self.activeIndex > -1 then
      local mouseAbsoluteX, mouseAbsoluteY = self.navigator:screenToAbsolute(mouseInfo.drag.fromX, mouseInfo.drag.fromY)
      self.pointDragInfo = {
         startAbsoluteX = mouseAbsoluteX,
         startAbsoluteY = mouseAbsoluteY,
      }
   end

   if mouseInfo.drag then
      if mouseInfo.drag.button == LEFT_MOUSE_BUTTON then
         if self.activeIndex > -1 then
            self.isDragging = mouseInfo.drag.maxSquaredDistance > DRAG_START_DISTANCE_SQUARED
            love.mouse.importantCursor = self.isDragging and POINT_DRAG_CURSOR or POINT_SELECTION_CURSOR
         else
            love.mouse.importantCursor = POINT_CREATION_CURSOR
         end
      elseif mouseInfo.drag.button == RIGHT_MOUSE_BUTTON and self.activeIndex > -1 then
         local mouseX, mouseY = love.mouse.getPosition()
         local pointX, pointY = self.navigator:absoluteToScreen(self.points[self.activeIndex].x, self.points[self.activeIndex].y)
         local distance = getSquaredDistance(mouseX, mouseY, pointX, pointY)
         love.mouse.importantCursor = (distance < ACTIVATION_DISTANCE_SQUARED) and POINT_SELECTION_CURSOR or nil
      end
   end

   if mouseInfo.dragConfirmed then
      local mouseAbsoluteX, mouseAbsoluteY = self.navigator:screenToAbsolute(love.mouse.getPosition())
      print(self.activeIndex, self.isDragging)
      if self.activeIndex > -1 then
         local activePoint = self.points[self.activeIndex]
         if self.isDragging then
            -- Move the active point to the current absolute mouse position
            local dx, dy = mouseAbsoluteX - self.pointDragInfo.startAbsoluteX, mouseAbsoluteY - self.pointDragInfo.startAbsoluteY
            activePoint.x, activePoint.y = activePoint.x + dx, activePoint.y + dy
            self.pointDragInfo = nil
         else
            if mouseInfo.dragConfirmed.button == LEFT_MOUSE_BUTTON then
               -- Edit the active point
               self.pointDragInfo = nil
               local idInput = TextInput:create(300, "ID", activePoint.id)
               local dataInput = TextInput:create(300, "Data (optional)", activePoint.data)
               local okButton = Button:create("OK", "solid", function()
                  activePoint.id = idInput.value
                  activePoint.data = dataInput.value
                  self.pointIdText[self.activeIndex] = love.graphics.newText(POINT_ID_FONT, activePoint.id)
                  viewStack:popView(self.dialog)
                  self.dialog = nil
               end)
               local cancelButton = Button:create("Cancel", nil, function()
                  viewStack:popView(self.dialog)
                  self.dialog = nil
               end)

               self.dialog = Dialog:create("Edit point", "What should the ID and info of the point be?",
                  { idInput, dataInput }, { cancelButton, okButton })
            elseif mouseInfo.dragConfirmed.button == RIGHT_MOUSE_BUTTON then
               local mouseX, mouseY = love.mouse.getPosition()
               local pointX, pointY = self.navigator:absoluteToScreen(activePoint.x, activePoint.y)
               local distance = getSquaredDistance(mouseX, mouseY, pointX, pointY)
               if distance < ACTIVATION_DISTANCE_SQUARED then
                  -- Remove the active point
                  local noButton = Button:create("No", nil, function()
                     viewStack:popView(self.dialog)
                     self.dialog = nil
                  end)
                  local yesButton = Button:create("Yes", "danger", function()
                     local lastIndex = #self.points
                     self.points[self.activeIndex] = self.points[lastIndex]
                     self.pointIdText[self.activeIndex] = self.pointIdText[lastIndex]
                     self.points[lastIndex] = nil
                     self.pointIdText[lastIndex] = nil
                     viewStack:popView(self.dialog)
                     self.dialog = nil
                  end)

                  self.dialog = Dialog:create("Delete point", "Are you sure you would like to delete point '" ..
                        self.points[self.activeIndex].id .. "'?", {}, { noButton, yesButton })
               end
            end
         end
      elseif mouseInfo.dragConfirmed.button == LEFT_MOUSE_BUTTON then
         -- Create point at the current absolute mouse position
         local newPoint = {
            x = mouseAbsoluteX,
            y = mouseAbsoluteY,
            id = "",
            data = "",
         }
         local idInput = TextInput:create(300, "ID", "")
         local dataInput = TextInput:create(300, "Data (optional)", "")
         local okButton = Button:create("OK", "solid", function()
            newPoint.id = idInput.value
            newPoint.data = dataInput.value
            self.points[#self.points + 1] = newPoint
            self.pointIdText[#self.pointIdText + 1] = love.graphics.newText(POINT_ID_FONT, newPoint.id)
            viewStack:popView(self.dialog)
            self.dialog = nil
         end)
         local cancelButton = Button:create("Cancel", nil, function()
            viewStack:popView(self.dialog)
            self.dialog = nil
         end)

         self.dialog = Dialog:create("Create point", "What should the ID and info of the point be?",
            { idInput, dataInput }, { cancelButton, okButton })
      end
   end

   if not mouseInfo.drag then
      local mouseX, mouseY = love.mouse.getPosition()
      local bestDistance = ACTIVATION_DISTANCE_SQUARED
      self.activeIndex = -1
      for index, point in ipairs(self.points) do
         local pointX, pointY = self.navigator:absoluteToScreen(point.x, point.y)
         local distance = getSquaredDistance(mouseX, mouseY, pointX, pointY)
         if distance < bestDistance then
            self.activeIndex = index
            bestDistance = distance
         end
      end
      love.mouse.cursor = self.activeIndex > -1 and POINT_SELECTION_CURSOR or POINT_CREATION_CURSOR
   end

   self.isDragging = self.isDragging and mouseInfo.drag ~= nil
end

local function setColour(colour)
   if not colour then
      return false
   end
   love.graphics.setColor(colour.r, colour.g, colour.b, colour.a == nil and 1 or colour.a)
   return true
end

--- LOVE draw handler
function PointEditor:draw()
   local mouseX, mouseY = love.mouse.getPosition()

   local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
   for index, point in ipairs(self.points) do
      local originalPointX, originalPointY = self.navigator:absoluteToScreen(point.x, point.y)
      local pointX, pointY = originalPointX, originalPointY
      local isDraggingCurrentPoint = self.isDragging and self.activeIndex == index
      if isDraggingCurrentPoint then
         local mouseAbsoluteX, mouseAbsoluteY = self.navigator:screenToAbsolute(mouseX, mouseY)
         local dx, dy = mouseAbsoluteX - self.pointDragInfo.startAbsoluteX, mouseAbsoluteY - self.pointDragInfo.startAbsoluteY
         pointX, pointY = self.navigator:absoluteToScreen(point.x + dx, point.y + dy)
      end

      if not (pointX + BOX_WIDTH < 0 or pointX > screenWidth or pointY + 1000 < 0 or pointY > screenHeight) then
         local topY = pointY + POINT_RADIUS + 3
         local textWidth, textHeight = self.pointIdText[index]:getDimensions()
         local boxWidth, boxHeight = textWidth + 2 * BOX_PADDING, textHeight + 2 * BOX_PADDING
         setColour(self.activeIndex == index and BOX_COLOUR or BOX_INACTIVE_COLOUR)
         love.graphics.rectangle("fill", math.floor(pointX - boxWidth / 2), topY, boxWidth, boxHeight,
            BOX_RADIUS, BOX_RADIUS)

         if isDraggingCurrentPoint then
            setColour(POINT_PHANTOM_COLOUR)
            love.graphics.circle("fill", originalPointX, originalPointY, POINT_RADIUS)
            setColour(POINT_PHANTOM_OUTLINE_COLOUR)
            love.graphics.circle("line", originalPointX, originalPointY, POINT_RADIUS)
         end

         setColour(#point.id > 0 and POINT_COLOUR or POINT_WITH_NO_ID_COLOUR)
         love.graphics.circle("fill", pointX, pointY, POINT_RADIUS)
         setColour(POINT_OUTLINE_COLOUR)
         love.graphics.circle("line", pointX, pointY, POINT_RADIUS)

         setColour(self.activeIndex == index and TEXT_ACTIVE or TEXT_INACTIVE)
         love.graphics.draw(self.pointIdText[index], pointX - math.floor(self.pointIdText[index]:getWidth() / 2), topY + BOX_PADDING)
      end
   end
end