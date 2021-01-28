--@name Music Player
--@author Zxvnm4
--@shared
--@model models/spacecode/sfchip_medium.mdl
--@includedir Pages
--@include Base.lua
requiredir("Pages")
require("Base.lua")
--I love my use of Capitalization in my func,var names
--I could use stencils to renders stuff proper, no need to render above stuff, only when yar doin transparent stuff(Or non rectangle stuff)
--Oh and it is all in the same bloody piece of code, that... that ain't good man.

--TODO
--Make Option so the CurrentTimeBr goes red or something when it is a live stream, cus... 
--The music shouldn't be on loop
--There is still an issue with the buttons, scrolling and the automatic cycling of songs, if it isn't on the page it isn't selected!... Sometimes?
--There is also an issue with one of the buttons not actually loading, I thought I fixed this... It appears to only happen when  I scroll up? It appears to only happen when I scroll down, then up not up then down

local function ZClassGetSuperClasses(self,K)
    local C=#self[2] 
    for i=1,C do 
        B=self[2][1+C-i]
        if type(B)=="table" then
            if B.C123456789==true then
                BA=ZClassGetSuperClasses(B,K)
                if BA~=nil then
                    return BA
                end
            else
                if B[K]~=nil then
                    return B[K]
                end
            end
        end 
    end
    return nil
end

