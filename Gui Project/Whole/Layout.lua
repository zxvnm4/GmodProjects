--@include Base.lua
--@includedir ../../Libs
requiredir("../../Libs")
require("Base.lua")
if CLIENT then
    Layout = ZClass(function(self,P,N)
        self.LayoutN=N
        self.ObjParent=P
        --self.VirtualSize=Vector(0)
        self.Scroll=vec2(0)
        self.OffsetPos=vec2(0)
        --self.RMatrix=Matrix()
        self.Objects={}
        self.ObjectsLocMap={}--Super Basic, but it doesn't matter.
        self.ObjectGeneratedDirMap={}
        self.DrawOrderTable={}
        self.DrawOrderList={}
        self.OverlappingObjs={}
        self.UnderlappingObjs={}
        self.ClickTree={}
        self.ClickableObjects={}
        self.LoadedObjects={}
        self.Hook=HookL()
        self.LoadedInObjs={}
        self.CurrentOffsetID=1
        self.OffsetIDList={{0,vec2(0)}}
    end,{
        RemakeZOrderList=function(self)
            self.DrawOrderList={}
            for n,k in pairs(self.DrawOrderTable) do table.insert(self.DrawOrderList, n) end
            table.sort(self.DrawOrderList,function(a,b) return a>b end)
        end
        --Ok, so you just need to make the offsets also function with all of this.
        --I plan to make the applyOffset only apply on the stuff that is actually near the screen.
        ,UnloadObject=function(self,Obj)
            
        end
        ,Clear=function(self)
            for i,k in pairs(self.Objects) do
                k.ParentLayout=nil
                k.Drawable=false
            end
            self.Objects={}
            self.ObjectsLocMap={}
            self.ObjectGeneratedDirMap={}
            self.DrawOrderTable={}
            self.DrawOrderList={}
            self.OverlappingObjs={}
            self.UnderlappingObjs={}
            self.ClickTree={}
            self.ClickableObjects={}
            self.LoadedObjects={}
            self.LoadedInObjs={}
            self.CurrentOffsetID=1
            self.OffsetIDList={{0,vec2(0)}}
        end
        ,RemoveFromMap=function(self,Obj)--This could be optimised...
            for i,MapLoc in pairs(Obj.MapLoc) do
                local A=self.ObjectsLocMap[MapLoc.x]
                if A~=nil then
                    if A[MapLoc.y]~=nil then
                        A[MapLoc.y][Obj.ID]=nil
                        if next(A[MapLoc.y])==nil then
                            A[MapLoc.y]=nil
                            if self.LoadedObjects[MapLoc.x]~=nil then
                                self.LoadedObjects[MapLoc.x][MapLoc.y]=nil
                            end
                            self.ObjectGeneratedDirMap[MapLoc.x][MapLoc.y]=nil
                            if next(A)==nil then
                                self.LoadedObjects[MapLoc.x]=nil
                                self.ObjectGeneratedDirMap[MapLoc.x]=nil
                                self.ObjectsLocMap[MapLoc.x]=nil
                            end
                        end
                    end
                end
            end
            Obj.MapLoc={}
        end
        --There should be MoveInMap or something but that is too much man.
        ,AddToMapS=function(self,MapLoc,Obj)
            local A=self.ObjectsLocMap[MapLoc.x]
            if A==nil then
                self.ObjectsLocMap[MapLoc.x]={}
                self.ObjectGeneratedDirMap[MapLoc.x]={}
            end
            if A[MapLoc.y]==nil then
                A[MapLoc.y]={}
                self.ObjectGeneratedDirMap[MapLoc.x][MapLoc.y]=vec2(0,0)
            end
            A[MapLoc.y][Obj.ID]=Obj
            Obj.MapLoc=MapLoc
        end
        ,AddToMap=function(self,Obj)
            Obj.MapLoc={}
            local MapLoc=(Obj.RelPosition/ScreenSize)
            MapLoc=vec2(math.floor(MapLoc.x),math.floor(MapLoc.y))
            local WithinLoc=vec2(math.floor(MapLoc.x)%ScreenSize.x,math.floor(MapLoc.y)%ScreenSize.y)
            for X=1,math.ceil((WithinLoc.x+Obj.Size.x)/ScreenSize.x) do
                CheckQuota()
                local A=self.ObjectsLocMap[X+MapLoc.x-1]
                if A==nil then
                    self.ObjectsLocMap[X+MapLoc.x-1]={}
                    self.ObjectGeneratedDirMap[X+MapLoc.x-1]={}
                    A=self.ObjectsLocMap[X+MapLoc.x-1]
                end
                for Y=1,math.ceil((WithinLoc.y+Obj.Size.y)/ScreenSize.y) do
                    if A[Y+MapLoc.y-1]==nil then
                        A[Y+MapLoc.y-1]={}
                        self.ObjectGeneratedDirMap[X+MapLoc.x-1][Y+MapLoc.y-1]=vec2(0)
                    end
                    A[Y+MapLoc.y-1][Obj.ID]=Obj

                    Obj.MapLoc[#Obj.MapLoc+1]=vec2(X-1,Y-1)+MapLoc
                end
            end
        end
        ,ObjsFromAreaInMap=function(self,Pos,Size2)
            local RoundedLoc=Pos
            RoundedLoc.x=math.floor(RoundedLoc.x)
            RoundedLoc.y=math.floor(RoundedLoc.y)
            local MapLoc=RoundedLoc/ScreenSize
            MapLoc.x=math.floor(MapLoc.x)
            MapLoc.y=math.floor(MapLoc.y)
            local WithinLoc=vec2(math.floor(RoundedLoc.x)%ScreenSize.x,math.floor(RoundedLoc.y)%ScreenSize.y)
            local Out={}
            for X=1,math.ceil((WithinLoc.x+Size2.x)/ScreenSize.x) do
                local A=self.ObjectsLocMap[X+MapLoc.x-1]
                if A~=nil then
                    for Y=1,math.ceil((WithinLoc.y+Size2.y)/ScreenSize.y) do
                        if A[Y+MapLoc.y-1]~=nil then
                            CheckQuota()
                            for i,k in pairs(A[Y+MapLoc.y-1]) do  Out[i]=k end
                        end
                    end
                end
            end
            return Out
        end
        ,EachAreaInMapFromArea=function(self,Pos,Size2)
            local RoundedLoc=Pos
            RoundedLoc.x=math.floor(RoundedLoc.x)
            RoundedLoc.y=math.floor(RoundedLoc.y)
            local MapLoc=RoundedLoc/ScreenSize
            MapLoc.x=math.floor(MapLoc.x)
            MapLoc.y=math.floor(MapLoc.y)
            local WithinLoc=vec2(math.floor(RoundedLoc.x)%ScreenSize.x,math.floor(RoundedLoc.y)%ScreenSize.y)
            local Out={}
            for X=1,math.ceil((WithinLoc.x+Size2.x)/ScreenSize.x) do
                local GX=X+MapLoc.x-1
                
                local A=self.ObjectsLocMap[GX]
                for Y=1,math.ceil((WithinLoc.y+Size2.y)/ScreenSize.y) do
                    local GY=Y+MapLoc.y-1
                    local B=self.Hook:OnEvent("CheckChunkAvailability",{self,vec2(GX,GY)*ScreenSize,ScreenSize})
                    local LExist=false
                    for i,k in pairs(B) do
                        if k then
                            LExist=true
                            break
                        end
                    end
                    if A~=nil then
                        if A[GY]~=nil then
                            if next(A[GY]) then
                                if Out[GX]==nil then Out[GX]={} end
                                Out[GX][GY]=A[GY]
                                LExist=false
                            end
                        end
                    end
                    if LExist then
                        if Out[GX]==nil then Out[GX]={} end
                        Out[GX][GY]={}
                    end
                end
            end
            return Out
        end

        ,ObjsDrawableInMap=function(self)
            local Meow=self:ObjsFromAreaInMap(vec2(0)-self.Scroll,self.ObjParent.Size)
            local Current=self:EachAreaInMapFromArea(vec2(0)-self.Scroll,self.ObjParent.Size)
            local Previous=self.LoadedObjects
            self.LoadedObjects=Current
            local AddedChunks={}
            local VisibleObjects={}
            for i2,k2 in pairs(Current) do
                for i,k in pairs(k2) do
                    if Previous[i2]~=nil then if Previous[i2][i]~=nil then continue end end
                    --print("ChunkAdded ",i2,i)
                    local Last=vec2(0,0)
                    local FoundLastXTimes=0
                    for x=-1,1 do
                        for y=-1,1 do 
                            CheckQuota()
                            if y==0 and x==0 then else
                                if AddedChunks[i2+x]~=nil then if AddedChunks[i2+x][i+y]~=nil then Last=vec2(x,y)  end end
                                if Previous[i2+x]~=nil then 
                                    if Previous[i2+x][i+y]~=nil then 
                                        Last=vec2(x,y)
                                        if self.ObjectGeneratedDirMap[i2+x][i+y].y ~= 0 and self.ObjectGeneratedDirMap[i2+x][i+y].y == -Last.y then-- This is temperary this whole last system should change if I decide to really add the x direction
                                            Last=vec2(0)
                                        end
                                    end 
                                end
                            end
                        end
                    end
                    --print(Last)
                    local A=self.Hook:OnEvent("ChunkAdded",{self,vec2(i2,i)*ScreenSize,ScreenSize,Last})
                    self.ObjectGeneratedDirMap[i2][i]=Last
                    if AddedChunks[i2]==nil then AddedChunks[i2]={} end 
                    AddedChunks[i2][i]=true
                    
                    for i,k in pairs(A) do
                        for i2,k2 in pairs(k) do
                            CheckQuota()
                            if k2~=nil then
                                Meow[k2.ID]=k2
                                self.LoadedInObjs[k2.ID]=k2
                                VisibleObjects[k2.ID]=true
                            end
                        end
                    end
                    
                end
            end
            
            for i2,k2 in pairs(Previous) do
                for i,k in pairs(k2) do
                    if Current[i2]~=nil then if not(Current[i2][i]==nil or Current[i2][i]=={}) then continue end end
                    
                    self.Hook:OnEvent("ChunkRemoved",{self,i2,i})
                    local Count=0
                    for i3,k3 in pairs(k) do
                        CheckQuota()
                        if Meow[k3.ID]==nil then
                            self.Hook:OnEvent("LoadedObjOutofScreen",k3)
                            --print("Removed")
                        end
                        self.LoadedInObjs[k3.ID]=nil
                        Count=Count+1
                    end
                    --print("ChunkRemoved ",i2,i,Count)
                end
            end
            
            return Meow
        end
        ,ObjsAroundObjInMap=function(self,Obj)
            return self:ObjsFromAreaInMap(Obj.RelPosition,Obj.Size)
        end
        ,ZListIter=function(self)
            local i = 0      -- iterator variable
            local a = self.DrawOrderList
            local t = self.DrawOrderTable
            local iter = function ()   -- iterator function
                i = i + 1
                if a[i] == nil then return nil
                else return a[i], t[a[i]]
                end
            end
            return iter
        end
        ,RemoveClickable=function(self,Obj)
            if self.ClickableObjects[Obj.ID] ~= nil then
                self.ClickableObjects[Obj.ID]=nil
                if next(self.ClickableObjects)==nil and not self.ObjParent.Clickable and not self.ObjParent.Hidden and self.ObjParent.CurrentLayout==self.LayoutN and self.ObjParent.ParentLayout ~= nil then
                    CheckQuota()
                    self.ObjParent.ParentLayout:RemoveClickable(self.ObjParent)
                end
            end
        end
        ,AddClickable=function(self,Obj)
            if not Obj:GetDrawable() then return end
            if next(self.ClickableObjects)==nil and not self.ObjParent.Clickable and not self.ObjParent.Hidden and self.ObjParent.CurrentLayout==self.LayoutN and self.ObjParent.ParentLayout ~= nil then
                CheckQuota()
                self.ObjParent.ParentLayout:AddClickable(self.ObjParent)
            end
            self.ClickableObjects[Obj.ID]=Obj
        end
        ,SetObjClickable=function(self,Obj,Click)
            if Click then
                self:AddClickable(Obj)
            else
                self:RemoveClickable(Obj)
            end
        end
        ,RemoveObjFromLayout=function(self,Obj)
            self.Objects[Obj.ID]=nil
            self:RemoveDrawObjFromLayout(Obj)
            self:RemoveFromMap(Obj)
        end
        ,RemoveFromZOrderTable=function(self,Obj)
            if self.DrawOrderTable[Obj.DrawZ] ~= nil then
                self.DrawOrderTable[Obj.DrawZ][Obj.ID]=nil
                if #self.DrawOrderTable[Obj.DrawZ]==0 then self.DrawOrderTable[Obj.DrawZ] = nil end
                return true
            end
            return false
        end
        ,AddToZOrderTable=function(self,Obj)
            if self.DrawOrderTable[Obj.DrawZ] == nil then self.DrawOrderTable[Obj.DrawZ]={} end
            self.DrawOrderTable[Obj.DrawZ][Obj.ID]=Obj
        end
        ,RemoveDrawObjFromLayout=function(self,Obj)
            if self:RemoveFromZOrderTable(Obj) then self:RemakeZOrderList() end
            local B=self.OverlappingObjs[Obj.ID]
            if B~=nil then
                for i,k in pairs(B) do
                    CheckQuota()
                    if self.UnderlappingObjs[i] ~= nil then
                        self.UnderlappingObjs[i][Obj.ID]=nil
                        if #self.UnderlappingObjs[i]==0 then
                            self.UnderlappingObjs[i]=nil
                        end
                    end
                end
            end
            self.OverlappingObjs[Obj.ID]=nil
            self:RemoveClickable(Obj)
        end
        --Rules, remove Offsetentry with 0 entries
        --if update a set of objects, you add one to the OffsetIDList[currentID] count and subtract one from the count it was previously. Done(unless all the objects are the same ones from the last entry)
        --On update you add the offset to all of the OffsetIDList entries, except the ones you just updated. Done
        --On update the previous OffsetID Vec2 is added to the current offset vec2 in the object. Done
        --On creation of an object add one to the OffsetIDList[currentID] and set the OffsetID to currentID. Done
        ,ApplyOff=function(self,Off)
            if Off.x==0 and Off.y == 0 then return end
            for i,k in pairs(self.OffsetIDList) do
                k[2]=k[2]+Off
            end
            if self.OffsetIDList[self.CurrentOffsetID][1]~=0 then
                self.CurrentOffsetID=self.CurrentOffsetID+1
                self.OffsetIDList[self.CurrentOffsetID]={0,vec2(0)}
            end
            for i,k in pairs(self:ObjsDrawableInMap()) do
                CheckQuota()
                local AppliedOff=self.OffsetIDList[k.OffsetID][2]
                if self.CurrentOffsetID~=k.OffsetID then
                    local Bla=self.OffsetIDList[k.OffsetID]
                    Bla[1]=Bla[1]-1
                    k.OffsetID=self.CurrentOffsetID
                end
                local Bla=self.OffsetIDList[k.OffsetID]
                Bla[1]=Bla[1]+1
                k.OffPosition=k.OffPosition+AppliedOff
                for i2,k2 in pairs(k.Layouts) do
                    CheckQuota()
                    if k.CurrentLayout==i2 then
                        k2:ApplyOff(AppliedOff)
                    else
                        k2.OffsetPos=k2.OffsetPos+AppliedOff
                    end
                end
            end
            for i,k in pairs(self.OffsetIDList) do
                CheckQuota()
                if k[1]==0 then
                    if i~=self.CurrentOffsetID then
                        self.OffsetIDList[i]=nil
                    end
                end
            end
        end
        ,CheckDrawability=function(self,Obj)
            local AT=Obj:getRenderBound()
            --printTable(getmetatable(self.ObjParent:getRenderBound()))
            Obj.Drawable=self.ObjParent:getRenderBound():check(AT) and not Obj.Hidden
        end
        ,CheckAllDrawability=function(self)
            self.DrawOrderTable={}
            self.ClickableObjects={}
            for i,k in pairs(self:ObjsDrawableInMap()) do
                CheckQuota()
                self:CheckDrawability(k)
                if k.Drawable then
                    self:AddToZOrderTable(k)
                    if k:GetClickablity() then
                        self:AddClickable(k)
                    end
                end
                
            end
            if next(self.ClickableObjects)==nil and not self.ObjParent.Clickable and not self.ObjParent.Hidden and self.ObjParent.CurrentLayout==LayoutN and self.ObjParent.ParentLayout ~= nil then
                self.ObjParent.ParentLayout:RemoveClickable(self.ObjParent)
            end
            self:RemakeZOrderList()
        end
        ,ApplyDrawability=function(self,Able)
            if Able==true then
                self.DrawOrderTable={}
                self.ClickableObjects={}
                for i,k in pairs(self:ObjsDrawableInMap()) do
                    CheckQuota()
                    self:CheckDrawability(k)
                    if k.Drawable then
                        self:AddToZOrderTable(k)
                        if k:GetClickablity() then
                            self:AddClickable(k)
                        end
                    end
                    for i2,k2 in pairs(k.Layouts) do
                        if k.CurrentLayout==i2 then
                            k2:ApplyDrawability(Able)
                        end
                    end
                end
                if next(self.ClickableObjects)==nil and not self.ObjParent.Clickable and not self.ObjParent.Hidden and self.ObjParent.CurrentLayout==LayoutN and self.ObjParent.ParentLayout ~= nil then
                    self.ObjParent.ParentLayout:RemoveClickable(self.ObjParent)
                end
                self:RemakeZOrderList()
            else
                for i,k in pairs(self:ObjsDrawableInMap()) do
                    CheckQuota()
                    k.Drawable=false
                    for i2,k2 in pairs(k.Layouts) do
                        if k.CurrentLayout==i2 then
                            k2:ApplyDrawability(Able)
                        end
                    end
                end
                if not self.ObjParent.Clickable and not self.ObjParent.Hidden and self.ObjParent.CurrentLayout==LayoutN and self.ObjParent.ParentLayout ~= nil then
                    self.ObjParent.ParentLayout:RemoveClickable(self.ObjParent)
                end
            end
        end
        ,ChangeScroll=function(self,NScroll)
            if NScroll.x==self.Scroll.x and NScroll.y==self.Scroll.y then return end
            local OldScroll=self.Scroll
            self:ApplyDrawability(false)
            self.Scroll=NScroll
            
            self:ApplyOff(NScroll-OldScroll)
            self:CheckAllDrawability()
        end
        ,FindObjAtPos=function(self,Pos)
            for i,k in pairs(self.ClickableObjects) do
                CheckQuota()
                local ObjC = k:GetObjAtPos(Pos)
                if ObjC~=nil then
                    return ObjC
                end
            end
            return nil
        end
        ,AddObjToData=function(self,Obj)
            self.Objects[Obj.ID]=Obj
            local C=self.OffsetIDList[self.CurrentOffsetID]
            if C[2].x~=0 or C[2].y~=0 then
                self.CurrentOffsetID=self.CurrentOffsetID+1
                self.OffsetIDList[self.CurrentOffsetID]={0,vec2(0)}
                C=self.OffsetIDList[self.CurrentOffsetID]
            end
            Obj.OffsetID=self.CurrentOffsetID
            local Bla=self.OffsetIDList[Obj.OffsetID] --Don't judge me, I don't know how much optimization LUA does.
            Bla[1]=Bla[1]+1
            self:AddToMap(Obj)
            self:CheckDrawability(Obj)
            if Obj:GetDrawable() then
                self:AddToZOrderTable(Obj)
                self:RemakeZOrderList()
                self:RefreshObj(Obj,true)
                if Obj:GetClickablity() then
                    self:AddClickable(Obj)
                end
            end
        end
        ,UpdateDrawZ=function(self,Obj,NDrawZ)
            self:CheckDrawability(Obj)
            if not Obj:GetDrawable() then Obj.DrawZ=NDrawZ return end
            if self.DrawOrderTable[Obj.DrawZ] ~= nil then
                self.DrawOrderTable[Obj.DrawZ][Obj.ID]=nil
                if #self.DrawOrderTable[Obj.DrawZ]==0 then self.DrawOrderTable[Obj.DrawZ] = nil end
            end
            if self.DrawOrderTable[NDrawZ] == nil then self.DrawOrderTable[NDrawZ]={} end
            self.DrawOrderTable[NDrawZ][Obj.ID]=Obj
            Obj.DrawZ=NDrawZ
            self:RemakeZOrderList()
        end
        ,RefreshObj=function(self,Obj,First)
            if First==nil then
                self:RemoveFromMap(Obj)  self:AddToMap(Obj)
                local F=Obj.Drawable
                self:CheckDrawability(Obj)
                
                if F~=Obj.Drawable then
                    local A= Obj:GetClickablity()
                    if not F then
                        self:AddToZOrderTable(Obj)
                        if A then
                            self:AddClickable(Obj)
                        end
                    else
                        if A then
                            self:RemoveClickable(Obj)
                        end
                        self:RemoveFromZOrderTable(Obj)
                    end
                end
                self:RemakeZOrderList()
            end
            for i,k in pairs(self:ObjsAroundObjInMap(Obj)) do
                CheckQuota()
                if i~=Obj.ID then
                    if Obj.BoundingVolume:check(k.BoundingVolume) then
                        local O1,O2 = Obj,k
                        if O1.DrawZ>O2.DrawZ or (O1.DrawZ==O2.DrawZ and O1.ID>O2.ID) then else
                            O2,O1=O1,O2
                        end
                        if self.OverlappingObjs[O1.ID] == nil then
                            self.OverlappingObjs[O1.ID]={}
                        end
                        if self.UnderlappingObjs[O2.ID] == nil then
                            self.UnderlappingObjs[O2.ID]={}
                        end
                        self.UnderlappingObjs[O2.ID][O1.ID]=O1
                        self.OverlappingObjs[O1.ID][O2.ID]=O2
                    else
                        if self.OverlappingObjs[O1.ID] ~= nil then
                            self.OverlappingObjs[O1.ID][O2.ID]=nil
                            if #self.UnderlappingObjs[O1.ID] == 0 then
                                self.UnderlappingObjs[O1.ID] = nil
                            end
                        end
                        if self.UnderlappingObjs[O2.ID] ~= nil then
                            self.UnderlappingObjs[O2.ID][O1.ID]=nil
                            if #self.UnderlappingObjs[O2.ID] == 0 then
                                self.UnderlappingObjs[O2.ID] = nil
                            end
                        end
                    end
                end
            end
        end
    })
end