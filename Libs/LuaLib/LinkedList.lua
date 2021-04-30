--@include ZClass.lua
require("ZClass.lua")
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