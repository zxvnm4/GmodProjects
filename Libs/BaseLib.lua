



--For the class, add getter and setter, so they work in the {} part as a {func Setter,func Getter}, if it is and one tries to get it then it makes an error!
--Oh and you forgot to add the important bit to the Network buffer entry id higharchy deal, you know, if it isn't right next to said thing, then update ID's, yeah you need
--to add the surrounding ids... oh and, make a check so if it is next to an existing one (aka next to the end of the same one ur adding, then add to it?)
--And do it all inside the NetBufferSeg class, cus yeah...
--And you should probably abstract this all using the getting and setter deal, and make this form of list it's own seperate class.
--So you can reuse it!



function ShiftForwardArray(Arr,N)
    local T=#Arr
    for i=1,T do
        local a=T+1-i
        Arr[a+N]=Arr[a]
    end
    for i=1,N do
        Arr[i]=nil
    end
end
function ShiftBackwardArray(Arr,N)
    local T=#Arr
    for i=2,T do
        Arr[i-1]=Arr[i]
    end
    for i=1,N do
        Arr[T-(i-1)]=nil
    end
end


local function ZClassGetSuperClasses(self,ret,K)
    local C=#self[2] 
    for i=1,C do 
        B=self[2][1+C-i]
        if type(B)=="table" then
            if B.C123456789==true then
                local BA=ZClassGetSuperClasses(B,ret,K)
                if BA~=nil then
                    return BA
                end
            else
                if B.Variables~=nil then
                    if B.Variables[K]~=nil then
                        return rawget(ret,B.Variables[K])
                    end
                end
                if B[K]~=nil then
                    return B[K]
                end
            end
        end 
    end
    return nil
end
local function ZClassGetSuperClassesNew(self,ret,K,V)
    local C=#self[2] 
    for i=1,C do 
        B=self[2][1+C-i]
        if type(B)=="table" then
            if B.C123456789==true then
                if ZClassGetSuperClassesNew(B,ret,K,V) then
                    return true
                end
            else
                if i==1 and B.Variables~=nil and B.Variables[K]~=nil then
                    rawset(ret, B.Variables[K], V)
                    return true
                end
            end
        end 
    end
    return false
end
function ZClass(Constructor,...) --I made this to fulfill 2 criteria, one to decrease ram usage and two to be easy to implement
    --Can be more efficient yo!
    local ClassTy={Constructor,{...}}
    ClassTy.C123456789=true
    local First=true
    setmetatable(ClassTy,{
    __index=function(self,K)
        if K=="const" then
            return self[1]
        end
        if K=="__setVar" then
            return function(self,K,V)
                local F=#self[2]
                if self[2][F].C123456789 == true then
                    F=F+1
                end
                if F==0 then F=1 end
                if self[2][F]==nil then
                    self[2][F]={}
                    self[2][F].Variables = {}
                end
                if self[2][F].Variables == nil then
                    self[2][F].Variables = {}
                end
                self[2][F].Variables[K] = V
                
            end
        end
        return ZClassGetSuperClasses(self,{},K)
    end,
    __call=function(self2,...)
        local ret = {}
        local NMeta = {
            __super = self2,
            __index = function(S,K)
                local self=getmetatable(S).__super
                if K=="const" then
                    return self[1]
                end
                return ZClassGetSuperClasses(self,S,K)
            end,
            __newindex = function(S,K,V)
                local self=getmetatable(S).__super
                if not ZClassGetSuperClassesNew(self,ret,K,V) then
                    print(K,V)
                    AWJIA()
                    rawset(S, K, V)
                end
            end
        }
        if First then
            local Num=0
            setmetatable(ret, {
                __super = self2,
                __index = function(S,K)
                    local self=getmetatable(S).__super
                    if K=="const" then
                        return self[1]
                    end
                    return ZClassGetSuperClasses(self,S,K)
                end,
                __newindex = function(S,K,V)
                    local self=getmetatable(S).__super
                    if type(K)=="number" then
                        rawset(S, K, V)
                        return
                    end
                    if not ZClassGetSuperClassesNew(self,ret,K,V) then
                        if First then
                            Num=Num+1
                            self:__setVar(K,Num)
                            rawset(S, Num, V)
                        else
                            rawset(S, K, V)
                        end
                    end
                end
            })
        else
            setmetatable(ret, NMeta)
        end
        self2[1](ret,...)
        if First then
            setmetatable(ret, NMeta)
        end
        First=false
        
        return ret
    end})
    return ClassTy
