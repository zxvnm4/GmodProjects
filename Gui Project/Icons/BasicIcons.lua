--@includedir ../../Libs
--@includedir ../Whole
requiredir("../../Libs",{"BaseLib.lua"})
requiredir("../Whole")
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
local PolyArc={}
function GenPolyArc()
    
    local MaxAngle=0.4*math.pi/2
    local Center=vec2(0,0)
    local V=7
    for i=0,V do

        local A=(MaxAngle*2*i)/(V+1)-MaxAngle
        local X=math.cos(A)
        local Y=math.sin(A)
        PolyArc[i]={x=X+Center.x,y=Y+Center.y,u=X+Center.x,v=Y+Center.y}
    end
    PolyArc[V+1]={x=Center.x,y=Center.y,u=Center.x,v=Center.y}
end
GenPolyArc()
function SoundIcon(Obj,Scale,Loc,C,B)
    local S=(vec2(Scale.x,Scale.y)/2)/1.2
    local T=0.15
    local R=0
    local StartV = #(Obj.RenderObjs)
    print(StartV)
    for b,v in pairs({1,0.75,0.5}) do
        Obj:AddRenderObj(RenderObjPoly(Loc+S*vec2(-0.6,0),S*(v*1.5+0.35),PolyArc,C))
        Obj:AddRenderObj(RenderObjPoly(Loc+S*vec2(-0.6,0),S*(v*1.5+0.35)-S*vec2(T,T),PolyArc,B))
    end

    local Rect=RenderObjRect(Loc+S*vec2(-1.1,-0.5),S*vec2(T,1),C,false)
    Rect:setRadius(R)
    Obj:AddRenderObj(Rect)

    local Rect3=RenderObjRect(Loc+S*vec2(-1.1,-0.5),S*vec2(0.6,T),C,false)
    Rect3:setRadius(R)
    Obj:AddRenderObj(Rect3)

    local Rect5=RenderObjRect(Loc+S*vec2(-1.1,0.5-T)+vec2(0,1),S*vec2(0.6,T),C,false)
    Rect5:setRadius(R)
    Obj:AddRenderObj(Rect5)

    local Len=math.sqrt(2)*0.5
    local Rect2=RenderObjRect(Loc+S*vec2(-1.1+0.6+(Len-T)*0.5*(math.sqrt(2)/2),-(0.5-T)-(Len+T)*0.5*(math.sqrt(2)/2)),S*vec2(0.15,Len),C,false)
    Rect2:setRadius(R)
    Rect2:setRotation(45)
    Rect2:setAlignment(0)
    Obj:AddRenderObj(Rect2)

    local Rect4=RenderObjRect(Loc+S*vec2(-1.1+0.6+(Len-T)*0.5*(math.sqrt(2)/2),(0.5-T)+(Len+T)*0.5*(math.sqrt(2)/2)),S*vec2(0.15,Len),C,false)
    Rect4:setRadius(R)
    Rect4:setRotation(-45)
    Rect4:setAlignment(0)
    Obj:AddRenderObj(Rect4)

    local Rect6=RenderObjRect(Loc+S*vec2(-1.1+0.6+0.5-T*(math.sqrt(2)/2),-1+T/4)+vec2(0,1),S*vec2(T*0.6,2-T/2)-vec2(0,2),C,false)
    Rect6:setRadius(R)
    Rect6:setRoundedEdges(false,true,false,true)
    Obj:AddRenderObj(Rect6)

    local Rect7=RenderObjRect(Loc+S*vec2(-1.1+0.6+0.5-T*(math.sqrt(2)/2)-T*0.4,-1+T*0.8)+vec2(1,0),S*vec2(T*0.4,2-T*1.6),C,false)
    Rect7:setRadius(R)
    Rect7:setRoundedEdges(true,false,true,false)

    Obj:AddRenderObj(Rect7)

    


    ModifyVolumeFunc=function(Volume)
        local State = 0
        if Volume == 0 then
            State = 0
        elseif Volume < 0.333 then
            State = 1
        elseif Volume < 0.666 then
            State = 2
        else
            State = 3
        end
        local Col=C
        for b,v in pairs({1,0.75,0.5}) do
            if 4-b > State then Col = Color(50,50,50) else Col = C end
            UpdateRenderObj(Obj,StartV+b*2-1,RenderObjPoly(Loc+S*vec2(-0.6,0),S*(v*1.5+0.35),PolyArc,Col))
            UpdateRenderObj(Obj,StartV+b*2,RenderObjPoly(Loc+S*vec2(-0.6,0),S*(v*1.5+0.35)-S*vec2(T,T),PolyArc,B))
        end
    end
    return ModifyVolumeFunc
