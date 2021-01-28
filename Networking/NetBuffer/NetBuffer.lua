--@include ../Base.lua
--@includedir ./
require("../Base.lua")
requiredir("./")
-- Could of abstracted entries into a template class, along with location.
-- Need a way to deal with removal of data, and the handling of whether or not to do so.

NetBuffer = ZClass(function(self)
    self.Clients={}
    self.Buffer=LinkedList()
    self.EntryID=0
    self.LocList={}
end,{ 
    AddToLocList = function(self,Loc)
        local S=tostring(Loc.Seg)
        if self.LocList[S] == nil then self.LocList[S]={} end
        self.LocList[S][tostring(Loc)]=Loc
    end,
    RemoveFromLocList = function(self,Loc)
        local S=tostring(Loc.Seg)
        if self.LocList[S] ~= nil then
            self.LocList[S][tostring(Loc)]=nil
            if next(self.LocList[S])==nil then
                self.LocList[S]=nil
            end
        end
    end,
    PreviousLocation = function(self,A)
        if A.Entry==A.Seg:GetStart().Entry then
            if A.Seg.Back ~= 0 then
                if A.Seg.Back.Data.End ~= 0 then
                    return A.Seg.Back:GetEnd()
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
            if A.Seg.Next ~= 0 then
                if A.Seg.Next.Data.Start ~= 0 then
                    return A.Seg:GetStart()
                end
            end
        else
            local BE=A.Seg:NextEntry(A)
            if BE ~= 0 then
                return BE
            end
        end
        return nil
    end,
    CloneClient = function(self,CClient,NClient)
        NClient = CClient:Cloneish(NClient)
        for i,k in NClient.Segments:Pairs() do
            k.Seg.Clients[NClient:GetID()]=k
        end
        return NClient 
    end,
    RemoveClient = function(self,Client)
        if Client.Segments == nil then Client = self.Clients[Client:entIndex()] end
        if Client==nil then return nil end
        local Ents=NBCliList(Client).List
        for i,k in Client.Segments:Pairs() do
            self:RemoveClientsFromSeg(k,Ents)
        end
        self.Clients[Client:GetID()]=nil 
        return Client
    end,
    RemoveSegment = function(self,Seg)
        if Seg.Back ~= 0 and Seg.Next ~= 0 and Seg.Back:HasAllClientsInList(Seg.Next.Clients) then
            self:CopyEntries(NSeg,0,true,Seg:GetStart(),Seg.Next:GetEnd(),false)
            self.Buffer:Remove(Seg.Next)
        end
        
        self.Buffer:Remove(Seg)
    end,
    RemoveClientsFromSeg = function(self,Seg,Clients)
        Seg:RemoveClients(Clients)
        if Seg.ClientCount == 0 then
            self:RemoveSegment(Seg)
        else
            local NSeg = self:FindBackwardDuplicateSeg(Seg,Seg.Clients)
            if NSeg~=nil then
                self:CopyEntries(NSeg,0,true,Seg:GetStart(),Seg:GetEnd(),Seg.Back ~= NSeg)
                for i,k in pairs(Seg.Clients) do 
                    k.Client.Segments:Remove(k)
                end
                self:RemoveSegment(Seg)
            end
        end
    end,
    FindBackwardDuplicateSeg2 = function(self,SClients,Clients)
        local DupSeg=0
        local Count=0
        for i,k in pairs(Clients) do 
            Count=Count+1
            local B=nil
            if SClients==0 then
                B=self.Clients[i].Segments.End
            else    
                if SClients[i] == nil then return nil end
                B=SClients[i].Back
            end
            if DupSeg==0 then
                if B == 0 then return nil end
                DupSeg=B.Seg
            else
                if B == 0 then return nil end
                if DupSeg~=B.Seg then
                    return nil
                end
            end
        end
        if DupSeg~=0 then
            local S=0
            for i,k in pairs(DupSeg.Clients) do
                S=S+1
            end 
            if S == Count then
                return DupSeg 
            end
        end 
        return nil
    end,
    FindBackwardDuplicateSeg = function(self,Seg,Clients)
        if Seg==0 then 
            return NetBuffer.FindBackwardDuplicateSeg2(self,0,Clients) 
        end
        return NetBuffer.FindBackwardDuplicateSeg2(self,Seg.Clients,Clients)
    end,
    FindForwardDuplicateSeg2 = function(self,SClients,Clients)
        local DupSeg=0
        local Count=0
        for i,k in pairs(Clients) do 
            Count=Count+1
            local B=nil
            if SClients==0 then
                B=self.Clients[i].Segments.Start
            else    
                if SClients[i] == nil then return nil end
                B=SClients[i].Next
            end
            if DupSeg==0 then
                if B == 0 then return nil end
                DupSeg=B.Seg
            else
                if B == 0 then return nil end
                if DupSeg~=B.Seg then
                    return nil
                end
            end
        end
        if DupSeg~=0 then
            local S=0
            for i,k in pairs(DupSeg.Clients) do
                S=S+1
            end 
            if S == Count then
                return DupSeg 
            end
        end 
        return nil
    end,
    FindForwardDuplicateSeg = function(self,Seg,Clients)
        if Seg==0 then 
            return NetBuffer.FindForwardDuplicateSeg2(self,0,Clients) 
        end
        return NetBuffer.FindForwardDuplicateSeg2(self,Seg.Clients,Clients)
    end,
    CopyEntries = function(self,Seg,To,IsBefore,Start,End,UpdateIDs) -- This might be bugged or this might not be bugged, who knows.
        local A,B,ToID
        if IsBefore then
            A,B,ToID=Seg:CopyEntriesToBefore(Start,End,To,UpdateIDs)
        else
            A,B,ToID=Seg:CopyEntriesToAfter(Start,End,To,UpdateIDs)
        end
        if Start.Seg ~= nil and Start.Seg ~= 0 then
            local SegID=tostring(Start.Seg)
            local CurSegID=tostring(Seg)
            local Locs = self.LocList[SegID]
            if Locs~=nil then
                local Cats=""
                for i,k in pairs(Locs) do
                    Cats=Cats..k:ToString().." "
                end
                --print("HEY MOVE LOC?",next(Locs),Cats)
                for i,k in pairs(Start.Seg:IsInSection(Start,End,Locs)) do
                    --print("Operation Move Locs",k:ToString())
                    k.Seg=Seg
                    local N
                    if To==0 then N={} else 
                        N=To.IDs:Clone().IDs 
                        N[#N]=nil 
                    end
                    if UpdateIDs then N[#N+1] = ToID end
                    for i2=math.min(A,B),#(k.IDs.IDs) do
                        N[#N+1]=k.IDs.IDs[i2]
                    end
                    Locs[tostring(k)]=nil
                    if next(Locs)==nil then self.LocList[SegID]=nil end
                    k.IDs=FunkyID(N)
                    --print("MOVED ",k:ToString())
                    if self.LocList[CurSegID]==nil then self.LocList[CurSegID]={} end
                    self.LocList[CurSegID][tostring(k)]=k
                end
            end
        end
    end,
    RemoveFromSeg = function(self,Clients,Seg,From,To) -- This will break preexisting Location Vars! So don't store em!
        if next(Clients) == nil then return end
        if not Seg:HasClients(Clients) then return end
        
        local isS = From == 0 or From.Entry==Seg:GetStart().Entry
        local isE = To == 0 or To.Entry==Seg:GetEnd().Entry
        --print("RemoveFromSeg",From:ToString(),To:ToString(),isS,isE,NBCliList(Clients):ToString())
        if isS and isE then
            self:RemoveClientsFromSeg(Seg,Clients)
            return
        end 
        if not Seg:HasAllClientsInList2(Clients) then
            --print("Not every one of those clients is in here..")
            local NSeg,SSeg
            local PartT=NBCliList(CopyTable(Seg.Clients)):Remove(Clients).List
            if not isE then
                NSeg = self:FindBackwardDuplicateSeg(Seg,PartT)
            end
            if isE then
                NSeg = self:FindForwardDuplicateSeg(Seg,PartT)
            end
            if NSeg == nil then
                NSeg = NetBufferSeg(PartT)
                SSeg = nil
                for i,k in NBCliList(NSeg.Clients):Pairs() do
                    local ClientSeg=NetBufferClientSeg(k.Client,NSeg) 
                    NSeg.Clients[i]=ClientSeg
                end
                if not isE then
                    self.Buffer:AddBefore(Seg,NSeg)
                    for i,k in NBCliList(Seg):PairsAnd(NSeg) do
                        k.Client.Segments:AddBefore(k,NSeg.Clients[i])
                    end
                elseif isE then
                    self.Buffer:AddAfter(Seg,NSeg)
                    for i,k in NBCliList(Seg):PairsAnd(NSeg) do
                        k.Client.Segments:AddAfter(k,NSeg.Clients[i])
                    end
                end
            end
            if not isE and not isS then
                SSeg = self:FindBackwardDuplicateSeg(Seg,Seg.Clients)
                if SSeg ~= nil then
                    SSeg = NetBufferSeg(CopyTable(Seg.Clients))
                    self.Buffer:AddBefore(NSeg,SSeg)
                    for i,k in pairs(Seg.Clients) do
                        local ClientSeg=NetBufferClientSeg(k.Client,NSeg)
                        Seg.Clients[k.Client:GetID()]=ClientSeg
                        if NSeg.Clients[i] == nil then
                            k.Client.Segments:AddBefore(k,ClientSeg)
                        else
                            k.Client.Segments:AddBefore(NSeg.Clients[i],ClientSeg)
                        end
                    end
                end
            end

            local UpdateIDs=false
            if isE then UpdateIDs = Seg.Next ~= NSeg else UpdateIDs = Seg.Back ~= NSeg  end 
            if not isE and not isS then
                UpdateIDs = NSeg.Back ~= SSeg
                local St=Seg:GetStart()
                self:CopyEntries(SSeg,0,true,St,Seg:BackEntry(From),UpdateIDs)
                Seg:RemoveSection(St,To)
            else
                Seg:RemoveSection(From,To)
            end
            self:CopyEntries(NSeg,0,not isE,From,To,UpdateIDs)

        else
            --print("Yeah I got all the clients in here.")
            Seg:RemoveSection(From,To)
        end
    end,
    ForeachSegWithClients = function(self,Clients,FromLoc,ToLoc,Foreach)
        if FromLoc.Seg == ToLoc.Seg then
            Foreach(FromLoc.Seg,FromLoc,ToLoc)
        else
            local Cur=FromLoc.Seg:NextShortestDistance(Clients,ToLoc)
            if Foreach(FromLoc.Seg,FromLoc,FromLoc.Seg:GetEnd()) == false then return end
            while Cur ~= ToLoc.Seg and Cur ~= nil do
                if Foreach(Cur,Cur:GetStart(),Cur:GetEnd()) == false then return end
                Cur=FromLoc.Seg:NextShortestDistance(Clients,ToLoc)
                if Cur == nil then
                    print("BAAAD ERROR")
                end
            end
            Foreach(ToLoc.Seg,ToLoc.Seg:GetStart(),ToLoc)
        end
    end,
    ForeachSpanInLocMap = function(self,LocMap,ForEach) -- Really, I just made this to future proof things ya know? This ALSO modifies the locmap...
        local Arr={} -- THIS SORT IS BAAAD, but I mean.. ugh, whatever, this is assuming that number of entries will be a bit larger than Locations
        if LocMap==nil then return end
        if next(LocMap.Locations)==nil then return end
        for i,k in pairs(LocMap.Locations) do
            Arr[#Arr+1]=k
        end
        table.sort(Arr,function(A,B) return A[1]:Compare(B[1]) == -1 end)
        --Cats = ""
        --for i,k in pairs(Arr) do
        --    Cats=Cats.."N "..i..": "..LocMap:ToStringNode(k).." "
        --end
        --print("SortedLocMap: "..Cats)
        local Cur=Arr[1][1]
        local ClientsN={}
        local Clients={}
        local ClientsNum=0
        local LChange=Cur
        for i,k in pairs(Arr[1][2]) do 
            ClientsN[k:GetID()]=1 
            Clients[k:GetID()]=k
            ClientsNum=ClientsNum+1
        end
        if next(Arr[1][4]) ~= nil then if ForEach(Arr[1][4],Arr[1][1],Arr[1][1])==false then return end end
        for i,Cur in pairs(Arr) do
            if i~=1 then 
                local Changed=false
                for i,k in pairs(Cur[2]) do 
                    local ID=k:GetID()
                    if Clients[ID]==nil then
                        if Changed==false then
                            if ClientsNum>0 then if ForEach(Clients,LChange,Cur[1])==false then return end end
                            LChange=Cur[1]
                            Changed=true
                        end
                        Clients[ID]=k
                        ClientsN[ID]=1
                        ClientsNum=ClientsNum+1
                    else
                        ClientsN[ID]=ClientsN[ID]+1
                    end 
                end
                if next(Cur[4]) ~= nil then
                    if ForEach(Cur[4],Cur[1],Cur[1])==false then return end
                end
                for i,k in pairs(Cur[3]) do 
                    local ID=k:GetID()
                    if Clients[ID]~=nil then
                        if Changed==false then
                            if ClientsNum>0 then  if ForEach(Clients,LChange,Cur[1])==false then return end end
                            LChange=Cur[1]
                            Changed=true
                        end
                        ClientsN[ID]=ClientsN[ID]-1
                        if ClientsN[ID]==0 then
                            Clients[ID]=nil
                            ClientsN[ID]=nil
                        end
                        ClientsNum=ClientsNum-1
                    end 
                end
            end
        end
        
    end,
    RemoveFromQueue = function(self,Clients,FromLoc,ToLoc)
        self:ForeachSegWithClients(Clients,FromLoc,ToLoc,function(Seg,From,To) 
            self:RemoveFromSeg(Clients,Seg,From,To)
        end)
    end,
    RemoveWithMap = function(self,Map)
        self:ForeachSpanInLocMap(Map,function(A,B,C)
            self:RemoveFromQueue(A,B,C)
        end)
    end,
    AddToQueue = function(self,To,Data)
        local Destinations={}
        if To.Ent == nil then
            Destinations=To
        else
            Destinations={To}
        end
        local Clis={}
        for i,k in pairs(Destinations) do
            local ID=k:GetID()
            if self.Clients[ID] == nil then
                self.Clients[ID] = k
            end
            Clis[ID]=k
        end
        local LatestSeg=self:FindBackwardDuplicateSeg2(0,Clis)
        local Seg
        
        if LatestSeg==nil then
            Seg=NetBufferSeg({})
            self.Buffer:AddBefore(0,Seg)
            for i,k in pairs(Destinations) do
                local ClientSeg=NetBufferClientSeg(k,Seg)
                Seg.Clients[k:GetID()]=ClientSeg
                Seg.ClientCount=Seg.ClientCount+1
                k.Segments:AddBefore(0,ClientSeg)
            end
        else
            Seg=LatestSeg
        end
        local EntryList = LinkedList()
        local S=self.EntryID+1
        for i,k in pairs(Data) do
            local Entry = NetBufferEntry(k[1],k[2])
            self.EntryID=self.EntryID+1
            Entry.ID = self.EntryID
            EntryList:AddBefore(0,Entry)
        end
        local Start=Seg:GetEnd()
        self:CopyEntries(Seg,0,true,NetBufferLocation(nil,EntryList.Start,{S}),NetBufferLocation(nil,EntryList.End,{self.EntryID}),Seg~=self.Buffer.End)
        if Start==0 then Start=Seg:GetStart() end
        local End = Seg:GetEnd()
        if Start.Entry ~= End.Entry then
            Start = self:NextLocation(Start)
        end
        
        return Start,End
    end
})