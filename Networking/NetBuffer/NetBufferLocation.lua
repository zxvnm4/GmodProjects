--@include ../Base.lua
require("../Base.lua")
NetBufferLocation = ZClass(function(self,Seg,Entry,IDs)
    self.Seg=Seg
    self.Entry=Entry
    if IDs.IDs == nil then IDs = FunkyID(IDs) end
    self.IDs=IDs
end,{
    GetID = function(self)
        return tostring(self.Seg)+tostring(self.Entry)
    end,
    GetID2 = function(self)
        return self.IDs:ToString()
    end,
    Compare = function(self,A)
        return self.IDs:Compare(A.IDs)    
    end,
    Equals = function(self,A)
        return A.Entry==self.Entry and A.Seg==self.Seg
    end,
    Clone = function(self)
        return NetBufferLocation(self.Seg,self.Entry,self.IDs:Clone())
    end,
    Empty = function(self)
        return self.Seg == nil
    end,
    ToString = function(self)
        return loctostring(self)
    end
})