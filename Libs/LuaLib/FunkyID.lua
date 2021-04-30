--@include ZClass.lua
require("ZClass.lua")
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