--@name
--@author Zxvnm4
--@shared
--@model models/spacecode/sfchip_medium.mdl
--@include Base.lua
require("Base.lua")

if CLIENT then
    InitScreen()
    Root=Object(nil)
    Root:AddRenderObj(RenderObjRect(vec2(0,0),vec2(ScreenSize.x,ScreenSize.y),Color(255*0.3,255*0.3,255*0.3),false))
    Root:SetSize(vec2(ScreenSize.x,ScreenSize.y))

    Play=Object(nil)
    Play:SetSize(vec2(120,120))
    Play:RelPos(vec2(ScreenSize.x/2-120/2,ScreenSize.y/2-120/2))
    Play.Clickable=true
    Play:AddRenderObj(RenderObjCircle(vec2(60),vec2(60),Color(255*0.34,255*0.34,255*0.34),false))
    Play:AddRenderObj(RenderObjCircle(vec2(60),vec2(58),Color(255*0.4,255*0.4,255*0.4),false))
    Play:AddRenderObj(RenderObjCircle(vec2(60),vec2(56),Color(255*0.35,255*0.35,255*0.35),false))
    Play:AddRenderObj(RenderObjCircle(vec2(60),vec2(54),Color(255*0.32,255*0.32,255*0.32),false))
    Play:AddRenderObj(RRect)
    Play:AddTo(1,Root)
    ButtonHooks(Play)
    RoundedClickable(Play)


    Cat=Button(vec2(ScreenSize.x/2-100,ScreenSize.y*3/4-10),vec2(200,20),Color(150,150,150),"CatsAndStuff",15,-1,vec2(0,0))
    Cat:AddTo(1,Root)
    ButtonHooks(Cat)
    RoundedClickable(Cat)
    StartDrawingRoot()
else

end