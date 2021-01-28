--@includedir ../../Libs
--@includedir ../Whole
requiredir("../../Libs",{"BaseLib.lua"})
requiredir("../Whole")
function RoundedClickable(Obj)
    Obj.Hooks:CreateHook("CheckPos","ButtonB",function(Data)
        local S=((Data[2]/Data[1].Size)*2-vec2(1)):lengthSq()
        return S<=1
    end)
end