--@include ../Base.lua
--@include NetBufferEntry.lua
--@include NetBufferLocation.lua
require("../Base.lua")
require("NetBufferEntry.lua")
require("NetBufferLocation.lua")
NetBufferSeg = ZClass(function(self,Clients)
    LinkedNode.const(self)
    self.Clients = Clients
    self.ClientCount = 0
    for i,k in pairs(Clients) do
        self.ClientCount = self.ClientCount + 1
    end
    self.Data = LinkedList()
end,LinkedNode,{
    AddEntry = function(self,Entry)
        local Entry=NetBufferEntry(NetObj,Data)
        self.Data:AddBefore(0,Entry)
        return Entry
    end,
    HasAllClientsInList = function(self,Clients)
        return NBCliList(Clients):IsEqual(self)
    end,
    HasAllClientsInList2 = function(self,Clients)
        return NBCliList(self):HasAllIn(Clients)
    end,
    HasClients = function(self,Clients)
        return NBCliList(self):HasAnyIn(Clients)
    end,
    RemoveClients = function(Seg,Clients)
        for i,k in NBCliList(Clients):PairsAnd(Seg) do 
            local ID=k:GetID()
            k.Segments:Remove(Seg.Clients[ID])
            Seg.Clients[ID] = nil
            Seg.ClientCount = Seg.ClientCount - 1
        end
    end,
    ForeachEntry = function(self,Loc1,Loc2,Func)
        local Node=nil
        local IDs=FunkyID({})
        local ENode=nil
        if self.Data.Start == 0 then
            return
        end
        if Loc1==0 then
            Node=self.Data.Start
        else
            IDs=Loc1.IDs:Clone()
            IDs:Pop()
            Node=Loc1.Entry
        end
        if Loc2==0 then
            ENode=self.Data.End
        else
            ENode=Loc2.Entry
        end    
        for i,k in Node:ContinueFToPairs(ENode) do
            if i.Up == true then
                IDs:Push(i.ID)
            elseif i.Up == false then
                IDs:Pop()
            else
                IDs:Push(i.ID)
                if Func(IDs,i) == false then break end
                IDs:Pop()
            end
        end
    end,
    EntryFPairs = function(self,Loc1,Loc2)
        local Node=nil
        local IDs=FunkyID({})
        local ENode=nil
        if self.Data.Start == 0 then
            return function(t,v) return nil end,nil,nil
        end
        if Loc1==0 then
            Node=self.Data.Start
        else
            IDs=Loc1.IDs:Clone()
            IDs:Pop()
            Node=Loc1.Entry
        end
        if Loc2==0 then
            ENode=self.Data.End
        else
            ENode=Loc2.Entry
        end
        A1,B1,C1=Node:ContinueFToPairs(ENode)
        return function(t,v)
            local A,B=A1(t,v)
            while A~= nil and A~=0 do
                if A.Up == true then
                    IDs:Push(A.ID)
                elseif A.Up == false then
                    IDs:Pop()
                else
                    break
                end
                A,B=A1(t,v)
            end
            return A,B,IDs
        end,nil,nil
    end,
    EntryBPairs = function(self,Loc1,Loc2)
        local Node=nil
        local IDs=FunkyID({})
        local ENode=nil
        if self.Data.Start == 0 then
            return function(t,v) return nil end,nil,nil
        end
        if Loc1==0 then
            Node=self.Data.Start
        else
            Node=Loc1.Entry
        end
        if Loc2==0 then
            ENode=self.Data.End
        else
            IDs=Loc2.IDs:Clone()
            IDs:Pop()
            ENode=Loc2.Entry
        end
        A1,B1,C1=ENode:ContinueBToPairs(Node)
        return function(t,v)
            local A,B=A1(t,v)
            while A~= nil and A~=0 do
                if A.Up == false then
                    IDs:Push(A.ID)
                elseif A.Up == true then
                    IDs:Pop()
                else
                    break
                end
                A,B=A1(t,v)
            end
            return A,B,IDs
        end,nil,nil
    end,
    NextEntry = function(self,Loc)
        local LocCopy=0
        if Loc~=0 then
            LocCopy=NetBufferLocation(self,Loc.Entry,Loc.IDs:Clone())
            LocCopy.IDs:Pop()
        end
        for i,k,id in self:EntryFPairs(LocCopy,0) do
            if LocCopy~=0 and k==LocCopy.Entry then else
            if type(k)~="table" then print("WUT",k) return 0 end
            id:Push(k.ID) --UNDER NORMAL SITUATIONS DON'T DO THIS BRO, cus it isn't a copy... At least pop it after
            return NetBufferLocation(self,k,id)
            end
        end
        return 0
    end,
    BackEntry = function(self,Loc)
        local LocCopy=0
        if Loc~=0 then
            LocCopy=NetBufferLocation(self,Loc.Entry,Loc.IDs:Clone())
            LocCopy.IDs:Pop()
        end
        for i,k,id in self:EntryBPairs(0,LocCopy) do
            if LocCopy~=0 and k==LocCopy.Entry then else
            if type(k)~="table" then print("WUT",k) return 0 end
            id:Push(k.ID) --UNDER NORMAL SITUATIONS DON'T DO THIS BRO, cus it isn't a copy... At least pop it after
            return NetBufferLocation(self,k,id)
            end
        end
        return 0
    end,
    GetStart = function(self)
        return self:NextEntry(0)
    end,
    GetEnd = function(self)
        return self:BackEntry(0)
    end,
    ResolveSection = function(self,Loc1,Loc2,StepDown) --Screams in horror
        local Entry1=Loc1.Entry
        local Entry2=Loc2.Entry
        local Count1=#(Loc1.IDs.IDs)-1
        local Count2=#(Loc2.IDs.IDs)-1
        while Count1>Count2 and Entry1.Back~=0 and Entry1.Back.Up == true do --Like, the mental hoops to get here, without paper or testing.
            Entry1=Entry1.Back
            Count1=Count1-1
        end
        while Count1<Count2 and Entry2.Next~=0 and Entry2.Next.Up == false do --This is practice right? Not torture?
            Entry2=Entry2.Next
            Count2=Count2-1
        end
        if StepDown == nil or StepDown then
            for i=1,Count1 do -- I don't really need this do I? or do I?
                if Entry1.Back~=0 and Entry1.Back.Up == true then 
                    if Entry2.Next~=0 and Entry2.Next.Up == false then 
                        Entry1=Entry1.Back
                        Entry2=Entry2.Next
                        Count1=Count1-1
                        Count2=Count2-1
                    end
                end
            end
        end

        return Entry1,Entry2,Count1,Count2
    end,
    ToStringEntiries = function(self)
        local cats = "["
        for i,k in self.Data:Pairs() do
            if type(k)=="table" then
                cats=cats..tostring(k.ID).." "
            else
                cats=cats..tostring(k).." Not Table".." "
            end
        end
        return cats.."]"
    end,
    RemoveSection = function(self,Loc1,Loc2)
        --print(Loc1:ToString(),Loc2:ToString())
        local A,B,C,D = self:ResolveSection(Loc1,Loc2)
        local Ba,Ne
        if C~=D then
            Ba,Ne = self:BackEntry(Loc1),self:NextEntry(Loc2)
        end
        --print("RemoveSectionEntries ",A.ID,B.ID)
        --print("Entiries: ",self:ToStringEntiries())
        self.Data:RemoveSec(A,B)
        --print("Entiries",self:ToStringEntiries())
        if C>D then -- Oh edge case, why did I make it in a way that it would be an "edge case"
            self:AddBackIDs(Loc1.IDs,Loc2.IDs,C,D,Ba,true,false) 
        elseif C<D then
            self:AddBackIDs(Loc1.IDs,Loc2.IDs,C,D,Ne,false,true) 
        end
    end,
    RemoveEntry = function(self,Loc)
        self:RemoveSection(Loc,Loc)
    end,
    AddBackIDs = function(self,LIDs,RIDs,L,R,To,isAfter,isUp) -- *cries in edge cases*
        if isUp then
            if R>L then
                if isAfter then 
                    for i=1, R-L do
                        local ID=RIDs.IDs[R-i]
                        self.Data:AddAfter(To,NetBufferUDEntry(true,ID))
                    end
                else
                    for i=1, R-L do
                        local ID=RIDs.IDs[L+i-1]
                        self.Data:AddBefore(To,NetBufferUDEntry(true,ID))
                    end
                end
            end
        else
            if L>R then
                 if isAfter then 
                    for i=1, R-L do
                        local ID=LIDs.IDs[R+i-1]
                        self.Data:AddAfter(To,NetBufferUDEntry(false,ID))
                    end
                else
                    for i=1, R-L do
                        local ID=LIDs.IDs[L-i]
                        self.Data:AddBefore(To,NetBufferUDEntry(false,ID))
                    end
                end
            end
        end
    end,
    IsInSection = function(self,L,R,Locs)
        local Out={}

        for i,k in pairs(Locs) do
            if k.Seg~=self then break end
            if k:Compare(L) > -1 and k:Compare(R) < 1 then
                Out[#Out+1]=k
            end
        end
        return Out
    end,
    CopyEntriesToAfter = function(self,Start,End,To,AddIDs)
        local A,B,C,D = self:ResolveSection(Start,End,false)
        self:AddBackIDs(Start.IDs,End.IDs,C,D,To,true,true) 
        local ToID
        if To==0 then 
            ToID=self.Data.Start.ID
        else
            ToID=To.Entry.ID
        end
        if AddIDs then
            self.Data:AddAfter(To,NetBufferUDEntry(true,ToID))
            self.Data:AddSAfter(To,A,B)
            self.Data:AddAfter(To,NetBufferUDEntry(false,ToID))
        else
            self.Data:AddSAfter(To,A,B)
            
        end
        self:AddBackIDs(Start.IDs,End.IDs,C,D,To,true,false)
        return C,D,ToID
    end,
    CopyEntriesToBefore = function(self,Start,End,To,AddIDs)
        local A,B,C,D = self:ResolveSection(Start,End,false)
        self:AddBackIDs(Start.IDs,End.IDs,C,D,To,false,true) 
        local ToID
        if To==0 then 
            if self.Data.End == 0 then
                ToID=End.IDs:Last()
            else
                ToID=self.Data.End.ID
            end
        else
            ToID=To.Entry.ID
        end
        if AddIDs then
            self.Data:AddSBefore(To,NetBufferUDEntry(false,ToID))
            self.Data:AddSAfter(To,A,B)
            self.Data:AddSBefore(To,NetBufferUDEntry(true,ToID))
        else
            self.Data:AddSBefore(To,A,B)
        end
        self:AddBackIDs(Start.IDs,End.IDs,C,D,To,false,false)
        return C,D,ToID
    end,
    GetSEIDs = function(self,Seg)
        local S=self:GetStart()
        if S ~= 0 then
            return S.IDs,self:GetEnd().IDs
        end
        return nil,nil
    end,
    GetEIDs = function(self,Seg)
        local E=self:GetEnd()
        if E ~= 0 then
            return E.IDs
        end
        return nil
    end,
    NextShortestDistance = function(self,Clients,MaxLoc)
        local Shortest=nil
        local ShortestID=nil
        for i,k in pairs(Clients) do
            local Cli=self.Clients[k:GetID()]
            if Cli ~= nil and Cli.Next ~= 0 and Cli.Next ~= nil then
                if Shortest == nil then
                    ShortestID, Shortest = Cli.Next.Seg:GetStart()
                else
                    local ID,Seg = Cli.Next.Seg:GetStart()
                    if ShortestID:Compare(ID) == 1 then
                        ShortestID = ID
                        Shortest = Seg
                    end
                end
            end
        end
        if ShortestID ~= nil and MaxLoc.IDs:Compare(ShortestID) ~= 1 then
            Shortest = nil
        end
        return Shortest
    end
})