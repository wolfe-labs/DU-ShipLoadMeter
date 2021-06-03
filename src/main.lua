Target_Gs = 2.0 --export: The minimum "g" value you want, affects thrust, maneuver, brakes, etc.
CustomBackground = false --export: Enables custom background image
CustomBackgroundUrl = "none" --export: The custom background image of the screen

-- The default background of the screen
Background = 'assets.prod.novaquark.com/113304/9b9b7884-5f8e-4579-900e-a1ccaf8db628.png'
if CustomBackground then
  Background = CustomBackgroundUrl
end

-- Gets a list of all linked screens
screens = library.getLinksByClass('ScreenUnit')

-- Gets a list of all emergency LEDs
leds = library.getLinksByClass('LightUnit')

local function getShipElementsMass ()
  local elementIds = core.getElementIdList()
  local massElements = 0
  local massContainers = 0

  for _, id in pairs(elementIds) do
    local mass = core.getElementMassById(id)

    -- Accounts all elements
    massElements = massElements + mass

    -- Accounts Container Hubs separately (cargo)
    if core.getElementTypeById(id) == 'Container Hub' then
      massContainers = massContainers + mass
    end
  end

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
  
  return string.format('%.3f', value) .. suffix
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

  return string.format('%.3f', value) .. suffix
end

local function getGravityReading (value)
  local suffix = 'm/s²'

  return string.format('%.2f', value) .. suffix
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
    '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Document</title><style type="text/css">body {color: #2B2A32;background-color: #57ED9D;background-image: url("' .. Background .. '");background-size: cover;}main {font-size: 20px;}svg {position: fixed;top: 0px;left: 0px;right: 0px;bottom: 0px;z-index: -1;}#breakdown {position: absolute;top: 65%;left: 50%;width: 90%;transform: translate(-50%, -50%);}hr.curve-down,hr.curve-up {height: 20px;border: 2px solid currentColor;margin: 10px auto;}hr.curve-down {border-bottom: none;border-radius: 10px 10px 0px 0px;}hr.curve-up {border-top: none;border-radius: 0px 0px 10px 10px;}.centered {text-align: center;}.title {text-transform: uppercase;font-weight: normal;font-size: 1.2em;}.value {font-weight: bold;font-size: 1.0em;}.progress-bar {height: 40px;white-space: nowrap;background-color: #ddd;border-radius: 10px;margin-bottom: calc(10px + 3em);}.progress-bar .progress-part,.progress-bar .progress-remaining {position: relative;display: inline-block;width: var(--size);height: 100%;}.progress-bar .progress-part {background-color: var(--color);}.progress-bar .progress-part:first-child {border-top-left-radius: 10px;border-bottom-left-radius: 10px;}.progress-bar .progress-part:last-of-type(.progress-part) {border-top-right-radius: 10px;border-bottom-right-radius: 10px;}.progress-bar .progress-part .label,.progress-bar .progress-remaining .label {position: absolute;bottom: -10px;left: 0px;right: 0px;transform: translateY(100%);}.progress-bar .progress-part .label {border-left: 2px solid currentColor;padding-left: 10px;margin-left: 10px;overflow: hidden;white-space: nowrap;}.progress-bar .progress-remaining .label {border-right: 2px solid currentColor;padding-right: 10px;margin-right: 10px;text-align: right;overflow: hidden;white-space: nowrap;}.parameters {margin-top: 20px;font-size: 0.75em;white-space: nowrap}.parameters > div {display: inline-block;}.parameters > div + div {border-left: 2px solid currentColor;margin-left: 20px;padding-left: 20px;}</style></head><body><main><div id="breakdown"><div class="centered"><div class="title">Max Weight</div><div class="value">' .. data.weightTotal .. '</div></div><hr class="curve-down" /><div class="progress-bar"><div class="progress-part" style="--color: #222222; --size: ' .. data.sliceShip .. '%;"><div class="label"><div class="title">Ship</div><div class="value">' .. data.weightShip .. '</div></div></div><div class="progress-part" style="--color: #FFC01E; --size: ' .. data.sliceCargo .. '%;"><div class="label"><div class="title">Cargo</div><div class="value">' .. data.weightCargo .. '</div></div></div><div class="progress-part" style="--color: #FF6F1E; --size: ' .. data.sliceDocked .. '%;"><div class="label"><div class="title">Other</div><div class="value">' .. data.weightDocked .. '</div></div></div><div class="progress-remaining" style="--size: ' .. data.sliceRemaining .. '%;"><div class="label"><div class="title">Remaining</div><div class="value">' .. data.weightRemaining .. '</div></div></div></div><hr class="curve-up" /><div class="parameters centered"><div><div class="title">Gravity</div><div class="value">' .. data.gravity .. '</div></div><div><div class="title">Target Multiplier</div><div class="value">' .. data.gTarget .. '</div></div><div><div class="title">Current Weight</div><div class="value">' .. data.weightCurrent .. '</div></div><div><div class="title">Overweight</div><div class="value">' .. data.weightExceeding .. '</div></div></div></div></main></body></html>'
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
  local gTarget = Target_Gs

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
  local gravityTarget = gravity * gTarget

  -- Gets max thrust forward
  local maxThrust = getShipMaxThrust(core.getConstructOrientationForward(), 'thrust')

  -- Low-altitude boosters
  local maxBoost = getShipMaxThrust(core.getConstructOrientationUp(), 'vertical')
  
  -- Airfoils
  local maxLiftUp = getShipMaxThrust(core.getConstructOrientationUp(), 'not_ground')

  -- Up-facing engines
  local maxLiftFwd = getShipMaxThrust(core.getConstructOrientationForward(), 'not_ground')

  -- Merges max lift vectors
  local maxLift = {
    atmo = {
      forward = maxLiftUp.atmo.forward + maxLiftFwd.atmo.forward,
      backward = maxLiftUp.atmo.backward + maxLiftFwd.atmo.backward,
    },
    space = {
      forward = maxLiftUp.space.forward,
      backward = maxLiftUp.space.backward,
    },
  }

  local maxWeightThrust = {
    atmo = maxThrust.atmo.forward / gravityTarget,
    space = maxThrust.space.forward / gravityTarget,
  }

  local maxWeightLift = {
    atmo = maxLift.atmo.forward / gravityTarget,
    space = maxLift.space.forward / gravityTarget,
  }

  local maxWeight = {
    atmo = math.min(maxWeightThrust.atmo, maxWeightLift.atmo),
    space = maxWeightThrust.space,
  }

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
  local weightRemaining = weightTotal - massTotal
  local weightExceeding = math.max(0, massTotal - weightTotal)
  local sliceShip = math.max(0, 100 * weightShip / weightTotal)
  local sliceCargo = math.min(100 - sliceShip, math.max(0, 100 * weightCargo / weightTotal))
  local sliceDocked = math.max(0, 100 * weightDocked / weightTotal)
  local sliceRemaining = math.max(0, 100 - (sliceShip + sliceCargo + sliceDocked))

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
    gTarget = string.format('%.2f', gTarget) .. 'g',
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