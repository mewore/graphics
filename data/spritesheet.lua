Spritesheet = {}
Spritesheet.__index = Spritesheet

--- Pad every tile of the image data with a 1-pixel border that is the same as the pixels at the edges. This is meant
-- to resolve the issue of pixels bleeding into tiles from the ones surrounding them when rendering quads with
-- non-integer coordinates.
-- @param imageData {{@link https://love2d.org/wiki/ImageData | ImageData}} - The image data to debleedify
-- @param tileWidth {int} - The height (in pixels) of each sub-image
-- @param tileHeight {int} - The width (in pixels) of each sub-image
-- @param rows {int} - The number of rows
-- @param columns {int} - The number of columns
local function debleedify(imageData, tileWidth, tileHeight, rows, columns)
   local result = love.image.newImageData(imageData:getWidth() + columns * 2, imageData:getHeight() + rows * 2)

   local stepX, stepY = tileWidth + 2, tileHeight + 2

   local x, sourceX
   local y, sourceY = 1, 0
   for i = 1, rows do
      x = 1
      sourceX = 0
      for j = 1, columns do
         -- Center
         result:paste(imageData, x, y, sourceX, sourceY, tileWidth, tileHeight)
         -- Top
         result:paste(imageData, x, y - 1, sourceX, sourceY, tileWidth, 1)
         -- Bottom
         result:paste(imageData, x, y + tileHeight, sourceX, sourceY + tileHeight - 1, tileWidth, 1)
         -- Left
         result:paste(imageData, x - 1, y, sourceX, sourceY, 1, tileHeight)
         -- Right
         result:paste(imageData, x + tileWidth, y, sourceX + tileWidth - 1, sourceY, 1, tileHeight)

         x = x + stepX
         sourceX = sourceX + tileWidth
      end
      y = y + stepY
      sourceY = sourceY + tileHeight
   end

   return result
end

--- A wrapper for image data that contains many smaller images. The dimensions of the spritesheet must be divisible by
-- the dimensions of the smaller images!
-- @param data {{@link https://love2d.org/wiki/ImageData | ImageData}} - The image data to construct the spritesheet
-- from
-- @param tileWidth {int} - The width (in pixels) of each sub-image
-- @param tileHeight {int} - The height (in pixels) of each sub-image
-- @param name {string} - The name of the spritesheet
-- @param shouldDebleedify {boolean} - Whether to add a 1-pixel border to each pixel to prevent bleeding when using
-- quads
function Spritesheet:create(data, tileWidth, tileHeight, name, shouldDebleedify)
   if data:getWidth() % tileWidth ~= 0 or data:getHeight() % tileHeight ~= 0 then
      error("Spritesheet '" .. name .. "' with dimensions (" .. data:getWidth() .. ", " .. data:getHeight() ..
            ") cannot be split evenly into tiles with dimensions (" .. tileWidth .. ", " .. tileHeight .. ")")
   end

   local rows = data:getHeight() / tileWidth
   local columns = data:getWidth() / tileWidth
   local originalImage = love.graphics.newImage(data)
   local newData = shouldDebleedify and debleedify(data, tileWidth, tileHeight, rows, columns) or data
   local newImage = shouldDebleedify and love.graphics.newImage(newData) or originalImage

   local this = {
      originalData = data,
      originalImage = originalImage,
      data = newData,
      image = newImage,
      quads = nil,
      debleedified = shouldDebleedify,
      tileWidth = tileWidth,
      tileHeight = tileHeight,
      rows = rows,
      columns = columns,
   }
   setmetatable(this, self)

   return this
end

--- Divide the spritesheet into quads.
-- @returns {LOVE.Quad[]} - https://love2d.org/wiki/Quad
function Spritesheet:getQuads()
   if self.quads ~= nil then
      return self.quads
   end
   local quads = {}
   local totalWidth, totalHeight = self.data:getDimensions()

   local padding = self.debleedified and 1 or 0
   local stepX, stepY = self.tileWidth + padding * 2, self.tileHeight + padding * 2

   local x
   local y = padding
   for i = 1, self.rows do
      x = padding
      for j = 1, self.columns do
         quads[#quads + 1] = love.graphics.newQuad(x, y, self.tileWidth, self.tileHeight, totalWidth, totalHeight)
         x = x + stepX
      end
      y = y + stepY
   end

   self.quads = quads
   return quads
end
