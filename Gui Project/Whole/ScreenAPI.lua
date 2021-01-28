--@include Object.lua
--@include Layout.lua
--@include Base.lua
require("Base.lua")
require("Object.lua")
require("Layout.lua")
if CLIENT then
    function AddToRenderQueue(Obj,Func,BB)
        local self=Obj.ParentScreen
        self.RenderQueue[#self.RenderQueue+1]={Obj,Func,BB}
    end
    local CurJob=nil
    function AddToChangeList(Obj,State,OverlapEvent,Type,BBFunc,Func,Args,BBArgs) --Removed 3,moved 2,stayed 1
        local self=Obj.ParentScreen
        if self.NotDrawnRoot then -- or coroutine.running() == ApplyRenderChangesCoroutine
            Func(Obj,unpack(Args))
            --print("Bam")
        else
            if CurJob then CurJob:NewJob() end
            if self.ChangeList[Obj.ID] == nil then -- the State==3 could include some funky bugs.
                self.ChangeList[Obj.ID]={Obj,State,{},{}}
                self.ChangeList[Obj.ID][4][1]={BBFunc,Func,Args,BBArgs,{CurJob}}
                self.ChangeList[Obj.ID][3][Type]=1

            else
                self.ChangeList[Obj.ID][2]=math.max(self.ChangeList[Obj.ID][2],State)
                local B=self.ChangeList[Obj.ID][4]
                local Jobs={CurJob}
                if OverlapEvent and self.ChangeList[Obj.ID][3][Type]~=nil then
                    for i,k in pairs(B[self.ChangeList[Obj.ID][3][Type]][5]) do
                        Jobs[#Jobs+1]=k
                    end
                    B[self.ChangeList[Obj.ID][3][Type]]=-1
                    
                end
                self.ChangeList[Obj.ID][3][Type]=#B+1
                B[#B+1]={BBFunc,Func,Args,BBArgs,Jobs}
            end
        end
    end
    
    function PushJob(Started,Finished)
        CurJob=Job(CurJob,Started,Finished)
    end
    function PopJob()
        if CurJob ~= nil then
            CurJob=CurJob.Parent
        end
    end
    --Could create a table of the change types, which could be used simplify the process. ([Type]={2,Type,BBFunc,Func})
    --Then turn them into functions automatically
    function SetPos(Obj,Pos)
        Obj.ParentScreen.SomethingMoved=true
        AddToChangeList(Obj,2,true,"Pos",Obj.getRenderBound,Obj.RelPos,{Pos})
    end
    function SetSize(Obj,Size)
        Obj.ParentScreen.SomethingMoved=true
        AddToChangeList(Obj,2,true,"Size",Obj.getRenderBound,Obj.SetSize,{Size})
    end
    function RemoveObj(Obj)
        Obj.ParentScreen.SomethingMoved=true
        AddToChangeList(Obj,1,false,"RemoveObj",Obj.getRenderBound,Obj.RemoveObj,{})
    end
    function AddObj(Obj,NObj,L)
        Obj.ParentScreen.SomethingMoved=true
        AddToChangeList(Obj,1,false,"AddTo",Obj.getRenderBound,Obj.AddTo,{L,NObj})
    end
    function SetColorM(Obj,ColorM)
        AddToChangeList(Obj,1,true,"SetColorMod",Obj.getRenderBound,Obj.SetColorMod,{ColorM})
    end
    function AddLayout(Obj,L)
        AddToChangeList(Obj,1,false,"AddLayout",Obj.getRenderBound,Obj.AddLayout,{})
    end
    function SwitchLayout(Obj,L)
        Obj.ParentScreen.SomethingMoved=true
        AddToChangeList(Obj,1,false,"SwitchLayout",Obj.getRenderBound,Obj.SwitchLayout,{L})
    end
    function ScrollObj(Obj,L,Scroll)
        Obj.ParentScreen.SomethingMoved=true
        AddToChangeList(Obj,1,true,"ScrollObj",Obj.getRenderBound,Obj.ChangeScroll,{L,Scroll})
    end
    function SetHiddenObj(Obj,Value)
        Obj.ParentScreen.SomethingMoved=true
        if not Value then
            AddToChangeList(Obj,1,true,"SetHidden",Obj.getRenderBound,Obj.SetHidden,{Value})
        else
            AddToChangeList(Obj,3,true,"SetHidden",Obj.getRenderBound,Obj.SetHidden,{Value})
        end
    end
    function GetRenderBoundRObj(self,B,Obj)
        local F=Obj:getBoundingBoxM(self:GetPosition())
        return BoundingBox(self:GetPosition(),self.Size):between(F)
    end
    GetRenderBoundRObj2B={}
    function GetRenderBoundRObj2(self,B,L)
        local Obj=nil
        if self.RenderObjs[L]==nil then
            BoundingBox(self:GetPosition(),vec2(0,0))
        end
        if GetRenderBoundRObj2B[self.ID]==nil then
            Obj=self.RenderObjs[L]
            GetRenderBoundRObj2B[self.ID]=Obj
        else
            Obj=GetRenderBoundRObj2B[self.ID]
            GetRenderBoundRObj2B[self.ID]=nil
        end
        local F=Obj:getBoundingBoxM(self:GetPosition())
        return BoundingBox(self:GetPosition(),self.Size):between(F)
    end
    GetRenderBoundRObj3B={}
    function GetRenderBoundRObj3(self,B,L,New)
        local IDA=tostring(self.ID)..tostring(L)
        if GetRenderBoundRObj3B[IDA]==nil then
            local Obj=self.RenderObjs[L]
            if Obj==nil then
                local Out=self:getRenderBound()
                GetRenderBoundRObj3B[IDA]=Out
                GetRenderBoundRObj3B[IDA].P=Out.P-self:GetPosition()
                return Out
            else
                GetRenderBoundRObj3B[IDA]=Obj:getBoundingBox(self:GetPosition()):combineArea(New:getBoundingBoxM(self:GetPosition()))
                
                local Out=BoundingBox(self:GetPosition(),self.Size):between(GetRenderBoundRObj3B[IDA])
                GetRenderBoundRObj3B[IDA].P=GetRenderBoundRObj3B[IDA].P-self:GetPosition()
                return Out
            end
            
        else
            
            GetRenderBoundRObj3B[IDA].P=GetRenderBoundRObj3B[IDA].P+self:GetPosition()
            local Out=BoundingBox(self:GetPosition(),self.Size):between(GetRenderBoundRObj3B[IDA])
            GetRenderBoundRObj3B[IDA]=nil
            return Out
        end
    end
    GetRenderBoundRObj3C={}
    function GetRenderBoundRObj4(self,B,L,New)
        local IDA=tostring(self.ID)..tostring(L)
        if GetRenderBoundRObj3C[IDA]==nil then
            local Obj=self.RenderObjs[L]
            local Out
            if Obj==nil then
                Out=BoundingBox(self:GetPosition(),self.Size):between(New:getBoundingBox(self:GetPosition()))
            else
                Out=BoundingBox(self:GetPosition(),self.Size):between(self.RenderObjs[L]:getBoundingBox(self:GetPosition()))
            end
            GetRenderBoundRObj3C[IDA]=Out
            return Out
        else
            local Mid=BoundingBox(self:GetPosition(),self.Size):between(self.RenderObjs[L]:getBoundingBoxM(self:GetPosition()))
            local Out= Mid:combineArea(GetRenderBoundRObj3C[IDA])
            GetRenderBoundRObj3C[IDA]=nil
            return Out
        end
    end
    function ChangedRenderObj(Obj,L,RenderObjk)
        AddToChangeList(Obj,1,true,"ChangedRenderObj"..tostring(L),GetRenderBoundRObj3,Obj.ChangeRenderObj,{L,RenderObjk},{L,RenderObjk})
    end
    function UpdateRenderObj(Obj,L,RenderObjk)
        AddToChangeList(Obj,1,true,"UpdatedRenderObj"..tostring(L),GetRenderBoundRObj4,Obj.ChangeRenderObj,{L,RenderObjk},{L,RenderObjk})
    end
    function AddRenderObj(Obj,RenderObjk)
        AddToChangeList(Obj,1,false,"AddRenderObj",GetRenderBoundRObj,Obj.AddRenderObj,{RenderObjk},{RenderObjk}) 
    end
    function RemoveRenderObj(Obj,L)--This can be problematic, maybe not... HMMM make renderObj's use unique id's, but that can be an issue, maybe not.
        AddToChangeList(Obj,1,false,"RemRenderObj",GetRenderBoundRObj2,Obj.RemRenderObj,{L},{L})
    end
else
    
end