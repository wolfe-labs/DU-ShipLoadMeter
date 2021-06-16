Debug = false --export: Enables debugging to logs
Target_Gravity = 1.0 --export: The target gravity for all calculations (1.0 = Earth and Alioth)
Target_ThrustAtmo = 1.0 --export: The minimum "g" value you want for atmo thrust
Target_ThrustSpace = 2.0 --export: The minimum "g" value you want for space thrust
Target_LiftLow = 1.4 --export: The minimum "g" value you want for low lift (vertical boosters and hover)
Target_LiftHigh = 2.0 --export: The minimum "g" value you want for high lift (wings and vertical engines)
Target_BrakeAtmo = 3.0 --export: The minimum "g" value you want for space brakes
Target_BrakeSpace = 3.0 --export: The minimum "g" value you want for atmo brakes
CustomBackground = false --export: Enables custom background image
CustomBackgroundUrl = "none" --export: The custom background image of the screen

-- The default background of the screen
backgroundImage = 'assets.prod.novaquark.com/113304/9b9b7884-5f8e-4579-900e-a1ccaf8db628.png'
if CustomBackground then
  backgroundImage = CustomBackgroundUrl
end

-- Gets the airfoils listing
local Airfoils = require('airfoils')
local currentAirfoils = {}

-- Gets a list of all linked screens
screens = library.getLinksByClass('ScreenUnit')

-- Gets a list of all emergency LEDs
leds = library.getLinksByClass('LightUnit')

local function getShipElementsMass ()
  local elementIds = core.getElementIdList()
  local massElements = 0
  local massContainers = 0
  local airfoils = {
    vertical = {
      lift = 0,
      elements = {},
    },
    lateral = {
      lift = 0,
      elements = {},
    },
  }

  for _, id in pairs(elementIds) do
    local mass = core.getElementMassById(id)
    local type = core.getElementTypeById(id)
    local mHPs = core.getElementMaxHitPointsById(id)

    if Airfoils[type] then
      -- Index by Max HP
      local idx = 'H' .. math.floor(mHPs)

      -- Ailerons have compact versions with same HP on XS, different mass, so consider here
      if 'Aileron' == type and 50 == mHPs then
        idx = idx .. 'M' .. math.floor(mass)
      end

      -- Gets proper element infos
      local info = Airfoils[type][idx]
      local tags = core.getElementTagsById(id)

      -- Checks if the info variable was found
      if info then
        -- Places on right airfoil type
        if string.find(tags, 'lateral') then
          airfoils.lateral.lift = airfoils.lateral.lift + info.lift
          table.insert(airfoils.lateral.elements, info)
        end
        if string.find(tags, 'vertical') then
          airfoils.vertical.lift = airfoils.vertical.lift + info.lift
          table.insert(airfoils.vertical.elements, info)
        end
      elseif Debug then
        -- Writes debug information about missing element
        system.print('Missing Airfoil information:')
        system.print('Element: ' .. core.getElementNameById(id))
        system.print('Element ID: ' .. id)
        system.print('Element Type: ' .. type)
        system.print('Element Index: ' .. idx)
      end
    end

    -- Accounts all elements
    massElements = massElements + mass

    -- Accounts Container Hubs separately (cargo)
    if core.getElementTypeById(id) == 'Container Hub' then
      massContainers = massContainers + mass
    end
  end

  -- Updates airfoils
  currentAirfoils = airfoils

  return {
    elements = massElements,
    containers = massContainers,
  }
end

local function getWeightReading (value)
  local suffix = 'kg'
  
  if value > 1000 then
    suffix = 't'
    value = value / 1000
  end
  
  if value > 1000 then
    suffix = 'kt'
    value = value / 1000
  end
  
  return string.format('%.3f%s', value, suffix)
end

local function getNewtonReading (value)
  local suffix = 'N'

  if value > 1000 then
    suffix = 'kN'
    value = value / 1000
  end

  if value > 1000 then
    suffix = 'MN'
    value = value / 1000
  end

  return string.format('%.3f%s', value, suffix)
end

local function getGravityReading (value, suffix)
  if not suffix then
    suffix = 'm/s²'
  end

  return string.format('%.2f%s', value, suffix)
end

local function getShipMaxThrust (vector, tags)
  if not tags then tags = 'all' end

  local mkRaw = core.getMaxKinematicsParametersAlongAxis(tags, vector)
  return {
    atmo = {
      forward = math.abs(mkRaw[1]),
      backward = math.abs(mkRaw[2]),
    },
    space = {
      forward = math.abs(mkRaw[3]),
      backward = math.abs(mkRaw[4]),
    },
  }
