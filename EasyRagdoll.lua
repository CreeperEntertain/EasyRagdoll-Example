---@class EasyRagdoll
local ERD = {}

local Fidget = require("Fidget.FidgetSetup")

--Fidget.physicsSim.changeQuality("lowest")
ERD.FidgetRate = 15
Fidget.physicsSim.dt = (1/ERD.FidgetRate)/Fidget.physicsSim.physicsIterations
Fidget.physicsSim.debug.axis = false
Fidget.physicsSim.debug.joints = false

ERD.Mass = 1
ERD.Friction = 1

ERD.RagdollRBs = {}
ERD.RagdollCs = {}
ERD.RbVel = vec(0, 0, 0)

local function rotMatToQuatWXYZ(R)
    local q = vec(0, 0, 0, 0)
    local trace = R[1][1] + R[2][2] + R[3][3]

    if trace > 0 then
        local s = 0.5 / math.sqrt(trace + 1.0)
        q[1] = 0.25 / s
        q[2] = (R[3][2] - R[2][3]) * s
        q[3] = (R[1][3] - R[3][1]) * s
        q[4] = (R[2][1] - R[1][2]) * s
    else
        if (R[1][1] > R[2][2]) and (R[1][1] > R[3][3]) then
            local s = 2.0 * math.sqrt(1.0 + R[1][1] - R[2][2] - R[3][3])
            q[1] = (R[3][2] - R[2][3]) / s
            q[2] = 0.25 * s
            q[3] = (R[1][2] + R[2][1]) / s
            q[4] = (R[1][3] + R[3][1]) / s
        elseif R[2][2] > R[3][3] then
            local s = 2.0 * math.sqrt(1.0 + R[2][2] - R[1][1] - R[3][3])
            q[1] = (R[1][3] - R[3][1]) / s
            q[2] = (R[1][2] + R[2][1]) / s
            q[3] = 0.25 * s
            q[4] = (R[2][3] + R[3][2]) / s
        else
            local s = 2.0 * math.sqrt(1.0 + R[3][3] - R[1][1] - R[2][2])
            q[1] = (R[2][1] - R[1][2]) / s
            q[2] = (R[1][3] + R[3][1]) / s
            q[3] = (R[2][3] + R[3][2]) / s
            q[4] = 0.25 * s
        end
    end

    return q
end
local function normalizedMatrix3(m4x4)
    return matrices.mat3(
        m4x4[1].xyz:normalize(),
        m4x4[2].xyz:normalize(),
        m4x4[3].xyz:normalize()
    )
end

local function getVertices(part)
    local vertData = part:getAllVertices()
    local posList = {}
    for _, vertexList in pairs(vertData) do
        for _, vertex in ipairs(vertexList) do
            table.insert(posList, vertex:getPos())
        end
    end
    return posList
end
local function getScale(vertexList)
    local minX, maxX, minY, maxY, minZ, maxZ
    for _, pos in ipairs(vertexList) do
        minX = math.min(minX or pos.x, pos.x)
        maxX = math.max(maxX or pos.x, pos.x)
        minY = math.min(minY or pos.y, pos.y)
        maxY = math.max(maxY or pos.y, pos.y)
        minZ = math.min(minZ or pos.z, pos.z)
        maxZ = math.max(maxZ or pos.z, pos.z)
    end
    return vec(
        math.abs(maxX - minX) / 16,
        math.abs(maxY - minY) / 16,
        math.abs(maxZ - minZ) / 16
    )
end

local function getParams(part, scaleSamplePart)
    local scaleSample = scaleSamplePart or part:getChildren()[1]
    local m = part:partToWorldMatrix()
    local quat = rotMatToQuatWXYZ(normalizedMatrix3(m))
    local worldSpacePos = m:apply()
    return {
        pos = worldSpacePos,
        rot = quat,
        scale = getScale(getVertices(scaleSample)) or vec(1, 1, 1)
    }
end

---Returns a full table of parameters, ready to use with Fidget's `rigidbodies.createRigidbody()` function.
---@param ragdollPart ModelPart
---@param velocity vector
---@param originalPart ModelPart
---@param collisionBlacklist table
---@return table
local function definition(ragdollPart, velocity, originalPart, collisionBlacklist)
    local params = getParams(originalPart, ragdollPart:getChildren()[1])
    return {
        mass = ERD.Mass,
        pos = params.pos,
        vel = velocity,
        friction = ERD.Friction,
        dimensions = params.scale,
        model = ragdollPart:setParentType("WORLD"),
        collisionBlacklist = collisionBlacklist,
        rot = params.rot
    }
