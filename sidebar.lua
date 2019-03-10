Sidebar = {}
Sidebar.__index = Sidebar

local WIDTH = 100
local BACKGROUND_OPACITY = 0.9
local BACKGROUND_OPACITY_HOVER = 1
local VALUE = 0.2
local OPACITY_DIFFERENCE_HALVING_PERIOD = 0.1 -- How long until the opacity reaches 0.5, then 0.75, 0.875, etc. to its desired value [s]
local PADDING_TOP = 10

--- A controller that keeps track of an X and Y offset as well as a zoom ratio
function Sidebar:create(controls)
   local y = PADDING_TOP
   for i = 1, #controls do
      controls[i].y = y
      controls[i].x = math.floor((WIDTH - controls[i].width) / 2)
      y = y + controls[i].height
   end

   local this = {
      controls = controls,
      isOpaque = false,
      opacity = BACKGROUND_OPACITY,
   }
   setmetatable(this, self)

   return this
end

function Sidebar:isHovered()
   return love.mouse.getX() < WIDTH
end

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function Sidebar:update(dt)
   for i = 1, #self.controls do
      self.controls[i]:update(dt)
   end
   local targetOpacity = self.isOpaque and BACKGROUND_OPACITY_HOVER or BACKGROUND_OPACITY
   local opacityDifference = targetOpacity - self.opacity
   opacityDifference = (math.abs(opacityDifference) > 0.001)
         and opacityDifference * math.pow(0.5, dt / OPACITY_DIFFERENCE_HALVING_PERIOD)
         or 0
   self.opacity = targetOpacity - opacityDifference
end

--- LOVE draw handler
function Sidebar:draw()
   love.graphics.setColor(VALUE, VALUE, VALUE, self.opacity)
   love.graphics.rectangle("fill", 0, 0, WIDTH, love.graphics.getHeight())
   love.graphics.reset()

   for i = 1, #self.controls do
      self.controls[i]:draw()
   end
end