function ZClass(Constructor,...) --I made this to fulfill 2 criteria, one to decrease ram usage and two to be easy to implement
    local ClassTy={Constructor,{...}}
    ClassTy.C123456789=true
    setmetatable(ClassTy,{
    __index=function(self,Key)
        if Key=="const" then
            return self[1]
        end
        return nil
    end,
    __call=function(self,...)
        local ret = {}
        setmetatable(ret, {
            __super = self,
            __index = function(S,K)
                local self=getmetatable(S).__super
                if K=="const" then
                    return self[1]
                end
                return ZClassGetSuperClasses(self,K)
            end
        })
        self[1](ret,...)
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
            net.start("Cats")
            net.writeString(Str)
            net.send()
        end
    end
else
    hook.add("net","Cats",function( name, len, ply ) 
        Type=net.readString()
        if Type=="Print" then
            Str=net.readString()
            print(ply:getName().." printed: "..Str)
        end
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
BoundingVolume = ZClass(function(self)
    self.Type="Null"
end,{
    check=function(self,BV)
        if type(BV)=="vector" then 
            return self:checkPoint(BV)
        else
            if BV.Type=="Box" then
                return self:checkArea(BV)
            end
        end
        return false
    end
    ,between=function(self,BV)
        if BV.Type=="Box" then
            return self:betweenArea(BV)
        end
        return
    end
    ,within=function(self,BV)
        if BV.Type=="Box" then
            return self:withinArea(BV)
        end
        return false
    end
    ,checkArea=function(BB) return false end
    ,checkPoint=function(Pos) return false end
})
BoundingBox = ZClass(function(self,Pos,Size)
    BoundingVolume.const(self)
    self.Type="Box"
    self.P=Pos
    self.S=Size
end,BoundingVolume,{
    checkArea=function(self,BB) 
        local XOut,YOut = false
        if self.S.x>BB.S.x then
            if self.P.x<=BB.P.x+BB.S.x and self.P.x+self.S.x>=BB.P.x then
                XOut= true
            end
        else
            if BB.P.x<=self.P.x+self.S.x and BB.P.x+BB.S.x>=self.P.x then
                XOut= true
            end
        end
        if self.S.y>BB.S.y then
            if self.P.y<=BB.P.y+BB.S.y and self.P.y+self.S.y>=BB.P.y then
                YOut= true
            end
        else
            if BB.P.y<=self.P.y+self.S.y and BB.P.y+BB.S.y>=self.P.y then
                YOut= true
                
            end
        end
        return (YOut&&XOut)
    end
    ,checkPoint=function(self,Pos) 
        if self.P.x<=Pos.x and self.P.x+self.S.x>=Pos.x then
            if self.P.y<=Pos.y and self.P.y+self.S.y>=Pos.y then
                return true
            end
        end
        return false
    end
    ,withinArea=function(self,BB) 
        if self.P.x>BB.P.x+BB.S.x and self.P.x>BB.P.x and self.P.x+self.S.x<BB.P.x and self.P.x+self.S.x<BB.P.x+BB.S.x then
            if self.P.y>BB.P.y+BB.S.y and self.P.y>BB.P.y and self.P.y+self.S.y<BB.P.y and self.P.y+self.S.y<BB.P.y+BB.S.y then
                return true
            end
        end
        return false
    end
    ,betweenArea=function(self,BB)
        local X=math.max(self.P.x,BB.P.x)
        local Y=math.max(self.P.y,BB.P.y)
        return BoundingBox(vec2(X,Y),vec2(math.min(self.P.x+self.S.x,BB.P.x+BB.S.x)-X,math.min(self.P.y+self.S.y,BB.P.y+BB.S.y)-Y))
    end
    ,combineArea=function(self,BB)
        local X1=math.min(self.P.x,BB.P.x)
        local Y1=math.min(self.P.y,BB.P.y)
        local X2=math.max(self.P.x+self.S.x,BB.P.x+BB.S.x)
        local Y2=math.max(self.P.y+self.S.y,BB.P.y+BB.S.y)
        return BoundingBox(vec2(X1,Y1),vec2(X2-X1,Y2-Y1))
    end
})
function GetPolyBoundingBox(Poly)
    local Min=vec2(10000000,10000000)
    local Max=vec2(0,0)
    for i,k in pairs(Poly) do
        Min.x=math.min(k.x,Min.x)
        Min.y=math.min(k.y,Min.y)
        Max.x=math.max(k.x,Max.x)
        Max.y=math.max(k.y,Max.y)
    end
    return BoundingBox(Min,Max-Min)
end
Job = ZClass(function(self,Parent,Started,Finished)
    self.JobsCompleted=0
    self.JobsStarted=0
    self.Parent=Parent
    self.OnFinished=Finished
    self.OnStarted=Started
end,{
    NewJob=function(self)
        self.JobsStarted=self.JobsStarted+1
        return self.JobsStarted
    end
    ,StartedJob=function(self)
        if self.JobsCompleted==0 then
            self.OnStarted(self)
            if self.Parent~=nil then
                self.Parent:OnFinished()
            end
        end
    end
    ,FinishedJob=function(self) 
        self.JobsCompleted=self.JobsCompleted+1
        if self.JobsCompleted==self.JobsStarted then
            self.OnFinished(self)
            if self.Parent~=nil then
                self.Parent:OnFinished()
            end
        end
    end
})
Scheduler = ZClass(function(self)
        self.Schedule=nil
end,{
    CurrentTick=function(self)
        return 0
    end,
    NewEventAtStart=function(self,t)
    
    end
    ,EmptyEvents=function(self)
        
    end
    ,NewScheduledEvent=function(self,time,func,data)
        if time<=self:CurrentTick() then
            func(unpack(data),time)
            return nil
        end
        local B={Next=nil,Back=nil,Time=time,Func=func,Data=data}
        local Nx=self.Schedule
        if nil==self.Schedule then
            self.Schedule=B
            self:NewEventAtStart(time)
            return B
        end
        while Nx.Next~=nil do
            if Nx.Time>=time then
                if Nx==self.Schedule then
                    self.Schedule=B
                    self:NewEventAtStart(time)
                else
                    B.Back=Nx.Back
                end
                B.Next=Nx
                Nx.Back=B
                return B
            end
            Nx=Nx.Next
        end
        B.Back=Nx
        Nx.Next=B
        return B
    end
    ,RemoveScheduledEvent=function(self,Node)
        local ContinueStuff=true
        if self.Schedule~=nil then
            if Node.Back~=nil then
                Node.Back.Next=Node.Next
            end
            if Node.Next~=nil then
                Node.Next.Back=Node.Back 
            end
            if self.Schedule.Next~=nil then
                if self.Schedule.Next==Node then
                    self.Schedule=self.Schedule.Next
                    self:NewEventAtStart(self.Schedule.Time)
                end
            else
                self.Schedule=nil
                self:EmptyEvents()
            end
        end
    end
    ,Next=function(self)
        if self.Schedule~=nil then
            local C=self.Schedule
            C.Func(unpack(C.Data),C.Time)
            if C.Next~=nil then
                self.Schedule=C.Next
                self.Schedule.Back=nil
                self:NewEventAtStart(self.Schedule.Time)
            else
                self.Schedule=nil
                self:EmptyEvents()
            end
        else
            self:EmptyEvents()
        end
    end
    ,TimerTick=function(self)
        self:Next()
    end
})
TimerScheduler = ZClass(function(self) Scheduler.const(self) end,Scheduler,{
    CurrentTick=function(self)
        return timer.systime()
    end   
    ,NewEventAtStart=function(self,time)
        timer.remove("Scheduler")
        timer.create( "Scheduler", time-timer.systime(), 0, self.TimerTick )
    end
    ,EmptyEvents=function(self)
        timer.stop("Scheduler")
    end
})
TickScheduler = ZClass(function(S)
    Scheduler.const(S)
    S.Schedule=nil
    S.Ticks=0
end,Scheduler,{
    CurrentTick=function(self)
        return self.Ticks
    end   
    ,TimerTick=function(self)
        if self.Schedule~=nil then
            if self.Schedule.Time<=self.Ticks then
                self:Next()
            end
        end
        self.Ticks=self.Ticks+1
    end
})
RenderScheduler = ZClass(function(S)
    S.TimerListID=0
    S.TimerList={}
    S.TickSchedule=TickScheduler()
    S.TimerSchedule=TimerScheduler()
end,{
    Create=function(self,Tick,MinInterval,MaxInterval,MaxQuota,Priority,Func)
        self.TimerListID=self.TimerListID+1--1  2  3  3        4         5           6        7       8      9
        self.TimerList[self.TimerListID]= {nil,nil,0,Tick,MinInterval,MaxInterval,MaxQuota,Priority,Running,Func,Data}
        self:Start(self.TimerListID)
        return self.TimerListID
    end
    ,Remove=function(self,id)
        self:Stop(id)
        self.TimerList[id]=nil
    end
    ,TimerTick=function(self,id,time)
        local Timer=self.TimerList[id]
        if not Timer[8] then return end
        Timer[3]=timer.systime()+Timer[4]
        Timer[1]=self.TimerSchedule:NewScheduledEvent(time+Timer[5],self.TimerTick,{self,id})
        if Timer[2]~=nil then
            self.TickSchedule:RemoveScheduledEvent(Timer[2])
        end
        Timer[2]=self.TickSchedule:NewScheduledEvent(self.TickSchedule.Ticks+Timer[3],self.TickTick,{self,id})
        Timer[9]()
    end
    ,TickTick=function(self,id,time)
        local Timer=self.TimerList[id]
        if not Timer[8] then return end
        if Timer[3]<timer.systime() then
            if Timer[1]~=nil then
                self.TimerSchedule:RemoveScheduledEvent(Timer[1])
            end
            Timer[3]=timer.systime()+Timer[4]
            Timer[1]=self.TimerSchedule:NewScheduledEvent(timer.systime()+Timer[5],self.TimerTick,{self,id})
        end
        Timer[2]=self.TickSchedule:NewScheduledEvent(time+Timer[3],self.TickTick,{self,id})
    end
    ,Start=function(self,id)
        local Timer=self.TimerList[id]
        Timer[1]=self.TimerSchedule:NewScheduledEvent(timer.systime()+Timer[5],self.TimerTick,{self,id})
        Timer[2]=self.TickSchedule:NewScheduledEvent(self.TickSchedule.Ticks+Timer[3],self.TickTick,{self,id})
        Timer[3]=timer.systime()+Timer[4]
    end
})
local Vec2Mt={}
Vec2Mt.__add=function(a,b)
    return vec2(a.x+b.x,a.y+b.y)
end
Vec2Mt.__sub=function(a,b)
    return vec2(a.x-b.x,a.y-b.y)
end
Vec2Mt.__mul=function(a,b)
    if type(b)=="number" then
    return vec2(a.x*b,a.y*b)
    else
        return vec2(a.x*b.x,a.y*b.y)
    end
end
Vec2Mt.__div=function(a,b)
    if type(b)=="number" then
        return vec2(a.x/b,a.y/b)
    else
        return vec2(a.x/b.x,a.y/b.y)
    end
end
Vec2Mt.__eq=function(a,b)
    return a.x==b.x and b.y==b.y
end
Vec2Mt.__tostring=function(a)
    return "("..tostring(a.x)..","..tostring(a.y)..")"
end
local VecSuper={}
VecSuper.lengthSq=function(a)
    return a.x*a.x+a.y*a.y
end
VecSuper.length=function(a)
    return math.sqrt(a.x*a.x+a.y*a.y)
end
Vec2Mt.__index=function(self,key)
    if VecSuper[key] then return VecSuper[key] end
    if key=="x" then return self[1] end
    if key=="y" then return self[2] end
    return self[key]
end
function vec2(x,y)
    if y==nil then
        y=x
    end
    T={x,y}
    setmetatable(T, Vec2Mt)
    return T 
end
function VecMatMul(Vec,Mat)
    X=Vec.x*Mat:getField(1,1)+Vec.y*Mat:getField(1,2)+Vec.z*Mat:getField(1,3)+1*Mat:getField(1,4)
    Y=Vec.x*Mat:getField(2,1)+Vec.y*Mat:getField(2,2)+Vec.z*Mat:getField(2,3)+1*Mat:getField(2,4)
    Z=Vec.x*Mat:getField(3,1)+Vec.y*Mat:getField(3,2)+Vec.z*Mat:getField(3,3)+1*Mat:getField(3,4)
    return Vector(X,Y,Z)
end

if CLIENT then
    function CheckQuota()
        if coroutine.running() then
            if quotaTotalAverage()>=quotaMax()*0.75 then
                coroutine.yield()
            end
        end
    end
    local RenderObjCount=0
    RenderObj = ZClass(function(self,RPos)
        RenderObjCount=RenderObjCount+1
        self.ID=RenderObjCount
        self.RelativePos=RPos
        self.BoundingBox=BoundingBox(vec2(0),vec2(0))
    end,{
        render=function(self,Pos,BB)
            
        end
    })
    RenderObjRect=ZClass(function(self,RPos,Size,ColorB,IsOutline)
        RenderObj.const(self,RPos)
        self.Radius=0 
        self.Size=Size 
        self.Color=ColorB 
        self.IsOutline=IsOutline
        self.DrawTimes=0
        self.Rot=0
        self.Matrix=Matrix()
        self.Matrix:setIdentity()
        self.Alignment=1
        self.RBox=nil
        self:reapplyBox()
    end,RenderObj,{
        getBoundingBox=function (self,Pos) --Could store a variable that says it changed then does the change when it asks for it...
            return BoundingBox(Pos+self.BoundingBox.P,self.BoundingBox.S)
        end
        ,reapplyBox=function(self)
            if self.Rot~=0 then
                local V1,V2,V3,V4
                CheckQuota()
                if self.Alignment==1 then
                    V1=VecMatMul(Vector(self.Size.x,0,0),self.Matrix)
                    
                    V2=VecMatMul(Vector(self.Size.x,self.Size.y,0),self.Matrix)
                    V3=VecMatMul(Vector(0,self.Size.y,0),self.Matrix)
                    V4=Vector(0,0,0)
                elseif self.Alignment==0 then
                    V1=VecMatMul(Vector(self.Size.x/2,self.Size.y/2,0),self.Matrix)
                    
                    V2=VecMatMul(Vector(-self.Size.x/2,self.Size.y/2,0),self.Matrix)
                    V3=VecMatMul(Vector(self.Size.x/2,-self.Size.y/2,0),self.Matrix)
                    V4=VecMatMul(Vector(-self.Size.x/2,-self.Size.y/2,0),self.Matrix)
                end
                local Min=vec2(math.min(math.min(V1.x,V2.x),math.min(V3.x,V4.x)),math.min(math.min(V1.y,V2.y),math.min(V3.y,V4.y)))
                local Max=vec2(math.max(math.max(V1.x,V2.x),math.max(V3.x,V4.x)),math.max(math.max(V1.y,V2.y),math.max(V3.y,V4.y)))
                --return BoundingBox(self.RelativePos,self.Size)
                self.BoundingBox= BoundingBox(Min,Max-Min)
            else
                if self.Alignment==1 then
                    self.BoundingBox= BoundingBox(self.RelativePos,self.Size)
                else
                    self.BoundingBox= BoundingBox(self.RelativePos-self.Size/2,self.Size)
                end
            end 
        end
        ,setAlignment=function (self,Align) self.Alignment=Align self:reapplyBox() end
        ,setMaterial=function (self,Mat) self.Material=Mat self:reapplyBox() end
        ,setRadius=function(self,Rad) self.Radius=Rad self:reapplyBox() end
        ,setRotation=function(self,Rot) self.Rot = Rot self.Matrix=Matrix() self.Matrix:setIdentity() self.Matrix:rotate(Angle(0,self.Rot,0)) self:reapplyBox() end
        ,setRoundedEdges=function(self,TL,TR,BL,BR) self.RBox={TL,TR,BL,BR} end
        --Next skew
        ,render=function(self,Pos,BB,MC)
            CheckQuota()
            if not BB:check(self:getBoundingBox(Pos)) then return end    
            local Size2=self.Size
            local Pos2=self.RelativePos+Pos
            local B=Color(self.Color.r,self.Color.g,self.Color.b)
            B.r=B.r*MC.x
            B.g=B.g*MC.y
            B.b=B.b*MC.z
            render.setColor(B)
            
            
            if self.Rot ~= 0 then
                C=Matrix()
                C:translate(Vector(Pos2.x,Pos2.y,0))
                if self.Alignment==0 then 
                    C2=Matrix()
                    C2:translate(Vector(-Size2.x/2,-Size2.y/2,0))
                    render.pushMatrix(C*(self.Matrix*C2))
                else
                    render.pushMatrix(C*self.Matrix)
                end
                Pos2=vec2(0)
            else
                if self.Alignment==0 then Pos2=Pos2-Size2/2 end
            end
            
            if self.Material then
                render.setMaterial(self.Material)
            elseif self.RTTex then
                render.setRenderTargetTexture(self.RTTex)
            end
            if self.IsOutline then
                if self.Radius~=0 then
                    
                else
                    render.drawRectOutline( Pos2.x, Pos2.y, Size2.x, Size2.y )
                end
            elseif self.Radius~=0 then
                if self.RBox~=nil then
                    local L=self.RBox
                    render.drawRoundedBoxEx( self.Radius, Pos2.x, Pos2.y, Size2.x, Size2.y , L[1], L[2], L[3], L[4] )
                else
                    render.drawRoundedBox(self.Radius, Pos2.x, Pos2.y, Size2.x, Size2.y )
                end
            elseif self.Material or self.RTTex then
                render.drawTexturedRectFast( Pos2.x, Pos2.y, Size2.x*2, Size2.y*2 )
            else
                render.drawRectFast( Pos2.x, Pos2.y, Size2.x, Size2.y )
            end
            
            if self.Rot ~= 0 then render.popMatrix() end
        end
    })
    RenderObjCircle = ZClass(function(self,RPos,Radius,ColorB,IsOutline)
        RenderObj.const(self,RPos)
        self.Rot=0
        self.Matrix=nil
        self.Radius=Radius 
        self.RelativePos=RPos 
        self.Color=ColorB 
        self.IsOutline=IsOutline
        self:reapplyBox()
    end,RenderObj,{
        getRadius=function(self)
            if type(self.Radius)=="number" then
                return vec2(self.Radius)
            else
                return self.Radius
            end
        end
        ,setRadius=function(self,Rad) self.Radius=Rad self:reapplyBox() end
        ,setRotation=function(self,Rot) self.Rot = Rot self.Matrix=Matrix() self.Matrix:setIdentity() self.Matrix:rotate(Angle(0,self.Rot,0)) self:reapplyBox() end
        ,getBoundingBox=function (self,Pos) --Could store a variable that says it changed then does the change when it asks for it...
            return BoundingBox(Pos+self.RelativePos+self.BoundingBox.P,self.BoundingBox.S)
        end
        ,reapplyBox=function(self)
            local Meow = self:getRadius()
            if self.Rot~=0 then
                local a=(self.Rot/180)*math.pi
                local c=Meow.x
                local d=Meow.y
                local max=vec2(math.sqrt((c^2)*(math.cos(a)^2)+(d^2)*(math.sin(a)^2)),math.sqrt((c^2)*(math.sin(a)^2)+(d^2)*(math.cos(a)^2)))
                self.BoundingBox= BoundingBox(vec2(0)-max,max*2)
            else
                
                self.BoundingBox= BoundingBox(vec2(0)-Meow,Meow*2)
            end 
        end
        ,render=function(self,Pos,BB,MC)
            CheckQuota()
            local B=Color(self.Color.r,self.Color.g,self.Color.b)
            B.r=B.r*MC.x
            B.g=B.g*MC.y
            B.b=B.b*MC.z
            render.setColor(B)
            render.setMaterial(nil)
            local Meow=self:getRadius()
            local SMat=Matrix()
            SMat:setIdentity()
            SMat:translate(Vector(Pos.x+self.RelativePos.x, Pos.y+self.RelativePos.y,0))
            if Meow.y~=Meow.x then
                local SMat2=Matrix()
                SMat2:setIdentity()
                SMat2:scale(Vector(1,Meow.y/Meow.x,1))
                if self.Rot~=0 then
                    render.pushMatrix(SMat*self.Matrix*SMat2)
                else
                    render.pushMatrix(SMat*SMat2)
                end
            else
                render.pushMatrix(SMat)
            end
            if self.IsOutline then
                
            else
                render.drawRoundedBox( Meow.x,-Meow.x,-Meow.x , Meow.x*2, Meow.x*2 )
                --render.drawCircle( Pos.x+self.RelativePos.x, Pos.y+self.RelativePos.y, self.Radius )
            end
            render.popMatrix()
        end
    })
    Font = ZClass(function(self, font, size, weight, antialias, additive, shadow, outline, blur, extended )
        self.font=font
        self.size=size
        self.weight=weight
        self.antialias=antialias
        self.additive=additive
        self.shadow=shadow
        self.outline=outline
        self.blur=blur
        self.extended=extended
        self.FontObj=render.createFont( font, size, weight, antialias, additive, shadow, outline, blur, extended )
    end,{
        Reaquire=function(self)
            self.FontObj=render.createFont( self.font, self.size, self.weight, self.antialias, self.additive, self.shadow, self.outline, self.blur, self.extended )
        end
        ,getTextSize=function(self,Text)
            render.setFont(self.FontObj)
            local SX,SY=render.getTextSize( Text)
            return vec2(SX,SY)
        end
    })
    RenderObjText = ZClass(function(self,RPos,Text,ColorB,Alignment,Font)
        RenderObj.const(self,RPos)
        self.Text=Text 
        self.RelativePos=RPos 
        self.Color=ColorB
        self.Alignment=Alignment
        self.Font=Font
        self.Changed=true
        self.BoundingBox=BoundingBox(vec2(0),vec2(0))
        self:bbc()
    end,RenderObj,{
        setAlignment=function(self,A)
            self.Changed=true
            self.Alignment=A
        end
        ,setFont=function(self, Font )
            self.Changed=true
            self.Font=Font
        end
        ,setText=function(self, Text )
            self.Changed=true
            self.Text=Text
        end
        ,getTextSize=function(self)
            if self.Font==nil then
                render.setFont(render.getDefaultFont())
            else
                render.setFont(self.Font.FontObj)
            end
            local SX,SY=render.getTextSize( self.Text)
            return vec2(SX,SY)
        end
        ,bbc=function(self)
            if self.Changed then
                if self.Font==nil then
                    render.setFont(render.getDefaultFont())
                else
                    render.setFont(self.Font.FontObj)
                end
                local SX,SY=render.getTextSize( self.Text)
                
                self.BoundingBox.S=vec2(SX,SY)
                local H=vec2(SX/2,SY/2)
                self.BoundingBox.P=H*(vec2(0)-self.Alignment)
                self.Changed =false
            end
        end
        
        ,getBoundingBox=function (self,Pos) 
            self:bbc()
            return BoundingBox(Pos+self.RelativePos+self.BoundingBox.P,self.BoundingBox.S)
        end
        ,render=function(self,Pos,BB,MC)
            CheckQuota()
            if not BB:check(self:getBoundingBox(Pos)) then return end
            local B=Color(self.Color.r,self.Color.g,self.Color.b)
            B.r=B.r*MC.x
            B.g=B.g*MC.y
            B.b=B.b*MC.z
            render.setColor(B)
            if self.Font==nil then
                render.setFont(render.getDefaultFont())
            else
                render.setFont(self.Font.FontObj)
            end
            render.drawSimpleText( Pos.x+self.RelativePos.x, Pos.y+self.RelativePos.y, self.Text, self.Alignment.x, self.Alignment.y )
        end
    })
    RenderObjPoly = ZClass(function(self,RPos,Scale,Indexes,ColorB)
        RenderObj.const(self,RPos)
        self.Indexes=Indexes 
        self.RelativePos=RPos 
        self.Scale=Scale
        self.Color=ColorB
        self.Rot=0
        self.BoundingBox=GetPolyBoundingBox(Indexes)--This could lag, it mean it makes sense for C++ but this...
        self.Matrix=Matrix()
        self.Matrix:setIdentity()
    end,RenderObj,{
        getBoundingBox=function (self,Pos) 
            return BoundingBox(self.BoundingBox.P*self.Scale+Pos+self.RelativePos,self.BoundingBox.S*self.Scale)
        end
        ,setRotation=function(self,Rot) self.Rot = Rot self.Matrix=Matrix() self.Matrix:setIdentity() self.Matrix:rotate(Angle(0,self.Rot,0)) end
        ,render=function(self,Pos,BB,MC)
            CheckQuota()
            local B=Color(self.Color.r,self.Color.g,self.Color.b)
            B.r=B.r*MC.x
            B.g=B.g*MC.y
            B.b=B.b*MC.z
            Mat=Matrix()
            Mat:translate(Vector(Pos.x,Pos.y,0)+Vector(self.RelativePos.x,self.RelativePos.y,0))
            Mat:scale(Vector(self.Scale.x,self.Scale.y,1))
            render.setTexture(nil)
            render.pushMatrix(Mat*self.Matrix)
            render.setColor(B)
            render.drawPoly(self.Indexes)
            render.popMatrix()
        end
    })
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
        ,RemoveFromMap=function(self,Obj)--This could be optimised...
            for i,MapLoc in pairs(Obj.MapLoc) do
                local A=self.ObjectsLocMap[MapLoc.x]
                if A~=nil then
                    if A[MapLoc.y]~=nil then
                        A[MapLoc.y][Obj.ID]=nil
                        if next(A[MapLoc.y])==nil then
                            A[MapLoc.y]=nil
                            self.ObjectGeneratedDirMap[MapLoc.x][MapLoc.y]=nil
                            if next(A)==nil then
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
    local TotalObjects=0
    Object = ZClass(function(self,P)
        TotalObjects=TotalObjects+1
        self.OnScreen=true
        self.ID=TotalObjects
        self.ParentLayout=P
        self.Layouts={Layout(self,1)}
        self.CurrentLayout=1
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
        OnEvent=function(self,EventN,Data)
            return self.Hooks:OnEvent(EventN,{self,Data})
        end
        ,SetColorMod=function(self,Value)
            self.ColorModify=Value
        end
        ,GetClickablity=function(self)
            return (self.Clickable or next(self.Layouts[self.CurrentLayout].ClickableObjects)~=nil)
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
                local CheckObj=self.Layouts[self.CurrentLayout]:FindObjAtPos(Pos)
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
            self.Layouts[self.CurrentLayout]:ApplyOff(Pos-LastPos)
            self:OnEvent("PositionChanged",LastPos,Pos)
        end
        ,RemoveObj=function(self)
            self:OnEvent("Removed")
            if self.ParentLayout ~=nil then
                self.ParentLayout:RemoveObjFromLayout(self)
            end
            self.Drawable=false
            
        end
        ,AddTo=function(self,L,Obj)
            self.Drawable=true
            if Obj ~=nil then
                self.ParentLayout=Obj.Layouts[L]
                Obj.Layouts[L]:AddObjToData(self)
                self.OffPosition=Obj:GetPosition()+Obj.Layouts[L].Scroll
            end
            local Boundin=self:getRenderBound()
            if not (Obj:getRenderBound()):check(Boundin) then return end
            self:OnEvent("AddedToScreen",Obj,L)
        end
        ,ChangeScroll=function(self,L,Scroll)
            self:OnEvent("Scrolled",self.Layouts[L].Scroll,Scroll)
            self.Layouts[L]:ChangeScroll(Scroll)
            
        end
        ,SetSize=function(self,NSize)
            if self.ParentLayout~=nil and Obj:GetDrawable() then
                self.ParentLayout:RefreshObj(self)
            end
            self:OnEvent("SizeChanged",self.Size,NSize)
            self.Size=NSize
        end
        ,GetPosition=function(self)
            return self.RelPosition+self.OffPosition
        end
        ,SwitchLayout=function(self,LayoutN)
            if LayoutN==self.CurrentLayout then return end
            self:OnEvent("SwitchedLayout",self.CurrentLayout,LayoutN)
            self.Layouts[self.CurrentLayout]:ApplyDrawability(false)
            self.CurrentLayout=LayoutN
            self.Layouts[self.CurrentLayout]:ApplyDrawability(true)
            Lay=self.Layouts[self.CurrentLayout]
            Lay:ApplyOff(Lay.OffsetPos)
            Lay.OffsetPos=vec2(0)
            
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
            return #self.RenderObjs
        end
        ,RemRenderObj=function(self,L) --Look at this, LOOK AT IT, then look at the next one.
            self.RenderObjs[L]=nil
            self:OnEvent("RemovedRenderObj",L)
        end
        ,ChangeRenderObj=function(self,L,Obj) --Look at this, LOOK AT IT, then look at the next one.
            self:OnEvent("ChangedRenderObj",L,Obj)
            self.RenderObjs[L]=Obj
            
        end
        ,SetHidden=function(self,Value)
            if self.Hidden~=Value then
                self.Hidden=Value
                if self.ParentLayout~=nil then
                    self.ParentLayout:RefreshObj(self)
                end
            end
        end
        ,getRenderBound=function(self)
            return BoundingBox(self:GetPosition(),self.Size)
        end
        ,renderErase=function(self,BB)
            if not self.NotDrawn and self:GetDrawable() then
                if self.ParentLayout~=nil then
                    BB=BB:between(self.ParentLayout.ObjParent:getRenderBound())
                end
                self:renderBelow(BB)
                self:renderAbove(BB)
                self.NotDrawn=true
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
                self:render(BB)
                self:renderAbove(BB)
                self.NotDrawn=true
            end
        end
        ,render=function(self,BB,Above)
            if self:GetDrawable() then
                self.NotDrawn=false
                local Boundin=self:getRenderBound()
                if not BB:check(Boundin) then return end
                
                BB=BB:between(Boundin)
                LastRenderArea=BoundingBox(BB.P,BB.S)
                render.enableScissorRect( BB.P.x, BB.P.y, BB.P.x+BB.S.x, BB.P.y+BB.S.y )
                for i,k in pairs(self.RenderObjs) do
                    k:render(self:GetPosition(),BB,self.ColorModify)
                end
                if Above==nil or Above then
                    self:renderLayout(BB,self.CurrentLayout)
                end
            end
        end
        ,renderLayout=function(self,BB,s)
            local L=self.Layouts[s]
            
            for i,k in L:ZListIter() do
                for i2,k2 in pairs(k) do
                    k2:render(BB)
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
                end
            end
        end
        ,renderBelow=function(self,BB)
            local Boundin=self:getRenderBound()
            if not BB:check(Boundin) then return end
            
            BB=BB:between(Boundin)
            if self.ParentLayout~=nil then

                self.ParentLayout.ObjParent:render(BB,false)
                if self.ParentLayout.UnderlappingObjs[self.ID]~=nil then
                    for i,k in pairs(self.ParentLayout.UnderlappingObjs[self.ID]) do
                        k:render(BB,false)
                    end
                end
            end
            --This could be better but I am not doin it because, it will be a waste of effort right now.
            --while self.ParentLayout~=nil do
        end
        ,Refresh=function(self)
            self.Layouts[self.CurrentLayout]:ApplyDrawability(true)
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
    LastRenderArea=BoundingBox(vec2(0,0),vec2(99999999,9999999999))
    local renderer={}
    Ent=chip()
    CurrentFontSize=0
    HookT={}

    DebugLines={}

    ScreenPosition=Vector(0,0,0)

    Root=Object(nil)
    LookingAtScreen=false
    AimPos=vec2(0)
    local LAimPos=vec2(0)
    CurrentlyDrawingToScreen=false

    CurrentlySelected=nil
    CurrentlyClicked=nil
    LastClickedObject=nil
    Frozen=false
    Click=true
    SomethingMoved=false
    RenderQueue={}
    ChangeList={}
    RenderUsedChangeList={}
    ScreenEnt=nil
    local First=true
    ScreenSize=vec2(512)
    ApplyRenderChangesCoroutine=nil
    local Counts=0
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



    hook.add("net","GetScreenPos",function(name,len,ply)
        Type=net.readString()
        if Type=="GetScreenPos" then
            ScreenPosition=net.readVector()
        end
    end)
    function CheckQuota()
        if coroutine.running() then
            if quotaTotalAverage()>=quotaMax()*0.90 then
                coroutine.yield()
            end
        end
    end
    local function DrawCursor()
        if LookingAtScreen then
            render.setColor(Color(255,255,255))
            render.drawRect(AimPos.x-2,AimPos.y-2,4,4)
        end
    end
    local function GetAimPosManual()
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

    local ApplyRenderChanges=nil
    local RenderChanges=nil
    local SomeFontMan=render.createFont( "Default", 13, 400, false, false, false, false, false, false )
    local SomeFontMan2=render.createFont( "Default", 13, 500, false, false, false, true, false, false )
    local function DrawDebugText(X,Y,Str)
        render.setColor(Color(0,0,0,255)) 
        render.setFont(SomeFontMan2)
        render.drawSimpleText( X, Y, Str, 0, 0 )
        render.setColor(Color(255,255,255)) 
        render.setFont(SomeFontMan)
        render.drawSimpleText( X, Y, Str, 0, 0 )
    end
    local function DrawDebugInfo()
        if player() == owner() then
            local QAve=quotaTotalAverage()
            DrawDebugText(10,10,"CPU Quota Average: "..tostring(math.floor(QAve*1000000)).."us "..tostring(math.floor(QAve*100/quotaMax())).."%")
            for i,k in pairs(DebugLines) do
                DrawDebugText( 10, 10+i*10, k)
            end
        end
    end
    local function ScreenRenderer()
        LookingAtScreen=false
        local X,Y = render.cursorPos()
        local W,H=render.getResolution()
        if W~=nil then
            ScreenSize=vec2(W,H)
            ScreenEnt=render.getScreenEntity()
            if X then
                AimPos=vec2(X,Y)
                LookingAtScreen=true
            end

            render.setRenderTargetTexture("Target")
            render.drawTexturedRect(0,0,W*2,H*2)
            RenderChanges() --Reminder the fancy dancy RenderObjBoxGraph messes around with the TargetTexture
            render.enableScissorRect( 0,0,W*2,H*2)
            if quotaTotalAverage()<=quotaMax()*0.95 then
                DrawCursor()
                DrawDebugInfo()
            end
        end
    end
    function RenderChanges()
        render.selectRenderTarget("Target2") 
        render.enableScissorRect( LastRenderArea.P.x, LastRenderArea.P.y, LastRenderArea.P.x+LastRenderArea.S.x, LastRenderArea.P.y+LastRenderArea.S.y )
        local Stat=coroutine.status(ApplyRenderChangesCoroutine)
        if Stat=="dead" then
            ApplyRenderChangesCoroutine=coroutine.create(ApplyRenderChanges)
            coroutine.resume(ApplyRenderChangesCoroutine)
        else
            coroutine.resume(ApplyRenderChangesCoroutine)
        end
        local Stat=coroutine.status(ApplyRenderChangesCoroutine)
        if quotaTotalAverage()<=quotaMax()*0.95 then
            if Stat=="dead" then
                render.enableScissorRect( 0,0,ScreenSize.x*2,ScreenSize.y*2)
                render.selectRenderTarget("Target")
                render.setRenderTargetTexture("Target2")
                render.setColor(Color(255,255,255))
                render.drawTexturedRect(0,0,ScreenSize.x*2,ScreenSize.y*2)
                render.setRenderTargetTexture()
            end
        end
        render.selectRenderTarget()
    end
    function ApplyRenderChanges()
        
        while next(ChangeList)~=nil do
            RenderUsedChangeList=ChangeList
            ChangeList={}
            local RenderableObjs={}
            for i,k in pairs(RenderUsedChangeList) do--I can just make it so there is a settin in the obj file, cus that would be better
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
            for i,k in pairs(RenderUsedChangeList) do
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
                if Renderable and (State==3 or State==2) then
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
                    BB=nil
                end
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
                
                if Renderable and (State==2 or State==1) then
                    k[1]:renderComplete(BB)
                        
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
            RenderUsedChangeList={}
        end
    end
    local DisableKeyPressTim=timer.curtime()
    local DisableKeyReleaseTim=timer.curtime()
    local ButtonPressed=false
    local ButtonsPressed={}
    local function OnKeyPress (Ply,Key)
        if DisableKeyPressTim<=timer.curtime() then
            if (Key==1 or Key==32 or Key==8192) and not ButtonPressed then-- (Key==15 or Key==107 or Key==28)
                if LastClickedObject~=CurrentlySelected then
                    local LFrozen=Frozen 
                    Frozen=false
                    if CurrentlySelected~=nil then 
                        local A=CurrentlySelected:OnEvent("IsNowClickedObject") 
                        for i,k in pairs(A) do
                            if k==true then Frozen=true end
                        end
                    end
                    if Frozen ~= LFrozen then
                        --input.enableCursor( Frozen )
                    end
                    
                    if LFrozen and LastClickedObject~=nil then 
                        for i,k in pairs(ButtonsPressed) do
                            LastClickedObject:OnEvent("KeyboardRelease",i)
                        end
                    end
                    if Frozen and CurrentlySelected~=nil then 
                        for i,k in pairs(ButtonsPressed) do
                            CurrentlySelected:OnEvent("KeyboardPress",i)
                        end
                    end
                    if LastClickedObject~=nil then 
                        LastClickedObject:OnEvent("IsNoLongerClickedObject")
                    end
                end
                if LookingAtScreen and CurrentlySelected~=nil then
                    CurrentlySelected:OnEvent("KeyPress",Key)
                    CurrentlyClicked=CurrentlySelected
                end
                LastClickedObject=CurrentlySelected
                ButtonPressed=true
            end
            if Frozen and LastClickedObject~=nil and ButtonsPressed[Key]==nil then
                LastClickedObject:OnEvent("KeyboardPress",Key)
            end
            ButtonsPressed[Key]=true
            DisableKeyPressTim=timer.curtime()+0.02
        end
        if Frozen then
            return false
        end
    end 
    local function KeyRelease(Ply,Key) 
        if DisableKeyReleaseTim<=timer.curtime() then
            if (Key==1 or Key==32 or Key==8192) then
                if LookingAtScreen and CurrentlyClicked~=nil and ButtonPressed then
                    CurrentlyClicked:OnEvent("KeyRelease",Key)
                    CurrentlyClicked=nil
                    
                end
                ButtonPressed=false
            end
            if Frozen and LastClickedObject~=nil and ButtonsPressed[Key]~=nil then
                LastClickedObject:OnEvent("KeyboardRelease",Key)
            end
            ButtonsPressed[Key]=nil
            DisableKeyReleaseTim=timer.curtime()+0.02
        end
        if Frozen then
            return false
        end
    end
    local function InputTickTimer()
        if quotaTotalAverage()>=quotaMax()*0.8 then
            return
        end
        if LookingAtScreen then
            if (AimPos.x~=LAimPos.x or AimPos.y~=LAimPos.y) or SomethingMoved then
                local Selected=ObjAtPos(AimPos)
                if CurrentlySelected~=Selected then
                    if CurrentlySelected~=nil then
                        CurrentlySelected:OnEvent("Deselected")
                    end
                    if Selected~=nil then
                        Selected:OnEvent("Selected")
                    end
                end
                CurrentlySelected=Selected
            end
        else
            if CurrentlySelected~=nil then
                CurrentlySelected:OnEvent("Deselected")
            end
            CurrentlySelected=nil
        end
        LAimPos=AimPos
        SomethingMoved=false
    end
    function InitScreen()
        ApplyRenderChangesCoroutine=coroutine.create(ApplyRenderChanges)

        render.createRenderTarget("Target")
        render.createRenderTarget("Target2")
        hook.add("Render","Render412",ScreenRenderer)

        hook.add("KeyPress","KeyP1",OnKeyPress)
        hook.add("KeyPress","KeyP2",function (Ply,Key) 
            if Frozen then
                return true
            end
        end)
        hook.add("KeyRelease","KeyP2",KeyRelease)
        timer.create( "InputTick", 1/20, 0, InputTickTimer)
    end
    function AddToRenderQueue(Obj,Func,BB)
        RenderQueue[#RenderQueue+1]={Obj,Func,BB}
    end
    local NotDrawnRoot=true
    local CurJob=nil
    function AddToChangeList(Obj,State,OverlapEvent,Type,BBFunc,Func,Args,BBArgs) --Removed 3,moved 2,stayed 1
        if NotDrawnRoot then -- or coroutine.running() == ApplyRenderChangesCoroutine
            Func(Obj,unpack(Args))
            --print("Bam")
        else
            if CurJob then CurJob:NewJob() end
            if ChangeList[Obj.ID] == nil then -- the State==3 could include some funky bugs.
                ChangeList[Obj.ID]={Obj,State,{},{}}
                ChangeList[Obj.ID][4][1]={BBFunc,Func,Args,BBArgs,{CurJob}}
                ChangeList[Obj.ID][3][Type]=1

            else
                ChangeList[Obj.ID][2]=math.max(ChangeList[Obj.ID][2],State)
                local B=ChangeList[Obj.ID][4]
                local Jobs={CurJob}
                if OverlapEvent and ChangeList[Obj.ID][3][Type]~=nil then
                    for i,k in pairs(B[ChangeList[Obj.ID][3][Type]][5]) do
                        Jobs[#Jobs+1]=k
                    end
                    B[ChangeList[Obj.ID][3][Type]]=-1
                    
                end
                ChangeList[Obj.ID][3][Type]=#B+1
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


    function StartDrawingRoot()
        NotDrawnRoot=false
        AddToChangeList(Root,1,true,"Refresh",Root.getRenderBound,Root.Refresh,{})
    end
    function ObjAtPos(Pos)
        return Root:GetObjAtPos(Pos)
    end
    --Could create a table of the change types, which could be used simplify the process. ([Type]={2,Type,BBFunc,Func})
    --Then turn them into functions automatically
    function SetPos(Obj,Pos)
        SomethingMoved=true
        AddToChangeList(Obj,2,true,"Pos",Obj.getRenderBound,Obj.RelPos,{Pos})
    end
    function SetSize(Obj,Size)
        SomethingMoved=true
        AddToChangeList(Obj,2,true,"Size",Obj.getRenderBound,Obj.SetSize,{Size})
    end
    function RemoveObj(Obj)
        SomethingMoved=true
        AddToChangeList(Obj,1,false,"RemoveObj",Obj.getRenderBound,Obj.RemoveObj,{})
    end
    function AddObj(Obj,NObj,L)
        SomethingMoved=true
        AddToChangeList(Obj,1,false,"AddTo",Obj.getRenderBound,Obj.AddTo,{L,NObj})
    end
    function SetColorM(Obj,ColorM)
        AddToChangeList(Obj,1,true,"SetColorMod",Obj.getRenderBound,Obj.SetColorMod,{ColorM})
    end
    function AddLayout(Obj,L)
        AddToChangeList(Obj,1,false,"AddLayout",Obj.getRenderBound,Obj.AddLayout,{})
    end
    function SwitchLayout(Obj,L)
        SomethingMoved=true
        AddToChangeList(Obj,1,false,"SwitchLayout",Obj.getRenderBound,Obj.SwitchLayout,{L})
    end
    function ScrollObj(Obj,L,Scroll)
        SomethingMoved=true
        AddToChangeList(Obj,1,true,"ScrollObj",Obj.getRenderBound,Obj.ChangeScroll,{L,Scroll})
    end
    function SetHiddenObj(Obj,Value)
        SomethingMoved=true
        AddToChangeList(Obj,1,true,"SetHidden",Obj.getRenderBound,Obj.SetHidden,{Value})
    end
    function GetRenderBoundRObj(self,B,Obj)
        local F=Obj:getBoundingBox(self:GetPosition())
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
        local F=Obj:getBoundingBox(self:GetPosition())
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
                GetRenderBoundRObj3B[IDA]=Obj:getBoundingBox(self:GetPosition()):combineArea(New:getBoundingBox(self:GetPosition()))
                
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
    function ChangedRenderObj(Obj,L,RenderObjk)
        AddToChangeList(Obj,1,true,"ChangedRenderObj"..tostring(L),GetRenderBoundRObj3,Obj.ChangeRenderObj,{L,RenderObjk},{L,RenderObjk})
    end
    function AddRenderObj(Obj,RenderObjk)
        AddToChangeList(Obj,1,false,"AddRenderObj",GetRenderBoundRObj,Obj.AddRenderObj,{RenderObjk},{RenderObjk}) 
    end
    function RemoveRenderObj(Obj,L)--This can be problematic, maybe not... HMMM make renderObj's use unique id's, but that can be an issue, maybe not.
        AddToChangeList(Obj,1,false,"RemRenderObj",GetRenderBoundRObj2,Obj.RemRenderObj,{L},{L})
    end
    local C=math.sqrt(0.75)*2
    IsoArrowVerts={{x=-C/3,y=-1,u=0,v=0},{x=C*2/3,y=0,u=1,v=0},{x=-C/3,y=1,u=0,v=1}}
    IsoArrowVerts2={{x=0,y=-1,u=0,v=0},{x=C,y=0,u=1,v=0},{x=0,y=1,u=0,v=1}}
    function IsoArrow(Obj,Scale,Loc,Rot,Color,Align)
        local TheThing=nil
        if Align==0 then
            TheThing=RenderObjPoly(Loc,Scale,IsoArrowVerts,Color)
        else
            TheThing=RenderObjPoly(Loc,Scale,IsoArrowVerts2,Color)
        end
        TheThing:setRotation(Rot)
        Obj:AddRenderObj(TheThing)
    end
    function RepeatIcon(Obj,Scale,Loc,Rot,Color)
        local LTh=0.25
        local Scale2=vec2(Scale.x,Scale.y)
        local RRect=RenderObjRect(Loc+Scale2*vec2(0,-1+LTh/2),Scale2*vec2(0.575*2,LTh),Color,false) RRect:setAlignment(0)
        Obj:AddRenderObj(RRect)
        local RRect=RenderObjRect(Loc+Scale2*vec2(0,1-LTh/2),Scale2*vec2(0.575*2,LTh),Color,false) RRect:setAlignment(0)
        Obj:AddRenderObj(RRect)
        for b,v in pairs({vec2(1-0.05,1-0.05),vec2(-1,-1)}) do
            local LA=90
            if v.x==-1 then
                LA=-90
            end
            for i=0,6 do
                local A=math.pi*i/12
                local X=0.575+math.cos(A)*0.3
                local Y=0.575+math.sin(A)*0.3
                local X1=0.575+math.cos(A+math.pi/12)*0.3
                local Y1=0.575+math.sin(A+math.pi/12)*0.3
                local Len=vec2(X-X1,Y-Y1):length()
                local RRect=RenderObjRect(Loc+Scale2*vec2(X,Y)*v,Scale2*vec2(Len+0.04,LTh),Color,false) RRect:setRotation(((i/6)*90)+LA) RRect:setAlignment(0)
                Obj:AddRenderObj(RRect)
            end
        end
        IsoArrow(Obj,Scale*vec2(0.21),Loc+Scale2*vec2(0.55,-1+LTh/2),0,Color,1)
        IsoArrow(Obj,Scale*vec2(0.21),Loc+Scale2*vec2(-0.55,1-LTh/2),180,Color,1)
    end
    function ShuffleIcon(Obj,Scale,Loc,Rot,Color)
        local Scale2=vec2(Scale.x,Scale.y/2.5)
        local RRect=RenderObjRect(Loc+Scale2*vec2(-0.6,0.9),Scale2*vec2(0.7,0.25),Color,false) RRect:setRadius(2) RRect:setAlignment(0)
        Obj:AddRenderObj(RRect)
        local RRect=RenderObjRect(Loc+Scale2*vec2(-0.6,-0.9),Scale2*vec2(0.7,0.25),Color,false) RRect:setRadius(2) RRect:setAlignment(0)
        Obj:AddRenderObj(RRect)
        local RRect=RenderObjRect(Loc+Scale2*vec2(0.5,0.9),Scale2*vec2(0.5,0.25),Color,false) RRect:setRadius(2) RRect:setAlignment(0)
        Obj:AddRenderObj(RRect)
        local RRect=RenderObjRect(Loc+Scale2*vec2(0.5,-0.9),Scale2*vec2(0.5,0.25),Color,false) RRect:setRadius(2) RRect:setAlignment(0)
        Obj:AddRenderObj(RRect)
        for b,v in pairs({vec2(1,1),vec2(-1,1),vec2(1,-1),vec2(-1,-1)}) do
            local LA=v.x*v.y
            for i=0,5 do
                local A=math.pi*i/16
                local X=-0.25+math.sin(A)*0.2
                local Y=0.1+math.cos(A)*0.8
                local X1=-0.25+math.sin(A+math.pi/16)*0.2
                local Y1=0.1+math.cos(A+math.pi/16)*0.8
                local Len=vec2(X-X1,Y-Y1):length()
                local RRect=RenderObjRect(Loc+Scale2*vec2(X,Y)*v,Scale2*vec2(Len+0.01,0.25),Color,false) RRect:setRotation(LA*(-(i/4)*45-10)) RRect:setAlignment(0)
                Obj:AddRenderObj(RRect)
            end
        end
        local RRect=RenderObjRect(Loc,Scale2*vec2(0.5,0.25),Color,false) RRect:setRotation(-70) RRect:setAlignment(0)
        Obj:AddRenderObj(RRect)
        local RRect=RenderObjRect(Loc,Scale2*vec2(0.5,0.25),Color,false) RRect:setRotation(70) RRect:setAlignment(0)
        Obj:AddRenderObj(RRect)
        IsoArrow(Obj,Scale*vec2(0.21),Loc+Scale2*vec2(0.5+0.25,-0.9),0,Color,1)
        IsoArrow(Obj,Scale*vec2(0.21),Loc+Scale2*vec2(0.5+0.25,0.9),0,Color,1)
    end
    function MusicIcon(Obj,Scale,Loc,Rot,ColorA)
        local Scale2=vec2(Scale.x,Scale.y)/2.25
        local ColorAB=Color(255*0.8,255*0.8,255*0.8)
        local LCirM=vec2(-Scale2.x/2,Scale2.y/2)
        local RCirM=vec2(Scale2.x/3,Scale2.y/3)
        local CirS=vec2(Scale2.x,Scale2.y*(4/5))*(2/8)
        Obj:AddRenderObj(RenderObjCircle(Loc+RCirM,CirS,ColorAB,false))
        Obj:AddRenderObj(RenderObjCircle(Loc+LCirM,CirS,ColorAB,false))
        local LBarP=vec2(LCirM.x+(Scale2.x*2/8)-CirS.x/4,0)
        local BarS=vec2(Scale2.x*(1/8),Scale2.y)
        local RRect=RenderObjRect(Loc+LBarP,BarS,ColorAB,false) RRect:setAlignment(0)
        Obj:AddRenderObj(RRect) 
        local RBarP=vec2(RCirM.x+(Scale2.x*2/8)-CirS.x/4-1,RCirM.y-LCirM.y)
        local RRect2=RenderObjRect(Loc+RBarP+vec2(1,Scale2.y*0.1),BarS-vec2(0,Scale2.y*0.1),ColorAB,false) RRect2:setAlignment(0)
        Obj:AddRenderObj(RRect2)
        local H=Scale2.x*(2/8)
        local Cats={{x=LBarP.x-BarS.x/2,y=LBarP.y-BarS.y/2+H,u=0,v=1},{x=LBarP.x-BarS.x/2,y=LBarP.y-BarS.y/2,u=1,v=0},{x=RBarP.x+BarS.x/2,y=RBarP.y-BarS.y/2,u=0,v=0},{x=RBarP.x+BarS.x/2,y=RBarP.y-BarS.y/2+H,u=1,v=0}}
        local Poly=RenderObjPoly(Loc,vec2(1),Cats,Color(255*0.8,255*0.8,255*0.8))
        Obj:AddRenderObj(Poly)
    end
    function PlaylistIcon(Obj,Scale,Loc,Rot,ColorA)
        local Scale2=vec2(Scale.x,Scale.y)/2.25
        local ColorAB=Color(255*0.8,255*0.8,255*0.8)
        local CirM=vec2(Scale2.x/4,Scale2.y*(5/12))    
        local CirS=vec2(Scale2.x,Scale2.y*(4/5))*(2/8)
        Obj:AddRenderObj(RenderObjCircle(Loc+CirM,CirS,ColorAB,false))
        local BarP=vec2(CirM.x+(Scale2.x*2/8)-CirS.x/4,-Scale2.y*(1/12))
        local BarS=vec2(Scale2.x*(1/8),Scale2.y)
        local RRect=RenderObjRect(Loc+BarP,BarS,ColorAB,false) RRect:setAlignment(0) Obj:AddRenderObj(RRect) 
        BarP.y=BarP.y-Scale2.x*(1.25/16)
        BarP.x=BarP.x-1
        local H=Scale2.x*(2/8)
        local H2=Scale2.x*(1/4)
        local Cats={{x=BarP.x-BarS.x/2,y=BarP.y-BarS.y/2+H,u=0,v=1},{x=BarP.x-BarS.x/2,y=BarP.y-BarS.y/2,u=1,v=0},{x=BarP.x+BarS.x/2+H2,y=BarP.y-BarS.y/2+H2,u=0,v=0},{x=BarP.x+BarS.x/2+H2,y=BarP.y-BarS.y/2+H+H2,u=1,v=0}}
        local Poly=RenderObjPoly(Loc,vec2(1),Cats,Color(255*0.8,255*0.8,255*0.8))
        Obj:AddRenderObj(Poly)
        Obj:AddRenderObj(RenderObjRect(Loc+Scale2*vec2(-0.8,-0.65),Scale2*vec2(1.05,0.16),ColorAB,false))
        Obj:AddRenderObj(RenderObjRect(Loc+Scale2*vec2(-0.8,-0.65+0.16*2),Scale2*vec2(1.05,0.16),ColorAB,false))
        Obj:AddRenderObj(RenderObjRect(Loc+Scale2*vec2(-0.8,-0.65+0.16*4),Scale2*vec2(1.05,0.16),ColorAB,false))
        Obj:AddRenderObj(RenderObjRect(Loc+Scale2*vec2(-0.8,-0.65+0.16*6),Scale2*vec2(0.68,0.16),ColorAB,false))
    end
    function GearIcon(Obj,Scale,Loc) 
        for i=0,4 do
            local RRect2=RenderObjRect(Loc,(vec2(40,5)*Scale/40),Color(255*0.8,255*0.8,255*0.8),false)
            RRect2:setRadius(2.5)
            RRect2:setRotation((i/5*180))
            RRect2:setAlignment(0)
            Obj:AddRenderObj(RRect2)
        end
        Obj:AddRenderObj(RenderObjCircle(Loc,vec2(Scale*15/40),Color(255*0.8,255*0.8,255*0.8),false))
        Obj:AddRenderObj(RenderObjCircle(Loc,vec2(Scale*12/40),Color(255*0.25,255*0.25,255*0.25),false))
    end
    local C=math.sqrt(0.75)
    ArrowIconPoly={{x=2*(C*0.7)/3,y=0,u=0,v=1},{x=C*2/3,y=0,u=1,v=0},{x=-C/3,y=1,u=0,v=0},{x=-C/3,y=1*0.8,u=1,v=0}}
    ArrowIconPoly2={{x=C*2/3,y=0,u=1,v=0},{x=2*(C*0.7)/3,y=0,u=0,v=1},{x=-C/3,y=-1*0.8,u=1,v=0},{x=-C/3,y=-1,u=0,v=0}}
    function ArrowIcon(Obj,Scale,Loc,Rot)
        local Poly=RenderObjPoly(Loc,vec2(-1.5,-1)*Scale/2,ArrowIconPoly,Color(255*0.8,255*0.8,255*0.8))
        local Poly2=RenderObjPoly(Loc,vec2(-1.5,-1)*Scale/2,ArrowIconPoly2,Color(255*0.8,255*0.8,255*0.8))
        Poly:setRotation(Rot)
        Poly2:setRotation(Rot)
        Obj:AddRenderObj(Poly)
        Obj:AddRenderObj(Poly2)
    end
    function NoteIcon(Obj,S,O)
        local Circle=RenderObjCircle(O+S*vec2(0,0.55),S*vec2(0.45,0.27),Color(255*0.9,255*0.9,255*0.9))
        Circle:setRotation(-20)
        Obj:AddRenderObj(Circle)
        local Cats=RenderObjRect(O+S*vec2(0.3925,-0.37-0.2),S*vec2(0.15,2.2),Color(255*0.9,255*0.9,255*0.9),false) Cats:setAlignment(0)
        Obj:AddRenderObj(Cats)
    end
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
    
    function RoundedClickable(Obj)
        Obj.Hooks:CreateHook("CheckPos","ButtonB",function(Data)
            local S=((Data[2]/Data[1].Size)*2-vec2(1)):lengthSq()
            return S<=1
        end)
    end
    function Button(Pos,Size,ColorB,Text,TextHeight,Channel,TextAlignment)
        local self=Object(nil)
        self:AddRenderObj(RenderObjRect(vec2(0),Size,ColorB,false))
        if TextAlignment==nil then
            self.TextAlignment=vec2(0,1)
        else
            self.TextAlignment=TextAlignment
        end
        self.Font=Font( "Arial", TextHeight, 800, true, false, false, false, true, true )
        local FullSize=Size.x-4
        local TextLoc=vec2(4,4)+(self.TextAlignment*(Size-vec2(8,8)))*0.5
        local Text2=RenderObjText(TextLoc,Text,Color(255,255,255),self.TextAlignment,self.Font)
        local S1=Text2:getTextSize()
        if S1.x>FullSize then
            self.Font.size=self.Font.size*(FullSize/S1.x)
            self.Font:Reaquire()
            Text2=RenderObjText(TextLoc,Text,Color(255,255,255),self.TextAlignment,self.Font)
        end
        self:AddRenderObj(Text2)
        self:RelPos(Pos)
        self:SetSize(Size)
        self.Clickable=true
        self.Channel=Channel
        return self
    end
    local RadioButtonChannels={}
    local ButtonStateStorage={}
    function SetPressStateButton(Type,ID,Pressed)
        if ButtonStateStorage[Type]~=nil then
            local Cat=ButtonStateStorage[Type]
            if Cat[ID]~=nil then
                if Cat[ID][2]~=Pressed then
                    Cat[ID][2]=Pressed
                    if Cat[ID][1]~=nil then
                        Cat[ID][1].Pressed=Pressed
                        Cat[ID][1]:Update()
                    end
                end
            end
        end
    end
    function SetPressStateRadioButton(Type,ID,Channel)
        local CurCan=RadioButtonChannels[Channel]
        if CurCan~=nil then
            if CurCan[1]==2 then
                if CurCan[2]==Type and CurCan[3]==ID then return end
            end
            if CurCan[1]==1 then
                CurCan[2]:Unpress()
            else
                SetPressStateButton(CurCan[2],CurCan[3],false)
            end
        end
        SetPressStateButton(Type,ID,true)
        RadioButtonChannels[Channel]={2,Type,ID}       
    end
    function ButtonHooks(Obj) -- The codes fine in all, except the values for hover and clicking, not hovering and clicking, hovering and not clicking, and not hovering and not clicking change depending on the process.
                            --Which is fairly stupid so fix this later ok.
        Obj.Hovering=false
        Obj.Pressed=false
        if Obj.Toggle== nil then Obj.Toggle=false end
        if Obj.Channel== nil then Obj.Channel=-1 end
        if Obj.DefaultB== nil then Obj.DefaultB=false end

        local Preexisted=false
        if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
            if ButtonStateStorage[Obj.ButtonType]==nil then
                ButtonStateStorage[Obj.ButtonType]={}
            end
            local Cat=ButtonStateStorage[Obj.ButtonType][Obj.ButtonID]
            if Cat==nil then
                ButtonStateStorage[Obj.ButtonType][Obj.ButtonID]={Obj,Obj.Pressed}
            else
                Obj.Pressed=Cat[2]
                Preexisted=true--This is gunna make things funky. and I am too lazy to fix it because it ain't gunna cause an error easily
            end
        end 
        if Obj.DefaultB and Obj.Channel~=-1 and not Preexisted then
            if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
                RadioButtonChannels[Obj.Channel]={2,Obj.ButtonType,Obj.ButtonID}
            else
                RadioButtonChannels[Obj.Channel]={1,Obj}
            end
            Obj.ColorModify=Vector(0.8,0.8,0.8)
            Obj.Pressed=true
        end
        if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
            ButtonStateStorage[Obj.ButtonType][Obj.ButtonID][2]=Obj.Pressed
        end
        local BaseVec=Vector(1,1,1)
        if Obj.Pressed then BaseVec=BaseVec-Vector(0.2,0.2,0.2) end
        if Obj.Hovering then BaseVec=BaseVec-Vector(0.1,0.1,0.1) end
        Obj.ColorModify=BaseVec
        Obj.Update=function(Obj)
            local BaseVec=Vector(1,1,1)
            if Obj.Pressed then BaseVec=BaseVec-Vector(0.2,0.2,0.2) end
            if Obj.Hovering then BaseVec=BaseVec-Vector(0.1,0.1,0.1) end
            SetColorM(Obj,BaseVec)
        end
        Obj.Unpress=function(Obj)
            if Obj.Pressed then
                Obj.Pressed=false
                Obj:Update()
                if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
                    ButtonStateStorage[Obj.ButtonType][Obj.ButtonID][2]=Obj.Pressed
                end
            end
        end
        Obj.Hooks:CreateHook("Removed","ButtonB",function(Data)
            if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
                if Data[1].Pressed then
                    ButtonStateStorage[Data[1].ButtonType][Data[1].ButtonID][1]=nil
                else
                    ButtonStateStorage[Data[1].ButtonType][Data[1].ButtonID]=nil
                    if next(ButtonStateStorage[Data[1].ButtonType])==nil then
                        ButtonStateStorage[Data[1].ButtonType]=nil
                    end
                end
            else
                if Obj.Channel~=-1 then
                    if RadioButtonChannels[Obj.Channel]~=nil then
                        if RadioButtonChannels[Obj.Channel][1]==1 then
                            if RadioButtonChannels[Obj.Channel][2]==Obj then
                                RadioButtonChannels[Obj.Channel]=nil
                            end
                        end
                    end
                end
            end
        end) 
        Obj.Hooks:CreateHook("KeyPress","ButtonB",function(Data) 
            local Obj=Data[1]
            if Obj.Channel~=-1 then
                local CurCan=RadioButtonChannels[Obj.Channel]
                if CurCan~=nil then
                    if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
                        if CurCan[1]==2 then
                            if CurCan[2]==Obj.ButtonType and CurCan[3]==Obj.ButtonID then return end
                        end
                    else
                        if CurCan[1]==1 then
                            if CurCan[2]==Obj then return end
                        end
                    end
                end
                if CurCan~=nil then
                    if CurCan[1]==1 then
                        CurCan[2]:Unpress()
                    else
                        SetPressStateButton(CurCan[2],CurCan[3],false)
                    end
                end
                Obj.Pressed=true
                Obj:Update()
                if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
                    ButtonStateStorage[Obj.ButtonType][Obj.ButtonID][2]=Obj.Pressed
                end
                if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
                    RadioButtonChannels[Obj.Channel]={2,Obj.ButtonType,Obj.ButtonID}
                else
                    RadioButtonChannels[Obj.Channel]={1,Obj}
                end
                
            else
                if not Obj.Toggle then
                    Obj.Pressed=true
                    Obj:Update()
                    if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
                        ButtonStateStorage[Obj.ButtonType][Obj.ButtonID][2]=Obj.Pressed
                    end
                else
                    if not Obj.Pressed then
                        Obj.Pressed=true
                        Obj:Update()
                        if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
                            ButtonStateStorage[Obj.ButtonType][Obj.ButtonID][2]=Obj.Pressed
                        end
                    else
                        Obj:Unpress()
                    end
                    
                end
            end
        end)
        Obj.Hooks:CreateHook("KeyRelease","ButtonB",function(Data)
            local Obj=Data[1]
            if not Obj.Toggle and Obj.Channel==-1 then
                Obj:Unpress()
            end
        end)
        Obj.Hooks:CreateHook("Deselected","ButtonB",function(Data)
            local Obj=Data[1]
            Obj.Hovering=false
            Obj:Update()
        end)
        Obj.Hooks:CreateHook("Selected","ButtonB",function(Data)
            local Obj=Data[1]
            Obj.Hovering=true
            Obj:Update()
        end)
    end
    function VerticalScrollBar(Loc,Size)
        local ScrollBarB=Object(nil)
        ScrollBarB.Length=Size.y-4
        local Width=Size.x-4
        ScrollBarB:AddRenderObj(RenderObjRect(vec2(0,0),vec2(Width+4,ScrollBarB.Length+4),Color(255*0.25,255*0.25,255*0.25),false))
        ScrollBarB:AddRenderObj(RenderObjRect(vec2(2,2),vec2(Width,ScrollBarB.Length),Color(255*0.2,255*0.2,255*0.2),false))
        ScrollBarB:SetSize(vec2(Width+4,ScrollBarB.Length+4))
        ScrollBarB:RelPos(Loc)
        ScrollBarB.Clickable=true
        ScrollBarB.Transparent=true
        ScrollBarB.Pages=0
        ScrollBarB.PerStep=0
        ScrollBarB.Percentage=0
        local ScrollBarUp=Object(nil)
        ScrollBarUp:SetSize(vec2(Width))
        ScrollBarUp:RelPos(vec2(2,2)) 
        ScrollBarUp.Clickable=true
        ScrollBarUp:AddRenderObj(RenderObjRect(vec2(0),vec2(Width),Color(255*0.225,255*0.225,255*0.225),false))
        IsoArrow(ScrollBarUp,vec2(Width/3),vec2(Width)/2+vec2(0,3),-90,Color(255*0.9,255*0.9,255*0.9),0)
        ScrollBarUp:AddTo(1,ScrollBarB)
        ButtonHooks(ScrollBarUp)
        RoundedClickable(ScrollBarUp)
        local ScrollBarDown=Object(nil)
        ScrollBarDown:SetSize(vec2(Width))
        ScrollBarDown:RelPos(vec2(2,SongList.Size.y-6-Width))
        ScrollBarDown.Clickable=true
        ScrollBarDown:AddRenderObj(RenderObjRect(vec2(0),vec2(Width),Color(255*0.225,255*0.225,255*0.225),false))
        IsoArrow(ScrollBarDown,vec2(Width/3),vec2(Width)/2-vec2(0,3),90,Color(255*0.9,255*0.9,255*0.9),0)
        ScrollBarDown:AddTo(1,ScrollBarB)
        ButtonHooks(ScrollBarDown)
        RoundedClickable(ScrollBarDown)
        local ScrollBar=Object(nil)
        ScrollBar.Length=SongList.Size.y-Width*2-4
        ScrollBar:SetSize(vec2(Width,ScrollBar.Length))
        ScrollBar:RelPos(vec2(2,2+Width))
        ScrollBar.Clickable=true
        ScrollBar:AddRenderObj(RenderObjRect(vec2(0),vec2(Width,ScrollBar.Length),Color(255*0.25,255*0.25,255*0.25),false))
        ScrollBar:AddRenderObj(RenderObjRect(vec2(0),vec2(Width,ScrollBar.Length),Color(255*0.35,255*0.35,255*0.35),false))
        ScrollBar:AddTo(1,ScrollBarB)
        local MoveBarFunc=function(Data)
            local NH=math.max(10,ScrollBar.Length/ScrollBarB.Pages)
            local Bottom=ScrollBar.Length-NH  
            ChangedRenderObj(ScrollBar,2,RenderObjRect(vec2(0,Bottom*Data[2]),vec2(Width,NH),Color(255*0.35,255*0.35,255*0.35),false))
            ScrollBarB.Percentage=Data[2]
            ScrollBarB:OnEvent("BarMoved")
        end
        ScrollBarB.Hooks:CreateHook("MoveBar","ScrollBarAction2",MoveBarFunc)
        ScrollBar.Hooks:CreateHook("MoveBar","ScrollBarAction",MoveBarFunc)
        ScrollBar.Clicking=false
        ScrollBar.ScrollOffset=0
        ScrollBar.Hooks:CreateHook("KeyPress","ScrollBarAction",function(Data)
            local NH=math.max(10,ScrollBar.Length/ScrollBarB.Pages)
            local Bottom=vec2(0,(ScrollBar.Length-NH)*ScrollBarB.Percentage)+Data[1]:GetPosition()
            if BoundingBox(Bottom,vec2(Width,NH)):checkPoint(AimPos) then
                ScrollBar.ScrollOffset=(AimPos.y)-Bottom.y-NH/2
            end
            Data[1]:OnEvent("MouseMovedKP")
            timer.remove("ScrollBarActionCheckMoved")
            timer.create( "ScrollBarActionCheckMoved", 1/30, 0, function () 
            Data[1]:OnEvent("MouseMovedKP")
            end) 
        end)
        ScrollBar.Hooks:CreateHook("KeyRelease","ScrollBarAction",function(Data)
            ScrollBar.ScrollOffset=0
            timer.stop("ScrollBarActionCheckMoved")
            timer.remove("ScrollBarActionCheckMoved")
        end)
        local PerCat=0
        ScrollBar.Hooks:CreateHook("MouseMovedKP","ScrollBarAction",function(Data)
            local NH=math.max(10,Data[1].Length/ScrollBarB.Pages)
            local Bottom=Data[1].Length-NH
            local Pos=Data[1]:GetPosition()
            local Per=0
            if ScrollBarB.Pages>0 then
                Per=math.min(math.max((-ScrollBar.ScrollOffset+AimPos.y-Pos.y-NH/2),0),Data[1].Length-NH)/(Data[1].Length-NH)
            end
            Data[1]:OnEvent("MoveBar",Per)
        end)
        local ScrollByAmount=function(Dir)
            if ScrollBarB.Pages>0 then
                ScrollBar:OnEvent("MoveBar",math.max(math.min(ScrollBarB.Percentage+(Dir*ScrollBarB.PerStep),1),0))
            end
        end
        ScrollBarDown.Hooks:CreateHook("KeyPress","OtherKPress",function(Data) 
            ScrollByAmount(1)
            timer.remove("ScrollBarDownActionCheckMoved")
            timer.create( "ScrollBarDownActionCheckMoved", 1/10, 0, function () 
                ScrollByAmount(1)
            end) 
        end)
        ScrollBarDown.Hooks:CreateHook("KeyRelease","OtherKPress",function(Data) 
            timer.stop("ScrollBarDownActionCheckMoved")
            timer.remove("ScrollBarDownActionCheckMoved")
        end)
        ScrollBarUp.Hooks:CreateHook("KeyPress","OtherKPress",function(Data)
            ScrollByAmount(-1)
            timer.remove("ScrollBarUpActionCheckMoved")
            timer.create( "ScrollBarUpActionCheckMoved", 1/10, 0, function () 
                ScrollByAmount(-1)
            end) 
        end)
        ScrollBarUp.Hooks:CreateHook("KeyRelease","OtherKPress",function(Data) 
            timer.stop("ScrollBarUpActionCheckMoved")
            timer.remove("ScrollBarUpActionCheckMoved")
        end)
        return ScrollBarB
    end
    function DefaultBackground(Obj)
        Obj:AddRenderObj(RenderObjRect(vec2(0,0),vec2(128,128),Color(255,100,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(128,128),vec2(128,128),Color(255,100,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(256,256),vec2(128,128),Color(255,100,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(384,384),vec2(128,128),Color(255,100,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(0,128),vec2(128,128),Color(255*0.8,100*0.8,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(128,256),vec2(128,128),Color(255*0.8,100*0.8,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(256,256+128),vec2(128,128),Color(255*0.8,100*0.8,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(128,0),vec2(128,128),Color(255*0.8,100*0.8,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(256,128),vec2(128,128),Color(255*0.8,100*0.8,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(256+128,256),vec2(128,128),Color(255*0.8,100*0.8,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(256,0),vec2(128,128),Color(255*0.6,100*0.6,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(384,0),vec2(128,128),Color(255*0.4,100*0.4,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(384,128),vec2(128,128),Color(255*0.6,100*0.6,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(0,256),vec2(128,128),Color(255*0.6,100*0.6,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(0,384),vec2(128,128),Color(255*0.4,100*0.4,0),false))
        Obj:AddRenderObj(RenderObjRect(vec2(128,384),vec2(128,128),Color(255*0.6,100*0.6,0),false))
    end
    FirstCAts=true
    function RenderObjBoxGraph(RPos,Scale,BoxPerc,ColorB)
        local self=RenderObj(RPos)
        self.BoxPerc=BoxPerc
        self.RelativePos=RPos 
        self.Scale=Scale
        self.Color=ColorB
        self.getBoundingBox=function (self,Pos) 
            return BoundingBox(self.RelativePos+Pos,self.Scale)
        end
        self.render=function(self,Pos,BB,MC)
            if FirstCAts then
                render.createRenderTarget("Gradient")
                render.selectRenderTarget("Gradient")
                for i=1,512 do
                    render.setColor(Color(180-(i/512)*180,1,1):hsvToRGB())
                    render.drawRect(0,i,512,1)
                end
                render.selectRenderTarget("Target2")
                
                FirstCAts=false
            end
            local Pos2=self.RelativePos+Pos
            local B=Color(self.Color.r,self.Color.g,self.Color.b)
            B.r=B.r*MC.x
            B.g=B.g*MC.y
            B.b=B.b*MC.z
            render.setColor(B)
            render.setRenderTargetTexture("Gradient")
            local Count=#self.BoxPerc
            for i=0,Count-1 do
                local Height=self.BoxPerc[i+1]
                render.drawTexturedRectUV( Pos2.x+(self.Scale.x/Count)*i, Pos2.y+(1-Height)*self.Scale.y, self.Scale.x/Count, self.Scale.y*Height ,0,0.5*(1-Height),0.5,0.5,true)
            end
        end
        return self
    end
    local Hooks=HookL()
    function Page1()

        Play=Object(nil)
        local C=math.sqrt(0.75)*20
        Bla={{x=-C/3,y=-10,u=0,v=0},{x=C*2/3,y=0,u=1,v=0},{x=-C/3,y=10,u=0,v=1}}
        
        Play:SetSize(vec2(120,120))
        Play:RelPos(vec2(ScreenSize.x/2-120/2,ScreenSize.y-120-7))
        Play.Clickable=true
        Play:AddRenderObj(RenderObjCircle(vec2(60),vec2(60),Color(255*0.34,255*0.34,255*0.34),false))
        Play:AddRenderObj(RenderObjCircle(vec2(60),vec2(58),Color(255*0.4,255*0.4,255*0.4),false))
        Play:AddRenderObj(RenderObjCircle(vec2(60),vec2(56),Color(255*0.35,255*0.35,255*0.35),false))
        Play:AddRenderObj(RenderObjCircle(vec2(60),vec2(54),Color(255*0.32,255*0.32,255*0.32),false))
        local RRect=RenderObjRect(vec2(60+25,60),vec2(20,70),Color(255*0.9,255*0.9,255*0.9),false)
        RRect:setRadius(5)
        RRect:setAlignment(0)
        Play:AddRenderObj(RRect)
        local RRect=RenderObjRect(vec2(60-25,60),vec2(20,70),Color(255*0.9,255*0.9,255*0.9),false)
        RRect:setRadius(5)
        RRect:setAlignment(0)
        Play:AddRenderObj(RRect)
        Play.DrawZ=5
        Play:AddTo(1,Root)
        ButtonHooks(Play)
        RoundedClickable(Play)
        
        Note=Object(nil)
        Note.DrawZ=3
        Note:AddRenderObj(RenderObjCircle(vec2(60),60,Color(255*0.34,255*0.34,255*0.34),false))
        
        FBack=Object(nil)
        FBack:SetSize(vec2(80,80))
        FBack:RelPos(vec2(ScreenSize.x/2-120/2-80-10,ScreenSize.y-60-40-7))
        FBack.Clickable=true
        FBack.DrawZ=5
        FBack:AddRenderObj(RenderObjCircle(vec2(40),40,Color(255*0.34,255*0.34,255*0.34),false))
        FBack:AddRenderObj(RenderObjCircle(vec2(40),38,Color(255*0.4,255*0.4,255*0.4),false))
        FBack:AddRenderObj(RenderObjCircle(vec2(40),36,Color(255*0.35,255*0.35,255*0.35),false))
        FBack:AddRenderObj(RenderObjCircle(vec2(40),34,Color(255*0.32,255*0.32,255*0.32),false))
        local B=10/4
        FBack:AddRenderObj(RenderObjPoly(vec2(40-(C*B*(1/4)),40),vec2(-B/2,-B),Bla,Color(255*1,255*1,255*1)))
        FBack:AddRenderObj(RenderObjPoly(vec2(40+(C*B*(1/4)),40),vec2(-B/2,-B),Bla,Color(255*1,255*1,255*1)))
        FBack.Toggle=true
        FBack:AddTo(1,Root)

        ButtonHooks(FBack)
        RoundedClickable(FBack)
        FForw=Object(nil)
        FForw:SetSize(vec2(80,80))
        FForw:RelPos(vec2(ScreenSize.x/2+120/2+10,ScreenSize.y-60-40-7))
        FForw.DrawZ=5
        FForw.Clickable=true
        FForw:AddRenderObj(RenderObjCircle(vec2(40),40,Color(255*0.34,255*0.34,255*0.34),false))
        FForw:AddRenderObj(RenderObjCircle(vec2(40),38,Color(255*0.4,255*0.4,255*0.4),false))
        FForw:AddRenderObj(RenderObjCircle(vec2(40),36,Color(255*0.35,255*0.35,255*0.35),false))
        FForw:AddRenderObj(RenderObjCircle(vec2(40),34,Color(255*0.32,255*0.32,255*0.32),false))
        FForw:AddRenderObj(RenderObjPoly(vec2(40-(C*B*(1/4)),40),vec2(B/2,B),Bla,Color(255*1,255*1,255*1)))
        FForw:AddRenderObj(RenderObjPoly(vec2(40+(C*B*(1/4)),40),vec2(B/2,B),Bla,Color(255*1,255*1,255*1)))
        FForw.Toggle=true
        FForw:AddTo(1,Root)

        ButtonHooks(FForw)
        RoundedClickable(FForw)
        
        ShuffleButton=Object(nil)
        ShuffleButton:SetSize(vec2(60,60))
        ShuffleButton:RelPos(vec2(ScreenSize.x/2-120/2-80-10-20-60,ScreenSize.y-60-30-7))
        ShuffleButton:AddRenderObj(RenderObjCircle(vec2(30),30,Color(255*0.32,255*0.32,255*0.32),false))
        ShuffleButton.Clickable=true
        ShuffleButton.DrawZ=5
        ShuffleButton:AddTo(1,Root)
        ShuffleIcon(ShuffleButton,vec2(30*0.75),vec2(30),0,Color(255,255,255))
        ButtonHooks(ShuffleButton)
        RoundedClickable(ShuffleButton)
        
        RepeatButton=Object(nil)
        RepeatButton.DrawZ=5
        RepeatButton:SetSize(vec2(60,60))
        RepeatButton:RelPos(vec2(ScreenSize.x/2+120/2+80+10+20,ScreenSize.y-60-30-7))
        RepeatButton:AddRenderObj(RenderObjCircle(vec2(30),30,Color(255*0.32,255*0.32,255*0.32),false))
        RepeatButton.Clickable=true
        RepeatButton:AddTo(1,Root)
        RepeatIcon(RepeatButton,vec2(30*0.6),vec2(30),0,Color(255,255,255))
        ButtonHooks(RepeatButton)
        RoundedClickable(RepeatButton)
        
        TopBar=Object(nil)
        TopBar.Clickable=false
        TopBar:AddRenderObj(RenderObjRect(vec2(0,0),vec2(ScreenSize.x,70),Color(255*0.26,255*0.26,255*0.26),false))
        TopBar:AddRenderObj(RenderObjRect(vec2(0,70),vec2(ScreenSize.x,2),Color(255*0.24,255*0.24,255*0.24),false))
        local Size=vec2(ScreenSize.x-160,50)
        local RRect=RenderObjRect(vec2(ScreenSize.x,70)/2-Size/2,Size,Color(255*0.18,255*0.18,255*0.18),false)
        RRect:setRadius(25)
        TopBar:AddRenderObj(RRect)
        Size=vec2(ScreenSize.x-160-4,50-4)
        local RRect2=RenderObjRect(vec2(ScreenSize.x,70)/2-Size/2,Size,Color(255*0.22,255*0.22,255*0.22),false)
        RRect2:setRadius(23)
        TopBar:AddRenderObj(RRect2)
        TopBar.Font=Font( "Arial", 45, 200, true, false, false, false, true, true )
        TopBar:AddRenderObj(RenderObjText(vec2(ScreenSize.x/2,70/2),"Explosion",Color(220,220,220),vec2(1,1),TopBar.Font))
        TopBar:SetSize(vec2(ScreenSize.x,72))
        TopBar:RelPos(vec2(0,0))
        TopBar:AddTo(1,Root)
        BackButton=Object(nil)
        BackButton.Clickable=true
        BackButton:SetSize(vec2(50,50))
        BackButton:RelPos(vec2(10,10))
        BackButton:AddRenderObj(RenderObjCircle(vec2(25),25,Color(255*0.25,255*0.25,255*0.25),false))
        ArrowIcon(BackButton,40,vec2(25),0)
        ButtonHooks(BackButton)
        RoundedClickable(BackButton)
        BackButton.Hooks:CreateHook("KeyPress","BackButtonKPress",function(Data) 
            SwitchLayout(Root,2)
        end)
        BackButton:AddTo(1,TopBar)
        
        SettingsButton=Object(nil)
        SettingsButton.Clickable=true
        SettingsButton:SetSize(vec2(50,50))
        SettingsButton:RelPos(vec2(ScreenSize.x-60,10))
        SettingsButton:AddRenderObj(RenderObjCircle(vec2(25),25,Color(255*0.25,255*0.25,255*0.25),false))
        GearIcon(SettingsButton,40,vec2(25))
        ButtonHooks(SettingsButton)
        RoundedClickable(SettingsButton)
        SettingsButton:AddTo(1,TopBar)
        
        Test5=Object(nil)
        Test5:AddRenderObj(RenderObjRect(vec2(0,12),vec2(ScreenSize.x,133),Color(255*0.26,255*0.26,255*0.26),false))
        Test5:AddRenderObj(RenderObjRect(vec2(0,0),vec2(ScreenSize.x,12),Color(255*0.24,255*0.24,255*0.24),false))
        Test5:AddRenderObj(RenderObjText(vec2(5,12),"0:00/0:00",Color(255*0.8,255*0.8,255*0.8),vec2(0,0),nil))
        Test5:SetSize(vec2(ScreenSize.x,145))
        Test5:RelPos(vec2(0,ScreenSize.y-145))
        Test5.DrawZ=7
        Test5:AddTo(1,Root)
        
        
        CurrentTime=Object(nil)
        local RRect2=RenderObjRect(vec2(0,5),vec2(ScreenSize.x,12),Color(255*0.4,255*0.4,255*0.4),false)
        RRect2:setRadius(6)
        CurrentTime:AddRenderObj(RRect2)
        local RRect2=RenderObjRect(vec2(1,6),vec2(ScreenSize.x-2,10),Color(255*0.15,255*0.15,255*0.15),false)
        RRect2:setRadius(5)
        CurrentTime:AddRenderObj(RRect2)
        CurrentTime:SetSize(vec2(ScreenSize.x,22))
        CurrentTime:RelPos(vec2(0,ScreenSize.y-145-5))
        CurrentTime.DrawZ=3
        CurrentTime.Clickable=true
        CurrentTime.Transparent=true
        local MoveBarFunc=function(Data)
            local RRect2=RenderObjRect(vec2(1,6),vec2(math.floor((ScreenSize.x-2)*Data[2]),10),Color(255*0.5,255*0.5,255*0.8),false)
            RRect2:setRadius(5)
            ChangedRenderObj(Data[1],3,RRect2)
            local Pos=vec2(math.floor(1+(ScreenSize.x-2)*Data[2]),11)
            ChangedRenderObj(Data[1],4,RenderObjCircle(Pos,10,Color(255*0.4,255*0.4,255*0.4),false))
            ChangedRenderObj(Data[1],5,RenderObjCircle(Pos,8,Color(255*0.34,255*0.34,255*0.34),false))
            ChangedRenderObj(Data[1],6,RenderObjCircle(Pos,6,Color(255*0.32,255*0.32,255*0.32),false))
            ChangedRenderObj(Data[1],7,RenderObjCircle(Pos,4,Color(255*0.3,255*0.3,255*0.3),false))
        end
        MoveBarFunc({CurrentTime,0})
        CurrentTime.Hooks:CreateHook("MoveBar","ScrollBarAction",MoveBarFunc)

        CurrentTime:AddTo(1,Root)
        
        
        VolumeBar=Object(nil)
        VolumeBar.Length=(ScreenSize.x/3)-2
        local RRect2=RenderObjRect(vec2(0,5),vec2(VolumeBar.Length+2,12),Color(255*0.4,255*0.4,255*0.4),false)
        RRect2:setRadius(6)
        VolumeBar:AddRenderObj(RRect2)
        local RRect2=RenderObjRect(vec2(1,6),vec2(VolumeBar.Length,10),Color(255*0.15,255*0.15,255*0.15),false)
        RRect2:setRadius(5)
        VolumeBar:AddRenderObj(RRect2)
        VolumeBar:SetSize(vec2(VolumeBar.Length+2,22))
        VolumeBar:RelPos(vec2(20,ScreenSize.y-22-5))
        VolumeBar.DrawZ=3
        VolumeBar.Clickable=true
        VolumeBar.Transparent=true
        local MoveBarFunc=function(Data)
            local RRect2=RenderObjRect(vec2(1,6),vec2(math.floor(Data[1].Length*Data[2]),10),Color(255*0.9,255*0.9,255*0.9),false)
            RRect2:setRadius(5)
            ChangedRenderObj(Data[1],3,RRect2)
            local Pos=vec2(math.floor(1+(Data[1].Length)*Data[2]),11)
            ChangedRenderObj(Data[1],4,RenderObjCircle(Pos,10,Color(255*0.4,255*0.4,255*0.4),false))
            ChangedRenderObj(Data[1],5,RenderObjCircle(Pos,8,Color(255*0.34,255*0.34,255*0.34),false))
            ChangedRenderObj(Data[1],6,RenderObjCircle(Pos,6,Color(255*0.32,255*0.32,255*0.32),false))
            ChangedRenderObj(Data[1],7,RenderObjCircle(Pos,4,Color(255*0.3,255*0.3,255*0.3),false))
        end
        MoveBarFunc({VolumeBar,0.5})
        VolumeBar.Hooks:CreateHook("MoveBar","ScrollBarAction",MoveBarFunc)
        VolumeBar.Clicking=false
        VolumeBar.Hooks:CreateHook("KeyPress","ScrollBarAction",function(Data) 
            Data[1]:OnEvent("MouseMovedKP")
            timer.create( "ScrollBarActionCheckMoved", 1/10, 0, function () 
            Data[1]:OnEvent("MouseMovedKP")
            end) 
        end)
        VolumeBar.Hooks:CreateHook("KeyRelease","ScrollBarAction",function(Data)
            timer.stop("ScrollBarActionCheckMoved")
        end)
        VolumeBar:AddTo(1,Root)
        
        
        Test6=Object(nil)
        Size=vec2(ScreenSize.x-10,ScreenSize.y-145-72-10)
        Test6:AddRenderObj(RenderObjRect(vec2(0,0),Size,Color(255*0.28,255*0.28,255*0.28),false))
        Test6:SetSize(Size)
        Test6:RelPos(vec2(5,72+5))
        Test6.DrawZ=7
        Test6:AddTo(1,Root)
        Test7=Object(nil)
        Size=vec2(ScreenSize.x-20,ScreenSize.y-145-72-20)
        Test7:AddRenderObj(RenderObjRect(vec2(0,0),Size,Color(255*0.1,255*0.1,255*0.1),false))
        Count=30
        Bap={}
        for i=1,Count do
            Bap[i]=math.random()*0.9
        end
        --if player()==owner() then


        Test7:AddRenderObj(RenderObjBoxGraph(vec2(0,0),Size,Bap,Color(255*0.9,255*0.9,255*0.9)))
        Test7:SetSize(Size)
        Test7:RelPos(vec2(ScreenSize.x/2-Size.x/2-5,5))
        Test7.DrawZ=7
        Test7:AddTo(1,Test6)
        local O=vec2(50,50)
        local S=vec2(50,50)
        Test8=Object(nil)

        Test8:SetSize(S*2)
        Test8:RelPos(vec2(ScreenSize.x/2-S.x/2,ScreenSize.y/2-S.y/2))
        Test8.DrawZ=2
        Test8:AddTo(1,Root)
        
    end
    local ChangeSong=nil
    function Page2()
        Root:AddLayout(Layout(Root,2))
        TopBar2=Object(nil)
        TopBar2.Clickable=false
        TopBar2:AddRenderObj(RenderObjRect(vec2(0,0),vec2(ScreenSize.x,70),Color(255*0.26,255*0.26,255*0.26),false))
        TopBar2:AddRenderObj(RenderObjRect(vec2(0,70),vec2(ScreenSize.x,2),Color(255*0.24,255*0.24,255*0.24),false))
        local Size=vec2(ScreenSize.x*0.7,50)
        local RRect=RenderObjRect(vec2(ScreenSize.x,70)/2-Size/2,Size,Color(255*0.18,255*0.18,255*0.18),false)
        RRect:setRadius(25)
        TopBar2:AddRenderObj(RRect)
        Size=vec2(ScreenSize.x*0.7-4,50-4)
        local RRect2=RenderObjRect(vec2(ScreenSize.x,70)/2-Size/2,Size,Color(255*0.22,255*0.22,255*0.22),false)
        RRect2:setRadius(23)
        TopBar2:AddRenderObj(RRect2)
        TopBar2:SetSize(vec2(ScreenSize.x,72))
        TopBar2:RelPos(vec2(0,0))
        TopBar2:AddTo(2,Root)
        
        --DefaultB Channel
        
        
        AllSongsButton=Object(nil)
        AllSongsButton.Clickable=true
        local Size2=Size
        Size=vec2((ScreenSize.x*0.7-4-4)/4-4,50-4-4)
        AllSongsButton:SetSize(Size+vec2(1,0))
        AllSongsButton:RelPos(vec2(ScreenSize.x,70)/2-Size2/2+vec2(4,2))
        local RRect=RenderObjRect(vec2(0),Size,Color(255*0.18,255*0.18,255*0.18),false)
        RRect:setRadius((Size.y-2)/2)
        RRect:setRoundedEdges(true,false,true,false)
        AllSongsButton:AddRenderObj(RRect)
        local RRect=RenderObjRect(vec2(1,1),Size-vec2(2,2),Color(255*0.31,255*0.31,255*0.31),false)
        RRect:setRadius((Size.y-2)/2)
        RRect:setRoundedEdges(true,false,true,false)
        AllSongsButton.DefaultB=true
        AllSongsButton.Channel=2
        AllSongsButton:AddRenderObj(RRect)
        MusicIcon(AllSongsButton,vec2(Size.y,Size.y),Size/2,0,Color(255,255,255))
        
        ButtonHooks(AllSongsButton)
        RoundedClickable(AllSongsButton)

        AllSongsButton:AddTo(1,TopBar2)
        
        PlaylistsButton=Object(nil)
        PlaylistsButton.Clickable=true
        Size=vec2((ScreenSize.x*0.7-4-4)/4-4,50-4-4)
        PlaylistsButton:SetSize(Size+vec2(1,0))
        PlaylistsButton:RelPos(vec2(ScreenSize.x,70)/2-Size2/2+vec2(Size.x+4+4,2))
        local RRect=RenderObjRect(vec2(0),Size+vec2(1,0),Color(255*0.18,255*0.18,255*0.18),false)
        PlaylistsButton:AddRenderObj(RRect)
        local RRect=RenderObjRect(vec2(1,1),Size-vec2(2,2)+vec2(1,0),Color(255*0.31,255*0.31,255*0.31),false)
        PlaylistsButton:AddRenderObj(RRect)
        PlaylistsButton.Channel=2
        PlaylistIcon(PlaylistsButton,vec2(Size.y,Size.y),Size/2,0,Color(255,255,255))
        
        ButtonHooks(PlaylistsButton)
        PlaylistsButton:AddTo(1,TopBar2)
        
        RadioButton=Object(nil)
        RadioButton.Clickable=true
        Size=vec2((ScreenSize.x*0.7-4-4)/4-4,50-4-4)
        RadioButton:SetSize(Size)
        RadioButton:RelPos(vec2(ScreenSize.x,70)/2-Size2/2+vec2(Size.x*2+4+4+4,2))
        local RRect=RenderObjRect(vec2(0),Size,Color(255*0.18,255*0.18,255*0.18),false)
        RadioButton:AddRenderObj(RRect)
        local RRect=RenderObjRect(vec2(1,1),Size-vec2(2,2),Color(255*0.31,255*0.31,255*0.31),false)
        RadioButton:AddRenderObj(RRect)
        RadioButton.Channel=2
        ButtonHooks(RadioButton)
        RadioButton.Hooks:CreateHook("KeyPress","BackButtonKPress",function(Data) 
            --SwitchLayout(Root,1)
        end)
        RadioButton:AddTo(1,TopBar2)
        
        ModifyButton=Object(nil)
        ModifyButton.Clickable=true
        Size=vec2((ScreenSize.x*0.7-4-4)/4-4,50-4-4)
        ModifyButton:SetSize(Size+vec2(2,0))
        ModifyButton:RelPos(vec2(ScreenSize.x,70)/2-Size2/2+vec2(Size.x*3+4+4+4+4,2))
        local RRect=RenderObjRect(vec2(0),Size+vec2(1,0),Color(255*0.18,255*0.18,255*0.18),false)
        RRect:setRadius((Size.y-2)/2)
        RRect:setRoundedEdges(false,true,false,true)
        ModifyButton:AddRenderObj(RRect)
        local RRect=RenderObjRect(vec2(1,1),Size-vec2(2,2)+vec2(1,0),Color(255*0.31,255*0.31,255*0.31),false)
        RRect:setRadius((Size.y-2)/2)
        RRect:setRoundedEdges(false,true,false,true)
        ModifyButton:AddRenderObj(RRect)
        ModifyButton.Channel=2
        ButtonHooks(ModifyButton)
        RoundedClickable(ModifyButton)

        ModifyButton:AddTo(1,TopBar2)
        
        BackButton2=Object(nil)
        BackButton2.Clickable=true
        BackButton2:SetSize(vec2(50,50))
        BackButton2:RelPos(vec2(ScreenSize.x-60,10))
        BackButton2:AddRenderObj(RenderObjCircle(vec2(25),25,Color(255*0.25,255*0.25,255*0.25),false))
        ArrowIcon(BackButton2,40,vec2(25),180)
        ButtonHooks(BackButton2)
        RoundedClickable(BackButton2)
        BackButton2.Hooks:CreateHook("KeyPress","BackButtonKPress",function(Data) 
            SwitchLayout(Root,1)
        end)
        BackButton2:AddTo(1,TopBar2)
        
        SettingsButton2=Object(nil)
        SettingsButton2.Clickable=true
        SettingsButton2:SetSize(vec2(50,50))
        SettingsButton2:RelPos(vec2(10,10))
        SettingsButton2:AddRenderObj(RenderObjCircle(vec2(25),25,Color(255*0.25,255*0.25,255*0.25),false))
        GearIcon(SettingsButton2,40,vec2(25))
        ButtonHooks(SettingsButton2)
        RoundedClickable(SettingsButton2)
        SettingsButton2:AddTo(1,TopBar2)
        
        local SongListS=vec2(ScreenSize.x-8,ScreenSize.y-74-4)
        SongList=Object(nil)
        SongList:SetSize(SongListS)
        SongList:RelPos(vec2(4,74))
        SongList:AddRenderObj(RenderObjRect(vec2(0,0),SongListS,Color(255*0.28,255*0.28,255*0.28),false))
        SongList.DrawZ=6
        SongList:AddLayout()
        SongList:AddLayout()
        SongList:AddLayout()
        SongList:AddLayout()
        SongList:AddTo(2,Root)
        
        ScrollBar=VerticalScrollBar(vec2(ScreenSize.x-8-(65-4-16)-2+4,2+74),vec2(65-4-4-16+4,ScreenSize.y-74-4-8+4))
        ScrollBar.DrawZ=5
        ScrollBar:AddTo(2,Root)
        
        --Search Layout
        local SearchBarS=vec2(SongListS.x-8,22+2)
        Search=Object(nil)
        Search.Clickable=true
        Search:SetSize(SearchBarS)
        Search:RelPos(vec2(4,4))
        local R=RenderObjRect(vec2(0),SearchBarS,Color(0,0,0),false) R:setRadius(5) Search:AddRenderObj(R)
        local R=RenderObjRect(vec2(1),SearchBarS-vec2(2),Color(255*0.8,255*0.8,255*0.8),false) R:setRadius(5) Search:AddRenderObj(R)
        Search.Font=Font( "Arial", 22, 400, true, false, false, false, true, true )
        local SearchTex=RenderObjText(vec2(1,SearchBarS.y/2),"Cat",Color(0,0,0),vec2(0,1),Search.Font)
        Search:AddRenderObj(SearchTex)
        Search.Hooks:CreateHook("IsNowClickedObject","SearchClick",function(Data)
            return true
        end)
        Search.Hooks:CreateHook("KeyboardPress","SearchClick",function(Data)
            print(Data[2])
        end)
        Search:AddTo(4,SongList)
        
        
    end
    function Page3()
        local P=3
        Root:AddLayout(Layout(Root,P))
        
    end
    local LoadedList
    local FailedToLoadList
    function Page4()
        local P=4
        Root:AddLayout(Layout(Root,P))
        local Icon=Object(nil)
        local Size=0
        if ScreenSize.x>ScreenSize.y then
            if ScreenSize.y<ScreenSize.x*0.7 then
                Size=ScreenSize.y*0.8
            else
                Size=ScreenSize.x*0.7
            end
        else
            if ScreenSize.x<ScreenSize.y*0.7 then
                Size=ScreenSize.x*0.8
            else
                Size=ScreenSize.y*0.7
            end
        end
        local StatusText="Waiting..."
        local URL="https://zxvnm4.ca/DOOM/DOOM (2016) OST - Rip 0026 Tear.mp3"
        local DialogBox
        if not hasPermission("bass.loadURL", URL) or not hasPermission("http.get", URL) then
            DialogBox=Object(nil)
            local Text="You need to click e to request permissions," 
            local Text2="they are required for this to function."
            DialogBox.Font2=Font( "Arial", 30, 200, true, false, false, false, true, true )
            DialogBox.Font=Font( "Arial", 20, 200, true, false, false, false, true, true )
            local Size3=DialogBox.Font:getTextSize(Text)
            local Size4=DialogBox.Font2:getTextSize(Text)
            local Size2=vec2(Size,Size4.y+Size3.y*2+5)
            local RRect=RenderObjRect(vec2(0),Size2,Color(255*0.05,255*0.05,255*0.05),false) RRect:setRadius(10) DialogBox:AddRenderObj(RRect)
            local RRect=RenderObjRect(vec2(1),Size2-vec2(2),Color(255*0.31,255*0.31,255*0.31),false) RRect:setRadius(10) DialogBox:AddRenderObj(RRect)
            local RRect=RenderObjRect(vec2(1),Size2-vec2(2),Color(255*0.8,255*0.8,255*0.8),false) RRect:setRadius(10) DialogBox:AddRenderObj(RRect)
            DialogBox:AddRenderObj(RenderObjText(vec2(Size2.x/2,2),"Hey Listen!",Color(255*0.05,255*0.05,255*0.05),vec2(1,0),DialogBox.Font2))
            DialogBox:AddRenderObj(RenderObjText(vec2(Size2.x/2,2+Size4.y),Text,Color(255*0.05,255*0.05,255*0.05),vec2(1,0),DialogBox.Font))
            DialogBox:AddRenderObj(RenderObjText(vec2(Size2.x/2,Size2.y-2-Size3.y),Text2,Color(255*0.05,255*0.05,255*0.05),vec2(1,0),DialogBox.Font))
            DialogBox.Transparent=true
            DialogBox:SetSize(Size2)
            DialogBox:RelPos(vec2(ScreenSize.x/2-Size2.x/2,ScreenSize.y/2-Size2.y/2))
            DialogBox.DrawZ=2
            DialogBox:AddTo(P,Root)

        else
            StatusText="Loading..."
        end
        Icon:SetSize(vec2(Size,Size))
        Icon:RelPos(vec2(ScreenSize.x/2-Size/2,ScreenSize.y/2-Size/2))
        Icon:AddRenderObj(RenderObjCircle(vec2(Size/2),vec2(Size/2),Color(100,100,230),false))
        MusicIcon(Icon,vec2(Size,Size),vec2(Size/2),0,Color(255,255,255))
        --PlaylistIcon(Icon,vec2(Size,Size),vec2(Size/2),0,Color(255,255,255))
        Icon:AddTo(P,Root)
        
        local Name=Object(nil)
        Name.Font=Font( "Arial", 55, 200, true, false, false, false, true, true )
        
        local Size2=Name.Font:getTextSize(StatusText)
        Name:AddRenderObj(RenderObjText(vec2(Size/2,Size2.y/2),"Music Player",Color(255*0.8,255*0.8,255*0.8),vec2(1,1),Name.Font))
        Name.Transparent=true
        Name:SetSize(vec2(Size,Size2.y))
        Name:RelPos(vec2(ScreenSize.x/2-Size/2,ScreenSize.y/2-Size/2-Size2.y))
        Name:AddTo(P,Root)
        local Info=Object(nil)
        Info.Font=Font( "Arial", 40, 200, true, false, false, false, true, true )
        
        local Size2=Info.Font:getTextSize(StatusText)
        Info:AddRenderObj(RenderObjText(vec2(Size/2,Size2.y/2),StatusText,Color(255*0.8,255*0.8,255*0.8),vec2(1,1),Info.Font))
        Info.Transparent=true
        Info:SetSize(vec2(Size,Size2.y))
        Info:RelPos(vec2(ScreenSize.x/2-Size/2,ScreenSize.y/2+Size/2))
        Info:AddTo(P,Root)
        local ListLoaded=false
        if not hasPermission("bass.loadURL", URL) or not hasPermission("http.get", URL) then
            hook.add("permissionrequest", "Page4DialogBox",function ()
                RemoveObj(DialogBox)
                ChangedRenderObj(Info,1,RenderObjText(vec2(Size/2,Size2.y/2),"Loading...",Color(255*0.8,255*0.8,255*0.8),vec2(1,1),Info.Font))
                if ListLoaded then LoadedList() end
            end)
        end
        
        LoadedList=function()
            if hasPermission("bass.loadURL", URL) and hasPermission("http.get", URL) then
                ChangedRenderObj(Info,1,RenderObjText(vec2(Size/2,Size2.y/2),"Finished",Color(255*0.8,255*0.8,255*0.8),vec2(1,1),Info.Font))
                timer.create("LoadedListWait",1,1,function()
                    SwitchLayout(Root,2)
                end)
            end
            ListLoaded=true
        end
        FailedToLoadList=function()
            ChangedRenderObj(Info,1,RenderObjText(vec2(Size/2,Size2.y/2),"Error: Cannot Load List",Color(255*0.8,255*0.8,255*0.8),vec2(1,1),Info.Font))
            ListLoaded=true
        end
    end
    function StartMusic()
        local Done=false
        local Bass=nil
        local IsPaused=false
        local Playing=true
        local MovingBar=false
        local URL=""
        local Volume=0.1
        local function CheckBass(B)
            if B then if B.isValid~=nil then if B:isValid() then return true end end end
            return false
        end
        VolumeBar:OnEvent("MoveBar",Volume)
        VolumeBar.Hooks:CreateHook("MouseMovedKP","ScrollBarAction",function(Data)
            
            local Pos=VolumeBar:GetPosition()
            local Per=math.min(math.max((AimPos.x-Pos.x),0),Data[1].Length)/Data[1].Length
            Volume=Per
            Data[1]:OnEvent("MoveBar",Per)
            if CheckBass(Bass) then
                Bass:setVolume(Per)
            end
        end)
        local StopMovingTime=function()
            FBack:Unpress()
            FForw:Unpress()
            if Bass then
                if MovingBar then
                    if Playing then
                        IsPaused=false
                        Bass:play()
                    end
                    MovingBar=false
                end
            end
            timer.remove("Whatadad")
        end
        local SetCurrentTime=function(Time)
            if CheckBass(Bass) then
                MovingBar=true
                timer.create("Whatadad",0.25,0,function()
                    if Bass then
                        if not Bass:isValid() then timer.remove("Whatadad") return end
                        local CTime=Bass:getTime()
                        if quotaTotalAverage()>=quotaMax()*0.7 then
                            return
                        end
                        if math.floor(Time/5)*5~=math.floor(CTime/5)*5 then
                            local Diff=Time-CTime
                            local Sign=1
                            if Diff<0 then
                                Sign=-1
                            end
                            Bass:setTime(CTime+Sign*math.min(10,Sign*Diff))
                        else
                            StopMovingTime()
                        end
                    else
                        timer.remove("Whatadad")
                    end
                end)
            end
        end
        FBack.Hooks:CreateHook("KeyPress","FBackKPress",function(Data) 
            if CheckBass(Bass) then
                if FBack.Pressed then
                    SetCurrentTime(0)
                else
                    StopMovingTime()
                end
            end
        end)
        FForw.Hooks:CreateHook("KeyPress","FBackKPress",function(Data) 
            if CheckBass(Bass) then
                if FForw.Pressed then
                    SetCurrentTime(Bass:getLength())
                else
                    StopMovingTime()
                end
            end
        end)
        CurrentTime.Hooks:CreateHook("KeyPress","ScrollBarAction",function(Data)
            if CheckBass(Bass) then
                local Per=math.min(math.max((AimPos.x-2),0),(ScreenSize.x-4))/(ScreenSize.x-4)
                local Time=math.floor(Per*Bass:getLength()*10)/10
                IsPaused=true
                Bass:pause()
                
                SetCurrentTime(Time)
            end
        end)
        Play.Hooks:CreateHook("ToggleButton","PlayButtonAction",function(Data) 
            if Playing then
                ChangedRenderObj(Play,5,RenderObjPoly(vec2(60),vec2(4,4)*10,IsoArrowVerts,Color(255*1,255*1,255*1)))
                RemoveRenderObj(Play,6)
            else
                local RRect=RenderObjRect(vec2(60+25,60),vec2(20,70),Color(255*0.9,255*0.9,255*0.9),false)
                RRect:setRadius(5)
                RRect:setAlignment(0)
                ChangedRenderObj(Play,5,RRect)
                local RRect=RenderObjRect(vec2(60-25,60),vec2(20,70),Color(255*0.9,255*0.9,255*0.9),false)
                RRect:setRadius(5)
                RRect:setAlignment(0)
                AddRenderObj(Play,RRect)
            end
        end)
        Play.Hooks:CreateHook("KeyPress","PlayButtonAction",function(Data) 
            if not CheckBass(Bass) then return end  
            if MovingBar then
                StopMovingTime()
                if Playing then return end
            end
            if Playing then
                IsPaused=false
                Bass:pause()
            else
                IsPaused=true
                Bass:play()
            end
            Play:OnEvent("ToggleButton")
            Playing=not Playing
        end)
        local LoadingSong=false
        local PlaySong = function()
            
            if not Done and hasPermission("bass.loadURL", URL) then
            Done=true
            IsPaused=false
            if Bass then
                if Bass.stop then Bass:stop() end
                if Bass.destroy then Bass:destroy() end
                
                timer.stop("Meow2")
                timer.stop("Meow")
            end
            
            bass.loadURL(URL , "mono 3d noblock", function (BassG,Err,Name)
                Bass=BassG
                LoadingSong=false
                if Bass then
                    
                    Bass:setFade(300, 400)
                    Bass:setVolume(Volume)
                    if Playing==false then
                        Play:OnEvent("ToggleButton")
                        Playing=true
                    end
                    MovingBar=false
                    timer.create( "Meow2", 1/10, 0, function ()
                        if Playing and Bass:isValid() and Test5:GetDrawable() and CurrentTime:GetDrawable()  then
                            CurrentTime:OnEvent("MoveBar",Bass:getTime()/Bass:getLength())
                            ChangedRenderObj(Test5,3,RenderObjText(vec2(5,12),SecondsToFormattedStr(Bass:getTime()).."/"..SecondsToFormattedStr(Bass:getLength()),Color(255*0.8,255*0.8,255*0.8),vec2(0,0),nil))
                        end
                    end)
                    local F=(1/1024)*1000
                    local CatsInstuff=function(T,a,b)
                        local Total=0
                        if b-a==0 then return 0 end
                        for i=a,b do
                            Total=Total+T[i]*F*(i-1)
                        end
                        return Total/(b-a)
                    end
                    local C=1.02
                    local Bars=math.floor((ScreenSize.y-145-72-20)/3)
                    local Max=C^Bars
                    local Pos=-C^(-Bars)
                    local Mul=(512-1)/(1+Pos)
                    local SkipTicks=0
                    local CatTick=0
                    timer.create( "Meow", 1/30, 0, function ()
                        CatTick=CatTick+1
                        if not CheckBass(Bass) then Hooks:OnEvent("SongEnded") return end
                        if quotaTotalAverage()>=quotaMax()*0.7 then
                            return
                        end
                        if Bass:isValid() then
                            if math.floor(Bass:getTime()*20)/20==math.floor(Bass:getLength()*20)/20 then
                                Hooks:OnEvent("SongEnded")
                            end
                        else
                            Hooks:OnEvent("SongEnded")
                        end   
                        if not CheckBass(Bass) then return end
                        if Playing and Bass:isValid() and Test7:GetDrawable() then
                            local B=Bass:getFFT(2)

                            if #B~=0 then
                                local Cats={}
                                local LDat=1
                                for i=1,Bars do
                                    local Dat=1+math.round(math.max((((C^i)/Max)+Pos)*Mul,0))
                                    Cats[Bars-i+1]=math.min(CatsInstuff(B,LDat,Dat)/10,1)--=math.min((math.log10(B[Dat]*math.max(Dat*2,10)+1))/1.5,1)
                                    LDat=Dat
                                end
                                for i=1,Bars do
                                    Cats[Bars+i]=Cats[Bars-i+1]--=math.min((math.log10(B[Dat]*math.max(Dat*2,10)+1))/1.5,1)
                                end
                                ChangedRenderObj(Test7,2,RenderObjBoxGraph(vec2(0,0),vec2(ScreenSize.x-20,ScreenSize.y-145-72-20),Cats,Color(255*0.9,255*0.9,255*0.9)))
                            end
                        end
                    end)
                    --pcall(Bass.setLooping, Bass, true) -- pcall in case of audio stream
                    hook.add("think", "snd", function()
                        if isValid(Bass) and isValid(chip()) then
                            Bass:setPos(ScreenPosition)--(ScreenEnt:getPos())
                        end
                    end)
                else
                    print(Name)
                end
            end)
            end
        end
        Hooks:CreateHook("SongEnded","MusicList",function(Data)
            timer.remove("Meow")
            timer.remove("Meow2")
        end)
        ChangeSong = function(NURL,Name)
            if LoadingSong then return end
            LoadingSong=true
            URL=NURL
            Done=false
            if TopBar.Font.size~=45 then
                TopBar.Font.size=45
                TopBar.Font:Reaquire()
            end   
            local FullSize=ScreenSize.x-160-4-10
            local Text=RenderObjText(vec2(ScreenSize.x/2,70/2),Name,Color(220,220,220),vec2(1,1),TopBar.Font)
            local S1=Text:getTextSize()
            if S1.x>FullSize then
                TopBar.Font.size=TopBar.Font.size*(FullSize/S1.x)
                TopBar.Font:Reaquire()
                Text=RenderObjText(vec2(ScreenSize.x/2,70/2),Name,Color(220,220,220),vec2(1,1),TopBar.Font)
            end
            ChangedRenderObj(TopBar,5,Text)
            PlaySong()
        end
        URL="https://zxvnm4.ca/DOOM/DOOM (2016) OST - Rip 0026 Tear.mp3"
        --URL="https://zxvnm4.ca/SineTest2"
        local Name="DOOM (2016) OST - Rip 0026 Tear"
        --URL="https://zxvnm4.ca/Retro/Toscanini - Dies irae  (1951).mp3"
        --"https://zxvnm4.ca/Classic Christmas Music with a Fireplace and Beautiful Background (Classics) (2 hours) (2017).mp3"
        
        if not hasPermission("bass.loadURL", URL) then
            
            hook.add("permissionrequest", "permission",function ()
                --ChangeSong(URL,Name)
            end)
        else
            --ChangeSong(URL,Name)
        end
    end
    local OnChangedSong
    local SongLocation=nil


    function GetMusicList()
        local MusicList={}
        local function MakeOnScrollPage(Page)
            local LastScrollValue=-SongList.Layouts[Page].Scroll.y
            local Ticks=0
            local NextTick=0
            local AveSpeed=Averager(20)
            local LastTime=timer.curtime()
            ScrollBar:OnEvent("MoveBar",LastScrollValue/(math.max((ScrollBar.Pages-1),0)*(SongList.Size.y-2)))
            ScrollBar.Hooks:CreateHook("BarMoved","ScrollBarAction2",function(Data)
                local ScrollValue=-(SongList.Size.y-2)*math.max((ScrollBar.Pages-1),0)*ScrollBar.Percentage
                local SPEED=math.abs(ScrollValue-LastScrollValue)
                
                local AveC=AveSpeed:NewValue(SPEED)
                DebugLines[1]="Scroll Bar Speed: "..tostring(math.round(AveC))
                if LastTime+0.2<=timer.curtime() then
                    AveSpeed:Reset()
                    NextTick=Ticks
                end
                if NextTick==Ticks then
                    ScrollObj(SongList,Page,vec2(0,ScrollValue))
                    if quotaTotalAverage()>=quotaMax()*0.85 then
                        NextTick=Ticks+16
                    elseif quotaTotalAverage()>=quotaMax()*0.80 then
                        NextTick=Ticks+8
                    elseif quotaTotalAverage()>=quotaMax()*0.75 then
                        NextTick=Ticks+4
                    else
                        if AveC>=80 then
                            NextTick=Ticks+3
                        elseif AveC>=40 then
                            NextTick=Ticks+2
                        else
                            NextTick=Ticks+1
                        end
                    end
                end
                Ticks=Ticks+1
                LastScrollValue=ScrollValue
                LastTime=timer.curtime()
            end)--Percentage
        end
        local function OnMusicListDone()
            local FolderLengths={}
            local function ScrollBarPage(N)--Run this after you change the layout.
                ScrollBar.Hooks:CreateHook("BarMoved","ScrollBarAction2",function(Data) end)
                local FoldersPerPage=((SongList.Size.y-2)/16)
                local Pages=math.max((FolderLengths[N])/FoldersPerPage,0)
                ScrollBar.Pages=Pages
                ScrollBar.PageHeight=FoldersPerPage
                ScrollBar.PerStep=1/(FoldersPerPage*Pages)
                MakeOnScrollPage(N+4)
                --SongList.Layouts[SongList.CurrentLayout].Scroll
            end
            local SongsCount=0
            local FolderCount=0
            
            local FontA=Font( "Arial", 12, 800, true, false, false, false, true, true )
            local FolderOrderArray={}
            SongList.Layouts[2].Hook:CreateHook("ChunkAdded","Cats",function(Data)
                local Loc,Size=Data[2],Data[3]
                local Dir=Data[4]
                local Start=math.min(math.max(((Loc.y-2)/40),0),FolderCount)
                local End=math.min(Start+Size.y/40,FolderCount)
                if Dir.y==0 then
                    End=math.ceil(End)
                    Start=math.floor(Start)
                end
                if Dir.y==1 then
                    Start=math.floor(Start)
                    End=math.floor(End)
                end
                if Dir.y==-1 then
                    Start=math.ceil(Start)
                    End=math.ceil(End)
                end
                local NewObjects={}
                for i=Start+1,End do
                    CheckQuota()
                    local i2,k2=unpack(FolderOrderArray[i])
                    local Other=Button(vec2(2,2+(i-1)*40),vec2(ScreenSize.x-8-(65-4-16)-2-4-2,38),Color(255*0.34,255*0.34,255*0.34),i2,20,3,vec2(0,0))
                    Other:AddRenderObj(RenderObjText(vec2(7,38-14),"Song Count: "..tostring(#k2),Color(255*0.6,255*0.6,255*0.6),vec2(0,0),FontA))
                    Other.ButtonID=i
                    Other.ButtonType=2
                    Other.Hooks:CreateHook("KeyPress","OtherKPress",function(Data)
                        SwitchLayout(SongList,4+Data[1].ButtonID)
                        ScrollBarPage(Data[1].ButtonID)
                    end)
                    --AddObj(Root,Other,2)
                    ButtonHooks(Other)
                    Other.Transparent=false
                    Other:AddTo(2,SongList)
                    NewObjects[Other.ID]=Other
                end
                return NewObjects
            end)
            local function BaseSongChunkLoad(Data,Args)--Look at me reducing lines of code!
                
                local Loc,Size=Data[2],Data[3]
                local Dir=Data[4]
                local Start=math.min(math.max(((Loc.y-2)/16),0),Args[1])
                local End=math.min(Start+Size.y/16,Args[1])
                if Dir.y==0 then
                    End=math.ceil(End)
                    Start=math.floor(Start)
                end
                if Dir.y==1 then
                    Start=math.floor(Start)
                    End=math.floor(End)
                end
                if Dir.y==-1 then
                    Start=math.ceil(Start)
                    End=math.ceil(End)
                end
                local NewObjects={}
                for i=Start+1,End do
                    CheckQuota()
                    local k=Args[2](i)
                    local Other=Button(vec2(2,2+(i-1)*16),vec2(ScreenSize.x-8-(65-4-16)-2-4-2,14),Color(255*0.34,255*0.34,255*0.34),k[1],12,1)
                    Other.ButtonID=i
                    Other.ButtonType=Args[3]
                    Other.Transparent=false
                    Other.Hooks:CreateHook("KeyPress","OtherKPress",function(Data)
                            SongLocation={function () 
                            local F=SongLocation[3]
                            if F(SongLocation[2]+1)==nil then
                                SongLocation[2]=1
                            else
                                SongLocation[2]=SongLocation[2]+1
                            end
                        end,Data[1].ButtonID,Args[2],Args[3]}
                        local k=Args[2](Data[1].ButtonID)
                        Hooks:OnEvent("PlayedSong",{k[2],k[1]})
                        ChangeSong(k[2],k[1])
                    end)
                    ButtonHooks(Other)
                    Other:AddTo(Args[3],SongList)
                    NewObjects[Other.ID]=Other
                end
                return NewObjects
            end
            local Bla3=MusicList["Songs"]
            
            local function CCAva(Data,MaxLen)
                local Layout,Loc,Size=Data[1],Data[2],Data[3]
                local Out=(Loc.x==0 and Loc.y>=0 and Loc.y<=MaxLen)
                return Out --Just checking to see if the X is zero could be a problem if I decide to change how Loc/Size works
            end
            --local ButtonStateStorage={}
            --function SetPressStateButton(Type,ID,Pressed)
            for i2,k2 in pairs(MusicList["Albums"]) do
                FolderOrderArray[FolderCount+1]={i2,k2}
                FolderLengths[FolderCount+1]=#k2
                local LayoutN=5+FolderCount
                SongList:AddLayout(LayoutN)
                
                SongList.Layouts[LayoutN].Hook:CreateHook("ChunkAdded","Cats",BaseSongChunkLoad,{#k2,function(i) return Bla3[k2[i]] end,LayoutN})
                SongList.Layouts[LayoutN].Hook:CreateHook("CheckChunkAvailability","Cats",CCAva,2+#k2*16)
                SongList.Layouts[LayoutN].Hook:CreateHook("LoadedObjOutofScreen","Cats",function(Obj) Obj:RemoveObj() end)
                for i,k in pairs(k2) do
                    SongsCount=SongsCount+1
                end
                FolderCount=FolderCount+1
            end
            SongList.Layouts[1].Hook:CreateHook("ChunkAdded","Cats",BaseSongChunkLoad,{SongsCount,function(i) return Bla3[i] end,1})
            SongList.Layouts[2].Hook:CreateHook("CheckChunkAvailability","Cats",CCAva,2+FolderCount*40)
            SongList.Layouts[1].Hook:CreateHook("CheckChunkAvailability","Cats",CCAva,2+SongsCount*16)
            SongList.Layouts[2].Hook:CreateHook("LoadedObjOutofScreen","Cats",function(Obj) Obj:RemoveObj() end)
            SongList.Layouts[1].Hook:CreateHook("LoadedObjOutofScreen","Cats",function(Obj) Obj:RemoveObj() end)
            --Percentage
            local function ScrollBarPage1(B)--Run this after you change the layout.
                ScrollBar.Hooks:CreateHook("BarMoved","ScrollBarAction2",function(Data) end)
                local SongsPerPage=((SongList.Size.y-2)/16)
                local Pages=math.max(SongsCount/SongsPerPage,0)
                ScrollBar.Pages=Pages
                ScrollBar.PageHeight=SongsPerPage
                ScrollBar.PerStep=1/(SongsPerPage*Pages)
                MakeOnScrollPage(1)
                --SongList.Layouts[SongList.CurrentLayout].Scroll
            end
            local function ScrollBarPage2()--Run this after you change the layout.
                ScrollBar.Hooks:CreateHook("BarMoved","ScrollBarAction2",function(Data) end)
                local FoldersPerPage=((SongList.Size.y-2)/40)
                local Pages=math.max(FolderCount/FoldersPerPage,0)
                ScrollBar.Pages=Pages
                ScrollBar.PageHeight=FoldersPerPage
                ScrollBar.PerStep=1/(FoldersPerPage*Pages)
                MakeOnScrollPage(2)
                --SongList.Layouts[SongList.CurrentLayout].Scroll
            end
            PlaylistsButton.Hooks:CreateHook("KeyPress","BackButtonKPress",function(Data) 
                if SongList.CurrentLayout==2 then return end
                if SongList.CurrentLayout==4 then SetHiddenObj(ScrollBar,false) end
                SwitchLayout(SongList,2)
                ScrollBarPage2()
            end)
            AllSongsButton.Hooks:CreateHook("KeyPress","BackButtonKPress",function(Data) 
                if SongList.CurrentLayout==1 then return end
                if SongList.CurrentLayout==4 then SetHiddenObj(ScrollBar,false) end
                SwitchLayout(SongList,1)
                ScrollBarPage1()
            end)
            ModifyButton.Hooks:CreateHook("KeyPress","BackButtonKPress",function(Data) 
                if SongList.CurrentLayout==4 then return end
                SetHiddenObj(ScrollBar,true)
                SwitchLayout(SongList,4)
            end)
            ScrollBarPage1(false)
            Hooks:CreateHook("SongEnded","MusicList",function(Data)
                if SongLocation~=nil then
                    SongLocation[1]()
                    local k = SongLocation[3](SongLocation[2])
                    SetPressStateRadioButton(SongLocation[4],SongLocation[2],1)
                    Hooks:OnEvent("PlayedSong",{k[2],k[1]})
                    ChangeSong(k[2],k[1])
                end
            end)
            AddToChangeList(Root,2,true,"Refresh",Root.getRenderBound,Root.Refresh,{})
            LoadedList()
        end
        local function SuccessGetMusicList(Body,Length,Headers,Code)
            if math.floor(Code/100)==2 then
                local CurrentFolder="Default"
                MusicList["Albums"]={}
                MusicList["Songs"]={}
                local Songs=MusicList["Songs"]
                local Albums=MusicList["Albums"]
                local Arr=Albums[CurrentFolder]
                local CurrentLocation=1
                while true do
                    local EOL=string.find(Body,"\n",CurrentLocation)
                    if EOL==nil then break end
                    local Line=string.sub(Body,CurrentLocation,EOL-1)
                    if Line:sub(1,4)=="@#$@" then
                        CurrentFolder=Line:sub(5)
                        Arr=Albums[CurrentFolder]
                    else
                        local Seperator=string.find(Line,"\"\"")
                        if Seperator==nil then print("Somethin is funky with the phrasing.") break end
                        local Name=Line:sub(1,Seperator-1)
                        local URLL=Line:sub(Seperator+2)
                        if Arr==nil then
                            Albums[CurrentFolder]={}
                            Arr=Albums[CurrentFolder]
                        end
                        local SongInd=#Songs+1
                        Arr[#Arr+1]=SongInd
                        Songs[SongInd]={Name,URLL}
                    end
                    CurrentLocation=EOL+1
                end
                timer.create("GetMusicListDoneTimer",1/10,1,OnMusicListDone)--Don't question it ok

            else
                print("The request failed with responce "..tostring(Code))
                FailedToLoadList()
            end
        end
        local function FailGetMusicList(FailReason)
            print(FailReason)
            FailedToLoadList()
        end
        
        if not hasPermission("http.get", "https://zxvnm4.ca/SongList.txt") then
            hook.add("permissionrequest", "permission2",function ()
                http.get( "https://zxvnm4.ca/SongList.txt", SuccessGetMusicList, FailGetMusicList, {} )
            end)
        else
            http.get( "https://zxvnm4.ca/SongList.txt", SuccessGetMusicList, FailGetMusicList, {} )
        end
    end
    function StartNetworking()
        Hooks:CreateHook("PlayedSong","Networking",function(Data)
            net.start("ThisScript")
            net.writeString("PlayedSong")
            net.writeString(Data[1])
            net.writeString(Data[2])
            net.send()
        end)
        hook.add("net","ThisScript",function( name, len, ply ) 
            Type=net.readString()
            if Type=="PlaySong" then
                local Player,URL,Name = net.readType(),net.readString(),net.readString()
                if player()~=Player then
                    ChangeSong(URL,Name)
                    SongLocation=nil
                end
            end
        end)
    end
    function ScreenStartDrawing()
        if not hasPermission("bass.loadURL", URL) or not hasPermission("http.get", URL) then
            setupPermissionRequest({"bass.loadURL","http.get"}, "URL sounds from external sites", true)
        end
        Root=Object(nil)
        Root:AddRenderObj(RenderObjRect(vec2(0,0),vec2(ScreenSize.x,ScreenSize.y),Color(255*0.3,255*0.3,255*0.3),false))
        Root:SetSize(vec2(ScreenSize.x,ScreenSize.y))
        Page1()
        Page2()
        Page3()
        Page4()
        
        
        StartMusic()
        GetMusicList()
        StartNetworking()
        Root:SwitchLayout(4)
        StartDrawingRoot()
        
        
    end
    InitScreen()
    timer.create( "CatsScreenStartDrawing", 1/10, 1, ScreenStartDrawing) 
else
    --qhook.add("net","ThisScript",function( name, len, ply ) 
    --    Type=net.readString()
    --    if Type=="PlayedSong" then
    --        local URL,Name = net.readString(),net.readString()
    --        net.start("ThisScript")
    --        net.writeString("PlaySong")
    --        net.writeType(ply)
    --        net.writeString(URL)
    --        net.writeString(Name)
    --        net.send()
    --    end
    --end)
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
    end
    timer.create("ScreenPositionSending",1,0,function()
        net.start("GetScreenPos")
        net.writeString("GetScreenPos")
        net.writeVector(WeldedTo:getPos())
        net.send()
    end)
end