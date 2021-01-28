--@include ../Base.lua
require("../Base.lua")

NetBufferClient = ZClass(function(self,Ent)
    self.Ent=Ent
    self.Segments = LinkedList()
end,{
    GetID = function(self)
        if self.Ent == nil then
            return -1
        else
            return self.Ent:entIndex()
        end
    end,
    Cloneish = function(self,New)
        for i,k in self.Segments:Pairs() do
            local N = k:Clone()
            N.Client = New
            New.Segments:AddBefore(0,N)
            
        end
        return New
    end,
    FindSegWithIDs = function(self,IDs,StartSeg,EndSeg)
        for i,k in self.Segments:ContinueFToPairs(StartSeg,EndSeg) do
            if k:GetStart().IDs:Compare(IDs) >= 0 and k:GetEnd().IDs:Compare(IDs) <= 0 then
                return k
            end
        end
        return nil
    end,
    PreviousLocation = function(self,A) 
        if A.Entry==A.Seg:GetStart().Entry then
            local B=A.Seg.Clients[self:GetID()].Back
            if B ~= 0 then
                if B.Seg.Data.End ~= 0 then
                    return B.Seg:GetEnd()
                end
            end
        else
            local BE=A.Seg:BackEntry(A)
            if BE ~= 0 then
                return BE
            end
        end
        return nil
    end,
    NextLocation = function(self,A)
        if A.Entry==A.Seg:GetEnd().Entry then
            local B=A.Seg.Clients[self:GetID()].Next
            if B ~= 0 then
                if B.Seg.Data.End ~= 0 then
                    return B.Seg:GetEnd()
                end
            end
        else
            local BE=A.Seg:NextEntry(A)
            if BE ~= 0 then
                return BE
            end
        end
        return nil
    end
})
NetBufferClientSeg = ZClass(function(self,Client,Seg)
    LinkedNode.const(self)
    self.Client = Client
    self.Seg = Seg
end,LinkedNode,{
    Clone = function(self,Base)
        if Base == nil then
            Base=NetBufferClientSeg(self.Client,self.Seg)
        else
            Base.Client = self.Client
            Base.Seg = self.Seg
        end
        LinkedNode.Clone(self,Base)
        return Base
    end
})