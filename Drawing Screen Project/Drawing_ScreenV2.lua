--@name
--@author
--@shared

--Huh, another stupidly overcomplex way to make code reuseable

--DataL={Header-1,DataAr-1,DataAr-0,Bottom-1}
--Obj={Req,GetSize(MaxLen),Send(),...}
--NetMsg={[Obj],DelObj,PairsR,PairsNR,PairsT,RegSent,MinSize}

function GetSize(self,MaxLen)
    local Totlen=2
    self.TotalSent=0
    for i,k in unpack(self.PairsR) do
        if k.Req then 
            local S = k:GetSize(MaxLen-Totlen)
            if S==false then return false end
            if Totlen+S>MaxLen then
                return false
            end
            Totlen=Totlen + S
        end
    end
    for i,k in unpack(self.PairsNR) do
        if not k.Req then
            local S = k:GetSize(MaxLen-Totlen)
            if S~=false then 
                if Totlen+S<=MaxLen then
                    Totlen=Totlen + S
                    self.TotalSent=self.TotalSent+1
                end
                if Totlen==MaxLen or Totlen+self.MinSize>MaxLen then
                    break
                end
            end
        end
    end
    return Totlen
end
function Send(self)
    net.writeInt(self.TotalSent,16)
    local Count=self.TotalSent
    local R=nil
    local CR=0
    for i,k in unpack(self.PairsT) do
        if k.Req then
            CR=CR+1
            R=CR
            k:Send()
        else
            local B=k:Send()
            Count=Count-1
            if B then
                self.DelObj(self.TotalSent-Count)
            end
            if Count==0 then break end
        end
    end
    while true do
        local CR
        R,CR=self.PairsR[1](self.PairsR[2],R) 
        if R==nil then break end
        CR:Send()
    end
end
--Obj={Req,Recieve}
--RecieveObj={[Obj],PairsR,PairsNR,PairsT}
function Recieve(self)
    local Out={}
    local TotalNR = net.readInt(16)
    local Count=TotalNR
    local R=nil
    local CR=0
    local Cur=0
    for i,k in unpack(self.PairsT) do
        Cur=Cur+1
        if k.Req then
            CR=CR+1
            R=CR
            Out[Cur]=k:Recieve()
        else
            Out[Cur]=k:Recieve()
            Count=Count-1
            if Count==0 then break end
        end
    end
    while true do
        Cur=Cur+1
        local CR
        R,CR=self.PairsR[1](self.PairsR[2],R) 
        if R==nil then break end
        Out[Cur]=CR:Recieve()
    end
end
local DataPacketStruct = {type=1,x=2,y=3,x1=4,y1=5,wid=6,col=7}
local DataPacketStructConst = {size=10}
function DataPacketLookup(metatable,key)
    if DataPacketStruct[key] ~= nil then
        return metatable[DataPacketStruct[key]]
    else
        return DataPacketStructConst[key]
    end
end
function DataPacket(Type,X,Y,X1,Y1,NX,NY,NX1,NY1,Width,Color)
    local T=setmetatable({},{__index = DataPacketLookup})
    T.type=Type
    T.x=X
    T.y=Y
    T.x1=X1
    T.y1=Y1
    T.nx=NX
    T.ny=NY
    T.nx1=NX1
    T.ny1=NY1
    T.width=Width
    T.color=Color
    return T
end
function ReadDataPacket()
    local Type=net.readUInt(8)
    
    local X=net.readFloat()
    local Y=net.readFloat()
    local X1=net.readFloat()
    local Y1=net.readFloat()
    
    
    local Width=net.readUInt(8)
    local Color=Color(net.readUInt(8),net.readUInt(8),net.readUInt(8),255)
    return DataPacket(Type,X,Y,X1,Y1,NX,NY,NX1,NY1,Width,Color)
end
function WriteDataPacket(k)
    net.writeUInt(k.type,8) --Type
    
    net.writeFloat(k.x)  --X
    net.writeFloat(k.y)  --Y
    net.writeFloat(k.x1)  --X1
    net.writeFloat(k.y1)  --Y1

    
    net.writeUInt(k.width,8)  --Width
    net.writeUInt(k.color.r,8)  --Color.r
    net.writeUInt(k.color.g,8)  --Color.g
    net.writeUInt(k.color.b,8)  --Color.b 
