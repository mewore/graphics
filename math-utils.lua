MathUtils = {}
MathUtils.__index = MathUtils

--- Utilities for math-related/algorithmic operations
function MathUtils:create()
   local this = {}
   setmetatable(this, self)

   return this
end

--- Get the path from (fromX, fromY) to (toX, toY) that would result in a line.
-- @param fromX {int} - The X coordinate of the first point
-- @param fromY {int} - The Y coordinate of the first point
-- @param toX {int} - The X coordinate of the second point
-- @param toY {int} - The Y coordinate of the second point
function MathUtils:getDiscreteLine(fromX, fromY, toX, toY)
   local dx = math.abs(toX - fromX)
   local dy = math.abs(toY - fromY)

   local reverse = dx < dy
   if reverse then
      fromX, fromY = fromY, fromX
      toX, toY = toY, toX
      dx, dy = dy, dx
   end

   local incUp = -2 * dx + 2 * dy
   local incDown = 2 * dy

   local incX = (fromX <= toX) and 1 or -1
   local incY = (fromY <= toY) and 1 or -1

   local d = -dx + 2 * dy

   local x = fromX
   local y = fromY

   local n = 0
   local points = { }

   for i = 0, dx do
      n = n + 1
      points[n] = reverse and { x = y, y = x } or { x = x, y = y }
      x = x + incX
      if d > 0 then
         y = y + incY
         d = d + incUp
      else
         d = d + incDown
      end
   end

   return points
end