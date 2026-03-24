-- Auto generated script file --

local playerIsLimp = false
local EasyRagdoll = require("EasyRagdoll")
local RagdollTables = require("RagdollTables")
local ragdollKey = keybinds:newKeybind("Radgoll", "key.keyboard.1")
local function renderCall(a, delta, context)
  local model = a:getModel()
  local pos = model:partToWorldMatrix():apply()
  local lightLevels = vec(
    world.getBlockLightLevel(pos),
    world.getSkyLightLevel(pos)
  )
  model:setLight(lightLevels)
end
ragdollKey.release = function()
  playerIsLimp = false
  models.model:setVisible(true)
  EasyRagdoll.DestroyRD()
end
ragdollKey.press = function()
  playerIsLimp = true
  EasyRagdoll.SpawnRD(
    RagdollTables.Rigidbodies,
    RagdollTables.Joints,
    renderCall
  )
  models.model:setVisible(false)
end

--hide vanilla model
vanilla_model.PLAYER:setVisible(false)

--hide vanilla armor model
vanilla_model.ARMOR:setVisible(false)
--re-enable the helmet item
vanilla_model.HELMET_ITEM:setVisible(true)

--hide vanilla cape model
vanilla_model.CAPE:setVisible(false)

--hide vanilla elytra model
vanilla_model.ELYTRA:setVisible(false)

--entity init event, used for when the avatar entity is loaded for the first time
function events.entity_init()
  --player functions goes here
end

--tick event, called 20 times per second
function events.tick()
  --code goes here
end

--render event, called every time your avatar is rendered
--it have two arguments, "delta" and "context"
--"delta" is the percentage between the last and the next tick (as a decimal value, 0.0 to 1.0)
--"context" is a string that tells from where this render event was called (the paperdoll, gui, player render, first person)
function events.render(delta, context)
  --code goes here
end