end
function DrawLine(X,Y,LX,LY,Width)
    local M={LX-X,LY-Y}
    local D=math.sqrt(M[1]^2+M[2]^2)
    local N={-M[2]/D,M[1]/D}
                    
    local W=Width
    render.drawRoundedBox( W, X-W, Y-W, W*2, W*2 )
    render.drawLine(X,Y,LX,LY)
    local H=0
                    
    if X==LX and Y==LY then
                    
    else
        if math.abs(N[1])<=math.abs(N[2]) then
            NX=math.abs(N[1]/N[2])
            if (N[1]<0 and N[2]>0) or (N[1]>0 and N[2]<0) then
                NY=-1
            else
                NY=1
            end
            local LOffX,LOffY=0,0
            for i=1,math.ceil(math.abs(N[2]*W)) do
                local OffX,OffY=math.round(NX*i),math.round(NY*i)
                render.drawLine(X+OffX,Y+OffY,LX+OffX,LY+OffY)
                render.drawLine(X-OffX,Y-OffY,LX-OffX,LY-OffY)
                if LOffX~=OffX then
                    render.drawLine(X+LOffX,Y+LOffY+NY,LX+LOffX,LY+LOffY+NY)
                    render.drawLine(X-LOffX,Y-LOffY-NY,LX-LOffX,LY-LOffY-NY)
                end
                LOffX,LOffY=OffX,OffY
            end
        else
            if (N[1]<0 and N[2]>0) or (N[1]>0 and N[2]<0) then
                NX=-1
            else
                NX=1
            end
            NY=math.abs(N[2]/N[1])
            local LOffX,LOffY=0,0
            for i=1,math.ceil(math.abs(N[1]*W)) do
                local OffX,OffY=math.round(NX*i),math.round(NY*i)
                render.drawLine(X+OffX,Y+OffY,LX+OffX,LY+OffY)
                render.drawLine(X-OffX,Y-OffY,LX-OffX,LY-OffY)
                if LOffY~=OffY then
                    render.drawLine(X+LOffX+NX,Y+LOffY,LX+LOffX+NX,LY+LOffY)
                    render.drawLine(X-LOffX-NX,Y-LOffY,LX-LOffX-NX,LY-LOffY)
                end
                LOffX,LOffY=OffX,OffY
            end
        end
    end
