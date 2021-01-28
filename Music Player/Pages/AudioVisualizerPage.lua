--@name
--@author Zxvnm4
--@shared
--@model models/spacecode/sfchip_medium.mdl
--@include ../Base.lua
require("../Base.lua")
AudioVisualizerPage = ZClass(function(self,MusicPlayer)
    self.Root=MusicPlayer.Main
    self.LayoutN=self.Root:AddLayout()
    self.MusicPlayer=MusicPlayer
    self.Screen=MusicPlayer.Screen
end,{
    SwitchTo = function(self)
        SwitchLayout(self.Root,self.LayoutN)
    end
    ,LoadPage = function(self)
        Play=Object(self.Screen)
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
        Play:AddTo(self.LayoutN,self.Root)
        ButtonHooks(Play)
        RoundedClickable(Play)
        
        Note=Object(self.Screen)
        Note.DrawZ=3
        Note:AddRenderObj(RenderObjCircle(vec2(60),60,Color(255*0.34,255*0.34,255*0.34),false))
        
        FBack=Object(self.Screen)
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
        FBack:AddTo(self.LayoutN,self.Root)

        ButtonHooks(FBack)
        RoundedClickable(FBack)
        FForw=Object(self.Screen)
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
        FForw:AddTo(self.LayoutN,self.Root)

        ButtonHooks(FForw)
        RoundedClickable(FForw)

        NSong=Object(self.Screen)
        NSong:SetSize(vec2(70))
        NSong:RelPos(vec2(ScreenSize.x/2+120/2+10+80+10,ScreenSize.y-60-35-7))
        NSong.DrawZ=5
        NSong.Clickable=true
        B=(35/40)*10/5
        NSong:AddRenderObj(RenderObjCircle(vec2(35),35,Color(255*0.34,255*0.34,255*0.34),false))
        NSong:AddRenderObj(RenderObjCircle(vec2(35),33,Color(255*0.4,255*0.4,255*0.4),false))
        NSong:AddRenderObj(RenderObjCircle(vec2(35),31,Color(255*0.35,255*0.35,255*0.35),false))
        NSong:AddRenderObj(RenderObjCircle(vec2(35),29,Color(255*0.32,255*0.32,255*0.32),false))
        NSong:AddRenderObj(RenderObjPoly(vec2(35-(C*B*(1/4)),35),vec2(B,B),Bla,Color(255*1,255*1,255*1)))
        local RRect=RenderObjRect(vec2(35+(C*B*(3/8))+(B*0.1*20),35),vec2(B*0.2,B)*20,Color(255,255,255),false)
        RRect:setAlignment(0)
        NSong:AddRenderObj(RRect)
        NSong:AddTo(self.LayoutN,self.Root)

        ButtonHooks(NSong)
        RoundedClickable(NSong)
        LSong=Object(self.Screen)
        LSong:SetSize(vec2(70))
        LSong:RelPos(vec2(ScreenSize.x/2-120/2-10-80-10-70,ScreenSize.y-60-35-7))
        LSong.DrawZ=5
        LSong.Clickable=true
        B=(35/40)*10/5
        LSong:AddRenderObj(RenderObjCircle(vec2(35),35,Color(255*0.34,255*0.34,255*0.34),false))
        LSong:AddRenderObj(RenderObjCircle(vec2(35),33,Color(255*0.4,255*0.4,255*0.4),false))
        LSong:AddRenderObj(RenderObjCircle(vec2(35),31,Color(255*0.35,255*0.35,255*0.35),false))
        LSong:AddRenderObj(RenderObjCircle(vec2(35),29,Color(255*0.32,255*0.32,255*0.32),false))
        LSong:AddRenderObj(RenderObjPoly(vec2(35+(C*B*(1/4)),35),vec2(-B,-B),Bla,Color(255*1,255*1,255*1)))
        local RRect=RenderObjRect(vec2(35-(C*B*(3/8))-(B*0.1*20),35),vec2(B*0.2,B)*20,Color(255,255,255),false)
        RRect:setAlignment(0)
        LSong:AddRenderObj(RRect)
        LSong:AddTo(self.LayoutN,self.Root)

        ButtonHooks(LSong)
        RoundedClickable(LSong)
        
        
        ShuffleButton=Object(self.Screen)
        ShuffleButton:SetSize(vec2(40,30))
        ShuffleButton:RelPos(vec2(ScreenSize.x/2+120/2+10+80+10+35-40-1,ScreenSize.y-30-1))
        local RRect=RenderObjRect(vec2(20,15),vec2(40,30),Color(255*0.3,255*0.3,255*0.3),false)
        RRect:setAlignment(0)
        RRect:setRadius(15)
        RRect:setRoundedEdges(true,false,true,false)
        ShuffleButton:AddRenderObj(RRect)
        ShuffleButton.Clickable=true
        ShuffleButton.DrawZ=5
        ShuffleButton.Toggle=true
        ShuffleButton:AddTo(self.LayoutN,self.Root)
        ShuffleIcon(ShuffleButton,vec2(20*0.75),vec2(20,15),0,Color(255,255,255))
        ButtonHooks(ShuffleButton)
        RoundedClickable(ShuffleButton)
        
        RepeatButton=Object(self.Screen)
        RepeatButton.DrawZ=5
        RepeatButton:SetSize(vec2(40,40))
        RepeatButton:RelPos(vec2(ScreenSize.x/2+120/2+10+80+10+35+1,ScreenSize.y-30-1))
        local RRect=RenderObjRect(vec2(20,15),vec2(40,30),Color(255*0.3,255*0.3,255*0.3),false)
        RRect:setAlignment(0)
        RRect:setRadius(15)
        RRect:setRoundedEdges(false,true,false,true)
        RepeatButton:AddRenderObj(RRect)
        RepeatButton.Clickable=true
        RepeatButton.Toggle=true
        RepeatButton:AddTo(self.LayoutN,self.Root)
        RepeatIcon(RepeatButton,vec2(20*0.5),vec2(20,15),0,Color(255,255,255))
        RepeatButton.DefaultPressed=0
        RepeatButton.Font=Font( "Arial", 13, 400, true, false, false, false, true, true )
        local NumberOne=RenderObjText(vec2(20,15),"1",Color(255,255,255),vec2(1,1),RepeatButton.Font)
        local NumberOnePos=#(RepeatButton.RenderObjs)+1
        RepeatButton.OnPressChState=function(Obj,Bool) 
            if Bool==false then
                Obj.Pressed=0
            else
                if Obj.Pressed==0 then
                    Obj.Pressed=1
                elseif Obj.Pressed==1 then
                    AddRenderObj(RepeatButton,NumberOne)
                    Obj.Pressed=2
                elseif Obj.Pressed==2 then
                    Obj.Pressed=0
                    RemoveRenderObj(RepeatButton,NumberOnePos)
                end
            end
        end 
        ButtonHooks(RepeatButton)
        RoundedClickable(RepeatButton)

        TopBar=Object(self.Screen)
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
        TopBar:AddTo(self.LayoutN,self.Root)
        BackButton=Object(self.Screen)
        BackButton.Clickable=true
        BackButton:SetSize(vec2(50,50))
        BackButton:RelPos(vec2(10,10))
        BackButton:AddRenderObj(RenderObjCircle(vec2(25),25,Color(255*0.25,255*0.25,255*0.25),false))
        ArrowIcon(BackButton,40,vec2(25),0)
        ButtonHooks(BackButton)
        RoundedClickable(BackButton)
        BackButton.Hooks:CreateHook("KeyPress","BackButtonKPress",function(Data) 
            self.MusicPlayer.SongListPage:SwitchTo()
        end)
        BackButton:AddTo(1,TopBar)
        CheckQuota()
        SettingsButton=Object(self.Screen)
        SettingsButton.Clickable=true
        SettingsButton:SetSize(vec2(50,50))
        SettingsButton:RelPos(vec2(ScreenSize.x-60,10))
        SettingsButton:AddRenderObj(RenderObjCircle(vec2(25),25,Color(255*0.25,255*0.25,255*0.25),false))
        GearIcon(SettingsButton,40,vec2(25))
        ButtonHooks(SettingsButton)
        RoundedClickable(SettingsButton)
        SettingsButton:AddTo(1,TopBar)
        
        Test5=Object(self.Screen)
        Test5:AddRenderObj(RenderObjRect(vec2(0,12),vec2(ScreenSize.x,133),Color(255*0.26,255*0.26,255*0.26),false))
        Test5:AddRenderObj(RenderObjRect(vec2(0,0),vec2(ScreenSize.x,12),Color(255*0.24,255*0.24,255*0.24),false))
        Test5:AddRenderObj(RenderObjText(vec2(5,12),"0:00/0:00",Color(255*0.8,255*0.8,255*0.8),vec2(0,0),nil))
        Test5:SetSize(vec2(ScreenSize.x,145))
        Test5:RelPos(vec2(0,ScreenSize.y-145))
        Test5.DrawZ=7
        Test5:AddTo(self.LayoutN,self.Root)
        
        
        CurrentTime=Object(self.Screen)
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
        CurrentTime.LastCurTime=0
        local MoveBarFunc=function(Data)
            if math.floor((ScreenSize.x-2)*Data[2])~=Data[1].LastCurTime then
                local RRect2=RenderObjRect(vec2(1,6),vec2(math.floor((ScreenSize.x-2)*Data[2]),10),Color(255*0.5,255*0.5,255*0.8),false)
                RRect2:setRadius(5)
                ChangedRenderObj(Data[1],3,RRect2)
                local Pos=vec2(math.floor(1+(ScreenSize.x-2)*Data[2]),11)
                ChangedRenderObj(Data[1],4,RenderObjCircle(Pos,10,Color(255*0.4,255*0.4,255*0.4),false))
                ChangedRenderObj(Data[1],5,RenderObjCircle(Pos,8,Color(255*0.34,255*0.34,255*0.34),false))
                ChangedRenderObj(Data[1],6,RenderObjCircle(Pos,6,Color(255*0.32,255*0.32,255*0.32),false))
                ChangedRenderObj(Data[1],7,RenderObjCircle(Pos,4,Color(255*0.3,255*0.3,255*0.3),false))
                Data[1].LastCurTime=math.floor((ScreenSize.x-2)*Data[2])
            end
        end
        MoveBarFunc({CurrentTime,0})
        CurrentTime.Hooks:CreateHook("MoveBar","ScrollBarAction",MoveBarFunc)

        CurrentTime:AddTo(self.LayoutN,self.Root)

        VolumeIcon=Object(self.Screen)
        local Size=vec2(28,28)
        ModifyVolumeFunc = SoundIcon(VolumeIcon,Size,vec2(Size.x/2,Size.y/2),Color(255*0.8,255*0.8,255*0.8),Color(255*0.25,255*0.25,255*0.25))
        VolumeIcon.DrawZ=3
        VolumeIcon.Clickable=true
        VolumeIcon.Transparent=false
        VolumeIcon:SetSize(Size)
        VolumeIcon:RelPos(vec2(6,ScreenSize.y-22-5+11-14))
        VolumeIcon:AddTo(self.LayoutN,self.Root)



        VolumeBar=Object(self.Screen)
        VolumeBar.Length=(ScreenSize.x/3)-2-20
        local RRect2=RenderObjRect(vec2(10,5),vec2(VolumeBar.Length+2,12),Color(255*0.4,255*0.4,255*0.4),false)
        RRect2:setRadius(6)
        VolumeBar:AddRenderObj(RRect2)
        local RRect2=RenderObjRect(vec2(11,6),vec2(VolumeBar.Length,10),Color(255*0.15,255*0.15,255*0.15),false)
        RRect2:setRadius(5)
        VolumeBar:AddRenderObj(RRect2)
        VolumeBar:SetSize(vec2(VolumeBar.Length+2+20,22))
        VolumeBar:RelPos(vec2(30,ScreenSize.y-22-5))
        VolumeBar.DrawZ=3
        VolumeBar.Clickable=true
        VolumeBar.Transparent=true
        VolumeBar.LastCurTime=0
        local MoveBarFunc=function(Data)
            if math.floor(Data[1].Length*Data[2])~=Data[1].LastCurTime then
                local RRect2=RenderObjRect(vec2(11,6),vec2(math.floor(Data[1].Length*Data[2]),10),Color(255*0.9,255*0.9,255*0.9),false)
                RRect2:setRadius(5)
                ChangedRenderObj(Data[1],3,RRect2)
                local Pos=vec2(math.floor(1+(Data[1].Length)*Data[2])+10,11)
                ChangedRenderObj(Data[1],4,RenderObjCircle(Pos,10,Color(255*0.4,255*0.4,255*0.4),false))
                ChangedRenderObj(Data[1],5,RenderObjCircle(Pos,8,Color(255*0.34,255*0.34,255*0.34),false))
                ChangedRenderObj(Data[1],6,RenderObjCircle(Pos,6,Color(255*0.32,255*0.32,255*0.32),false))
                ChangedRenderObj(Data[1],7,RenderObjCircle(Pos,4,Color(255*0.3,255*0.3,255*0.3),false))
                Data[1].LastCurTime=math.floor(Data[1].Length*Data[2])
            end
        end
        MoveBarFunc({VolumeBar,1})
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
        VolumeBar:AddTo(self.LayoutN,self.Root)
        
        
        Test6=Object(self.Screen)
        Size=vec2(ScreenSize.x-10,ScreenSize.y-145-72-10)
        Test6:AddRenderObj(RenderObjRect(vec2(0,0),Size,Color(255*0.28,255*0.28,255*0.28),false))
        Test6:SetSize(Size)
        Test6:RelPos(vec2(5,72+5))
        Test6.DrawZ=7
        Test6:AddTo(self.LayoutN,self.Root)
        
        Test7=Object(self.Screen)
        Size=vec2(ScreenSize.x-20,ScreenSize.y-145-72-20)
        Test7:AddRenderObj(RenderObjRect(vec2(0,0),Size,Color(255*0.1,255*0.1,255*0.1),false))
        Count=30
        Bap={}
        for i=1,Count do
            Bap[i]=0
        end
        --if player()==owner() then

        CheckQuota()
        Test7:AddRenderObj(RenderObjBoxGraph(vec2(0,0),Size,Bap,Color(255*0.9,255*0.9,255*0.9)))
        Test7:SetSize(Size)
        Test7:RelPos(vec2(ScreenSize.x/2-Size.x/2-5,5))
        Test7.DrawZ=7
        Test7:AddTo(1,Test6)
        local O=vec2(50,50)
        local S=vec2(50,50)

        Test8=Object(self.Screen)
        local S = vec2(ScreenSize.x/2,ScreenSize.y/2)
        --MusicVisualizerIcon(Test8,S,vec2(S.x/2,S.y/2),Color(255*0.8,255*0.8,255*0.8),Color(255*0.25,255*0.25,255*0.25))
        Test8:SetSize(S*2)
        Test8:RelPos(vec2(ScreenSize.x/2-S.x/2,ScreenSize.y/2-S.y/2))
        Test8.DrawZ=2
        Test8:AddTo(self.LayoutN,self.Root)
        
    end
})