end

local function render (data)
  local html = (
    '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Document</title><style type="text/css">body {color: #2B2A32;background-color: #57ED9D;background-image: url("' .. backgroundImage .. '");background-size: cover;}main {font-size: 20px;}svg {position: fixed;top: 0px;left: 0px;right: 0px;bottom: 0px;z-index: -1;}#breakdown {position: absolute;top: 65%;left: 50%;width: 90%;transform: translate(-50%, -50%);}hr.curve-down,hr.curve-up {height: 20px;border: 2px solid currentColor;margin: 10px auto;}hr.curve-down {border-bottom: none;border-radius: 10px 10px 0px 0px;}hr.curve-up {border-top: none;border-radius: 0px 0px 10px 10px;}.centered {text-align: center;}.title {text-transform: uppercase;font-weight: normal;font-size: 1.2em;}.value {font-weight: bold;font-size: 1.0em;}.progress-bar {height: 40px;white-space: nowrap;background-color: #ddd;border-radius: 10px;margin-bottom: calc(10px + 3em);}.progress-bar .progress-part,.progress-bar .progress-remaining {position: relative;display: inline-block;width: var(--size);height: 100%;}.progress-bar .progress-part {background-color: var(--color);}.progress-bar .progress-part:first-child {border-top-left-radius: 10px;border-bottom-left-radius: 10px;}.progress-bar .progress-part:last-of-type(.progress-part) {border-top-right-radius: 10px;border-bottom-right-radius: 10px;}.progress-bar .progress-part .label,.progress-bar .progress-remaining .label {position: absolute;bottom: -10px;left: 0px;right: 0px;transform: translateY(100%);}.progress-bar .progress-part .label {border-left: 2px solid currentColor;padding-left: 10px;margin-left: 10px;white-space: nowrap;}.progress-bar .progress-remaining .label {border-right: 2px solid currentColor;padding-right: 10px;margin-right: 10px;text-align: right;overflow: hidden;white-space: nowrap;}.parameters {margin-top: 20px;font-size: 0.75em;white-space: nowrap}.parameters > div {display: inline-block;}.parameters > div + div {border-left: 2px solid currentColor;margin-left: 20px;padding-left: 20px;}</style></head><body><main><div id="breakdown"><div class="centered"><div class="title">Max Weight</div><div class="value">' .. data.weightTotal .. '</div></div><hr class="curve-down" /><div class="progress-bar"><div class="progress-part" style="--color: #222222; --size: ' .. data.sliceShip .. '%;"><div class="label"><div class="title">Ship</div><div class="value">' .. data.weightShip .. '</div></div></div><div class="progress-part" style="--color: #FFC01E; --size: ' .. data.sliceCargo .. '%;"><div class="label"><div class="title">Cargo</div><div class="value">' .. data.weightCargo .. '</div></div></div><div class="progress-part" style="--color: #FF6F1E; --size: ' .. data.sliceDocked .. '%;">' .. ((data.sliceDocked > 5 and '<div class="label"><div class="title">Other</div><div class="value">' .. data.weightDocked .. '</div></div>') or '') .. '</div><div class="progress-remaining" style="--size: ' .. data.sliceRemaining .. '%;"><div class="label"><div class="title">Remaining</div><div class="value">' .. data.weightRemaining .. '</div></div></div></div><hr class="curve-up" /><div class="parameters centered"><div><div class="title">Gravity</div><div class="value">' .. data.gravity .. '</div></div><div><div class="title">Target Multiplier</div><div class="value">' .. data.gTarget .. '</div></div><div><div class="title">Current Weight</div><div class="value">' .. data.weightCurrent .. '</div></div><div><div class="title">Overweight</div><div class="value">' .. data.weightExceeding .. '</div></div></div></div></main></body></html>'
  )

  -- Updates on all screens
  for _, screen in pairs(screens) do
    screen.setHTML(html)
  end
end