end
---Creates and returns a fully functioning rigidbody based on the parameters.
---@param ragdollPart ModelPart
---@param velocity vector
---@param originalPart ModelPart
---@param collisionBlacklist table
---@return table
local function create(ragdollPart, velocity, originalPart, collisionBlacklist)
    return Fidget.rigidbodies.createRigidbody(definition(ragdollPart, velocity, originalPart, collisionBlacklist))
end

local function joint(part1, part2, connector1, connector2, length)
    return {
        rigidbody1 = part1,
        rigidbody2 = part2,
        pos1 = connector1:getPivot() / 16,
        pos2 = connector2:getPivot() / 16,
        distance = length or 0
    }
end
local function connect(part1, part2, connector1, connector2, length)
    return Fidget.joints.createJoint(joint(part1, part2, connector1, connector2, length))
end

local function spawnRBs(definitions, renderCallFunction)
    ERD.RbVel = player:getVelocity() * ERD.FidgetRate
    local function CreateRB(rdPart, original, bl)
        local RB = create(rdPart, ERD.RbVel, original, bl or {})
        RB.onRender = function(a, d, c)
            renderCallFunction(a, d, c)
        end
        return RB
    end

    for key, _definition in pairs(definitions) do
        local bl = {}
        for _, entry in ipairs(bl) do
            table.insert(bl, ERD.RagdollRBs[entry])
        end
        ERD.RagdollRBs[key] = CreateRB(_definition[1], _definition[2], bl)
    end
end
local function spawnCs(definitions)
    local function CreateC(p1, p2, c1, c2, length)
        return connect(ERD.RagdollRBs[p1], ERD.RagdollRBs[p2], c1, c2, length)
    end

    for key, _definition in pairs(definitions) do
        ERD.RagdollCs[key] = CreateC(_definition[1], _definition[2], _definition[3], _definition[4], _definition[5])
    end
end

---Destroys the currently acive ragdoll.
function ERD.DestroyRD()
    for _, rbPart in pairs(ERD.RagdollRBs) do
        rbPart:remove()
    end
end
---Spawns a ragdoll based on the definitions you supply it.<br><br>
---For extra help, read the documentation over at<br>
---https://docs.google.com/document/d/11aw5hRHtwZdVQOEPo-5T47fF9qRRRiz3MWgdwHeSILg/edit?usp=sharing<br><br>
---`rigidbodyDefinitions` needs to be a table you use to define rigidbodies.<br>
---Example to make the head and body of a character into rigidbodies:<br>
---```lua
---local rigidbodies = {
---    ["Head"] = {models.ragdoll.root.Head, models.model.root.Head, {}},
---    ["Body"] = {models.ragdoll.root.Body, models.model.root.Body, {"Head"}}
---}
---```
---Just keep in mind that th first cube inside, for instance, `models.ragdoll.root.Head` will be sampled for
---the size of the collider. If you have more complex body parts, it's advised to create a new cube with
---a name you can remember and place it all the way at the top. It does not need a texture.<br><br>
---`jointDefinitions` needs to be a table you use to define connections between rigidbodies.<br>
---Example to connect the `Head` to your `Body` part. Notice how the names you set above get used here:<br>
---```lua
---local joints = {
---    ["Body_Head"] = {"Body", "Head", models.ragdoll.root.Head.C1, models.ragdollModel.root.Body.C1, 0.05}
---}
---```
---`C1` is a part specifically created for connectors. You need to add it to your model as well. Simply create
---a cube inside your body part (the ragdoll model is advised), name it something you can remember, and move it
---all the way down. The pivot of the cube will define where it connects to. It does not have to be textured.<br>
---`0.05` is how loose the connectors are. If not defined, it defaults to 0.<br><br>
---`renderFunctionCall` is a function that will be called on every physics step by every part.<br>
---Example to update the light levels of each rigidbody:
---```lua
---local onRender = function(a, delta, context)
---    local model = a:getModel()
---    local pos = model:partToWorldMatrix():apply()
---    local lightLevels = vec(
---        world.getBlockLightLevel(pos),
---        world.getSkyLightLevel(pos)
---    )
---    model:setLight(lightLevels)
---end
---```
---@param rigidbodyDefinitions table
---@param jointDefinitions table
---@param renderFunctionCall function
function ERD.SpawnRD(rigidbodyDefinitions, jointDefinitions, renderFunctionCall)
    spawnRBs(rigidbodyDefinitions, renderFunctionCall)
    spawnCs(jointDefinitions)
end

return ERD