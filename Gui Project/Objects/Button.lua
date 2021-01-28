--@includedir ../../Libs
--@includedir ../Whole
requiredir("../../Libs",{"BaseLib.lua"})
requiredir("../Whole")
function Button(Screen,Pos,Size,ColorB,Text,TextHeight,Channel,TextAlignment)
    local self=Object(Screen)
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
function SetPressStateButton(Type,ID,Pressed,DState)
    if Pressed ~= DState then
        if ButtonStateStorage[Type]==nil then
            ButtonStateStorage[Type]={}
        end
        local Cat=ButtonStateStorage[Type][ID]
        if Cat==nil then
            ButtonStateStorage[Type][ID]={nil,Pressed,DState}
        else
            Cat[2]=Pressed
            if Cat[1]~=nil then
                if Cat[1].Pressed~=Pressed then
                    Cat[1].Pressed=Pressed
                    Cat[1]:Update()
                end
            end
        end
    else
        if ButtonStateStorage[Type]~=nil then
            local Cat=ButtonStateStorage[Type]
            if Cat[ID][1]==nil then
                Cat[ID]=nil
                if next(ButtonStateStorage[Type])==nil then
                    ButtonStateStorage[Type]=nil
                end
            else
                Cat[ID][2]=Pressed
                if Cat[ID][1].Pressed~=Pressed then
                    Cat[ID][1].Pressed=Pressed
                    Cat[ID][1]:Update()
                end
            end
        end
    end
end
function SetPressStateRadioButton(Type,ID,Channel,State,DState)
    if State==nil then State=true end
    if DState==nil then DState=false end
    local CurCan=RadioButtonChannels[Channel]
    if CurCan~=nil then
        if CurCan[1]==2 then
            if CurCan[2]==Type and CurCan[3]==ID then return end
        end
        if CurCan[1]==1 then
            CurCan[2]:Unpress()
        else
            SetPressStateButton(CurCan[2],CurCan[3],CurCan[4],CurCan[4])
        end
    end
    SetPressStateButton(Type,ID,State,DState)
    RadioButtonChannels[Channel]={2,Type,ID,DState}       
end
function ButtonHooks(Obj) -- The codes fine in all, except the values for hover and clicking, not hovering and clicking, hovering and not clicking, and not hovering and not clicking change depending on the process.
                        --Which is fairly stupid so fix this later ok.
    Obj.Hovering=false
    if Obj.DefaultPressed==nil then Obj.DefaultPressed=false end
    Obj.Pressed=Obj.DefaultPressed
    if Obj.Toggle== nil then Obj.Toggle=false end
    if Obj.Channel== nil then Obj.Channel=-1 end
    if Obj.DefaultB== nil then Obj.DefaultB=false end
    if Obj.GetColorState==nil then -- Obj.OnPressChState  Obj.GetColorState Obj.DefaultPressed
        Obj.GetColorState=function(Obj)
            if Obj.Pressed == Obj.DefaultPressed then 
                return false 
            end 
            return true
        end 
    end 
    if Obj.OnPressChState==nil then 
        Obj.OnPressChState=function(Obj,Bool) 
            if Obj.Toggle and Obj.Channel==-1 then
                if Bool==false then
                    Obj.Pressed=Bool
                else
                    Obj.Pressed=not Obj.Pressed
                end
            else
                Obj.Pressed=Bool
            end
        end 
    end
    local Preexisted=false
    if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
        if ButtonStateStorage[Obj.ButtonType]==nil then
            ButtonStateStorage[Obj.ButtonType]={}
        end
        local Cat=ButtonStateStorage[Obj.ButtonType][Obj.ButtonID]
        
        if Cat==nil then
            ButtonStateStorage[Obj.ButtonType][Obj.ButtonID]={Obj,Obj.Pressed,Obj.DefaultPressed}
        else
            ButtonStateStorage[Obj.ButtonType][Obj.ButtonID][1]=Obj
            Obj.Pressed=Cat[2]
            Preexisted=true--This is gunna make things funky. and I am too lazy to fix it because it ain't gunna cause an error easily
        end
    end 
    if Obj.DefaultB and Obj.Channel~=-1 and not Preexisted then
        if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
            RadioButtonChannels[Obj.Channel]={2,Obj.ButtonType,Obj.ButtonID,Obj.DefaultPressed}
        else
            RadioButtonChannels[Obj.Channel]={1,Obj}
        end
        if Obj.ButtonType~=nil and Obj.ButtonID~=nil and Obj.Pressed == Obj.DefaultPressed then
            ButtonStateStorage[Obj.ButtonType][Obj.ButtonID][2]=Obj.Pressed
        end
        Obj:OnPressChState(true)
    end
    local BaseVec=Vector(1,1,1)
    if Obj:GetColorState() then BaseVec=BaseVec-Vector(0.2,0.2,0.2) if Obj.Hovering then BaseVec=BaseVec-Vector(0.03,0.03,0.03) end else if Obj.Hovering then BaseVec=BaseVec-Vector(0.1,0.1,0.1) end end
    
    Obj.ColorModify=BaseVec
    Obj.Update=function(Obj)
        local BaseVec=Vector(1,1,1)
        if Obj:GetColorState() then BaseVec=BaseVec-Vector(0.2,0.2,0.2) if Obj.Hovering then BaseVec=BaseVec-Vector(0.03,0.03,0.03) end else if Obj.Hovering then BaseVec=BaseVec-Vector(0.1,0.1,0.1) end end
        SetColorM(Obj,BaseVec)
    end
    Obj.Unpress=function(Obj)
        local L=Obj.Pressed
        
        if Obj.DefaultPressed ~= Obj.Pressed then
            Obj:OnPressChState(false)
            Obj:Update()
            if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
                ButtonStateStorage[Obj.ButtonType][Obj.ButtonID][2]=Obj.Pressed
            end
        end
    end
    Obj.Hooks:CreateHook("Removed","ButtonB",function(Data)
        if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
            if Data[1].Pressed ~= Data[1].DefaultPressed then   
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
                    SetPressStateButton(CurCan[2],CurCan[3],Obj.DefaultPressed,CurCan[4])
                end
            end
            Obj:OnPressChState(true)
            Obj:Update()
            if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
                ButtonStateStorage[Obj.ButtonType][Obj.ButtonID][2]=Obj.Pressed
            end
            if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
                RadioButtonChannels[Obj.Channel]={2,Obj.ButtonType,Obj.ButtonID,Obj.DefaultPressed}
            else
                RadioButtonChannels[Obj.Channel]={1,Obj}
            end
            
        else
            Obj:OnPressChState(true)
            Obj:Update()
            if Obj.ButtonType~=nil and Obj.ButtonID~=nil then
                ButtonStateStorage[Obj.ButtonType][Obj.ButtonID][2]=Obj.Pressed
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
