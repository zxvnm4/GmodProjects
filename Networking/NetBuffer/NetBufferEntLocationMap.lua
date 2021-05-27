--@include ../Base.lua
--@include NBCliList.lua
require("../Base.lua")
require("NBCliList.lua")
NetBufferEntLocationMap = ZClass(function(self)
    self.Locations={}
    self.Last=0
    self.First=0
end,{
    CombineTwoNodes = function(self,Prv,NLoc) -- This is beyond insane, I mean.. I am going to have to debug this...
        if Prv==nil or NLoc==nil then return end
        --print("Combining Nodes",self:ToStringNode(Prv),self:ToStringNode(NLoc))
        NBCliList(Prv[4]):AndMoveTo(NLoc[4],Prv[2],NLoc[3]) -- Aww, isn't it lovely?
        NBCliList(Prv[4]):IfInMove(Prv[2],NLoc[2])          -- I came up with cute little functions for every operation (:
        NBCliList(Prv[4]):Remove(NLoc[3])

        NBCliList(Prv[3]):IfInMove(NLoc[3],NLoc[4]) 
        NBCliList(Prv[3]):Remove(NLoc[3])
        NBCliList(NLoc[2]):IfInRBoth(Prv[3])

        NBCliList(Prv[2]):RemoveFrom(NLoc[2],NLoc[3],NLoc[4])
        --print("End Combining Nodes",self:ToStringNode(Prv),self:ToStringNode(NLoc))
    end,
    ToStringNode = function(self,N)
        return loctostring(N[1]).." "..NBCliList(N[2]):ToString().." "..NBCliList(N[3]):ToString().." "..NBCliList(N[4]):ToString()
    end,
    Empty = function(self)
        return next(self.Locations)==nil
    end,
    ToString = function(self)
        Cats = ""
        for i,k in pairs(self.Locations) do
            Cats=Cats.."N "..i..": "..self:ToStringNode(k).." "
        end
        return "LocMap: "..Cats
    end,
    CombineNode = function(self,A2,NLoc)
        local A=self.Locations[A2]
        if A~=nil then
            --print("Combine Node",self:ToStringNode(A),self:ToStringNode(NLoc))
            for i,k in pairs(NLoc[2]) do
                A[2][k:GetID()]=k
                A[3][k:GetID()]=nil
            end
            for i,k in pairs(NLoc[3]) do
                A[2][k:GetID()]=nil
                A[3][k:GetID()]=k
            end
            for i,k in pairs(NLoc[4]) do
                A[4][k:GetID()]=k
            end
            if next(A[2])==nil and next(A[3])==nil and next(A[4])==nil then
                self.Locations[A2]=nil
            end
            --print("End Combine Node",self:ToStringNode(A),self:ToStringNode(NLoc))
            return A
        else
            
            local PrvL=NetBuffer.PreviousLocation(nil,NLoc[1])
            local NexL=NetBuffer.NextLocation(nil,NLoc[1])
            --print("Combine NodeV2",PrvL==nil or PrvL:ToString(),NexL==nil or NexL:ToString(),self:ToStringNode(NLoc))
            if PrvL~=nil then
                local Prv=PrvL:GetID2()
                self:CombineTwoNodes(self.Locations[Prv],NLoc)
                if self.Locations[Prv]~=nil and next(self.Locations[Prv][2])==nil and next(self.Locations[Prv][3])==nil and next(self.Locations[Prv][4])==nil then
                    self.Locations[Prv]=nil
                end
            end
            if NexL~=nil then
                local Nex=NexL:GetID2()
                self:CombineTwoNodes(NLoc,self.Locations[Nex])
                if self.Locations[Nex]~=nil and next(self.Locations[Nex][2])==nil and next(self.Locations[Nex][3])==nil and next(self.Locations[Nex][4])==nil then
                    self.Locations[Nex]=nil
                end
            end
            --print("End Combine NodeV2",self:ToStringNode(NLoc))
            return NLoc

        end   
    end,
    AddSec = function(self,Ents,Start,End) -- It does not do the whole check if you are inside of an existing thing deal, that... could be done
                                            -- With a RB-Tree? Each node is either start or end, you just slowly go to smaller and smaller numbers
                                            -- From where you are until you find one that covers you? There ought to be a better way...
                                            -- Oh I know!, A overlapping system! That, works the other way around doesn't it tho?
                                            -- Although that thankfully doesn't have the issue where you gotta go through a bunch of small <>
                                            -- So in a situation where it is heavy with childs then it good. *screams in 2d trees* Wait, complex numbers as indexs
        local SL=Start:GetID2()
        local EL=End:GetID2()
        
        if SL==EL then
            
            local S=self:CombineNode(SL,{Start,{},{},CopyTable(Ents)})
            if next(S[2])~=nil or next(S[3])~=nil or next(S[4])~=nil then
                self.Locations[SL] = S
            end
        else 
            local S={Start,CopyTable(Ents),{},{}}
            local E={End,{},CopyTable(Ents),{}}
            self:CombineNode(SL,S)
            self:CombineNode(EL,E)
            if next(S[2])~=nil or next(S[3])~=nil or next(S[4])~=nil then 
                self.Locations[SL] = S 
            end
            if next(E[2])~=nil or next(E[3])~=nil or next(E[4])~=nil then
                self.Locations[EL] = E
            end
        end
    end,
    AddSec3 = function(self,Ents,Start,End) -- I'll pretend it's fine...
        local Cur=Start.Seg
        local CurL=Start
        local EndID=End.Seg:GetEnd().IDs

        while Cur ~= End.Seg do
            local NSeg = NetBuffer.FindForwardDuplicateSeg(nil,Cur,Ents)
            if NSeg == nil or NSeg.Data.End == 0 or NSeg:GetEnd().IDs:Compare(EndID) == -1 then
                break
            end 
            if Cur.Next ~= NSeg then
                local NLoc=NSeg:GetEnd()
                self:AddSec2(Ents,CurL,NLoc)
                CurL=NLoc
            end
            Cur=NSeg
        end
        self:AddSec2(Ents,CurL,End)
    end
})