--@includedir ../Libs
requiredir("../Libs",{"BaseLib.lua"})

local SegMap={}
local SegID=0
function loctostring(Loc)
    if Loc:Empty() then return "EmptyLoc" end
    return "["..tostring(SegMap[tostring(Loc.Seg)])..","..Loc.Entry.ID..","..Loc.IDs:ToString().."]"
end
function UpdateSegMap(Seg)
    local ID=tostring(Seg)
    if SegMap[ID]==nil then 
        SegID=SegID+1
        SegMap[ID]=SegID 
    end
end







