
local helper = require 'helpers'

local DELAY = 2000 -- ms between each type for demonstration purpose

-- Parameters
local BLUE = {59, 156, 208}
local ORANGE = {242, 148, 0}
local RED = {200, 0, 0}
local MM_TO_PROCESS = 10 --10mm slices

-- Create the views
local v2D = View.create()
local v3D = View.create('Viewer3D1')

local function viewHeightMap()
  -- Load the data
  local data = Object.load('resources/image_34.json')
  local heightMap = data[1]

  -- Extract the properties of the heightMap
  local _, pixelSizeY = Image.getPixelSize(heightMap)
  local _, heightMapH = Image.getSize(heightMap)
  local stepsize = math.ceil(MM_TO_PROCESS / pixelSizeY)

  local deco3D = View.ImageDecoration.create()
  deco3D:setRange(heightMap:getMin(), heightMap:getMax() / 1.01)

  -- Visualize the heightMap
  v3D:clear()
  v3D:addHeightmap(heightMap, deco3D)
  v3D:present()

  -------------------------------------------------
  -- Aggregate a number of profiles together ------
  -------------------------------------------------

  local profilesToAggregate = {}
  for j = 0, heightMapH - 1, stepsize do
    profilesToAggregate[#profilesToAggregate + 1] = heightMap:extractRowProfile(j)
  end
  local frameProfile = Profile.aggregate(profilesToAggregate, 'MEAN')

  -------------------------------------------------
  -- Fix missing data -----------------------------
  -------------------------------------------------
  frameProfile = frameProfile:blur(7)
  frameProfile = frameProfile:median(3)
  frameProfile:setValidFlagsEnabled(false)

  v2D:clear()
  local grDec = helper.getProfileDeco(BLUE)
  local profileID = v2D:addProfile(frameProfile, grDec)
  v2D:addText('Profile', helper.getTextDeco(20, 65, 6), nil, profileID)
  v2D:present()

  Script.sleep(DELAY)

  --------------------------------------------------
  -- Get the two highest points ------------------
  -------------------------------------------------
  -- Get max values from the mean profile

  local maxima = frameProfile:findLocalExtrema('MAX', 201)
  local max1 = frameProfile:getValue(maxima[1])
  local max2 = frameProfile:getValue(maxima[2])
  local min = frameProfile:getMin()

  local zero = frameProfile:getCoordinate(0)
  local zeroX = zero:getX()
  local trans = Transform.createTranslation2D(-zeroX, 0)

  -- Get the coordinates for max and min
  local coord = frameProfile:getCoordinate(maxima[1])
  local coord2 = frameProfile:getCoordinate(maxima[2])

  -- Calculate the heights

  local height1 = max1 - min
  local height2 = max2 - min

  -- Create points and lines for max, min, distance and height
  local maxPoint = Point.transform(Point.create(coord:getX(), max1), trans)
  local maxPoint2 = Point.transform(Point.create(coord2:getX(), max2), trans)
  local intersectionPoint = Point.transform(Point.create(coord:getX(), max2), trans)
  local minPoint1 = Point.transform(Point.create(coord:getX(), min), trans)
  local minPoint2 = Point.transform(Point.create(coord2:getX(), min), trans)

  -- Find intersection and measuring angle
  local hypoLine = Shape.createLineSegment(maxPoint, maxPoint2)
  local cathLine = Shape.createLineSegment(maxPoint2, intersectionPoint)
  local height1Line = Shape.createLineSegment(maxPoint, minPoint1)
  local height2Line = Shape.createLineSegment(maxPoint2, minPoint2)
  local angle = cathLine:getIntersectionAngle(hypoLine)

  -- Visualization
  v2D:clear()
  grDec:setTitle('Max points')
  v2D:addProfile(frameProfile, grDec)
  v2D:addShape(maxPoint, helper.getDeco(ORANGE, nil, 2))
  v2D:addShape(maxPoint2, helper.getDeco(ORANGE, nil, 2))
  v2D:present()
  Script.sleep(DELAY)

  v2D:clear()
  grDec:setTitle('Max points and heights')
  v2D:addProfile(frameProfile, grDec)
  v2D:addShape(maxPoint, helper.getDeco(ORANGE, nil, 2))
  v2D:addShape(maxPoint2, helper.getDeco(ORANGE, nil, 2))
  v2D:addShape(height1Line, helper.getDeco(RED, 0.5))
  v2D:addShape(height2Line, helper.getDeco(RED, 0.5))
  v2D:addShape(minPoint1, helper.getDeco(ORANGE, nil, 2))
  v2D:addShape(minPoint2, helper.getDeco(ORANGE, nil, 2))
  v2D:addText("height= "..helper.round(height1).." mm", helper.getTextDeco(maxPoint:getX()+2, maxPoint:getY(), 3))
  v2D:addText("height= "..helper.round(height2).." mm", helper.getTextDeco(maxPoint2:getX()+2, maxPoint2:getY(), 3))
  v2D:present()
  Script.sleep(DELAY)

  v2D:clear()
  grDec:setTitle('Angle= '..helper.round(angle)..' rad')
  v2D:addProfile(frameProfile, grDec)
  v2D:addShape(hypoLine, helper.getDeco(RED, 0.5))
  v2D:addShape(cathLine, helper.getDeco(RED, 0.5))
  v2D:present()
  Script.sleep(DELAY)
  print('App finished.')
end
Script.register('Engine.OnStarted', viewHeightMap)
