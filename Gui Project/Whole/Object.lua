--@include Layout.lua
--@include Base.lua
--@includedir ../../Libs
requiredir("../../Libs")
require("Base.lua")
require("Layout.lua")
if CLIENT then
    local TotalObjects=0
    ChangeMade=false
    Object = ZClass(function(self,Screen)
        TotalObjects=TotalObjects+1
        self.ParentScreen=Screen
        self.OnScreen=true
        self.ID=TotalObjects
        self.ParentLayout=P
        self.Layouts={}
        self.CurrentLayout=0
        self.RelPosition=vec2(0)
        self.Size=vec2(512)
        self.OffPosition=vec2(0)
        self.RenderObjs={}
        self.MapLoc={vec2(1,1)}
        self.OffsetID=1
        self.BoundingVolume=BoundingBox(vec2(0,0),vec2(1,1))
        self.DrawZ=9
        self.Drawable=true
        self.Transparent=false
        self.Hidden=false
        self.NotDrawn=true
        self.Clickable=false
        self.HasClickableObj=false
        self.Writable=false
        self.Hooks=HookL()
        self.ColorModify=Vector(1,1,1)
    end,{
        ClearAndRefreshLayout=function(self,L)
            self.Layouts[L]:Clear(true)
            self.Layouts[L]:ApplyDrawability(true)
            ChangeMade=true
        end
        ,OnEvent=function(self,EventN,Data)
            return self.Hooks:OnEvent(EventN,{self,Data})
        end
        ,SetColorMod=function(self,Value)
            self.ColorModify=Value
            ChangeMade=true
        end
        ,GetClickablity=function(self)
            if self.CurrentLayout~=0 then
                return (self.Clickable or next(self.Layouts[self.CurrentLayout].ClickableObjects)~=nil)
            else
                return self.Clickable
            end
        end
        ,SetClickablity=function(self,Value)
            if ParentLayout~=nil and self.Clickable~=Value then
                self.ParentLayout:SetObjClickable(Value)
            end
            self.Clickable=Value
        end
        ,GetDrawable=function(self)
            return not self.Hidden and self.Drawable 
        end
        ,GetObjAtPos=function(self,Pos)
            if self:getRenderBound():checkPoint(Pos) then
                local CheckObj=nil
                if self.CurrentLayout~=0 then self.Layouts[self.CurrentLayout]:FindObjAtPos(Pos) end
                if CheckObj ~= nil then
                    return CheckObj
                elseif self.Clickable and self:GetDrawable() then
                    local Isin=true
                    local O=self:GetPosition()
                    for i,k in pairs(self:OnEvent("CheckPos",Pos-O)) do
                        if not k then
                            Isin=false
                        end
                    end
                    if Isin then
                        return self
                    end
                else
                    return nil
                end
            else
                return nil
            end
        end
        ,RelPos=function(self,Pos)
            local LastPos=self:GetPosition()
            if ParentLayout~=nil and Obj:GetDrawable() then
                ParentLayout:RefreshObj(self)
            end
            self.RelPosition=self.RelPosition+Pos-LastPos
            if self.CurrentLayout==0 then
                self.Layouts[self.CurrentLayout]:ApplyOff(Pos-LastPos)
            end
            self:OnEvent("PositionChanged",LastPos,Pos)
        end
        ,RemoveObj=function(self)
            self:OnEvent("Removed")
            if self.ParentLayout ~=nil then
                self.ParentLayout:RemoveObjFromLayout(self)
            end
            self.Drawable=false
            ChangeMade=true
        end
        ,AddTo=function(self,L,Obj)
            self.Drawable=true
            if Obj ~=nil then
                self.ParentLayout=Obj.Layouts[L]
                Obj.Layouts[L]:AddObjToData(self)
                local LastPos=self:GetPosition()
                self.OffPosition=Obj:GetPosition()+Obj.Layouts[L].Scroll
                self.Layouts[self.CurrentLayout]:ApplyOff(self:GetPosition()-LastPos)
                ChangeMade=true
            end
            local Boundin=self:getRenderBound()
            if not (Obj:getRenderBound()):check(Boundin) then return end
            self:OnEvent("AddedToScreen",Obj,L)
        end
        ,ChangeScroll=function(self,L,Scroll)
            self:OnEvent("Scrolled",self.Layouts[L].Scroll,Scroll)
            self.Layouts[L]:ChangeScroll(Scroll)
            ChangeMade=true
        end
        ,SetSize=function(self,NSize)
            if self.ParentLayout~=nil and Obj:GetDrawable() then
                self.ParentLayout:RefreshObj(self)
            end
            self:OnEvent("SizeChanged",self.Size,NSize)
            self.Size=NSize
            ChangeMade=true
        end
        ,GetPosition=function(self)
            return self.RelPosition+self.OffPosition
        end
        ,SwitchLayout=function(self,LayoutN)
            if LayoutN==self.CurrentLayout then return end
            self:OnEvent("SwitchedLayout",self.CurrentLayout,LayoutN)
            if self.CurrentLayout~=0 then
                self.Layouts[self.CurrentLayout]:ApplyDrawability(false)
            end
            self.CurrentLayout=LayoutN
            if self.CurrentLayout~=0 then
                self.Layouts[self.CurrentLayout]:ApplyDrawability(true)
                Lay=self.Layouts[self.CurrentLayout]
                Lay:ApplyOff(Lay.OffsetPos)
                Lay.OffsetPos=vec2(0)
            end
            ChangeMade=true
        end
        ,AddLayout=function(self)
            local Bla=Layout(self,#(self.Layouts)+1)
            self.Layouts[#(self.Layouts)+1]=Bla
            self:OnEvent("AddedLayout",#(self.Layouts))
            return Bla
        end
        ,AddRenderObj=function(self,Obj) --Look at this, LOOK AT IT, then look at the next one.
            self.RenderObjs[#self.RenderObjs+1]=Obj
            self:OnEvent("AddedRenderObj",Obj)
            ChangeMade=true
        end
        ,RemRenderObj=function(self,L) --Look at this, LOOK AT IT, then look at the next one.
            self.RenderObjs[L]=nil
            self:OnEvent("RemovedRenderObj",L)
            ChangeMade=true
        end
        ,ChangeRenderObj=function(self,L,Obj) --Look at this, LOOK AT IT, then look at the next one.
            self:OnEvent("ChangedRenderObj",L,Obj)
            self.RenderObjs[L]=Obj
            ChangeMade=true
        end
        ,SetHidden=function(self,Value)
            if self.Hidden~=Value then
                self.Hidden=Value
                if self.ParentLayout~=nil then
                    self.ParentLayout:RefreshObj(self)
                end
                ChangeMade=true
            end          
        end
        ,getRenderBound=function(self)
            return BoundingBox(self:GetPosition(),self.Size)
        end
        ,renderErase=function(self,BB)
            if not self.NotDrawn or self:GetDrawable()  then
                if self.ParentLayout~=nil then
                    BB=BB:between(self.ParentLayout.ObjParent:getRenderBound())
                end
                self:renderBelow(BB)
                self:renderAbove(BB)
                self.NotDrawn=true
                ChangeMade=true
            end
        end
        ,renderComplete=function(self,BB)
            if self:GetDrawable() then  
                if self.ParentLayout~=nil then
                    BB=BB:between(self.ParentLayout.ObjParent:getRenderBound())
                end
                if self.Transparent then --GetDrawable
                    self:renderBelow(BB)
                end
                self.NotDrawn=true
                self:render(BB)
                self:renderAbove(BB)
            end
        end
        ,render=function(self,BB,Above)
            if self:GetDrawable() then
                self.NotDrawn=false
                local Boundin=self:getRenderBound()
                if not BB:check(Boundin) then return end
                
                BB=BB:between(Boundin)
                self.ScreenParent.LastRenderArea=BoundingBox(BB.P,BB.S)
                render.enableScissorRect( BB.P.x, BB.P.y, BB.P.x+BB.S.x, BB.P.y+BB.S.y )
                for i,k in pairs(self.RenderObjs) do
                    k:render(self:GetPosition(),BB,self.ColorModify)
                    ChangeMade=true
                end
                if Above==nil or Above then
                    if self.CurrentLayout~=0 then self:renderLayout(BB,self.CurrentLayout) end
                end
                
            end
        end
        ,renderLayout=function(self,BB,s)
            local L=self.Layouts[s]
            
            for i,k in L:ZListIter() do
                for i2,k2 in pairs(k) do
                    k2:render(BB)
                    ChangeMade=true
                end
            end
        end
        ,renderAbove=function(self,BB)
            local Boundin=self:getRenderBound()
            if not BB:check(Boundin) then return end
            local BB2=BB:between(Boundin)
            local AboveObjs={}
            local CurP=self
            while CurP.ParentLayout~=nil do
                local B=CurP.ParentLayout.OverlappingObjs[CurP.ID]
                if B~=nil then
                    AboveObjs[#AboveObjs+1]=B
                end
                CurP=CurP.ParentLayout.ObjParent
            end
            for i2,k2 in pairs(AboveObjs) do
                if k2== nil then continue end
                for i,k in pairs(k2) do
                    k:render(BB2)
                    ChangeMade=true
                end
            end
        end
        ,renderBelow=function(self,BB)
            local Boundin=self:getRenderBound()
            if not BB:check(Boundin) then return end
            
            BB=BB:between(Boundin)
            if self.ParentLayout~=nil then
                self.ParentLayout.ObjParent:render(BB,false)
                ChangeMade=true
                if self.ParentLayout.UnderlappingObjs[self.ID]~=nil then
                    for i,k in pairs(self.ParentLayout.UnderlappingObjs[self.ID]) do
                        k:render(BB,true)
                        
                    end
                end
            end
            --This could be better but I am not doin it because, it will be a waste of effort right now.
            --while self.ParentLayout~=nil do
        end
        ,Refresh=function(self)
            if self.CurrentLayout~=0 then
                self.Layouts[self.CurrentLayout]:ApplyDrawability(true)
            end
            ChangeMade=true
        end
        ,CheckIfParent=function(self,Obj)
            local P=self.ParentLayout
            while P~=nil do
                if P==Obj.ObjParent then
                    return true
                end
                P=P.ObjParent.ParentLayout
            end
            return false
        end
    })
end