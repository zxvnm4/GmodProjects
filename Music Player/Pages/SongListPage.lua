--@name
--@author Zxvnm4
--@shared
--@model models/spacecode/sfchip_medium.mdl
--@include ../Base.lua
require("../Base.lua")
SongListPage = ZClass(function(self,MusicPlayer)
    self.Root=MusicPlayer.Main
    self.LayoutN=self.Root:AddLayout()
    self.MusicPlayer=MusicPlayer
    self.Screen=MusicPlayer.Screen
end,{
    SwitchTo = function(self)
        SwitchLayout(self.Root,self.LayoutN)
    end
    ,LoadPage = function(self,L)
        local ScreenSize=self.Screen.ScreenSize
        TopBar2=Object(self.Screen)
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
        TopBar2:AddTo(self.LayoutN,self.Root)
        CheckQuota()
        --DefaultB Channel
        
        
        AllSongsButton=Object(self.Screen)
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
        
        PlaylistsButton=Object(self.Screen)
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
        
        RadioButton=Object(self.Screen)
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
            --SwitchLayout(self.Root,1)
        end)
        RadioButton:AddTo(1,TopBar2)

        CheckQuota()
        ModifyButton=Object(self.Screen)
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
        SearchIcon(ModifyButton,vec2(Size.y*1.2-6),Size/2+vec2(-6,5),Color(255*0.8,255*0.8,255*0.8),Color(255*0.31,255*0.31,255*0.31))
        ModifyButton.Channel=2
        ButtonHooks(ModifyButton)
        RoundedClickable(ModifyButton)

        ModifyButton:AddTo(1,TopBar2)
        
        BackButton2=Object(self.Screen)
        BackButton2.Clickable=true
        BackButton2:SetSize(vec2(50,50))
        BackButton2:RelPos(vec2(ScreenSize.x-60,10))
        BackButton2:AddRenderObj(RenderObjCircle(vec2(25),25,Color(255*0.25,255*0.25,255*0.25),false))
        --ArrowIcon(BackButton2,40,vec2(25),180)
        MusicVisualizerIcon(BackButton2,vec2(40),vec2(25),Color(255*0.8,255*0.8,255*0.8),Color(255*0.25,255*0.25,255*0.25))
        ButtonHooks(BackButton2)
        RoundedClickable(BackButton2)
        BackButton2.Hooks:CreateHook("KeyPress","BackButtonKPress",function(Data) 
            self.MusicPlayer.AudioVisualizerPage:SwitchTo()
        end)
        BackButton2:AddTo(1,TopBar2)
        
        SettingsButton2=Object(self.Screen)
        SettingsButton2.Clickable=true
        SettingsButton2:SetSize(vec2(50,50))
        SettingsButton2:RelPos(vec2(10,10))
        SettingsButton2:AddRenderObj(RenderObjCircle(vec2(25),25,Color(255*0.25,255*0.25,255*0.25),false))
        GearIcon(SettingsButton2,40,vec2(25))
        ButtonHooks(SettingsButton2)
        RoundedClickable(SettingsButton2)
        SettingsButton2:AddTo(1,TopBar2)
        
        local SongListS=vec2(ScreenSize.x-8,ScreenSize.y-74-4)
        SongList=Object(self.Screen)
        SongList:SetSize(SongListS)
        SongList:RelPos(vec2(4,74))
        SongList:AddRenderObj(RenderObjRect(vec2(0,0),SongListS,Color(255*0.28,255*0.28,255*0.28),false))
        SongList.DrawZ=6
        SongList:AddLayout()
        SongList:AddLayout()
        SongList:AddLayout()
        SongList:AddLayout()
        SongList:AddTo(self.LayoutN,self.Root)
        



        ScrollBar=VerticalScrollBar(vec2(ScreenSize.x-8-(65-4-16)-2+4,2+74),vec2(65-4-4-16+4,ScreenSize.y-74-4-8+4))
        ScrollBar.DrawZ=5
        ScrollBar:AddTo(self.LayoutN,self.Root)
        CheckQuota()


        --Search Layout
        local SearchBarS=vec2(SongListS.x-8,22+2)
        Search=Object(self.Screen)
        Search.Clickable=true
        Search:SetSize(SearchBarS)
        Search:RelPos(vec2(4,4))
        local R=RenderObjRect(vec2(0),SearchBarS,Color(0,0,0),false) R:setRadius(5) Search:AddRenderObj(R)
        local R=RenderObjRect(vec2(1),SearchBarS-vec2(2),Color(255*0.8,255*0.8,255*0.8),false) R:setRadius(5) Search:AddRenderObj(R)
        Search.Font=Font( "Arial", 22, 400, true, false, false, false, true, true )
        Search.TextS=Search.Font:getTextSize("G")
        Search.TextSW=Search.Font:getTextSize("gG")
        Search.TextSW.x=Search.TextS.x
        Search.TextOffset=vec2(3,math.round(SearchBarS.y/2-Search.TextSW.y/2))

        Search.DefaultText="Search Songs Here"
        local SearchTex=RenderObjText(Search.TextOffset,Search.DefaultText,Color(255*0.3,255*0.3,255*0.3),vec2(0,0),Search.Font)
        Search:AddRenderObj(SearchTex)
        Search.Writable=true
        Search.CurrentlyEmpty=true
        
        local function LocToXY(Loc)
            return Search.TextOffset+vec2(math.round(Search.Font:getTextSize(SearchTex.Text:sub(0,Loc.x)).x),math.round(Loc.y*Search.TextSW.y))
        end
        Search.CursorLoc=vec2(0,0)
        Search.CursorRenderObj=RenderObjRect(LocToXY(Search.CursorLoc),vec2(1,Search.TextS.y),Color(255*0,255*0,255*0),false)
        
        --ChangedRenderObj
        Search.CursorState=false
        Search.Hooks:CreateHook("IsNowClickedObject","SearchClick",function(Data)
            if Search.CurrentlyEmpty then
                SearchTex.Color=Color(0,0,0)
                SearchTex.Changed=true
                SearchTex.Text=""
                UpdateRenderObj(Search,3,SearchTex)
            end
            print("Clicked")
            Search.CursorState=true
            AddRenderObj(Search,Search.CursorRenderObj)
            timer.remove("CursorBlink")
            timer.create("CursorBlink",0.5,0,function()
                if Search.CursorState then
                    RemoveRenderObj(Search,4)
                else
                    AddRenderObj(Search,Search.CursorRenderObj)
                end
                Search.CursorState=not Search.CursorState
            end)
        end)
        Search.Hooks:CreateHook("IsNoLongerClickedObject","SearchClick",function(Data)
            print("UnClicked")
            if Search.CursorState then
                RemoveRenderObj(Search,4)
                Search.CursorState=false
            end
            if Search.CurrentlyEmpty then
                SearchTex.Color=Color(255*0.3,255*0.3,255*0.3)
                SearchTex.Changed=true
                SearchTex.Text=Search.DefaultText
                UpdateRenderObj(Search,3,SearchTex)
            end
            timer.remove("CursorBlink")
        end)
        local NonShiftConvArr={k65=" ",k64="\n",k67="\x09",k88="\x11",k89="\x12",k90="\x13",k91="\x14"}
        
        Search.Hooks:CreateHook("OnChar","SearchClick",function(Data)
            local LCursorLoc=vec2(Search.CursorLoc.x,Search.CursorLoc.y)
            local TextChanged=false
            if Data[2]=="\x09" then
                if Search.CursorLoc.x~=0 then
                    TextChanged=true
                    Search.CursorLoc.x=Search.CursorLoc.x-1
                    SearchTex.Text=SearchTex.Text:sub(0,Search.CursorLoc.x)..SearchTex.Text:sub(Search.CursorLoc.x+2)
                end
            elseif Data[2]=="\x12" then
                if Search.CursorLoc.x~=0 then
                    Search.CursorLoc.x=Search.CursorLoc.x-1
                end
            elseif Data[2]=="\x14" then
                if Search.CursorLoc.x~=SearchTex.Text:len() then
                    Search.CursorLoc.x=Search.CursorLoc.x+1
                end
            elseif Data[2]=="\x11" or Data[2]=="\x13" then

            elseif Data[2]=="\n" then

            else
                TextChanged=true
                SearchTex.Text=SearchTex.Text:sub(0,Search.CursorLoc.x)..Data[2]..SearchTex.Text:sub(Search.CursorLoc.x+1)
                Search.CursorLoc.x=Search.CursorLoc.x+1
            end
            
            if LCursorLoc~=Search.CursorLoc then
                Search.CursorRenderObj.RelativePos=LocToXY(Search.CursorLoc)
                if Search.CursorState then
                    UpdateRenderObj(Search,4,Search.CursorRenderObj)
                else
                    Search.CursorState=true
                    AddRenderObj(Search,Search.CursorRenderObj)
                end
            end
            if TextChanged then
                SearchTex.Changed=true
                Search.CurrentlyEmpty=SearchTex.Text:len()==0
                UpdateRenderObj(Search,3,SearchTex)
                Search.Hooks:OnEvent("TextChanged",SearchTex.Text)
            end
        end)
        Search:AddTo(4,SongList)
        CheckQuota()
        ScrollBar2=VerticalScrollBar(vec2(ScreenSize.x-4-(35)-8,22+4+2+4),vec2(35,ScreenSize.y-74-4-4-(22+4+2+4)))
        ScrollBar2.DrawZ=5
        ScrollBar2:AddTo(4,SongList)
        
        SSongListS2=vec2(SongListS.x-8-35,ScreenSize.y-74-4-4-(22+4+2+4))
        SSongList=Object(self.Screen)
        SSongList:SetSize(SSongListS2)
        SSongList:RelPos(vec2(4,22+4+2+4))
        SSongList:AddRenderObj(RenderObjRect(vec2(0,0),SSongListS2,Color(255*0.25,255*0.25,255*0.25),false))
        SSongList:AddTo(4,SongList)
    end
    ,MakeOnScrollPage = function(self,Page)
        local Player=self.Player
        local LastScrollValue=-self.SongList.Layouts[Page].Scroll.y
        local Ticks=0
        local NextTick=0
        local AveSpeed=Averager(20)
        local LastTime=timer.curtime()
        self.ScrollBar:OnEvent("MoveBar",LastScrollValue/(math.max((self.ScrollBar.Pages-1),0)*(self.SongList.Size.y-2)))
        self.ScrollBar.Hooks:CreateHook("BarMoved","ScrollBarAction2",function(Data)
            local ScrollValue=-(self.SongList.Size.y-2)*math.max((self.ScrollBar.Pages-1),0)*self.ScrollBar.Percentage
            local SPEED=math.abs(self.ScrollValue-LastScrollValue)
            
            local AveC=AveSpeed:NewValue(SPEED)
            Player.Screen.DebugLines[1]="Scroll Bar Speed: "..tostring(math.round(AveC))
            if LastTime+0.2<=timer.curtime() then
                AveSpeed:Reset()
                NextTick=Ticks
            end
            if NextTick==Ticks then
                ScrollObj(self.SongList,Page,vec2(0,ScrollValue))
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
})