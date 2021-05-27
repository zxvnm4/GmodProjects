--@name
--@author Zxvnm4
--@shared
--@model models/spacecode/sfchip_medium.mdl
--@include Base.lua
--@include NetObjHandler.lua
--@include NetworkManager.lua
--@includedir NetBuffer
require("Base.lua")
require("NetObjHandler.lua")
require("NetworkManager.lua")
requiredir("NetBuffer")

BasicNetHandler = ZClass(function(self)
    
end,{
    Send = function(self,k)
        net.writeUInt(k,8) --Type
        return self:GetSize(),true
    end
    ,GetSize = function(self,MaxSize)
        return 1
    end
    ,Read = function(self)
        return net.readUInt(8)
    end
})

if CLIENT then
    local Count2=0
    Play.Hooks:CreateHook("KeyPress","BackButtonKPress",function(Data) 
        net.start("Spooky")
        Count2=Count2+1
        BasicNetHandler:Send(Count2)
        net.send()
    end)
    
    local Wut = NetworkSenderSendHandler(function() 
        local Count=0
        while true do 
            Count=Count+1
            if coroutine.yield(Count,BasicNetHandler) == false then return nil end
        end 
    end)
    net.receive("NetworkSender Whoah",function(len)
        local ID,Data = Wut:Read()
        print("DATA ID!",ID)
        for i,k in pairs(Data) do
            print("First Data!",k)
        end
        net.start("NetworkSender Whoah")
        NetConfirmedSendHandler:Send(ConfirmedSendPacket(ID,#Data)) -- Add to send queue later.
        net.send()
    end)
    net.start("NetworkSenderNewClient")
    net.send()
    --NetConfirmedSendHandlerClass().Read()
    
    
    
else
    NetSender = NetworkSender("Whoah")
    
    if true then
        NetSender:Init()
        net.receive("NetworkSenderNewClient",function(len,ply)
            T=NetSender:AddClient(ply)
            print("New Client:",ply)
        end)
        net.receive("Spooky",function(len,ply)
            local Data = BasicNetHandler:Read(Count2)
            NetSender:Add({{BasicNetHandler,Data}},{},true)
            for i,k in NetSender.NB.Buffer:Pairs() do
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
            print("AllClients:")
            for i,k in pairs(NetSender.Clients) do
                if not k.CurrentSendingLocation:Empty() then
                    print("  Client: ",k.Ent,k.SendingLength,k.SendingLeft,"Cur: "..loctostring(k.CurrentSendingLocation),"End: "..loctostring(k.EndOfSendingLocation))
                end
            end
        end)
    end
    
    
    
    
    
    
    
    
end