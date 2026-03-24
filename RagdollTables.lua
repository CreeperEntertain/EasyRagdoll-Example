local RagdollTables = {}

local ragdoll = models.ragdoll.root
local avatar = models.model.root

RagdollTables.Rigidbodies = {
    ["Head"] = {ragdoll.Head, avatar.Head},
    ["Body"] = {ragdoll.Body, avatar.Body},
    ["LeftArm"] = {ragdoll.LeftArm, avatar.LeftArm},
    ["RightArm"] = {ragdoll.RightArm, avatar.RightArm},
    ["LeftLeg"] = {ragdoll.LeftLeg, avatar.LeftLeg},
    ["RightLeg"] = {ragdoll.RightLeg, avatar.RightLeg}
}

RagdollTables.Joints = {
    ["Head"] = {"Body", "Head", ragdoll.Body.C1, ragdoll.Head.C1},
    ["LeftArm"] = {"Body", "LeftArm", ragdoll.Body.C2, ragdoll.LeftArm.C1, 2/16},
    ["RighArm"] = {"Body", "RightArm", ragdoll.Body.C3, ragdoll.RightArm.C1, 2/16},
    ["LeftLeg"] = {"Body", "LeftLeg", ragdoll.Body.C4, ragdoll.LeftLeg.C1},
    ["RightLeg"] = {"Body", "RightLeg", ragdoll.Body.C5, ragdoll.RightLeg.C1}
}

return RagdollTables