end
if CLIENT then
    local W,H=512,512
    render.createRenderTarget("Target")
    local AimPos
    local LX,LY=0,0
    local LNX,LNY=0,0
    local Queue={}
    local QueueOut={}
    local LastL={}
    local DrawColor=Color(255,255,255,255)
    local DrawThickness=2
    local Font=render.createFont( "Arial", 20, 5000, true, false, false, false, true, true )
    hook.add("render","Cats",function()
        render.selectRenderTarget("Target")
        render.setColor(Color(255,255,255,255))
        local X,Y = render.cursorPos()
        if quotaAverage()<=(quotaMax()*0.5) then
            
            if X then
                if input.isKeyDown(input.lookupBinding( "use" )) and (player():getSteamID()!="STEAM_0:1:42942061") then
                    local OnSomethin=false
                    if X>=5 and X<=30 and Y>=5 and Y<=90 then
                        if Y<=30 then
                            OnSomethin=true
                            DrawColor=Color(0,0,0,255)
                            DrawThickness=4
                        end
                        if Y>=35 and Y<=60 then
                            OnSomethin=true
                            render.setColor(Color(0,0,0,255))
                            render.drawRect(0,0,512*2,512*2)
                            QueueOut[#QueueOut+1]=DataPacket(1,0,0,0,0,0,0,0,0,0,Color())
                            
                        end
                        if Y>=65 then
                            OnSomethin=true 
                            DrawColor=Color(255,255,255,255)
                            DrawThickness=2
                        end
                    end
                    if not OnSomethin then
                        if LX then
                            if LX~=X or LY~=Y then
                                render.setColor(DrawColor)
                                DrawLine(X,Y,LX,LY,DrawThickness)
                                QueueOut[#QueueOut+1]=DataPacket(0,X,Y,LX,LY,0,0,0,0,DrawThickness,DrawColor)
                                --LNX,LNY=N[1],N[2]
                            end
                        end
                    end
                    
                end
            end
            for i,k in pairs(Queue) do
                if k.type==0 then
                    render.setColor(k.color)
                    DrawLine(k.x,k.y,k.x1,k.y1,k.width)
                else
                    render.setColor(Color(0,0,0,255))
                    render.drawRect(0,0,512*2,512*2)
                end
            end
            Queue={}
        end
        
        LX=X
        LY=Y
        
        render.selectRenderTarget()
        render.setColor(Color(255,255,255,255))
        render.setRenderTargetTexture("Target")
        render.drawTexturedRect(0,0,512*2,512*2)
        render.setRenderTargetTexture()
        render.setColor(Color(200,200,200,255))
        render.drawRect(5,5,25,25)
        render.setFont(Font)
        render.setColor(Color(10,10,10,255))
        render.drawSimpleText( 17.5 , 17.5, "E" ,1, 1 )
        
        render.setColor(Color(200,200,200,255))
        render.drawRect(5,35,25,25)
        render.setColor(Color(10,10,10,255))
        render.drawSimpleText( 17.5 , 17.5 + 30, "C" ,1, 1 )
        
        render.setColor(Color(200,200,200,255))
        render.drawRect(5,65,25,25)
        render.setColor(Color(10,10,10,255))
        render.drawSimpleText( 17.5 , 17.5 + 60, "D" ,1, 1 )
    end)
    local ByteLimiter=10000
    timer.create( "Ticky", 0.025, 0, function()
        if quotaAverage()>=(quotaMax()*0.7) then return end
        local BL=ByteLimiter
        if #QueueOut~=0 and BL>=20+16*20 then
            local B=net.getBytesLeft()
            net.start("ThisScript")
            local C=math.min(math.floor((BL-21)/21),#QueueOut)
            net.writeUInt(C,16)
            local Tot=#QueueOut
            for i=(Tot-C)+1,Tot do
                local k=QueueOut[i]
                WriteDataPacket(k)
                QueueOut[i]=nil
            end
            net.send()
            if Tot==C then
                QueueOut={}
            end
            ByteLimiter=math.max(ByteLimiter-(B-net.getBytesLeft()),0)
        end
                
        ByteLimiter=math.min(10000,ByteLimiter+0.025*10000)
    end)
    hook.add("net","ThisScript",function( name, len, ply ) 
        if quotaAverage()>=(quotaMax()*0.8) then return end
        local P=net.readUInt(16)
        for i=1,P do
            local TypeA=net.readUInt(32)
            local N=net.readUInt(16)
            if TypeA~=player():entIndex() then 
                for i=1,N do
                    
                    Queue[#Queue+1]=ReadDataPacket()
                end
            end
        end
    end)
    net.start("StartedScript")
    net.send()
else
    if chip():isWeldedTo() then
        local WeldedTo=chip():isWeldedTo()
        if WeldedTo:getClass()=="starfall_screen" then
            local Doit=true
            if Doit then
                WeldedTo:linkComponent(chip())
            end
        end
    end
    local T={}
    local PacketSize=21
    local NChanges={}
    local TotalChanges={}
    hook.add("net","StartedScript",function( name, len, ply )
        if name=="StartedScript" then
            if #TotalChanges==0 then
                return
            end
            local B=ply:entIndex()
            NChanges[B]=true
        elseif name=="ThisScript" then
            local B=ply:entIndex()
            if not T[B] then
                T[B]={{},B}
            end
            local N=net.readUInt(16)
            for i=1,N do
                
                T[B][1][(#T[B][1])+1]=ReadDataPacket()
                TotalChanges[#TotalChanges+1]=T[B][1][#T[B][1]]
            end
        end
    end)
    local ByteLimitMax=10000
    local ByteLimiter=ByteLimitMax
    function cats()
        local BL=ByteLimiter
        if next(T)~=nil and BL>=21+2+9+2+4+4 then
            local B=net.getBytesLeft()
            
            local MaxInd1=0
            local BytesUsed=21+2-3
            local MaxInd2=0
            for i,k in pairs(T) do
                BytesUsed=BytesUsed+11 + PacketSize
                if BytesUsed>BL then break end
                MaxInd1=MaxInd1+1
                local Added=(#k[1]*4)-PacketSize
                
                if BytesUsed+Added>BL then 
                    MaxInd2 = math.min(math.floor((BL-BytesUsed)/PacketSize)+4,#k[1])
                    BytesUsed = BytesUsed + MaxInd2*PacketSize - PacketSize
                    break 
                else
                    BytesUsed=BytesUsed+Added
                end
                MaxInd2=#k[1]
            end
            if MaxInd1~=0 then
                net.start("ThisScript")
                net.writeUInt(MaxInd1,16)
                for i,k in pairs(T) do 
                    MaxInd1=MaxInd1-1
                    local Til=#k[1]
                    local Tot=Til
                    local NoFin=false
                    if MaxInd1==0 then
                        if Til~=MaxInd2 then NoFin=true end
                        Til=MaxInd2
                    end
                    net.writeUInt(k[2],32)
                    net.writeUInt(Til,16)
                    local BA=0
                    for i2=Tot-Til+1,Tot do
                        WriteDataPacket(k[1][i2])
                        k[1][i2]=nil
                        BA=BA+1
                    end
                    
                    if not NoFin then T[i]=nil end
                    if MaxInd1==0 then
                        break
                    end
                end
                net.send()
                --print(MaxInd2,MaxInd1,(B-net.getBytesLeft()),BytesUsed,ByteLimiter)
                --print(B-net.getBytesLeft(),BytesUsed)
                ByteLimiter=math.max(ByteLimiter-(B-net.getBytesLeft()),0)
            end
        end
        ByteLimiter=math.min(ByteLimitMax,ByteLimiter+0.025*ByteLimitMax)
    end
    timer.create("ServerTick",0.05,0,cats)
end