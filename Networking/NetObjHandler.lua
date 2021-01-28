--@include Base.lua

require("Base.lua")

local SendCounts=0
local SendMax=100
function SendChecker()
    return (quotaTotalAverage() < (quotaMax()*0.7))
end
--    if quotaTotalAverage()>=(quotaMax()*0.7) or SendCounts >= SendMax then 
--        return false
--    else
--        SendCounts = SendCounts + 1
--        return true
--    end

--Uhh, Remove GetSize, I don't think you need it dude.

NetObjHandler = ZClass(function(self,RequiredObjs,NotRequiredObjs)
    self.TotalSent=0
    self.ActuallySent=0
    self.RequiredObjs=RequiredObjs
    self.NotRequiredObjs=NotRequiredObjs
end,{
    Send = function(self,Data)
        local Count=self.TotalSent
        self.ActuallySent=0
        local ActualB=0
        local Actual=0
        local DoneAll=true
        local FailedOne=false
        if type(Data)=="function" then
            for i,k in self.RequiredObjs() do
                local Bytes,Finished=k:Send(Data(i))
                ActualB=ActualB+Bytes
            end
            if self.NotRequiredObjs==nil then return 0 end
            if Count==0 or not SendChecker() then net.writeBool(false) DoneAll=false return 0 end
            for i,k in self.NotRequiredObjs() do
                net.writeBool(true)
                
                local Bytes,Finished=k:Send(Data(i))
                ActualB=ActualB+Bytes+1
                Count=Count-1
                Actual=Actual+1
                if not Finished then 
                    DoneAll=false 
                    FailedOne=true
                    break 
                end
                if Count==0 then DoneAll=false break end
                if not SendChecker() then 
                    DoneAll=false
                    break
                end
            end
        else
            for i,k in self.RequiredObjs() do --Repeat but different, not because it is line efficient but because it is CPU efficient.
                local Bytes,Finished=k:Send(Data[i])
                ActualB=ActualB+Bytes
            end
            if self.NotRequiredObjs==nil then return 0 end
            if Count==0 or not SendChecker() then net.writeBool(false) DoneAll=false return 0 end
            for i,k in unpack(self.NotRequiredObjs()) do
                net.writeBool(true)
                local Bytes,Finished=k:Send(Data[i])
                ActualB=ActualB+Bytes+1
                Count=Count-1
                Actual=Actual+1
                if not Finished then 
                    DoneAll=false 
                    FailedOne=true
                    break 
                end
                if Count==0 then DoneAll=false break end
                if not SendChecker() then 
                    DoneAll=false
                    break
                end
            end
        end
        net.writeBool(false)
        if FailedOne then
            print("FAILED ONE!!")
            Actual=Actual-1 -- This... Might be a baaad idea
        end
        self.ActuallySent = Actual
        return ActualB+1, DoneAll
    end,
    Read = function(self,Out)
        if type(Out) == "function" then
            for i,k in self.RequiredObjs() do
                Out(i,k:Read(Out(i)))
            end
            for i,k in self.NotRequiredObjs() do
                if net.readBool() then
                    Out(i,k:Read(Out(i)))
                else
                    return Out
                end
            end
        else
            if type(Out) ~= "table" then --Repeat but different, not because it is line efficient but because it is CPU efficient.
                Out = {}
            end
            for i,k in self.RequiredObjs() do
                Out[i] = k:Read()
            end
            for i,k in self.NotRequiredObjs() do
                if net.readBool() then
                    Out[i] = k:Read()
                else
                    return Out
                end
            end
        end
        net.readBool()
        return Out
    end,
    GetTotalSent = function(self)
        return self.TotalSent
    end
    ,GetActualSent = function(self)
        return self.ActuallySent
    end
    ,GetSize = function(self,MaxLen)
        local Totlen=2
        self.TotalSent=0
        for i,k in self.RequiredObjs() do
            local S = k:GetSize(MaxLen-Totlen)
            if S==false then return false end
            if Totlen+S>MaxLen then
                return false
            end
            Totlen=Totlen + S + 1
        end
        if self.NotRequiredObjs==nil then return end
        for i,k in self.NotRequiredObjs() do
            local S = k:GetSize(MaxLen-Totlen)
            if S~=false then 
                if Totlen+S<=MaxLen then
                    Totlen=Totlen + S + 1
                    self.TotalSent=self.TotalSent+1
                end
                if Totlen==MaxLen then
                    break
                end
            else
                break
            end
        end
        return Totlen + 1
    end
})
SingleTypeArrayNetHandler = ZClass(function(self,NetObj,Start,To)
    NetObjHandler.const(self,RepeatPairs(NetObj,Start,Start-1),RepeatPairs(NetObj,To,Start))
    self.Start=Start
    self.Type=NetObj
    self.To=To
end,{
    SetLength = function(self,Start,To)
        self.NotRequiredObjs = function() RepeatPairs(self.Type,To,Start) end
        self.RequiredObjs = function() RepeatPairs(self.Type,Start,Start-1) end
        self.Start = Start
        self.To = To
    end
    ,Send = function(self,Data)
        net.writeInt(self.Start,16)
        net.writeInt(self.To,16)
        return 2 + 2 + NetObjHandler.Send(self,Data)
    end
    ,GetSize = function(self,MaxSize)
        return 2 + 2 + NetObjHandler.GetSize(self,MaxSize)
    end
    ,Read = function(self,Out)
        local Start = net.readInt(16)
        local To = net.readInt(16)
        self:SetLength(Start,To)
        return NetObjHandler.Read(self,Out)
    end
},NetObjHandler)