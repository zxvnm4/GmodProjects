--@include Base.lua
--@include NetObjHandler.lua
--@includedir NetBuffer
require("Base.lua")
require("NetObjHandler.lua")
requiredir("NetBuffer")

--This is an example mate!
--Well sorta...

NetworkReciever = ZClass(function(self,ID) 
    self.ID=ID
end,{
    NetSenderRecieve = function(self,len)
        local ID,Data = Wut:Read()
        print("DATA ID!",ID)
        for i,k in pairs(Data) do
            print("First Data!",k)
        end
        net.start("NetworkSender Whoah")
        NetConfirmedSendHandler:Send(ConfirmedSendPacket(ID,#Data)) -- Add to send queue later.
        net.send()
    end

})



NetworkSenderClient = ZClass(function(self,Ent,Start)
    NetBufferClient.const(self,Ent)
    self.CurrentSendingLocation=Start
    self.EndOfSendingLocation=Start
    self.SendingLength=0
    self.SendingLeft=0
    self.Active=false
end,NetBufferClient,{
    Cloneish = function(self,New)
        New.CurrentSendingLocation=self.CurrentSendingLocation
        New.EndOfSendingLocation=self.EndOfSendingLocation
        New.SendingLength=self.SendingLength
        New.SendingLeft=self.SendingLeft
        return NetBufferClient.Cloneish(self,New)
    end,
    ChangeCurrentSendingLocation = function(self,NB,NLoc)
        local CSL=self.CurrentSendingLocation
        if NLoc:Equals(CSL) then return end
        NLoc=NLoc:Clone()
        self.CurrentSendingLocation=NLoc
        if CSL == self.EndOfSendingLocation then return end
        if not CSL:Empty() then NB:RemoveFromLocList(CSL) end
        if not NLoc:Empty() then NB:AddToLocList(NLoc) end
    end,
    ChangeEndOfSendingLocation = function(self,NB,NLoc)
        local EOSL=self.EndOfSendingLocation
        if NLoc:Equals(EOSL) then return end
        NLoc=NLoc:Clone()
        self.EndOfSendingLocation=NLoc
        if EOSL == self.CurrentSendingLocation then return end
        if not EOSL:Empty() then 
            --print("RemovedFrom: "..tostring(self:GetID()).." "..tostring(EOSL)) 
            NB:RemoveFromLocList(EOSL) 
        end
        if not NLoc:Empty() then 
            --print("AddedTo: "..tostring(self:GetID()).." "..tostring(NLoc)) 
            NB:AddToLocList(NLoc) 
        end
    end,
    TopNodeAdd = function(self,LL,SLoc,ELoc,Count)
        if self.CurrentSendingLocation:Empty() then
            self:ChangeCurrentSendingLocation(LL,SLoc)
            self:ChangeEndOfSendingLocation(LL,ELoc)
            self.SendingLength=Count
            self.SendingLeft=self.SendingLeft-Count
        else
            if self.SendingLeft ~= 0 then
                local Prev = self:PreviousLocation(SLoc) 
                if Prev ~= nil and Prev:Equals(self.EndOfSendingLocation) then
                    self.SendingLength=self.SendingLength+Count
                    self.SendingLeft=self.SendingLeft-Count
                    self:ChangeEndOfSendingLocation(LL,ELoc)
                end
            end
        end
    end,
    MoveEndOfSendingLocBySendingLeft = function(self,LL,Num)
        if self.SendingLeft==0 then return end
        if Num==nil then Num = self.SendingLeft else Num = math.min(self.SendingLeft,Num) end
        if Num==0 then return end
        local CurLoc=self.CurrentSendingLocation:Clone()
        local NAmount=0
        for i=1, Num do
            local Nx=self:NextLocation(CurLoc)
            if Nx != nil then
                CurLoc = Nx
                NAmount=NAmount+1
            else
                break
            end
        end
        self.SendingLength=self.SendingLength+NAmount
        self.SendingLeft=self.SendingLeft-NAmount
        self:ChangeEndOfSendingLocation(LL,CurLoc)
    end,
    ReacquireEndOfSendingLoc = function(self,LL,Max)
        if self.Segments.Start == 0 then
            self:ChangeCurrentSendingLocation(LL,NetBufferLocation(nil,nil,{}))
            self:ChangeEndOfSendingLocation(LL,NetBufferLocation(nil,nil,{}))
            self.SendingLength=0
            self.SendingLeft=Max
            return
        end
        local NLoc = self.Segments.Start.Seg:GetStart()
        self:ChangeCurrentSendingLocation(LL,NLoc)
        self.SendingLength=1
        self.SendingLeft=Max-1
        self:MoveEndOfSendingLocBySendingLeft(LL)
    end,
    StEnCoGet = function(self)
        local Start,End,Count = self.CurrentSendingLocation,self.EndOfSendingLocation,self.SendingLength
        return Start,End,Count
    end,
    SendOperation = function(self,LL,Max)
        if Max==0 then return end
        if self.SendingLeft~=0 and Max~=self.SendingLength then 
            self.SendingLeft=self.SendingLeft-self.SendingLength
            self:MoveEndOfSendingLocBySendingLeft(LL,Max)
        end
        if self.Segments.End.Seg:GetEnd().Entry == self.EndOfSendingLocation.Entry then
            self:ChangeCurrentSendingLocation(LL,NetBufferLocation(nil,nil,{}))
            self:ChangeEndOfSendingLocation(LL,NetBufferLocation(nil,nil,{}))
            self.SendingLength=0
        else
            self:ChangeCurrentSendingLocation(LL,self:NextLocation(self.EndOfSendingLocation))
            self.SendingLength=1
            self:MoveEndOfSendingLocBySendingLeft(LL)
        end
    end
})


NetworkSenderSendHandler = ZClass(function(self,Func)
    
    local Gen = CreateGenerator(Func)
    local FirstData,FirstNetObj = Gen(false)
    Req = function()
        return CreateGenerator(function() return FirstData,FirstNetObj end),nil,nil
    end

    NotReq= function()  
        local Gen=CreateGenerator(Func)
        local First = Gen()
        self.Generators[#self.Generators+1]=Gen
        return Gen,nil,nil
    end
    self.Generators={}
    NetObjHandler.const(self,Req,NotReq)
end,NetObjHandler,{
    Send = function(self,ID)
        net.writeUInt(ID,32)
        local Out,Out2 = NetObjHandler.Send(self,function(i) return i end)
        for i,k in pairs(self.Generators) do k(false) end
        self.Generators = {}
        return Out+4,Out2
    end,
    GetData = function(self,Max)
        if Max-4<0 then return false end
        local Out = NetObjHandler.GetData(self,Max-4)
        for i,k in pairs(self.Generators) do k(false) end
        self.Generators = {}
        if Out==false then return false end
        return Out+4
    end,
    Read = function(self,Data)
        local ID = net.readUInt(32)
        local Out = NetObjHandler.Read(self,Data)
        for i,k in pairs(self.Generators) do k(false) end
        self.Generators = {}
        return ID,Out
    end
})

ConfirmedSend = ZClass(function(self,Start,Count,Clients) 
    self.Start=Start
    self.Count=Count
    self.Clients=Clients
end,{})

ConfirmedSendPacket = ZClass(function(self,ID,Count) 
    self.ID=ID
    self.Count=Count
end,{})

NetConfirmedSendHandlerClass = ZClass(function(self)
    self.Bytes=32/8
end,{
    Send = function(self,k)
        net.writeUInt(k.ID,self.Bytes*8)
        net.writeUInt(k.Count,self.Bytes*8)
        return self.Bytes+self.Bytes
    end
    ,GetSize = function(self,MaxSize)
        return self.Bytes+self.Bytes
    end
    ,Read = function(self)
        local ID=net.readUInt(self.Bytes*8)
        local Count=net.readUInt(self.Bytes*8)
        return ConfirmedSendPacket(ID,Count)
    end
})
NetConfirmedSendHandler=NetConfirmedSendHandlerClass()


NetworkSender = ZClass(function(self,ID)
    self.NB = NetBuffer()
    self.Clients = {}
    self.NB.Clients = self.Clients
    self.Clients[-1] = NetworkSenderClient(nil,NetBufferLocation(nil,nil,{}))
    
    self.ToBeConfirmedSends={}
    self.ConfirmedClients={}
    self.RemovedClients={}
    self.ToBeConfirmedIDs=0 -- Convert to a different system later, this has an expiry date.
    self.MaxSendingLen=100
    self.Clients[-1].SendingLeft=self.MaxSendingLen
    self.RemoveBuffer=NetBufferEntLocationMap()
    self.ID = ID
end,{ 
    AddClient = function(self,Client)
        local ID = Client:entIndex()
        if self.Clients[ID] == nil then
            self.Clients[ID]=self.NB:CloneClient(self.Clients[-1],NetworkSenderClient(Client))
            self.Clients[ID].Active = true
            self.Clients[ID].SendingLeft=self.MaxSendingLen
        end
        return self.Clients[ID]
    end,
    RemoveClient = function(self,Client)
        local Cli = self.NB:RemoveClient(Client)
        if Cli~=nil then
            self.ConfirmedClients[Cli:GetID()]=nil
            self.RemovedClients[Cli:GetID()]=Cli
            Cli.Active = false
            return true
        end
        return false
    end,
    GetClientActive = function(self,Client)
        local Cli
        if Client.EndOfSendingLocation ~= nil then Cli=Client else Cli=self.Clients[Client:entIndex()] end
        if Cli ~= nil then
            return Cli.Active
        end
    end,
    SetClientActive = function(self,Client,Active)
        if Client ~= nil then
            local Cli
            if Client.EndOfSendingLocation ~= nil then Cli=Client else Cli=self.Clients[Client:entIndex()] end
            if Cli ~= nil then
                if not Cli.Active and Active then
                    Cli:MoveEndOfSendingLocBySendingLeft(self.NB)
                end
                Cli.Active = Active
            else
                self:AddClient(Client)
            end
        end
    end,
    Add = function(self,Data,ClientList,Inv)
        local NList={}

        if ClientList.entIndex == nil then 
            for i,k in pairs(ClientList) do 
                NList[k:entIndex()]=self.Clients[k:entIndex()] 
            end 
        else 
            NList[ClientList:entIndex()]=self.Clients[ClientList:entIndex()] 
        end
        local CL = NBCliList(NList,Inv):ResolveInversion(self.Clients)
        local S,E = self.NB:AddToQueue(CL.List,Data)
        for i,k in CL:Pairs() do
            k:TopNodeAdd(self.NB,S,E,#Data)--self.MaxSendingLen
        end 
        return S,E
    end,
    ReceiveConfirmed = function(self,Client)
        if Client==owner() then return end
        print("Got yo back jack",Client)
        local NetConfirmedPacket=NetConfirmedSendHandler:Read()
        local CID=Client:entIndex()
        local Client=self.Clients[CID]
        if Client == nil then print("ERROR: Client doesn't exist in Clients (HOW?) In ReceiveConfirmed") return end
        local ID=NetConfirmedPacket.ID
        local ConfirmedSend = self.ToBeConfirmedSends[ID]
        if ConfirmedSend == nil then print("ERROR: ConfirmedSend doesn't exist in ToBeConfirmedSends (How???) In ReceiveConfirmed") return end
        if ConfirmedSend.Clients[CID] == nil then print("ERROR: ConfirmedSend doesn't have client Registered In ReceiveConfirmed") return end
        NBCliList(ConfirmedSend.Clients):Remove(Client)
        if next(ConfirmedSend.Clients)==nil then self.ToBeConfirmedSends[ID] = nil print("Confirmed Send Removed") end
        
        local Start,Count=ConfirmedSend.Start,ConfirmedSend.Count
        local SuccessCount=NetConfirmedPacket.Count
        if SuccessCount==0 then print("ERROR: SuccessCount==0 In ReceiveConfirmed ") return end
        if SuccessCount > Count then print("ERROR: SuccessCount("..tostring(SuccessCount)..") > Count("..tostring(Count)..") In ReceiveConfirmed ") return end
        if SuccessCount < 0 then print("ERROR: SuccessCount("..tostring(SuccessCount)..") < 0 (Seriously...) in ReceiveConfirmed") return end
        local SuccessLoc=Start:Clone() 
        if SuccessCount~=1 then
            for i=1, SuccessCount-1 do
                SuccessLoc=Client:NextLocation(SuccessLoc)
            end
        end
        local Ents=NBCliList(Client).List
        self.RemoveBuffer:AddSec(Ents,Start,SuccessLoc)  -- STUPID STUPID STUPID STUPID STUPID STUPID I can see soo much room for error...
        self.ConfirmedClients[CID] = Client
    end,
    SendBacklog2 = function(self,MaxSize)
        local SendMap = NetBufferEntLocationMap()
        local Active=false
        for i,k in pairs(self.Clients) do
            local A,B,C = k:StEnCoGet()
            if C~=0 and k.Active and not A:Empty() and not B:Empty() then
                Active=true
                local Ents=NBCliList(k).List
                SendMap:AddSec(Ents,A,B)
            end
        end
        local Size=0
        if Active then
            print("SendingBackLog")
        end
        self.NB:ForeachSpanInLocMap(SendMap,function(Cl,S,E)
            net.start("NetworkSender "..self.ID)
            
            local Func=function()
                self.NB:ForeachSegWithClients(Cl,S,E,function(Seg,F,T)
                    for i,k in Seg:EntryFPairs(F,T) do
                        if coroutine.yield(k.Data,k.NetObj) == false then return false end
                    end
                end)
                return nil
            end
            local TotalCount=0
            local Gen=CreateGenerator(Func)
            while Gen()~=nil do 
                TotalCount=TotalCount+1
            end
            local Bytes,Finished = 0, false
            local Sender = NetworkSenderSendHandler(Func,TotalCount)
            if Sender:GetSize(MaxSize-Size) ~= 0 then
                Bytes,Finished=Sender:Send(self.ToBeConfirmedIDs+1)
                if Bytes~=0 then
                    Size = Size + Bytes -- I might not even need GetSize anymore huh.
                    for i,k in pairs(Cl) do
                        k:SendOperation(self.NB,Sender.ActuallySent+1)
                    end
                    local Clients={}
                    local Sent=""
                    for i,k in pairs(Cl) do
                        Clients[#Clients+1]=k.Ent
                        Sent=Sent..tostring(k.Ent).." "
                    end
                    print("I just sent you",Sent)
                    net.send(Clients)
                    self.ToBeConfirmedIDs=self.ToBeConfirmedIDs+1 
                    self.ToBeConfirmedSends[self.ToBeConfirmedIDs]=ConfirmedSend(S,Sender.ActuallySent+1,CopyTable(Cl))
                end
            end
            if not Finished then
                return false
            end
        end)
    end,
    PrintStuff = function(self)
        for i,k in self.NB.Buffer:Pairs() do
            print("Seg:",k.ClientCount,k)
            UpdateSegMap(k)
            for i2,k2 in pairs(k.Clients) do
                print("  Client: ",i2,k2.Client.Ent)
                for i3,k3 in k2.Client.Segments:Pairs() do
                    print("    Segment:",k3.Seg,k3.Client)
                end 
            end
            for i2,k2 in k.Data:Pairs() do
                print("  Entry:",k2.ID,k2.Data)
            end 
        end
        self:PrintAllClients()
    end,
    PrintAllClients = function(self)
        print("AllClients:")
        for i,k in pairs(self.Clients) do
            if not k.CurrentSendingLocation:Empty() then
                print("  Client: ",k.Ent,k.SendingLength,k.SendingLeft,"Cur: "..loctostring(k.CurrentSendingLocation),"End: "..loctostring(k.EndOfSendingLocation))
            end
        end
    end,
    DealWithCompleted = function(self)
        local Wut=false
        --if not self.RemoveBuffer:Empty() then
        --    print("DealingWithCompleted")
        --end
        self.NB:ForeachSpanInLocMap(self.RemoveBuffer,function(A,B,C)
            --print(B:ToString(),C:ToString())
            NBCliList(A):Remove(self.RemovedClients)
            self.NB:RemoveFromQueue(A,B,C)
            Wut=true
        end)
        self.RemoveBuffer=NetBufferEntLocationMap()
        if Wut==true then
            print("DealingWithCompleted")
            self:PrintStuff()
        end
        local Out=""
        for i,k in pairs(self.ConfirmedClients) do
            Out=Out..tostring(k.Ent).." "
            k:ReacquireEndOfSendingLoc(self.NB,self.MaxSendingLen)
        end
        if next(self.ConfirmedClients)~=nil then print("Completed Stuff",Out) end
        --if Wut==true then
        --    self:PrintAllClients()
        --end
        self.ConfirmedClients={}
        self.RemovedClients={}
    end,
    SendRecieveTick = function(self,MaxBytes)
        
        self:DealWithCompleted()
        self:SendBacklog2(MaxBytes)
    end,
    Init = function(self)
        timer.create( "Ticky", 1, 0, function()
            if quotaTotalAverage()>=(quotaMax()*0.7) then return end
            self:SendRecieveTick(net.getBytesLeft())
        end)
        net.receive("NetworkSender "..self.ID,function(len,ply) 
            self:ReceiveConfirmed(ply)
        end)
        hook.add("PlayerDisconnected", "NetworkSenderPD "..self.ID, function(ply) 
            self:RemoveClient(ply)
        end)
    end
})