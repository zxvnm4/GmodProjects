--@include ZClass.lua
require("ZClass.lua")
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