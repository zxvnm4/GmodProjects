--@includedir LuaLib
requiredir("LuaLib")



--For the class, add getter and setter, so they work in the {} part as a {func Setter,func Getter}, if it is and one tries to get it then it makes an error!
--Oh and you forgot to add the important bit to the Network buffer entry id higharchy deal, you know, if it isn't right next to said thing, then update ID's, yeah you need
--to add the surrounding ids... oh and, make a check so if it is next to an existing one (aka next to the end of the same one ur adding, then add to it?)
--And do it all inside the NetBufferSeg class, cus yeah...
--And you should probably abstract this all using the getting and setter deal, and make this form of list it's own seperate class.
--So you can reuse it!


OPSAverager = ZClass(function(self,Length)
    self.Averager=Averager(Length)
    self.LastTime=timer.systime()
    self.OPS=0
end,{
    Check=function(self,NewValue)
        local T=self.Averager:NewValue((timer.systime()-self.LastTime))
        self.LastTime=timer.systime()
        self.OPS=T
        return T
    end
})
--bit.lshift
--bit.rshift
--
--
local function BitsInStrToChar(Str,Loc,Size)
    if Size>8 then print("BitsInStrToChar BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD") return end
    local FByte=math.rshift(Loc,4)
    local EByte=math.rshift(Loc+Size,4)
    local F=Str[FByte]:byte(1)
    if Str:len()<EByte then 
        EByte=FByte
        Range=7-Loc%8
    end
    if EByte~=FByte then
        F=F..Str[EByte]:byte(1)
    end
    return string.char(bit.band(bit.rshift(F,bit.band(Loc,255)),bit.rshift(255,8-Size))) "\255"
end
local function CharToBitsInStr(Str,Loc,Size,Val)
    if Size>8 then print("BitsInStrToChar BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD") return end
    local FByte=math.rshift(Loc,4)
    local EByte=math.rshift(Loc+Size,4)
    local F=Str[FByte]:byte(1)
    if Str:len()<EByte then 
        EByte=FByte
        Range=7-Loc%8
    end
    if EByte~=FByte then
        F=F..Str[EByte]:byte(1)
    end
    local Mask=bit.lshift(bit.rshift(256*256-1,16-Size),Loc)
    local NMask=bit.rshift(bit.lshift(bit.bnot(Mask),16),16)
    local Ba = Str:byte(FByte)+Str:byte(FByte+1)*256
    Ba = bit.bor(bit.band(Ba,Mask),bit.band(bit.lshift(Val:byte(1),Loc),Mask))
    local OutStr=string.char(bit.band(Ba,F,255))
    if EByte~=FByte then
        OutStr=OutStr..bit.band(Ba,Str[EByte]:byte(1),255*256)
    end
    return OutStr
end
BitArray = ZClass(function(self,len)
    self.Str=string.rep("\0",len)
end,{
    Get = function(self,Loc)

    end,
    Set = function(self,Loc,Val)

    end,
    RangeSetStr = function(self,Loc,Range,Val)

    end,
    RangeGetStr = function(self,Loc,Range)
        
    end
})
AutoGrouper = ZClass(function(self)
    self.Ar={}
end,{
    NewGroup=function(self,Location,Size)
        self.Ar[Location]="cat"
    end,
    NewLocation=function(self,Location)

    end
    
})

if CLIENT then
    function ServerPrint(Str)
        if net.getBytesLeft()>=Str:len() then
            net.start("Print")
            net.writeString(Str)
            net.send()
        end
    end
else
    net.receive("Print",function( name, len, ply ) 
        Str=net.readString()
        print(ply:getName().." printed: "..Str)
    end)
end
Queue = ZClass(function(self)
    self.List={}
    self.Cur=0
    self.To=0
end,{
    PushTop = function(self,Data)
        self.To=self.To+1
        self.List[self.To]=Data
    end
    ,GetBottom = function(self)
        return self.List[self.Cur]
    end
    ,PopBottom = function(self)
        if self.Cur==self.To then
            if #(self.List) ~= 0 then
                self.List={}
                self.Cur=0
                self.To=0
            end
            return nil
        end
        self.Cur=self.Cur+1
        return self.List[self.Cur]
    end
})
RepeatIter = function (Item,To)
    return function(t,v) 
        if v<To then 
            return v+1,Item 
        else 
            return nil 
        end 
    end
    
