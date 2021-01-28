--@include ../Base.lua
require("../Base.lua")
local ToCliList = function(A)
    local L = A
    if L.List ~= nil then L=L.List
    elseif L.Clients ~= nil then L=L.Clients
    elseif L.Segments ~= nil then 
        L={}
        L[A:GetID()]=A
    elseif L.entIndex ~= nil then
        L={}
        L[A:entIndex()]=A
    end
    return L
end
local ToCliListAr = function(A)
    if next(A)==nil then return A end
    if ToCliList(A)~=A then return A end
    local D={}
    for i,k in pairs(A) do
        D[i]=ToCliList(k)
    end 
    return D
end
NBCliList = ZClass(function(self,List,Inv)
    if List.List ~= nil then
        self.List = CopyTable(List)
        self.Inverted=List.Inverted
    else
        self.List=ToCliList(List)
        if Inv==nil then
            self.Inverted=false
        else
            self.Inverted=Inv
        end
    end

end,{ 
    ToString = function(self)
        local Cats="{"
        local F=true
        for i,k in pairs(self.List) do
            if k.entIndex ~= nil then
                Cats=Cats..(F and "" or ",")..k:entIndex()
            elseif k.Segments ~= nil then 
                Cats=Cats..(F and "" or ",")..k:GetID()
            elseif k.Client ~= nil then 
                Cats=Cats..(F and "" or ",")..k.Client:GetID()
            end
            F=false
        end
        return Cats.."}"
    end,
    ToCliList = function(self,A)
        return ToCliList(A)
    end,
    Pairs = function(self)
        return pairs(self.List)
    end,
    PairsAnd = function(self,A) 
        local L=ToCliList(A)
        local F=function()
            for i,k in pairs(self.List) do
                if L[i]~=nil then
                    coroutine.yield(i,k)
                end
            end
        end
        return CreateGenerator(F),nil,nil
    end,
    HasAllIn = function(self,A)
        local L=ToCliList(A)
        for i,k in pairs(self.List) do
            if L[i]==nil then
                return false
            end
        end
        return true
    end,
    HasAnyIn = function(self,A)
        local A=ToCliList(A)
        for i,k in pairs(self.List) do
            if A[i] ~= nil then return true end
        end
        return false
    end,
    IsEqual = function(self,A)
        local L=ToCliList(A) 
        local Count=0
        for i,k in pairs(self.List) do
            if L[i]==nil then
                return false
            end
            Count=Count+1
        end
        for i,k in pairs(A) do
            Count=Count-1
        end
        return Count==0
    end,
    ResolveInversion = function(self,AllClients)
        if self.Inverted then
            for i,k in pairs(AllClients) do
                local ID
                if type(i)=="number" then
                    ID=k:GetID()
                else
                    ID=i
                end
                if self.List[ID]==nil then
                    self.List[ID]=k
                else
                    self.List[ID]=nil
                end
            end
        end
        self.Inverted=false
        return self
    end,
    RemoveFrom = function(self,...)
        local D=ToCliListAr({...})
        for i,k in pairs(self.List) do
            for i2,k2 in pairs(D) do
                k2[i]=nil
            end
        end
    end,
    AddTo = function(self,A)
        local L=ToCliList(A)
        for i,k in pairs(self.List) do
            L[i]=k
        end
    end,
    Add = function(self,A)
        local L=ToCliList(A)
        for i,k in pairs(L) do
            self.List[i]=k
        end
        return self
    end,
    Remove = function(self,A)
        local L=ToCliList(A)
        for i,k in pairs(L) do
            self.List[i]=nil
        end
        return self
    end,
    IfInRBoth = function(self,To,Filter)
        local L=ToCliList(To)
        for i,k in pairs(L) do
            if self.List[i]~=nil then
                L[i]=nil
                self.List[i]=nil
            end
        end
    end,
    IfInMove = function(self,To,Filter)
        local L=ToCliList(To)
        local F=ToCliList(Filter)
        for i,k in pairs(F) do
            if self.List[i]~=nil then
                L[i]=self.List[i]
                self.List[i]=nil
            end
        end
    end,
    AndMoveTo = function(self,A,...)
        local L=ToCliList(A)
        local D=ToCliListAr({...})

        for i,k in self:PairsAnd(L) do
            local V=k
            for i2,k2 in pairs(D) do
                k2[i]=V
            end
            L[i]=nil
            self.List[i]=nil
        end
    end,
})