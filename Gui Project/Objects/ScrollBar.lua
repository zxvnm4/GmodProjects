--@includedir ../../Libs
--@includedir ../Whole
requiredir("../../Libs",{"BaseLib.lua"})
requiredir("../Whole")
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
    ScrollBarB.Pages=1
    ScrollBarB.PagesO=1
    ScrollBarB.PerStep=0
    ScrollBarB.Percentage=0
    ScrollBarB.PercentageMax=0
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
    ScrollBarDown:RelPos(vec2(2,2+ScrollBarB.Length-Width))
    ScrollBarDown.Clickable=true
    ScrollBarDown:AddRenderObj(RenderObjRect(vec2(0),vec2(Width),Color(255*0.225,255*0.225,255*0.225),false))
    IsoArrow(ScrollBarDown,vec2(Width/3),vec2(Width)/2-vec2(0,3),90,Color(255*0.9,255*0.9,255*0.9),0)
    ScrollBarDown:AddTo(1,ScrollBarB)
    ButtonHooks(ScrollBarDown)
    RoundedClickable(ScrollBarDown)
    local ScrollBar=Object(nil)
    ScrollBar.Length=ScrollBarB.Length-Width*2
    ScrollBar:SetSize(vec2(Width,ScrollBar.Length))
    ScrollBar:RelPos(vec2(2,2+Width))
    ScrollBar.Clickable=true
    ScrollBar:AddRenderObj(RenderObjRect(vec2(0),vec2(Width,ScrollBar.Length),Color(255*0.25,255*0.25,255*0.25),false))
    ScrollBar:AddRenderObj(RenderObjRect(vec2(0),vec2(Width,ScrollBar.Length),Color(255*0.35,255*0.35,255*0.35),false))
    ScrollBar:AddTo(1,ScrollBarB)
    local LastScrollLoc=0
    local MoveBarFunc=function(Data)
        local Bottom=0
        local NH=ScrollBar.Length
        if ScrollBarB.Pages~=0 then
            NH=math.min(math.max(10,ScrollBar.Length/ScrollBarB.Pages),ScrollBar.Length)
            Bottom=math.max(ScrollBar.Length-NH,0)
        end

        if math.round(LastScrollLoc)~=math.round(Bottom*Data[2]) or ScrollBarB.PagesO~=ScrollBarB.Pages then
            ChangedRenderObj(ScrollBar,2,RenderObjRect(vec2(0,Bottom*Data[2]),vec2(Width,NH),Color(255*0.35,255*0.35,255*0.35),false))
        end
        if LastScrollLoc~=Bottom*Data[2] or ScrollBarB.PagesO~=ScrollBarB.Pages then
            ScrollBarB.Percentage=Data[2]
            ScrollBarB:OnEvent("BarMoved")
            ScrollBarB.PagesO=ScrollBarB.Pages
        end
        LastScrollLoc=Bottom*Data[2]
    end
    ScrollBarB.Hooks:CreateHook("MoveBar","ScrollBarAction2",MoveBarFunc)
    ScrollBar.Hooks:CreateHook("MoveBar","ScrollBarAction",MoveBarFunc)
    ScrollBar.Clicking=false
    ScrollBar.ScrollOffset=0
    ScrollBar.Hooks:CreateHook("KeyPress","ScrollBarAction",function(Data)
        local NH=math.min(math.max(10,ScrollBar.Length/ScrollBarB.Pages),ScrollBar.Length)
        local Bottom=vec2(0,math.max(ScrollBar.Length-NH,0)*ScrollBarB.Percentage)+Data[1]:GetPosition()
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
        local NH=math.min(math.max(10,ScrollBar.Length/ScrollBarB.Pages),ScrollBar.Length)
        local Bottom=math.max(Data[1].Length-NH,0.0001)
        local Pos=Data[1]:GetPosition()
        local Per=0
        if ScrollBarB.Pages>0 then
            Per=math.min(math.max((-ScrollBar.ScrollOffset+AimPos.y-Pos.y-NH/2),0),Bottom)/Bottom
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