end

function ZTemplateClass(Constructor,Templates,...) --I made this to fulfill 2 criteria, one to decrease ram usage and two to be easy to implement
    local ClassTy={Constructor,{...}}
    ClassTy.C123456789=true
    setmetatable(ClassTy,{
    __index=function(self,K)
        if K=="const" then
            return self[1]
        end
    end,
    __call=function(self2,...)
        local ret = {}
        local GeneratedTemplate={self2[1],{}}
        local Arguments={}
        local TTemplates={}
        local T=1
        for i,k in pairs(self2[2]) do
            GeneratedTemplate[2][i]=k
        end
        for i,k in pairs({...}) do
            if T<=Templates then
                TTemplates[#TTemplates+1]=k
                GeneratedTemplate[2][#GeneratedTemplate[2]+1]=k
            else
                Arguments[#Arguments+1]=k
            end
            T=T+1
        end
        setmetatable(ret, {
            __super = GeneratedTemplate,
            __index = function(S,K)
                local self=getmetatable(S).__super
                if K=="const" then
                    return self[1]
                end
                return ZClassGetSuperClasses(self,ret,K)
            end
        })
        self2[1](ret,TTemplates,unpack(Arguments))
        return ret
    end})
    return ClassTy
end
Averager = ZClass(function(self,Length)
    self.ItemCircle={} -- Idk, it's a constant size queue like thing, as soon as you add something it removes the last thing from the line
    self.CurLoc=1
    for i=1,Length do
        self.ItemCircle[i]=0
    end 
    self.Length=Length
    self.MidValue=0
end,{
    NewValue=function(self,NewValue)
        local NextItemInCircle=self.CurLoc
        if NextItemInCircle==self.Length then
            NextItemInCircle=1
        else
            NextItemInCircle=NextItemInCircle+1
        end
        self.MidValue=self.MidValue-self.ItemCircle[NextItemInCircle]
        self.MidValue=self.MidValue+NewValue
        self.ItemCircle[NextItemInCircle]=NewValue
        self.CurLoc=NextItemInCircle
        return self.MidValue/self.Length
    end,
    Reset=function(self)
        for i=1,self.Length do
            self.ItemCircle[i]=0
        end 
        self.MidValue=0
    end
})
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
BinSearchOperations=0
function BinarySearch(Ar,Num,Comp)
    local Area=#Ar
    local Off=1
    local CompRes=0
    if Comp==nil then
        while Area~=1 do
            Area=math.floor(Area/2)
            local Mid=Off+Area
            BinSearchOperations=BinSearchOperations+1
            if Ar[Mid]==Num then
                return Mid
            elseif Ar[Mid]>Num then
                Off=Off
                Area=Mid-Off
                CompRes=1
            else
                Area=Area+Off-Mid
                Off=Mid
                CompRes=0
            end
        end
    else
        while Area~=1 do
            local Mid=Off+math.floor(Area/2)
            CompRes=Comp(Ar[Mid],Num)
            BinSearchOperations=BinSearchOperations+1

            if CompRes==0 then
                return Mid
            elseif CompRes==1 then
                Off=Off
                Area=Mid-Off
            else
                Area=Area+Off-Mid
                Off=Mid
                
            end
        end
    end
    return Off
end
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
function ToNumWBack(N,L,P)
    local NL=1
    for i=1,L do
        if N>=10^i then
            NL=NL+1
        else
            break
        end
    end
    return string.rep(P,math.max(L-NL,0))..tostring(N)
    
end
function SecondsToFormattedStr(Secs)
    local SecsP=math.floor(Secs)
    local S=SecsP%60
    local M=math.floor(SecsP/60)%60
    local H=math.floor(SecsP/(60*60))
    if SecsP>=60 then
        if SecsP>=60*60 then
            return tostring(H)..":"..ToNumWBack(M,2,"0")..":"..ToNumWBack(S,2,"0")
        else
            return tostring(M)..":"..ToNumWBack(S,2,"0")
        end
    else
        return tostring(0)..":"..ToNumWBack(S,2,"0")
    end
    
end

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

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
function copyChanges(orig)
    local copy = {}
    for i, k in next, orig, nil do
        copy[i]={k[1],k[2],shallowcopy(k[3]),shallowcopy(k[4])}
    end
    return copy
end


HookL = ZClass(function(T)
    T.Hooks={}
    end,{
    OnEvent=function(self,EventN,Data)
        local Out={}
        local Count=0
        if self.Hooks[EventN]~=nil then
            for i,k2 in pairs(self.Hooks[EventN][2]) do
                k=self.Hooks[EventN][1][k2]
                Count=Count+1
                Out[Count]=k[1](Data,k[2])
            end
        end
        return Out
    end
    ,CreateHook=function(self,EventN,EventID,Func,Args)
        if self.Hooks[EventN]==nil then
            self.Hooks[EventN]={{},{}}
        end
        local Ar=self.Hooks[EventN]
        if Ar[1][EventID]==nil then
            Ar[2][#Ar[2]+1]=EventID
        end
        Ar[1][EventID]={Func,Args}
    end
    ,RemoveHook=function(self,EventN,EventID)
        if self.Hooks[EventN]~=nil then
            self.Hooks[EventN][1][EventID]=nil
            if next(self.Hooks[EventN]) == nil then
                self.Hooks[EventN]=nil
            end
        else
            print("But that EventN hook didn't exist in the first place!")
        end
    end  
})
LinkedNode = ZClass(function(self)
    self.Next=0
    self.Back=0
end,{
    Disconnect = function(self)
        self.Next=0
        self.Back=0
    end,
    ContinueFTo = function(self,Des,Func)
        local Cur=self
        while Cur~=0 and Cur~=Des.Next do
            if Func(Cur)==false then return end
            Cur=Cur.Next
        end
    end,
    ContinueFToPairs = function(self,Des)
        return function(t,v)
            if v==nil then
                return self,self
            elseif v~=0 and v~=Des then
                return v.Next,v.Next
            else
                return nil
            end
        end,nil,nil
    end,
    ContinueBToPairs = function(self,Des)
        return function(t,v)
            if v==nil then
                return self,self
            elseif v~=0 and v~=Des then
                return v.Back,v.Back
            else
                return nil
            end
        end,nil,nil
    end,
    Clone = function(self,Base)
        if Base == nil then
            Base=LinkedNode()
        end
        Base.Next = self.Next
        Base.Back = self.Back
        return Base
    end
})

LinkedNodeData = ZClass(function(self,Data)
    self.Data=Data
end,LinkedNode,{})

LinkedList = ZClass(function(self)
    self.Start=0
    self.End=0
end,{
    Connect = function(self,A,B)
        if A==0 and B==0 then
            self.Start=0
            self.End=0
        elseif A==0 then
            self.Start=B
            B.Back = 0
        elseif B==0 then
            self.End=A
            A.Next = 0
        else
            A.Next = B
            B.Back = A
        end
    end,
    AddAfter = function(self,CNode,NNode)
        if CNode==0 then
            self:Connect(NNode,self.Start)
        else
            self:Connect(NNode,CNode.Next)
        end
        self:Connect(CNode,NNode)
    end,
    AddBefore = function(self,CNode,NNode)
        if CNode==0 then
            self:Connect(self.End,NNode)
        else
            self:Connect(CNode.Back,NNode)
        end
        self:Connect(NNode,CNode)
        
    end,
    AddSAfter = function(self,CNode,NNode,ENode)
        if CNode==0 then
            self:Connect(ENode,self.Start)
        else
            self:Connect(ENode,CNode.Next)
        end
        self:Connect(CNode,NNode)
    end,
    AddSBefore = function(self,CNode,NNode,ENode)
        if CNode==0 then
            self:Connect(self.End,NNode)
        else
            self:Connect(CNode.Back,NNode)
        end
        self:Connect(ENode,CNode)
    end,
    Remove = function(self,Node)
        self:Connect(Node.Back,Node.Next)
        Node:Disconnect()
    end,
    RemoveSec = function(self,SNode,ENode)
        self:Connect(SNode.Back,ENode.Next)
        SNode.Back=0
        ENode.Next=0
    end,
    Foreach = function(self,Func)
        if self.Start~=0 then
            self.Start:ContinueFTo(self.End,Func)
        end
    end,
    Pairs = function(self)
        if self.Start==0 then return pairs({}) end
        return LinkedNode.ContinueFToPairs(self.Start,self.End)
    end
})
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
FunkyID = ZClass(function(self,LeftID,RightID)
    if LeftID ~= nil and LeftID.IDs~={} and RightID == nil then
        self.IDs = LeftID
        return
    end
    if RightID==nil and LeftID==nil then
        self.IDs = {}
        return
    end
    local RIDs={}
    local LIDs={}
    if RightID~=nil then
        RIDs=RightID.IDs
    end
    if LeftID~=nil then
        LIDs=LeftID.IDs
    end
    
    local IDs={}
    while true do
        if RIDs[#IDs+1]==nil and LIDs[#IDs+1]==nil then
            IDs[#IDs+1]=0
            break
        elseif RIDs[#IDs+1]==nil then
            IDs[#IDs+1]=LIDs[1]+1
            break
        elseif LIDs[#IDs+1]==nil then
            IDs[#IDs+1]=RIDs[1]-1
            break
        elseif LIDs[#IDs+1]+1 < RIDs[#IDs+1] then
            IDs[#IDs+1]=LIDs[#IDs+1]+1
            break
        else
            IDs[#IDs+1]=LIDs[#IDs+1]
        end
    end
    self.IDs=IDs
end,{
    Compare = function(A,B)
        local I=1
        local LIDs=A.IDs
        local RIDs=B.IDs
        while true do
            if RIDs[I]==nil and LIDs[I]==nil then
                return 0
            elseif RIDs[I]==nil then
                return 1
            elseif LIDs[I]==nil then
                return -1
            elseif LIDs[I] > RIDs[I] then
                return 1
            elseif LIDs[I] < RIDs[I] then
                return -1
            else
                I=I+1
            end
        end
        I() --You see here should not be able to happen so it will spit out an error.
        return 0 --WHAT????
    end,
    PartOf = function(self,A)
        local Out = {}
        for i,k in pairs(self.IDs) do
            if k == A.IDs[i] then
                Out[i]=k
            else
                break
            end
        end
        return Out
    end,
    Push = function(self,num)
        self.IDs[#(self.IDs)+1]=num
    end,
    Pop = function(self)
        local A=self.IDs[#(self.IDs)]
        self.IDs[#(self.IDs)]=nil
        return A
    end,
    Clone = function(self)
        return FunkyID(CopyTable(self.IDs))
    end,
    ToString = function(self)
        local Out=tostring(self.IDs[1])
        for i=2, #(self.IDs) do
            Out=","+tostring(self.IDs[i])
        end
        return Out
    end,
    Last = function(self)
        return self.IDs[#self.IDs]
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