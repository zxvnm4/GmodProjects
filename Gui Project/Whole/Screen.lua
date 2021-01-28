--@include Object.lua
--@include Layout.lua
--@include Base.lua
require("Base.lua")
require("Object.lua")
require("Layout.lua")
if CLIENT then
    local ConversionTable="0123456789abcdefghijklmnopqrstuvwxyz"
    local ConversionTableS=")!@#$%^&*(ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local ConversionArray={k62="-",k63="=",k53="[",k54="]",k61="\\",k55=";",k56="'",k58=",",k59=".",k60="/"}
    local ConversionArrayS={k62="_",k63="+",k53="{",k54="}",k61="|",k55=":",k56="\"",k58="<",k59=">",k60="?",k57="~"}
    local NonShiftConvArr={k65=" ",k64="\n",k66="\x09",k88="\x11",k89="\x12",k90="\x13",k91="\x14"}
    local ScreenID=0
    Ent=chip()
    Screen = ZClass(function(self)
        ScreenID=ScreenID+1
        self.ID=ScreenID
        self.LastRenderArea=BoundingBox(vec2(0,0),vec2(99999999,9999999999))

        self.DebugLines={}

        self.ScreenPosition=Vector(0,0,0)

        self.Root=Object(self)
        self.LookingAtScreen=false
        self.AimPos=vec2(0)
        self.LAimPos=vec2(0)
        self.CurrentlyDrawingToScreen=false

        self.CurrentlySelected=nil
        self.CurrentlyClicked=nil
        self.LastClickedObject=nil
        self.Frozen=false
        self.Click=true
        self.SomethingMoved=false
        self.RenderQueue={}
        self.ChangeList={}
        self.RenderUsedChangeList={}
        self.ScreenEnt=nil
        self.ScreenSize=vec2(512)
        self.ApplyRenderChangesCoroutine=nil
        self.ApplyRenderChanges=nil
        self.RenderChanges=nil
        self.SomeFontMan=render.createFont( "DejaVu Sans Mono", 13, 400, false, false, false, false, false, false )
        self.SomeFontMan2=render.createFont( "DejaVu Sans Mono", 13, 500, false, false, false, true, false, false )
        self.DisableKeyPressTim=timer.curtime()
        self.DisableKeyReleaseTim=timer.curtime()
        self.ButtonPressed=false
        self.ButtonsPressed={}
        self.LockControlState=false
        self.LastControlLockState=false
        self.IsFreezable=false
        self.NotDrawnRoot=false
    end,{
        InitScreen = function(self)
            net.receive("GetScreenPos",function(len,ply)
                Type=net.readString()
                if Type=="GetScreenPos" then
                    self.ScreenPosition=net.readVector()
                end
            end)

        end
        ,DrawCursor = function(self)
            if self.LookingAtScreen then
                render.setColor(Color(255,255,255))
                render.drawRect(self.AimPos.x-2,self.AimPos.y-2,4,4)
            end
        end
        ,GetAimPosManual = function(self)
            local Ent=render.getScreenEntity()
            local Info,ResX,ResY=render.getScreenInfo(Ent),render.getResolution()
            local Tracec
            local Loc=player():getShootPos()
            local X,Y=input.getCursorPos(  )
            Tracec=trace.trace(Loc,Loc+input.screenToVector(X, Y)*1000,{player()})
            if Tracec["Entity"]==Ent then
                local Size=Vector(math.abs(Info.x2-Info.x1),math.abs(Info.y2-Info.y1),1)
                local Meow=Ent:worldToLocal(Tracec["HitPos"])-Info.offset--+Vector(Info.x1,Info.y1,0)
                
                Counts=Counts+1
                local M=Matrix()
                M:setIdentity()
                M:rotate(Info.rot)
                M:invert()
                Meow=VecMatMul(Meow,M)
                -- if Counts==60 then Counts=0  print((Meow/Size)) end
                local AimPos=(Vector(0.5,-0.5,0)+(Meow/Size))*Vector(ResX,ResY,1)
                AimPos=vec2(-AimPos[2],AimPos[1])
                if AimPos.x<=ResX and AimPos.x>=0 and AimPos.y<=ResY and AimPos.y>=0 then
                    return AimPos
                end
            end
            --AimPos=((Ent:worldToLocal(Tracec["HitPos"])/(Ent:obbSize()/2)*Vector((522/512)/2,(522/512)/2,0))+Vector(0.5,0.5,0))*Vector(512,512,0)
            return nil
        end
        ,DrawDebugText = function(self,X,Y,Str)
            render.setColor(Color(0,0,0,255)) 
            render.setFont(self.SomeFontMan2)
            render.drawSimpleText( X, Y, Str, 0, 0 )
            render.setColor(Color(255,255,255)) 
            render.setFont(self.SomeFontMan)
            render.drawSimpleText( X, Y, Str, 0, 0 )
        end
        ,DrawDebugInfo = function(self)
            local QAve=quotaTotalAverage()
            self:DrawDebugText(10,10,"CPU Quota Average: "..tostring(math.floor(QAve*1000000)).."us "..tostring(math.floor(QAve*100/quotaMax())).."%")
            for i,k in pairs(self.DebugLines) do
                self:DrawDebugText( 10, 10+i*10, k)
            end
        end
        ,ScreenRenderer = function(self)
            self.LookingAtScreen=false
            local X,Y = render.cursorPos()
            local W,H = render.getResolution()
            --local W,H = 512,512
            if W~=nil then
                self.ScreenSize=vec2(W,H)
                self.ScreenEnt=render.getScreenEntity()
                if X then
                    self.AimPos=vec2(X,Y)
                    self.LookingAtScreen=true
                end

                render.setRenderTargetTexture("Target")
                render.drawTexturedRect(0,0,512*2,512*2)
                self:RenderChanges() --Reminder the fancy dancy RenderObjBoxGraph messes around with the TargetTexture
                render.enableScissorRect( 0,0,512*2,512*2)
                if quotaTotalAverage()<=quotaMax()*0.95 then
                    self:DrawCursor()
                    self:DrawDebugInfo()
                end
            end
        end
        ,RenderChanges = function(self)
            render.selectRenderTarget("Target2") 
            render.enableScissorRect( self.LastRenderArea.P.x, self.LastRenderArea.P.y, self.LastRenderArea.P.x+self.LastRenderArea.S.x, self.LastRenderArea.P.y+self.LastRenderArea.S.y )
            local Stat=coroutine.status(self.ApplyRenderChangesCoroutine)
            if Stat=="dead" then
                self.ApplyRenderChangesCoroutine=coroutine.create(function() self:ApplyRenderChanges() end)
                coroutine.resume(self.ApplyRenderChangesCoroutine)
            else
                coroutine.resume(self.ApplyRenderChangesCoroutine)
            end
            local Stat=coroutine.status(self.ApplyRenderChangesCoroutine)
            if quotaTotalAverage()<=quotaMax()*0.95 then
                if Stat=="dead" then
                    render.enableScissorRect( 0,0,512*2,512*2)
                    render.selectRenderTarget("Target")
                    render.setRenderTargetTexture("Target2")
                    render.setColor(Color(255,255,255))
                    render.drawTexturedRect(0,0,512*2,512*2)
                    render.setRenderTargetTexture()
                end
            end
            render.selectRenderTarget()
        end
        ,ApplyRenderChanges = function(self)
            
            while next(self.ChangeList)~=nil do
                self.RenderUsedChangeList=self.ChangeList
                self.ChangeList={}
                local RenderableObjs={}
                for i,k in pairs(self.RenderUsedChangeList) do--I can just make it so there is a settin in the obj file, cus that would be better
                    RenderableObjs[i]=k[1]
                end
                
                local I,K=next(RenderableObjs)
                while I~= nil do
                    IN,KN=next(RenderableObjs,I)
                    for i,k in pairs(RenderableObjs) do
                        if IN~=i and K:CheckIfParent(k) then
                            RenderableObjs[I]=nil
                            break
                        end
                    end
                    I=IN
                    K=KN
                end
                for i,k in pairs(self.RenderUsedChangeList) do
                    local Renderable=RenderableObjs[i] ~= nil
                    --local Meow=coroutine.create(function()
                    for i2,k2 in pairs(k[4]) do
                        if k2~=-1 then
                            for Id,JobOb in pairs(k2[5]) do
                                JobOb:StartedJob()
                            end
                        end
                    end
                    local State=k[2]
                    local BB=nil
                    local ChangeMade=false
                    if Renderable and State==2 then
                        for i2,k2 in pairs(k[4]) do
                            if k2~=-1 then
                                if k2[4]==nil then
                                    if BB==nil then
                                        BB=k2[1](k[1],k2[4])
                                    else
                                        BB=BB:combineArea(k2[1](k[1],k2[4]))
                                    end
                                else
                                    if BB==nil then
                                        BB=k2[1](k[1],false,unpack(k2[4]))
                                    else
                                        BB=BB:combineArea(k2[1](k[1],true,unpack(k2[4])))
                                    end
                                end
                            end
                        end
                        k[1]:renderErase(BB)
                        ChangeMade=true
                        BB=nil
                    end
                    local Visible
                    
                    for i2,k2 in pairs(k[4]) do
                        if k2~=-1 then
                            if k2[4]~=nil then
                                if Renderable and (State==3 or State==2) then
                                else
                                    k2[1](k[1],false,unpack(k2[4]))
                                end
                            end
                            k2[2](k[1],unpack(k2[3]))
                            if k2[4]==nil then
                                if BB==nil then
                                    BB=k2[1](k[1],k2[4])
                                else
                                    BB=BB:combineArea(k2[1](k[1],k2[4]))
                                end
                            else
                                if BB==nil then
                                    BB=k2[1](k[1],true,unpack(k2[4]))
                                else
                                    BB=BB:combineArea(k2[1](k[1],true,unpack(k2[4])))
                                end
                            end
                        end
                    end
                    
                    if Renderable and (State==2 or State==1 or State==3) and ChangeMade then
                        if State==3 then
                            k[1]:renderErase(BB)
                        else
                            k[1]:renderComplete(BB)
                        end
                    end
                    for i2,k2 in pairs(k[4]) do
                        if k2~=-1 then
                            for Id,JobOb in pairs(k2[5]) do
                                JobOb:FinishedJob() 
                            end
                        end
                    end
                    CatsTest=false
                    --end)
                    
                    --coroutine.resume(Meow)
                    
                    --if coroutine.status(Meow)~="dead" then
                    --    while coroutine.status(Meow)~="dead" do
                    --        coroutine.yield()
                    --        coroutine.resume(Meow)
                    --    end
                    --    break
                    --end
                end
                self.RenderUsedChangeList={}
            end
        end
        ,enablelockcontrolsonscreen = function(self,State)
            if self.LockControlState==State then return end
            self.LockControlState=State
            net.start("enablelockcontrols")
            net.writeString("enablelockcontrols")
            if State then
                net.writeBit(1)
            else
                net.writeBit(0)
            end 
            net.send(nil,false)
        end
        ,FromKeyToChar = function(self,key,shift)
        
            local char=''
            if (key>=1 and key<=36) then
                if shift then
                    char= ConversionTableS[key]
                else
                    char= ConversionTable[key]
                end
            else
                if shift then
                    if ConversionArrayS["k"..key]~=nil then
                        char= ConversionArrayS["k"..key]
                    end
                else
                    if ConversionArray["k"..key]~=nil then
                        char= ConversionArray["k"..key]
                    end
                end
                if char=='' then
                    if NonShiftConvArr["k"..key]~=nil then
                        char= NonShiftConvArr["k"..key]
                    end
                end
            end
            return char
        end
        ,OnChar = function(self,Ch,Key)
            
            if input.isControlLocked() and self.LastClickedObject~=nil then
                self.LastClickedObject:OnEvent("OnChar",Ch)
            end
        end
        ,CharPress = function(self,Key)
            local Ch=FromKeyToChar(Key,input.isShiftDown())
            if Ch~='' then
                self.OnChar(Ch,Key)
                timer.remove("CharHold"+tostring(self.ID))
                timer.remove("CharRepeat"+tostring(self.ID))
                timer.create("CharHold"+tostring(self.ID),0.5,1,function()
                    self.OnChar(Ch,Key)
                    timer.create("CharHold"+tostring(self.ID),0.05,0,function()
                        self.OnChar(Ch,Key)
                    end)
                end)
            end
        end
        ,CharRelease = function(self,Key)
            timer.remove("CharHold"+tostring(self.ID))
            timer.remove("CharRepeat"+tostring(self.ID))
        end
        ,CharRelease = function(self,Key)
            timer.remove("CharHold"+tostring(self.ID))
            timer.remove("CharRepeat"+tostring(self.ID))
        end
        ,OnKeyPress = function(self,Key)
            --if DisableKeyPressTim<=timer.curtime() then
                if (Key==15 or Key==28 or Key==107) and not self.ButtonPressed then-- (Key==15 or Key==107 or Key==28)
                    if self.LookingAtScreen and self.CurrentlySelected~=nil then
                        self.CurrentlySelected:OnEvent("KeyPress",Key)
                        self.CurrentlyClicked=self.CurrentlySelected
                    end
                    
                    self.ButtonPressed=true
                end
                if input.isControlLocked() and self.LastClickedObject~=nil and self.ButtonsPressed[Key]==nil then
                    self.LastClickedObject:OnEvent("KeyboardPress",Key)
                    CharPress(Key)
                end
                self.ButtonsPressed[Key]=true
                self.DisableKeyPressTim=timer.curtime()+0.02
            --end
        end 
        ,KeyRelease = function(self,Key) 
            --if DisableKeyReleaseTim<=timer.curtime() then
                if (Key==15 or Key==28 or Key==107) then
                    if self.LookingAtScreen and self.CurrentlyClicked~=nil and self.ButtonPressed then
                        self.CurrentlyClicked:OnEvent("KeyRelease",Key)
                        self.CurrentlyClicked=nil
                        
                    end
                    self.ButtonPressed=false
                end
                if input.isControlLocked() and self.LastClickedObject~=nil and self.ButtonsPressed[Key]~=nil then
                    self.LastClickedObject:OnEvent("KeyboardRelease",Key)
                    CharRelease(Key)
                end
                self.ButtonsPressed[Key]=nil
                --DisableKeyReleaseTim=timer.curtime()+0.005
            --end
        end
        ,InputTickTimer = function(self)
            if quotaTotalAverage()>=quotaMax()*0.8 then
                return
            end
            if self.LookingAtScreen then
                if (self.AimPos.x~=self.LAimPos.x or self.AimPos.y~=self.LAimPos.y) or self.SomethingMoved then
                    local Selected=self:ObjAtPos(self.AimPos)
                    if self.CurrentlySelected~=Selected then
                        if self.CurrentlySelected~=nil then
                            self.CurrentlySelected:OnEvent("Deselected")
                        end
                        if Selected~=nil then
                            self.IsFreezable=Selected.Writable
                            Selected:OnEvent("Selected")
                        else
                            self.IsFreezable=false
                        end
                    end
                    self.CurrentlySelected=Selected
                end
                
            else
                self.IsFreezable=false
                if self.CurrentlySelected~=nil then
                    self.CurrentlySelected:OnEvent("Deselected")
                end
                self.CurrentlySelected=nil
            end
            if input.isControlLocked() ~= self.LastControlLockState then
                if self.LastClickedObject~=nil then 
                    for i,k in pairs(self.ButtonsPressed) do
                        self.LastClickedObject:OnEvent("KeyboardRelease",i)
                    end
                    self.LastClickedObject:OnEvent("IsNoLongerClickedObject")
                end
                if input.isControlLocked() and self.CurrentlySelected~=nil then 
                    self.CurrentlySelected:OnEvent("IsNowClickedObject")
                    --for i,k in pairs(ButtonsPressed) do
                    --    self.CurrentlySelected:OnEvent("KeyboardPress",i)
                    --end
                    self.LastClickedObject=self.CurrentlySelected
                end
                if not input.isControlLocked() then
                    self.LastClickedObject=nil
                end
            end
            self.LastControlLockState=input.isControlLocked()
            self:enablelockcontrolsonscreen(self.IsFreezable)
            self.LAimPos=self.AimPos
            self.SomethingMoved=false
        end
        ,InitScreen = function(self)
            self.ApplyRenderChangesCoroutine=coroutine.create(function() self:ApplyRenderChanges() end)

            render.createRenderTarget("Target")
            render.createRenderTarget("Target2")
            hook.add("Render","Render412",function() self:ScreenRenderer() end)

            hook.add("inputPressed","KeyP1",function(Key) self:OnKeyPress(Key) end )
            hook.add("inputPressed","KeyP2",function (Key) 
                if self.Frozen then
                    return true
                end
            end)
            hook.add("inputReleased","KeyP2",function(Key) self:KeyRelease(Key) end )
            timer.create( "InputTick", 1/20, 0, function() self:InputTickTimer() end )
        end
        ,StartDrawingRoot = function(self)
            NotDrawnRoot=false
            AddToChangeList(self.Root,1,true,"Refresh",self.Root.getRenderBound,self.Root.Refresh,{})
        end
        ,ObjAtPos = function(self,Pos)
            return self.Root:GetObjAtPos(Pos)
        end
        --[[
            Ok so man I got somethin for ya, the job idea up there is fairly cool and all but don't you just want to make it better!
            Well I got something just for you, a plan! So look something like the scrolling feature or the fancy audio visualizer thingy, they all are just boring as they are
            They hardly have what you call... Scheduling! That is right I'm going to combine that scheduling feature with jobs!
            It's gonna be a boosted scheduler to be honest, but it will use the jobs feature to tell when it can schedule another event.
            So the main scheduler, has 2 features, time and tick, the next two ones are going to be CPUQuota and JobReady.
            It should be a sinch to add those two features, the logic is simple.
            If time or tick are ticked then it will see if CPUQuota and JobReady are good if they are it will continue, otherwise it will "wait" for CPUQuota to get 
            better(has to constantly check) and JobReady to issue it's finished event.

            So Basically it's like this On Time/Tick/Job/CPUQuotaCheck it will see if Time/Tick/Job/CPUQuota are all good, if they are then issue the event.

            It will simply act like an object timer you have in C# or something, it will issue the stuff to the ChangeList when it's done under the job that it represents
        ]]



        --[[
            Ok so this is the plan, take the Key and convert it to a char
            So this means I got to make another event hook, for Characters.
            I think I'll make it function the same way that computercraft acts, or my C++ GUI library acts.
            Like, backspace will be the backspace ascii char, if you hold down a key it will run faster after a short delay, enter is newline and yada yada.
            It will be fun!
        ]]
    })

        

        --[[            if ChangeList[Obj.ID] == nil then -- the State==3 could include some funky bugs.
                    ChangeList[Obj.ID]={Obj,State,{},{}}
                    ChangeList[Obj.ID][4][1]={BBFunc,Func,Args,BBArgs}
                    ChangeList[Obj.ID][3][Type]=1
                else
                    ChangeList[Obj.ID][2]=math.max(ChangeList[Obj.ID][2],State)
                    local B=ChangeList[Obj.ID][4]
                    if OverlapEvent and ChangeList[Obj.ID][3][Type]~=nil then
                        B[ChangeList[Obj.ID][3][Type] ]=-1
                    end
                    ChangeList[Obj.ID][3][Type]=#B+1
                    B[#B+1]={BBFunc,Func,Args,BBArgs}
                end--]]
else
    local WeldedTo=chip():isWeldedTo()
    if WeldedTo:getClass()=="starfall_screen" then
        local Doit=true
        --for i,k in pairs(chip():getLinkedComponents()) do
        --    if k==WeldedTo then
        --        Doit=false
        --    end
        --end
        if Doit then
            WeldedTo:linkComponent(chip())
        end
        local LockControlsEnabledByPlayersList={}
        net.receive("enablelockcontrols",function(len, ply ) 
            Type=net.readString()
            if Type=="enablelockcontrols" then
                local Bool=false
                if net.readBit()==1 then
                    Bool=true
                    LockControlsEnabledByPlayersList[ply:getSteamID()]=Bool
                else
                    LockControlsEnabledByPlayersList[ply:getSteamID()]=nil
                end
                local C=0
                for i,k in pairs(LockControlsEnabledByPlayersList) do C=C+1 end
                Bool=false
                if C~=0 then Bool=true end
                --print(Bool)
                WeldedTo:setComponentLocksControls(Bool)
            end
        end)
    end
    timer.create("self.ScreenPositionSending",1,0,function()
        net.start("GetScreenPos")
        net.writeString("GetScreenPos")
        net.writeVector(WeldedTo:getPos())
        net.send()
    end)
end