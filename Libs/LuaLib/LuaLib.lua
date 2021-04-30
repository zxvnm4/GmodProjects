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