end
function SearchIcon(Obj,Scale,Loc,C,B)
    local S=vec2(Scale.y,Scale.y)/2.25
    local T=0.17
    local R=0
    local Rect=RenderObjRect(Loc,S*vec2(T,1*math.sqrt(2)),C,false)
    Rect:setRadius(R)
    Rect:setAlignment(0)
    Rect:setRotation(45)
    Obj:AddRenderObj(Rect)
    Obj:AddRenderObj(RenderObjCircle(Loc+S*vec2(0.5,-0.5),S*vec2(0.5),C,false))
    Obj:AddRenderObj(RenderObjCircle(Loc+S*vec2(0.5,-0.5),S*vec2(0.5-T*0.6),B,false))
end
function MusicVisualizerIcon(Obj,Scale,Loc,C,B)
    local S=vec2(Scale.y,Scale.y)/2.25
    local T=0.17
    local R=0
    --local Rect=RenderObjRect(Loc,S*vec2(T,1*math.sqrt(2)),C,false)
    --Rect:setRadius(R)
    --Rect:setAlignment(0)
    --Rect:setRotation(45)
    Obj:AddRenderObj(Rect)
    local T = 5
    local B = 0.5
    local RB = math.ceil(S.y*(B))
    local Wid = math.ceil(S.x*(2/T))
    local Start = math.floor(S.x*(-1))
    local LXPos=Start
    for i,k in pairs({0.35,0.53,0.45,0.53,0.35}) do
        local CM=0.80+(k+0.35)*0.2
        local Height=math.ceil(S.y*k*2.5)
        local XTo = math.ceil(S.x*(-1+((i)*2)/T))
        Obj:AddRenderObj(RenderObjRect(Loc+vec2(LXPos,RB-Height),vec2(XTo-LXPos,Height),Color(C.r*CM,C.g*CM,C.b*CM),false))
        LXPos=XTo
    end
    Obj:AddRenderObj(RenderObjRect(Loc+S*vec2(-0.9,B+0.23),S*vec2(0.6,0.1),C,false))
    Obj:AddRenderObj(RenderObjRect(Loc+S*vec2(0.3,B+0.23),S*vec2(0.6,0.1),C,false))

    Obj:AddRenderObj(RenderObjCircle(Loc+S*vec2(0,B+0.28),S*vec2(0.17),C,false))

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
function RotVec2(Vect,Rot)
    return vec2(Vect.x*math.cos(Rot)-Vect.y*math.sin(Rot),Vect.x*math.sin(Rot)+Vect.y*math.cos(Rot))
end
function NoteIcon(Obj,S,O)
    local Circle=RenderObjCircle(O+S*vec2(0,0.55),S*vec2(0.45,0.27),Color(255*0.9,255*0.9,255*0.9))
    Circle:setRotation(-20)
    Obj:AddRenderObj(Circle)
    local Cats=RenderObjRect(O+S*vec2(0.3925,-0.37-0.2),S*vec2(0.15,2.2),Color(255*0.9,255*0.9,255*0.9),false) Cats:setAlignment(0)
    Obj:AddRenderObj(Cats)
end