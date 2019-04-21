Sidebar = {}
Sidebar.__index = Sidebar

local WIDTH = 100
local BACKGROUND_OPACITY = 0.9
local BACKGROUND_OPACITY_HOVER = 1
local VALUE = 0.2
local OPACITY_DIFFERENCE_HALVING_PERIOD = 0.1 -- How long until the opacity reaches 0.5, then 0.75, 0.875, etc. to its desired value [s]
local PADDING_TOP = 10

local MIN_MARGIN = 5

--- A controller that keeps track of an X and Y offset as well as a zoom ratio
function Sidebar:create(controls, width)
   width = width or WIDTH

   local y = PADDING_TOP
   for i = 1, #controls do
      controls[i]:setPosition(0, y)
      local _, controlHeight = controls[i]:getSize()
      controls[i]:setSize(width, controlHeight)
      if i < #controls then
         y = y + controlHeight + math.max(controls[i].marginBottom or 0, controls[i + 1].marginTop or 0, MIN_MARGIN)
      end
   end

   local this = {
      width = width,
      controls = controls,
      isActive = false,
      opacity = BACKGROUND_OPACITY,
   }
   setmetatable(this, self)

   return this
end

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function Sidebar:update(dt)
   local isOpaque = false
   if self.isActive then
      for i = 1, #self.controls do
         self.controls[i]:update(dt)
         isOpaque = isOpaque or self.controls[i].isActive
      end

      local mouseInfo = love.mouse.registerSolid(self, { shape = { rightX = self.width } })
      isOpaque = isOpaque or mouseInfo.isHovered
   end

   local targetOpacity = isOpaque and BACKGROUND_OPACITY_HOVER or BACKGROUND_OPACITY
   local opacityDifference = targetOpacity - self.opacity
   opacityDifference = (math.abs(opacityDifference) > 0.001)
         and opacityDifference * math.pow(0.5, dt / OPACITY_DIFFERENCE_HALVING_PERIOD)
         or 0
   self.opacity = targetOpacity - opacityDifference
end

--- LOVE draw handler
function Sidebar:draw()
   love.graphics.setColor(VALUE, VALUE, VALUE, self.opacity)
   love.graphics.rectangle("fill", 0, 0, self.width, love.graphics.getHeight())
   love.graphics.reset()

   for i = 1, #self.controls do
      self.controls[i]:draw()
   end
end