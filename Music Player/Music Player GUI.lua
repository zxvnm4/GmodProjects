--@name
--@author Zxvnm4
--@shared
--@model models/spacecode/sfchip_medium.mdl
--@include Base.lua
--I love my use of Capitalization in my func,var names
--I could use stencils to renders stuff proper, no need to render above stuff, only when yar doin transparent stuff(Or non rectangle stuff)
--Oh and it is all in the same bloody piece of code, that... that ain't good man.

require("Base.lua")
--TODO
--Make Option so the CurrentTimeBr goes red or something when it is a live stream, cus... 
--The music shouldn't be on loop
--There is still an issue with the buttons, scrolling and the automatic cycling of songs, if it isn't on the page it isn't selected!... Sometimes?
--There is also an issue with one of the buttons not actually loading, I thought I fixed this... It appears to only happen when  I scroll up? It appears to only happen when I scroll down, then up not up then down

--Uhh so the search feature, it should stop your ability to do the text when you click off of it mate

--Weird rendering issue on renderobjs, it might just be localized to rotated boxes, don't forget to check it. SearchIcon
--Or it could be tranparent? ah no.

if CLIENT then
    local ModifyVolumeFunc=nil
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
        self.getBoundingBoxM=function (self,Pos) 
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

    function StartMusic()
        local Done=false
        local Bass=nil
        local IsPaused=false
        local Playing=true
        local MovingBar=false
        local URL=""
        local Volume=1
        local function CheckBass(B)
            if B then if B.isValid~=nil then if B:isValid() then return true end end end
            return false
        end
        VolumeBar:OnEvent("MoveBar",Volume)
        VolumeBar.Hooks:CreateHook("MouseMovedKP","ScrollBarAction",function(Data)
            
            local Pos=VolumeBar:GetPosition()
            local Per=math.min(math.max((AimPos.x-Pos.x-10),0),Data[1].Length)/Data[1].Length
            Volume=Per
            Data[1]:OnEvent("MoveBar",Per)
            ModifyVolumeFunc(Per)
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
        CheckQuota()
        local SetCurrentTime=function(Time)
            if CheckBass(Bass) then
                MovingBar=true
                timer.create("Whatadad",0.25,0,function()
                    if Bass then
                        if Bass.isValid == nil then timer.remove("Whatadad") return end
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
            local Distance=1
            bass.loadURL(URL , "noblock", function (BassG,Err,Name)
                Bass=BassG
                LoadingSong=false
                if Bass then
                    
                    Bass:setFade(300, 400)
                    Bass:setVolume(Volume*Distance)
                    if Playing==false then
                        Play:OnEvent("ToggleButton")
                        Playing=true
                    end
                    MovingBar=false
                    local LastTime=0
                    timer.create( "Meow2", 1/10, 0, function ()
                        if Playing and Bass:isValid() and Test5:GetDrawable() and CurrentTime:GetDrawable()  then
                            CurrentTime:OnEvent("MoveBar",Bass:getTime()/Bass:getLength())
                            if math.round(LastTime)~=math.round(Bass:getTime()) then
                                ChangedRenderObj(Test5,3,RenderObjText(vec2(5,12),SecondsToFormattedStr(Bass:getTime()).."/"..SecondsToFormattedStr(Bass:getLength()),Color(255*0.8,255*0.8,255*0.8),vec2(0,0),nil))
                                LastTime=math.round(Bass:getTime())
                            end
                            
                        end
                    end)
                    local Num=512
                    local F=(1/1024)*1000
                    local CatsInstuff=function(T,a,b)
                        local Total=0
                        if b-a==0 then b=b+1 end
                        for i=a,b do
                            Total=Total+T[i]*F*((i-1)/4+1.5)
                        end
                        return Total/(b-a)
                    end
                    local C=728
                    local Bars=math.floor((ScreenSize.y-145-72-20)/3)
                    local Max=C^Bars
                    local Pos=-C^(-Bars)
                    local Mul=(Num-1)/(1+Pos)
                    local SkipTicks=0
                    local CatTick=0
                    local UpdateCount=0
                    --local Cats={}
                    --for i=1,Bars do
                    --    Cats[i]=Averager(5)
                    --end 
                    local SampleRate=44100
                    local MaxFrequency=15000
                    local FQ=MaxFrequency/(SampleRate/2)
                    local BarAr={}
                    timer.create( "Meow", 1/60, 0, function ()
                        CatTick=CatTick+1
                        if not CheckBass(Bass) then Hooks:OnEvent("SongEnded") return end
                        if Bass:isValid() then
                            if math.floor(Bass:getTime()*20)/20==math.floor(Bass:getLength()*20)/20 then
                                Hooks:OnEvent("SongEnded")
                                return 
                            end
                        else
                            Hooks:OnEvent("SongEnded")
                            return 
                        end   
                        if quotaTotalAverage()>=quotaMax()*0.7 then
                            return
                        end
                        if Playing and Test7:GetDrawable() then
                            local B=Bass:getFFT(4)

                            if #B~=0 then
                                
                                local LDat=1
                             for i=1,Bars do 
                                    --Well, ok I can see how this could be a little intimidating to look at...
                                    local Dat=1+6+math.round(((C^( ((i-1)*0.8/Bars)+0.2 ))/C-(1/C))*(((#B)*FQ-6)/(1-(1/C))))--math.round(math.max((((C^(i/#B))/Max)+Pos)*Mul,0))--math.round(((#B)/Bars)*i)--
                                    --=math.min((math.log10(B[Dat]*math.max(Dat*2,10)+1))/1.5,1)
                                    local Value=math.min(CatsInstuff(B,LDat,Dat)/3,1)*Volume
                                    BarAr[Bars-i+1]=Value--Cats[Bars-i+1]:NewValue(Value)
                                    LDat=Dat
                                end
                                for i=1,Bars do
                                    BarAr[Bars+i]=BarAr[Bars-i+1]--=math.min((math.log10(B[Dat]*math.max(Dat*2,10)+1))/1.5,1)
                                end

                                ChangedRenderObj(Test7,2,RenderObjBoxGraph(vec2(0,0),vec2(ScreenSize.x-20,ScreenSize.y-145-72-20),BarAr,Color(255*0.9,255*0.9,255*0.9)))
                            end
                        end
                    end)
                    --pcall(Bass.setLooping, Bass, true) -- pcall in case of audio stream
                    hook.add("think", "snd", function()
                        if isValid(Bass) and isValid(chip()) then
                            Distance=math.min(500,math.max(0,1000-player():getPos():getDistance(ScreenPosition)))/500
                            --Bass:setPos(ScreenPosition)
                            Bass:setVolume(Distance*Volume)--(ScreenEnt:getPos())
                        end
                    end)
                else
                    Hooks:OnEvent("SongEnded")
                    ServerPrint(Name)
                end
            end)
            end
        end
        CheckQuota()
        Hooks:CreateHook("SongEnded","MusicList",function(Data)
            timer.remove("Meow")
            timer.remove("Meow2")
        end)
        ChangeSong = function(NURL,Name)
            timer.remove("Meow")
            timer.remove("Meow2")
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
                local AddDots=S1.x>FullSize*2.6
                while S1.x>FullSize*2.6 do
                    Name=Name:sub(0,Name:len()-2)
                    Text=RenderObjText(vec2(ScreenSize.x/2,70/2),Name,Color(220,220,220),vec2(1,1),TopBar.Font)
                    S1=Text:getTextSize()
                end
                if AddDots then
                    Name=Name.."..."
                end
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
            NSong.Hooks:CreateHook("KeyPress","FBackKPress",function(Data) 
                Hooks:OnEvent("SongEnded")
            end)
            LSong.Hooks:CreateHook("KeyPress","FBackKPress",function(Data) 
                if SongLocation~=nil then
                    if SongLocation[5]() then
                        local k = SongLocation[3](SongLocation[2])
                        SetPressStateRadioButton(SongLocation[4],SongLocation[2],1)
                        Hooks:OnEvent("PlayedSong",{k[2],k[1]})
                        ChangeSong(k[2],k[1])
                    end
                end
            end)

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
                    local Other=Button(MusicPlayer.Screen,vec2(2,2+(i-1)*40),vec2(ScreenSize.x-8-(65-4-16)-2-4-2,38),Color(255*0.34,255*0.34,255*0.34),i2,20,3,vec2(0,0))
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
            local function BaseSongChunkLoader(RowHeight,ButtonDrawer)
                return function(Data,Args)--Look at me reducing lines of code!
                    
                    local Loc,Size=Data[2],Data[3]
                    local Dir=Data[4]
                    local Start=math.min(math.max(((Loc.y-2)/RowHeight),0),Args[1])
                    local End=math.min(Start+Size.y/RowHeight,Args[1])
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
                        local Other = ButtonDrawer(Args,i)
                        --RepeatButton.Pressed ShuffleButton.Pressed
                        Other.Hooks:CreateHook("KeyPress","OtherKPress",function(Data)
                            SongLocation={function () 
                                if RepeatButton.Pressed==2 then return true end
                                local F=SongLocation[3]
                                if ShuffleButton.Pressed then
                                    SongLocation[2]=math.random(SongLocation[6])
                                else
                                    if F(SongLocation[2]+1)==nil then
                                        if RepeatButton.Pressed==0 then return false end
                                        SongLocation[2]=1
                                    else
                                        SongLocation[2]=SongLocation[2]+1
                                    end
                                end
                                return true
                            end,Data[1].ButtonID,Args[2],Args[3],function () 
                                if RepeatButton.Pressed==2 then return true end
                                local F=SongLocation[3]
                                if ShuffleButton.Pressed then
                                    SongLocation[2]=math.random(SongLocation[6])
                                else
                                    if F(SongLocation[2]-1)==nil then
                                        if RepeatButton.Pressed==0 then return false end
                                        SongLocation[2]=Args[1]
                                    else
                                        SongLocation[2]=SongLocation[2]-1
                                    end
                                end
                                return true
                            end,Args[1]}
                            local k=Args[2](Data[1].ButtonID)
                            Hooks:OnEvent("PlayedSong",{k[2],k[1]})
                            ChangeSong(k[2],k[1])
                        end)

                        NewObjects[Other.ID]=Other
                    end
                    return NewObjects
                end
            end
            local BaseSongChunkLoad=BaseSongChunkLoader(16,function(Args,i)
                local k=Args[2](i)
                local Other=Button(MusicPlayer.Screen,vec2(2,2+(i-1)*16),vec2(ScreenSize.x-8-(65-4-16)-2-4-2,14),Color(255*0.34,255*0.34,255*0.34),k[1],12,1)
                Other.ButtonID=i
                Other.ButtonType=Args[3]
                Other.Transparent=false
                ButtonHooks(Other)
                Other:AddTo(Args[3],SongList)
                return Other
            end)
            local Bla3=MusicList["Songs"]
            local SortedMusicList={}
            local function SortStr(k2,k1)
                local L1=k1[2][1]:len()
                local L2=k2[2][1]:len()
                for i=1,math.min(L2,L1) do
                    local A,B=k1[2][1]:lower():byte(i),k2[2][1]:lower():byte(i)
                    if A>B then
                        return true
                    elseif A<B then
                        return false
                    end
                end
                if L1>L2 then
                    return true
                end
                return false
            end
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
                CheckQuota()
                for i,k in pairs(k2) do
                    SongsCount=SongsCount+1
                    
                end
                FolderCount=FolderCount+1
            end
            for i,k in pairs(Bla3) do
                SortedMusicList[i]={i,Bla3[i]}
            end
            CheckQuota()
            
            local MusicListExtraIndex={}
            local SeperationPoints={}
            --Ok I'll stop here, I got the bulk done I guess?
            --local LongerThan20={}
            local function DoTheThing()
                local i=0
                while true do
                    i=i+1
                    local LCh=0
                    local CCh=0
                    local SLCh=0
                    local SCCh=0
                    local Cou=0
                    local Off=1
                    local AnEntry=false
                    MusicListExtraIndex[i]={}
                    for i2=1,#SortedMusicList do
                        CheckQuota()
                        local CStr=SortedMusicList[i2][2][1]
                        if CStr:len()>=i then
                            CCh=CStr[i]:lower():byte(1)
                            SCCh=CCh
                            if CStr:len()>=i+1 then
                                CCh=CCh+(256*CStr[i+1]:lower():byte(1))
                            end
                            AnEntry=true
                        else
                            CCh=0
                        end
                        if LCh~=CCh then
                            if LCh~=0 then
                                if MusicListExtraIndex[i][LCh]==nil then MusicListExtraIndex[i][LCh]={} end
                                
                                MusicListExtraIndex[i][LCh][#(MusicListExtraIndex[i][LCh])+1]={Off,Cou}
                                if LCh~=SLCh then
                                    if MusicListExtraIndex[i][SLCh]==nil then MusicListExtraIndex[i][SLCh]={} end
                                    MusicListExtraIndex[i][SLCh][#(MusicListExtraIndex[i][SLCh])+1]={Off,Cou}
                                end
                            end
                            Cou=0
                            Off=i2
                        end
                        Cou=Cou+1
                        LCh=CCh
                        SLCh=SCCh
                    end
                    if Cou~=0 and LCh~=0 then
                        if MusicListExtraIndex[i][LCh]==nil then MusicListExtraIndex[i][LCh]={} end
                        MusicListExtraIndex[i][LCh][#(MusicListExtraIndex[i][LCh])+1]={Off,Cou}
                    elseif not AnEntry then
                        break
                    end
                end
            end
            local SortingCoroutine=coroutine.create(DoTheThing)
            local TimeTaken=0
            local L=timer.systime()
            local Iterations=1
            local Start=timer.systime()
            table.sort(SortedMusicList,SortStr)
            coroutine.resume(SortingCoroutine)
            TimeTaken=TimeTaken+timer.systime()-L
            local Stat=coroutine.status(SortingCoroutine)
            if Stat~="dead" then
                timer.create("SortingCoroutineTimer",0.25,0,function()
                    if quotaTotalAverage()>=quotaMax()*0.90 then return end 
                    local Stat=coroutine.status(SortingCoroutine) 
                    if Stat~="dead" then
                        L=timer.systime()
                        coroutine.resume(SortingCoroutine)
                        Iterations=Iterations+1
                        TimeTaken=TimeTaken+timer.systime()-L
                    else
                        print("Sorting Took "..tostring(TimeTaken*1000).."ms Ran For "..tostring((timer.systime()-Start)*1000).."ms".." Iterated "..tostring(Iterations).." Times")
                        print("Total Of "..tostring(#SortedMusicList).." Entries")
                        timer.remove("SortingCoroutineTimer")
                    end
                end)
            else
                print("Sorting Took "..tostring(TimeTaken*1000).."ms and ran for "..tostring(TimeTaken*1000).."ms")
                print("Total Of "..tostring(#SortedMusicList).." Entries")
            end
            local TimeUsedBinSearch=0
            --[[local Arr=MusicListExtraIndex[2][('a'):byte(1)]
            for i,k in pairs(Arr) do
                print(i,k[1],k[2])
                
            end
            for i=1,40 do
                print(i,250+i*50,BinarySearch(Arr,250+i*50,function(k1,k2) if k1==nil then return 0 end if k1[1]==k2 then return 0 elseif k1[1]>k2 then return 1 end return -1 end))
            end]]
            SeperationPoints=nil
            local DEBUGA=false
            local function SearchFromPoint(i,StrL,Off,Area,Thing,OutArr)
                if i>#MusicListExtraIndex then return end
                local SChar=Thing:byte(StrL)
                if Thing:len() >= StrL+1 then
                    SChar=SChar+(256*Thing:byte(StrL+1))
                end
                local Bas=MusicListExtraIndex[i][SChar]
                if DEBUGA then if i==2 then
                    for i,k in pairs(Bas) do
                        print(i,k[1],k[2])
                    end
                end end
                if Bas~=nil then
                    TimeUsedBinSearch=TimeUsedBinSearch-timer.systime()
                    local Ba=BinarySearch(Bas,Off,function(k1,k2) if k1[1]==k2 then return 0 elseif k1[1]>k2 then return 1 end return -1 end)
                    TimeUsedBinSearch=TimeUsedBinSearch+timer.systime()
                    --[[
                    local Ba=0    
                    for i2,k3 in pairs(Bas) do
                        if not ((k3[1]<Off and k3[1]+k3[2]-1<Off) or (k3[1]>Off+Area-1)) then
                            Ba=i2
                            break
                        end
                    end
                    if Ba==0 then
                        print("Failed2")
                        return
                    end]]
                    local k3=Bas[Ba]
                    local End=Ba
                    if not ((k3[1]<Off and k3[1]+k3[2]-1<Off) or (k3[1]>Off+Area-1)) then
                    else
                        while Bas[Ba+1]~=nil and (k3[1]<Off and k3[1]+k3[2]-1<Off) do
                            Ba=Ba+1
                            k3=Bas[Ba]
                        end
                    end
                    End=Ba
                    if DEBUGA then  print(i,Ba,End,Off,Area,k3[1],k3[2],Thing[StrL])end
                    if ((k3[1]<Off and k3[1]+k3[2]-1<Off) or (k3[1]>Off+Area-1)) then
                        if DEBUGA then print("Failed2") end
                        return
                    end
                    while Bas[End+1]~=nil and Area+Off-1>Bas[End+1][1] do
                        End=End+1
                    end
                    
                    local M=(StrL==Thing:len())
                    for i2=Ba,End do
                        
                        local Off2=Bas[i2][1]
                        local Area2=Bas[i2][2]+Off2
                        if DEBUGA then  print("Meow",Off,Area,Off2,Area2) end
                        if i2==End then
                            Area2=math.min(Off+Area,Area2)
                        end
                        if Ba==i2 then
                            Off2=math.max(Off,Off2)
                        end
                        Area2=Area2-Off2
                        if M then
                            
                            for i3=Off2,Off2+Area2-1 do
                                --if SortedMusicList[i][2][1]:lower():find(Thing) then
                                    if OutArr[1][i3]==nil then
                                        OutArr[1][i3]=i3
                                        OutArr[2][#OutArr[2]+1]=i3
                                    end
                                --end
                            end
                        else
                            if DEBUGA then print("Meow2",Off2,Area2) end
                            SearchFromPoint(i+1,StrL+1,Off2,Area2,Thing,OutArr)
                        end
                    end
                else
                    if DEBUGA then print("Failed1") end
                end
            end
            local function SearchMusicList(Thing)
                local ObjsWithThingInThem={{},{}}
                Thing=Thing:lower()
                LastTime=timer.systime()
                TimeUsedBinSearch=0
                BinSearchOperations=0
                for i=1,math.max(#MusicListExtraIndex-Thing:len()-1,1) do
                    if #SortedMusicList==#(ObjsWithThingInThem[2]) then
                        break
                    end
                    SearchFromPoint(i,1,1,#SortedMusicList,Thing,ObjsWithThingInThem)
                end
                --print("TimeTook "..tostring((timer.systime()-LastTime)*1000).."ms "..tostring(#(ObjsWithThingInThem[2])).." "..tostring(TimeUsedBinSearch*1000).."ms")
                --print(BinSearchOperations)
                
                LastTime=timer.systime()
                local Outaw=0
                local TotalLength=0
                for i=1,#SortedMusicList do
                    TotalLength=TotalLength+SortedMusicList[i][2][1]:len()
                    if SortedMusicList[i][2][1]:lower():find(Thing) then
                        Outaw=Outaw+1
                    end
                end
                --print("TimeTook2 "..tostring((timer.systime()-LastTime)*1000).."ms "..tostring(Outaw).." Length: "..tostring(TotalLength))
                return ObjsWithThingInThem[2]
            end
            if false then
                local Thing="doom"
                local Ba=SearchMusicList(Thing)
                local Count=0
                for i,k in pairs(Ba) do
                    print(SortedMusicList[k][2][1])
                    Count=Count+1
                end
                print("")
                local Count2=0
                for i,k in pairs(SortedMusicList) do
                    if k[2][1]:lower():find(Thing) then
                        Count2=Count2+1
                        print(k[2][1])
                        --[[if (k[2][1]=="Do You Hear What I Hear - Johnny Mathis") then
                            print(i,k[2][1]:find("J"),k[2][1][k[2][1]:find("J")])
                        end]]
                    end
                end
                print(Count,Count2)
            end
            --Ok I know this stupid searching algorithm is a little bit extreme but... Efficiency???? (probs not big enough for this level but ehhhh)
            SongList.Layouts[1].Hook:CreateHook("ChunkAdded","Cats",BaseSongChunkLoad,{SongsCount,function(i) return SortedMusicList[i][2] end,1})
            SongList.Layouts[2].Hook:CreateHook("CheckChunkAvailability","Cats",CCAva,2+FolderCount*40)
            SongList.Layouts[1].Hook:CreateHook("CheckChunkAvailability","Cats",CCAva,2+SongsCount*16)
            SongList.Layouts[2].Hook:CreateHook("LoadedObjOutofScreen","Cats",function(Obj) Obj:RemoveObj() end)
            SongList.Layouts[1].Hook:CreateHook("LoadedObjOutofScreen","Cats",function(Obj) Obj:RemoveObj() end)
            CheckQuota()
            local SearchResults={}

            
            --Percentage
            local SearchSongChunkLoad=BaseSongChunkLoader(16,function(Args,i)
                local k=Args[2](i)
                local Other=Button(MusicPlayer.Screen,vec2(2,2+(i-1)*16),vec2(SSongListS2.x-4,14),Color(255*0.34,255*0.34,255*0.34),k[1],12,1)
                Other.ButtonID=i
                Other.ButtonType=1000
                Other.Transparent=false
                ButtonHooks(Other)
                Other:AddTo(1,SSongList)
                return Other
            end)
            --SSongListS2.Layouts[1].Hook:CreateHook("LoadedObjOutofScreen","Cats",function(Obj) Obj:RemoveObj() end)
            --SSongListS2.Layouts[1].Hook:CreateHook("CheckChunkAvailability","Cats",CCAva,0)
            --SSongListS2.Layouts[1].Hook:CreateHook("ChunkAdded","Cats",SearchSongChunkLoad,{#SearchResults,function(i) return SortedMusicList[SearchResults[i]][2] end,1})
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
            
            Search.Hooks:CreateHook("TextChanged","SearchCheck",function(Data)
                
                local SearchResults=SearchMusicList(Data)
                --for i,k in pairs(SearchResults) do
                --    print(SortedMusicList[k][2][1])
                --end
                if #SearchResults~=0  then
                    if SongLocation~=nil then SongLocation[4]=-1 end
                    SSongList.Layouts[1].Hook:CreateHook("ChunkAdded","Cats",SearchSongChunkLoad,{#SearchResults,function(i) if SortedMusicList[SearchResults[i]]==nil then return nil end return SortedMusicList[SearchResults[i]][2] end,1000})
                    SSongList.Layouts[1].Hook:CreateHook("CheckChunkAvailability","Cats",CCAva,2+16*#SearchResults)
                    SSongList.Layouts[1].Hook:CreateHook("LoadedObjOutofScreen","Cats",function(Obj) Obj:RemoveObj() end)
                    AddToChangeList(SSongList,1,true,"ClearAndRefreshLayout",SSongList.getRenderBound,SSongList.ClearAndRefreshLayout,{1})
                end
                --SSongListS2
                --[[
                for i=Start+1,End do
                    CheckQuota()
                    local k=Args[2](i)
                    local Other=Button(MusicPlayer.Screen,vec2(2,2+(i-1)*16),vec2(ScreenSize.x-8-(65-4-16)-2-4-2,14),Color(255*0.34,255*0.34,255*0.34),k[1],12,1)
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
                        end,Data[1].ButtonID,Args[2],Args[3],function () 
                            local F=SongLocation[3]
                            if F(SongLocation[2]-1)==nil then
                                SongLocation[2]=Args[1]
                            else
                                SongLocation[2]=SongLocation[2]-1
                            end
                        end}
                        local k=Args[2](Data[1].ButtonID)
                        Hooks:OnEvent("PlayedSong",{k[2],k[1]})
                        ChangeSong(k[2],k[1])
                    end)
                    ButtonHooks(Other)
                    AddObj()
                    Other:AddTo(Args[3],SongList)
                    NewObjects[Other.ID]=Other
                end
                ]]--
            end)
            ScrollBarPage1(false)
            Hooks:CreateHook("SongEnded","MusicList",function(Data)
                if SongLocation~=nil then
                    if SongLocation[1]() then
                        local k = SongLocation[3](SongLocation[2])

                        if SongLocation[4]~=-1 then SetPressStateRadioButton(SongLocation[4],SongLocation[2],1) end
                        Hooks:OnEvent("PlayedSong",{k[2],k[1]})
                        ChangeSong(k[2],k[1])
                    end
                end
            end)
            AddToChangeList(Root,2,true,"Refresh",Root.getRenderBound,Root.Refresh,{})
            LoadedList()
        end
        

    end
    MusicListClass = ZClass(function(self,Player)
        self.Player=Player
        self.MusicList={}
        self.SongLocation=nil
    end,{
        Load = function(self)
            if not hasPermission("http.get", "https://zxvnm4.ca/SongList.txt") then
                hook.add("permissionrequest", "permission2",function ()
                    http.get( "https://zxvnm4.ca/SongList.txt", function(Body,Length,Headers,Code) self:SuccessGetMusicList(Body,Length,Headers,Code) end, function(FailReason) self:FailGetMusicList(FailReason) end, {} )
                end)
            else
                http.get( "https://zxvnm4.ca/SongList.txt", function(Body,Length,Headers,Code) self:SuccessGetMusicList(Body,Length,Headers,Code) end, function(FailReason) self:FailGetMusicList(FailReason) end, {} )
            end
        end
        ,SuccessGetMusicList = function(self,Body,Length,Headers,Code)
            if math.floor(Code/100)==2 then
                local CurrentFolder="Default"
                self.MusicList["Albums"]={}
                self.MusicList["Songs"]={}
                local Songs=self.MusicList["Songs"]
                local Albums=self.MusicList["Albums"]
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
                timer.create("GetMusicListDoneTimer",1/10,1,function() self:OnMusicListDone() end)--Don't question it ok

            else
                ServerPrint("The request failed with responce "..tostring(Code))
                FailedToLoadList()
            end
        end
        ,FailGetMusicList = function(self,FailReason)
            ServerPrint(FailReason)
            self:FailedToLoadList()
        end
    })
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

    MusicPlayerClass = ZClass(function(self)
        self.Main=nil
        self.AudioVisualizerPage=nil
        self.SongListPage=nil
        self.SettingsPage=nil
        self.LoadingPage=nil
        self.Screen=nil
        self.Hooks=HookL()
    end,{
        Load = function(self,Screen)
            self.Main=Screen.Root
            self.Screen=Screen
            Screen.Root=Object(Screen)
            Screen.Root:AddRenderObj(RenderObjRect(vec2(0,0),vec2(Screen.ScreenSize.x,Screen.ScreenSize.y),Color(255*0.3,255*0.3,255*0.3),false))
            Screen.Root:SetSize(vec2(Screen.ScreenSize.x,Screen.ScreenSize.y))
            self.SongListPage = SongListPage(self)
            self.AudioVisualizerPage = AudioVisualizerPage(self)
            self.SettingsPage = SettingsPage(self)
            self.LoadingPage = LoadingPage(self)

            self.SongListPage:LoadPage()
            self.AudioVisualizerPage:LoadPage()
            self.SettingsPage:LoadPage()
            self.LoadingPage:LoadPage()

            StartMusic()
            GetMusicList()
            StartNetworking()
            self.Main:SwitchLayout(4)
            self.Screen:StartDrawingRoot()
        end
    })
    local ScreenObj = Screen()
    function ScreenStartDrawing()
        if not hasPermission("bass.loadURL", URL) or not hasPermission("http.get", URL) then
            setupPermissionRequest({"bass.loadURL","http.get","bass.play2D"}, "URL sounds from external sites", true)
        end

        

        
        
    end

    ScreenObj:InitScreen()
    timer.create( "CatsScreenStartDrawing", 1/10, 1, function() 
        RunQuotaLimitedFunction(ScreenStartDrawing)
    end) 
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
end