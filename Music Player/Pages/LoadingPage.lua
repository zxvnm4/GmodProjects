--@name
--@author Zxvnm4
--@shared
--@model models/spacecode/sfchip_medium.mdl
--@include ../Base.lua
require("../Base.lua")
LoadingPage = ZClass(function(self,MusicPlayer)
    self.Root=MusicPlayer.Root
    self.LayoutN=self.Root:AddLayout()
    self.MusicPlayer=MusicPlayer
    self.Screen=MusicPlayer.Screen
end,{
    SwitchTo = function(self)
        SwitchLayout(self.Root,self.LayoutN) 
    end
    ,LoadPage = function(self)
        local Icon=Object(self.Screen)
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
            DialogBox=Object(self.Screen)
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
            DialogBox:AddTo(self.Root,self.LayoutN)

        else
            StatusText="Loading..."
        end
        Icon:SetSize(vec2(Size,Size))
        Icon:RelPos(vec2(ScreenSize.x/2-Size/2,ScreenSize.y/2-Size/2))
        Icon:AddRenderObj(RenderObjCircle(vec2(Size/2),vec2(Size/2),Color(100,100,230),false))
        MusicIcon(Icon,vec2(Size,Size),vec2(Size/2),0,Color(255,255,255))
        --PlaylistIcon(Icon,vec2(Size,Size),vec2(Size/2),0,Color(255,255,255))
        Icon:AddTo(self.Root,self.LayoutN)
        
        local Name=Object(self.Screen)
        Name.Font=Font( "Arial", 55, 200, true, false, false, false, true, true )
        CheckQuota()
        local Size2=Name.Font:getTextSize(StatusText)
        Name:AddRenderObj(RenderObjText(vec2(Size/2,Size2.y/2),"Music Player",Color(255*0.8,255*0.8,255*0.8),vec2(1,1),Name.Font))
        Name.Transparent=true
        Name:SetSize(vec2(Size,Size2.y))
        Name:RelPos(vec2(ScreenSize.x/2-Size/2,ScreenSize.y/2-Size/2-Size2.y))
        Name:AddTo(self.Root,self.LayoutN)
        local Info=Object(self.Screen)
        Info.Font=Font( "Arial", 40, 200, true, false, false, false, true, true )
        
        local Size2=Info.Font:getTextSize(StatusText)
        Info:AddRenderObj(RenderObjText(vec2(Size/2,Size2.y/2),StatusText,Color(255*0.8,255*0.8,255*0.8),vec2(1,1),Info.Font))
        Info.Transparent=true
        Info:SetSize(vec2(Size,Size2.y))
        Info:RelPos(vec2(ScreenSize.x/2-Size/2,ScreenSize.y/2+Size/2))
        Info:AddTo(self.Root,self.LayoutN)
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
                    self.MusicPlayer.SongListPage:SwitchTo()
                end)
            end
            ListLoaded=true
        end
        
        FailedToLoadList=function()
            ChangedRenderObj(Info,1,RenderObjText(vec2(Size/2,Size2.y/2),"Error: Cannot Load List",Color(255*0.8,255*0.8,255*0.8),vec2(1,1),Info.Font))
            ListLoaded=true
        end
    end
})