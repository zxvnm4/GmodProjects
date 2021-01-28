--@include ../Base.lua
require("../Base.lua")
NetBufferUDEntry = ZClass(function(self,isUp,ID)
    LinkedNode.const(self)
    self.Up = true
    self.ID = 0
end
,LinkedNode,{})
NetBufferEntry = ZClass(function(self,NetObj,Data)
    LinkedNode.const(self)
    self.NetObj = NetObj
    self.Data = Data
    self.ID = 0
end,LinkedNode,{
    GetID = function(self)
        return self.ID:tostring()
    end
})