end
RepeatPairs = function (Item,From,To)
    return {RepeatIter(Item,To),{},From}
end
function Gen(List)
    local Index=nil
    return function(i)
        local A,B = next(List,Index)
        Index = A
        return B
    end
end
function Ind(List)
    return function(i)
        return List[i]
    end
end

function SetGet(List)
    return function(i,a)
        if a==nil then
            return List[i]
        else
            List[i]=a
        end
    end
end
function CopyTable(T)
    local N={}
    for i,k in pairs(T) do
        N[i]=k
    end
    return N
end
local MaxQuota=0.80
function CheckQuota()
    if coroutine.running() then
        if quotaTotalAverage()>=quotaMax()*MaxQuota then
            coroutine.yield("QuotaExceeded")
        end
    end
end
function SetMaxQuota(Quota)
    MaxQuota=Quota
end
local RunQuotaLimitedFunctionTimerID=0
function RunQuotaLimitedFunction(Function,...)
    local Arrrrrgs={...}
    local StartingCoroutine=coroutine.create(function() Function(unpack(Arrrrrgs)) end)
    coroutine.resume(StartingCoroutine)
    local Stat=coroutine.status(StartingCoroutine)
    if Stat~="dead" then
        local ID=RunQuotaLimitedFunctionTimerID+1
        RunQuotaLimitedFunctionTimerID=ID
        timer.create("RunQuotaLimitedFunctionTimer"+tostring(ID),0.25,0,function()
            if quotaTotalAverage()>=quotaMax()*MaxQuota then return end 
            local Stat=coroutine.status(StartingCoroutine) 
            if Stat~="dead" then
                coroutine.resume(StartingCoroutine)
            else
                timer.remove("RunQuotaLimitedFunctionTimer"+tostring(ID))
            end
        end)
    end
end
function CreateQuotaLimitedFunction(Function,...)
    local Arrrrrgs={...}
    local Coroutine=nil
    return function()
        if quotaTotalAverage()>=quotaMax()*MaxQuota then return end 
        if Coroutine~=nil and coroutine.status(Coroutine) ~="dead" then
            coroutine.resume(Coroutine)
        else
            Coroutine=coroutine.create(function() Function(unpack(Arrrrrgs)) end)
            coroutine.resume(Coroutine)
        end
        return coroutine.status(Coroutine) ~= "dead"
    end
end
function RepeatQuotaLimitedFunction(Time,Function,...)
    local Arrrrrgs={...}
    local Coroutine=nil
    local ID=RunQuotaLimitedFunctionTimerID+1
    RunQuotaLimitedFunctionTimerID=ID
    timer.create("RunQuotaLimitedFunctionTimer"+tostring(ID),Time,0,function()
        if quotaTotalAverage()>=quotaMax()*MaxQuota then return end 
        if Coroutine~=nil and coroutine.status(Coroutine) ~="dead" then
            coroutine.resume(Coroutine)
        else
            Coroutine=coroutine.create(function() Function(unpack(Arrrrrgs)) end)
            coroutine.resume(Coroutine)
        end
    end)
    return ID
end
function CreateGenerator(Function)
    local Coroutine=coroutine.create(Function)
    return function(...)
        if coroutine.status(Coroutine) == "dead" then
            return nil
        end
        local A = {coroutine.resume(Coroutine,...)}
        if ({...})[1]==false then
            if coroutine.status(Coroutine) == "dead" then
                return A
            end
            coroutine.resume(Coroutine,...)
            
        end
        if A[1] == "QuotaExceeded" then
            coroutine.yield("QuotaExceeded")
        end
        return unpack(A)
    end
end
function StopQuotaLimitedFunction(ID)
    timer.remove("RunQuotaLimitedFunctionTimer"+tostring(ID))
end