local function handleTimerTick (self, timer)
  -- The target g we want our ship to limit to
  -- local gTarget = 1.75
  -- local gTarget = 2.00
  -- local gTarget = Target_Gs

  -- Current total mass (including inventories)
  local massTotal = core.getConstructMass()

  -- Current element mass
  local massElementsBase = getShipElementsMass()

  -- Current ship mass (estimated)
  local massElementsShip = massElementsBase.elements - massElementsBase.containers

  -- Current cargo mass (estimated)
  local massElementsCargo = massElementsBase.containers

  -- Current extra mass (docked things, for example)
  local massExtra = massTotal - massElementsBase.elements

  -- Current gravity
  local gravity = core.g()

  -- The target gravity our load should still be able to fly
  local gravityTarget = 9.807 * Target_Gravity

  -- The max "g" value of each attribute we want to use
  local gTargetThrustAtmo = gravityTarget * Target_ThrustAtmo
  local gTargetThrustSpace = gravityTarget * Target_ThrustSpace
  local gTargetLiftHigh = gravityTarget * Target_LiftHigh
  local gTargetLiftLow = gravityTarget * Target_LiftLow

  -- Gets max thrust forward
  local maxThrust = getShipMaxThrust(core.getConstructOrientationForward(), 'thrust')

  -- Low-altitude boosters
  local maxBoost = getShipMaxThrust(core.getConstructOrientationUp(), 'vertical')
  
  -- Up-facing engines
  local maxLiftUp = getShipMaxThrust(core.getConstructOrientationUp(), 'not_ground')
  
  -- Airfoils
  local maxLiftFwd = {
    atmo = {
      forward = currentAirfoils.vertical.lift,
      backward = 0,
    },
    space = {
      forward = 0,
      backward = 0,
    },
  }

  -- Max weight by thrust
  local maxWeightThrust = {
    atmo = maxThrust.atmo.forward / gTargetThrustAtmo,
    space = maxThrust.space.forward / gTargetThrustSpace,
  }

  if Debug then
    system.print('------------------')
    system.print('Thrust values:')
    system.print('------ ATMO ------')
    system.print('-> Forward Thrust: ' .. getNewtonReading(maxThrust.atmo.forward))
    system.print('-> Reverse Thrust: ' .. getNewtonReading(maxThrust.atmo.backward))
    system.print('-> Max Weight Est: ' .. getWeightReading(maxWeightThrust.atmo))
    system.print('------ SPACE -----')
    system.print('-> Forward Thrust: ' .. getNewtonReading(maxThrust.space.forward))
    system.print('-> Reverse Thrust: ' .. getNewtonReading(maxThrust.space.backward))
    system.print('-> Max Weight Est: ' .. getWeightReading(maxWeightThrust.space))
  end

  -- We'll store the max ship weight here
  local maxWeight = {}
  local maxLift = {}
  
  -- Merges max lift values
  maxLift.atmo = {
    forward = math.min(
      maxLiftFwd.atmo.forward / gTargetLiftHigh,
      maxBoost.atmo.forward / gTargetLiftLow
    ) + (maxLiftUp.atmo.forward / math.max(gTargetLiftHigh, gTargetLiftLow)),
    backward = math.min(
      maxLiftFwd.atmo.backward / gTargetLiftHigh,
      maxBoost.atmo.backward / gTargetLiftLow
    ) + (maxLiftUp.atmo.backward / math.max(gTargetLiftHigh, gTargetLiftLow)),
  }
  maxLift.space = {
    forward = math.min(
      maxLiftUp.space.forward / gTargetLiftHigh,
      maxBoost.space.forward / gTargetLiftLow
    ),
    backward = math.min(
      maxLiftUp.space.backward / gTargetLiftHigh,
      maxBoost.space.backward / gTargetLiftLow
    ),
  }

  -- Max weight by lift
  local maxWeightLift = {
    atmo = maxLift.atmo.forward,
    space = maxLift.space.forward,
  }

  if Debug then
    system.print('------------------')
    system.print('Lift calculations:')
    system.print('------ ATMO ------')
    system.print('-> Upward Engines: ' .. getNewtonReading(maxLiftUp.atmo.forward))
    system.print('-> High-alt: ' .. getNewtonReading(maxLiftFwd.atmo.forward))
    system.print('-> Low-alt: ' .. getNewtonReading(maxBoost.atmo.forward))
    system.print('-> Safe Lift: ' .. getNewtonReading(maxWeightLift.atmo * gravityTarget))
    system.print('-> Safe Lift Mass: ' .. getWeightReading(maxWeightLift.atmo))
    system.print('------ SPACE -----')
    system.print('-> Upward Engines: ' .. getNewtonReading(maxLiftUp.space.forward))
    system.print('-> High-alt: ' .. getNewtonReading(maxLiftFwd.space.forward))
    system.print('-> Low-alt: ' .. getNewtonReading(maxBoost.space.forward))
    system.print('-> Safe Lift: ' .. getNewtonReading(maxWeightLift.space * gravityTarget))
    system.print('-> Safe Lift Mass: ' .. getWeightReading(maxWeightLift.space))
  end

  -- Actual max weight calculation
  maxWeight.atmo = math.min(maxWeightThrust.atmo, maxWeightLift.atmo)
  maxWeight.space = maxWeightThrust.space

  if Debug then
    system.print('------------------')
    system.print('Weight results:')
    system.print('Max Weight (Atmo): ' .. getWeightReading(maxWeight.atmo))
    system.print('Max Weight (Space): ' .. getWeightReading(maxWeight.space))
  end

  -- system.print('SHIP -> ' .. getWeightReading(massElementsShip))
  -- system.print('CARGO -> ' .. getWeightReading(massElementsCargo))
  -- system.print('DOCKED -> ' .. getWeightReading(massExtra))

  local maxCargo = {
    atmo = maxWeight.atmo - massElementsShip,
    space = maxWeight.space - massElementsShip,
  }

  -- system.print('Gravity: ' .. getGravityReading(gravity))
  -- system.print('Gravity Target: ' .. getGravityReading(gravityTarget))
  -- system.print('Tmax A,F: ' .. getNewtonReading(maxThrust.atmo.forward))
  -- system.print('Tmax A,R: ' .. getNewtonReading(maxThrust.atmo.backward))
  -- system.print('Tmax S,F: ' .. getNewtonReading(maxThrust.space.forward))
  -- system.print('Tmax S,R: ' .. getNewtonReading(maxThrust.space.backward))
  -- system.print('Boost A: ' .. getNewtonReading(maxBoost.atmo.forward))
  -- system.print('Boost S: ' .. getNewtonReading(maxBoost.space.forward))
  -- system.print('Lift A: ' .. getNewtonReading(maxLift.atmo.forward))
  -- system.print('Lift S: ' .. getNewtonReading(maxLift.space.forward))
  -- system.print('--------------------------');
  -- system.print('Max Weight Thrust (Atmo): ' .. maxWeightThrust.atmo)
  -- system.print('Max Weight Thrust (Space): ' .. maxWeightThrust.space)
  -- system.print('Max Weight Lift (Atmo): ' .. maxWeightLift.atmo)
  -- system.print('Max Weight Lift (Space): ' .. maxWeightLift.space)
  -- system.print('Max Weight (Atmo): ' .. maxWeight.atmo)
  -- system.print('Max Weight (Space): ' .. maxWeight.space)
  -- system.print('--------------------------');
  -- system.print('Max Weight (Atmo): ' .. getWeightReading(maxWeight.atmo))
  -- system.print('Max Weight (Space): ' .. getWeightReading(maxWeight.space))
  -- system.print('Base Ship Weight: ' .. getWeightReading(massElementsShip))
  -- system.print('Max Cargo (Atmo): ' .. getWeightReading(maxCargo.atmo))
  -- system.print('Max Cargo (Space): ' .. getWeightReading(maxCargo.space))

  -- Local max weight, switches over to space load at 2% atmo
  local weightTotal = maxWeight.atmo
  if unit.getAtmosphereDensity() < 0.02 then
    weightTotal = maxWeight.space
  end
  
  local weightShip = massElementsShip
  local weightCargo = massElementsCargo
  local weightDocked = massExtra
  local weightExceeding = math.max(0, massTotal - weightTotal)
  local sliceShip = math.max(0, 100 * weightShip / weightTotal)
  local sliceCargo = math.min(100 - sliceShip, math.max(0, 100 * weightCargo / weightTotal))
  local sliceDocked = math.max(0, 100 * weightDocked / weightTotal)
  local sliceRemaining = math.max(0, 100 - (sliceShip + sliceCargo + sliceDocked))
  local weightRemaining = weightTotal * (sliceRemaining / 100)

  -- Overweight indicator
  if #leds > 0 then
    for _, led in pairs(leds) do
      if (weightExceeding > 0) then
        led.activate()
      else
        led.deactivate()
      end
    end
  end

  render({
    gravity = getGravityReading(gravity),
    gTarget = getGravityReading(Target_Gravity, 'g'),
    weightCurrent = getWeightReading(massTotal),
    weightExceeding = getWeightReading(weightExceeding),
    weightTotal = getWeightReading(weightTotal),
    weightShip = getWeightReading(weightShip),
    weightCargo = getWeightReading(weightCargo),
    weightDocked = getWeightReading(weightDocked),
    weightRemaining = getWeightReading(weightRemaining),
    sliceShip = sliceShip,
    sliceCargo = sliceCargo,
    sliceDocked = sliceDocked,
    sliceRemaining = sliceRemaining,
  })
end

-- Hooks the timer for refreshes
unit:onEvent('tick', handleTimerTick)

-- Refreshes every 3 secs
unit.setTimer('refresh', 3)

-- Triggers for first time
handleTimerTick()