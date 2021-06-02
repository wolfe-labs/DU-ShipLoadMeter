Target_Gs = 2.0 --export: The minimum "g" value you want, affects thrust, maneuver, brakes, etc.

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
    '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Document</title><style type="text/css">body {color: #2B2A32;background-color: #57ED9D;}main {font-size: 20px;}svg {position: fixed;top: 0px;left: 0px;right: 0px;bottom: 0px;z-index: -1;}#breakdown {position: absolute;top: 65%;left: 50%;width: 90%;transform: translate(-50%, -50%);}hr.curve-down,hr.curve-up {height: 20px;border: 2px solid currentColor;margin: 10px auto;}hr.curve-down {border-bottom: none;border-radius: 10px 10px 0px 0px;}hr.curve-up {border-top: none;border-radius: 0px 0px 10px 10px;}.centered {text-align: center;}.title {text-transform: uppercase;font-weight: normal;font-size: 1.2em;}.value {font-weight: bold;font-size: 1.0em;}.progress-bar {height: 40px;white-space: nowrap;background-color: #ddd;border-radius: 10px;margin-bottom: calc(10px + 3em);}.progress-bar .progress-part,.progress-bar .progress-remaining {position: relative;display: inline-block;width: var(--size);height: 100%;}.progress-bar .progress-part {background-color: var(--color);}.progress-bar .progress-part:first-child {border-top-left-radius: 10px;border-bottom-left-radius: 10px;}.progress-bar .progress-part:last-of-type(.progress-part) {border-top-right-radius: 10px;border-bottom-right-radius: 10px;}.progress-bar .progress-part .label,.progress-bar .progress-remaining .label {position: absolute;bottom: -10px;left: 0px;right: 0px;transform: translateY(100%);}.progress-bar .progress-part .label {border-left: 2px solid currentColor;padding-left: 10px;margin-left: 10px;overflow: hidden;white-space: nowrap;}.progress-bar .progress-remaining .label {border-right: 2px solid currentColor;padding-right: 10px;margin-right: 10px;text-align: right;overflow: hidden;white-space: nowrap;}.parameters {margin-top: 20px;font-size: 0.75em;white-space: nowrap}.parameters > div {display: inline-block;}.parameters > div + div {border-left: 2px solid currentColor;margin-left: 20px;padding-left: 20px;}</style></head><body><svg width="100%" height="100%" viewBox="0 0 1670 1000" fill="none" xmlns="http://www.w3.org/2000/svg"><g id="Wolfe Labs Background"><rect width="1670" height="1000" fill="#57ED9D"/><g id="Group 5" opacity="0.1"><g id="Group 4" style="mix-blend-mode:hard-light"><path id="Star" d="M125.612 323.353C155.934 323.353 165.918 333.338 165.918 363.659C165.918 333.338 175.903 323.353 206.225 323.353C175.903 323.353 165.918 313.369 165.918 283.047C165.918 313.369 155.934 323.353 125.612 323.353Z" fill="#211D1F"/><path id="Star_2" d="M186.071 242.741C201.232 242.741 206.225 247.733 206.225 262.894C206.225 247.733 211.217 242.741 226.378 242.741C211.217 242.741 206.225 237.749 206.225 222.588C206.225 237.749 201.232 242.741 186.071 242.741Z" fill="#211D1F"/><path id="Star_3" d="M125.612 81.5163C155.934 81.5163 165.918 91.5008 165.918 121.822C165.918 91.5008 175.903 81.5163 206.225 81.5163C175.903 81.5163 165.918 71.5319 165.918 41.2102C165.918 71.5319 155.934 81.5163 125.612 81.5163Z" fill="#211D1F"/><path id="Star_4" d="M45 162.129C75.3217 162.129 85.3061 172.113 85.3061 202.435C85.3061 172.113 95.2906 162.129 125.612 162.129C95.2906 162.129 85.3061 152.144 85.3061 121.823C85.3061 152.144 75.3217 162.129 45 162.129Z" fill="#211D1F"/><path id="Star_5" d="M206.225 162.129C236.546 162.129 246.531 172.113 246.531 202.435C246.531 172.113 256.515 162.129 286.837 162.129C256.515 162.129 246.531 152.144 246.531 121.823C246.531 152.144 236.546 162.129 206.225 162.129Z" fill="#211D1F"/></g><g id="atom-laboratory-science 1" style="mix-blend-mode:hard-light" clip-path="url(#clip0)"><g id="Group"><path id="Vector" d="M322.182 146.687C347.485 146.687 368.981 179.335 383.313 232.091C388.284 250.408 392.538 271.322 395.897 294.207C417.394 285.698 437.636 278.935 455.953 274.054C508.754 260.081 547.762 262.41 560.436 284.31C573.065 306.209 555.554 341.141 517.039 379.88C503.694 393.315 487.705 407.467 469.523 421.843C476.778 427.576 483.72 433.308 490.258 438.951C484.302 443.116 479.42 448.624 476.017 455.073C468.493 448.58 460.432 441.996 451.923 435.323C436.92 446.475 420.752 457.671 403.555 468.733C402.57 489.199 400.958 508.815 398.808 527.401C421.335 536.537 442.473 543.702 461.462 548.718C504.5 560.093 534.64 560.944 541.805 548.584C545.612 542 542.925 531.655 534.908 518.668C541.402 515.846 547.135 511.547 551.703 506.217C564.645 527.401 568.273 545.807 560.48 559.287C547.806 581.187 508.844 583.516 455.998 569.543C437.681 564.706 417.438 557.899 395.897 549.39C392.538 572.275 388.284 593.189 383.313 611.506C368.981 664.262 347.485 696.91 322.182 696.91C296.878 696.91 275.382 664.262 261.051 611.506C256.079 593.189 251.825 572.275 248.466 549.39C240.674 552.48 233.06 555.346 225.671 557.944C225.089 550.465 222.715 543.523 218.998 537.477C227.596 534.432 236.464 531.073 245.6 527.356C243.45 508.77 241.793 489.11 240.853 468.643C223.655 457.581 207.488 446.385 192.485 435.234C173.273 450.192 156.479 464.926 142.64 478.854C111.201 510.561 95.3923 536.268 102.558 548.673C106.544 555.57 117.65 558.347 134.131 557.496C133.997 558.839 133.952 560.228 133.952 561.616C133.952 567.483 135.071 573.081 137.042 578.231C110.753 579.351 91.9887 573.35 83.9275 559.377C71.2982 537.477 88.809 502.545 127.324 463.806C140.714 450.371 156.658 436.219 174.84 421.843C156.702 407.467 140.714 393.315 127.324 379.88C88.809 341.141 71.2982 306.209 83.9275 284.31C96.6015 262.41 135.564 260.081 188.41 274.054C206.727 278.891 226.969 285.653 248.511 294.207C249.72 285.922 251.064 277.905 252.497 270.202C258.722 273.337 265.708 275.084 273.142 275.084H273.545C271.888 283.907 270.411 293.177 269.067 302.761C286.219 310.15 304.044 318.57 322.182 327.93C340.364 318.57 358.144 310.15 375.296 302.761C371.937 278.622 367.593 256.722 362.443 237.778C350.799 194.875 336.468 168.317 322.182 168.317C314.255 168.317 306.283 176.513 298.804 191.113C293.027 187.217 286.354 184.574 279.099 183.634C291.325 160.077 305.97 146.687 322.182 146.687ZM513.322 445.579C529.758 445.579 543.104 458.925 543.104 475.361C543.104 491.797 529.758 505.143 513.322 505.143C496.886 505.143 483.54 491.797 483.54 475.361C483.54 458.925 496.841 445.579 513.322 445.579ZM179.946 530.894C196.382 530.894 209.727 544.24 209.727 560.675C209.727 577.111 196.382 590.457 179.946 590.457C163.51 590.457 150.164 577.111 150.164 560.675C150.164 544.24 163.51 530.894 179.946 530.894ZM273.098 199.353C289.534 199.353 302.879 212.699 302.879 229.135C302.879 245.571 289.534 258.917 273.098 258.917C256.662 258.917 243.316 245.571 243.316 229.135C243.316 212.699 256.662 199.353 273.098 199.353ZM322.182 382.254C344.036 382.254 361.771 399.988 361.771 421.843C361.771 443.698 344.036 461.433 322.182 461.433C300.327 461.433 282.592 443.698 282.592 421.843C282.592 399.988 300.327 382.254 322.182 382.254ZM192.441 408.318C207.443 397.167 223.611 385.971 240.808 374.909C241.793 354.487 243.405 334.827 245.555 316.241C222.984 307.105 201.89 299.939 182.901 294.879C139.863 283.504 109.723 282.653 102.558 295.013C95.3923 307.418 111.201 333.125 142.595 364.698C156.434 378.626 173.228 393.36 192.441 408.318ZM375.296 540.97C358.144 533.581 340.319 525.117 322.182 515.757C303.999 525.117 286.219 533.536 269.067 540.97C272.426 565.109 276.77 587.009 281.92 605.953C293.564 648.856 307.895 675.414 322.226 675.414C336.513 675.414 350.888 648.856 362.488 605.953C367.593 587.009 371.937 565.064 375.296 540.97ZM298.938 503.396C293.027 500.127 287.07 496.768 281.114 493.319C280.935 493.23 280.711 493.096 280.532 492.961C274.665 489.558 268.888 486.154 263.2 482.705C264.006 495.066 265.036 507.068 266.29 518.623C276.949 513.965 287.877 508.86 298.938 503.396ZM345.425 340.29C351.381 343.56 357.382 346.963 363.428 350.412C369.429 353.86 375.341 357.353 381.163 360.891C380.357 348.576 379.327 336.573 378.073 325.019C367.414 329.721 356.531 334.827 345.425 340.29ZM403.555 374.909C420.752 385.971 436.92 397.167 451.923 408.318C471.135 393.36 487.929 378.626 501.768 364.698C533.117 333.125 548.926 307.418 541.805 295.013C534.64 282.653 504.5 283.504 461.462 294.879C442.473 299.895 421.335 307.06 398.808 316.241C400.958 334.827 402.57 354.442 403.555 374.909ZM434.009 421.843C424.604 414.991 414.751 408.094 404.451 401.242C404.585 408.05 404.675 414.902 404.675 421.843C404.675 428.785 404.585 435.682 404.451 442.489C414.751 435.637 424.604 428.74 434.009 421.843ZM382.462 387.001C372.833 380.955 362.846 374.954 352.635 369.087C342.424 363.175 332.258 357.577 322.182 352.203C312.105 357.532 301.939 363.175 291.728 369.087H291.683C281.472 374.998 271.53 380.955 261.901 387.001C261.498 398.421 261.274 410.02 261.274 421.843C261.274 433.666 261.498 445.31 261.901 456.686C271.441 462.642 281.248 468.554 291.325 474.376C291.37 474.376 291.594 474.51 291.594 474.51L291.728 474.599C301.984 480.511 312.15 486.154 322.226 491.483C332.213 486.199 342.245 480.645 352.366 474.779C352.545 474.689 352.725 474.555 352.904 474.465C363.025 468.598 372.922 462.687 382.462 456.686C382.865 445.31 383.089 433.666 383.089 421.843C383.089 410.02 382.865 398.421 382.462 387.001ZM298.894 340.29C287.832 334.827 276.904 329.721 266.29 325.019C265.036 336.618 264.006 348.576 263.2 360.936C269.022 357.398 274.934 353.905 280.935 350.457C286.936 346.963 292.937 343.56 298.894 340.29ZM210.354 421.843C219.759 428.74 229.612 435.637 239.912 442.489C239.778 435.682 239.688 428.785 239.688 421.843C239.688 414.902 239.778 408.005 239.912 401.197C229.612 408.05 219.714 414.946 210.354 421.843ZM345.38 503.396C356.487 508.86 367.369 513.965 378.028 518.668C379.282 507.068 380.312 495.111 381.118 482.75C375.296 486.288 369.384 489.781 363.339 493.275L363.025 493.454C357.158 496.857 351.247 500.171 345.38 503.396Z" fill="#211D1F"/></g></g></g></g><defs><clipPath id="clip0"><rect width="484.659" height="550.313" fill="white" transform="translate(79.8527 146.687)"/></clipPath></defs></svg><main><div id="breakdown"><div class="centered"><div class="title">Max Weight</div><div class="value">' .. data.weightTotal .. '</div></div><hr class="curve-down" /><div class="progress-bar"><div class="progress-part" style="--color: #222222; --size: ' .. data.sliceShip .. '%;"><div class="label"><div class="title">Ship</div><div class="value">' .. data.weightShip .. '</div></div></div><div class="progress-part" style="--color: #FFC01E; --size: ' .. data.sliceCargo .. '%;"><div class="label"><div class="title">Cargo</div><div class="value">' .. data.weightCargo .. '</div></div></div><div class="progress-part" style="--color: #FF6F1E; --size: ' .. data.sliceDocked .. '%;"><div class="label"><div class="title">Other</div><div class="value">' .. data.weightDocked .. '</div></div></div><div class="progress-remaining" style="--size: ' .. data.sliceRemaining .. '%;"><div class="label"><div class="title">Remaining</div><div class="value">' .. data.weightRemaining .. '</div></div></div></div><hr class="curve-up" /><div class="parameters centered"><div><div class="title">Gravity</div><div class="value">' .. data.gravity .. '</div></div><div><div class="title">Target Multiplier</div><div class="value">' .. data.gTarget .. '</div></div><div><div class="title">Current Weight</div><div class="value">' .. data.weightCurrent .. '</div></div><div><div class="title">Overweight</div><div class="value">' .. data.weightExceeding .. '</div></div></div></div></main></body></html>'
  )

  screenCargo.setHTML(html)
  screenDashboard.setHTML(html)
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

  if (weightExceeding > 0) then
    ledOverweight.activate()
  else
    ledOverweight.deactivate()
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