--@includedir ../../Libs
--@include Base.lua
requiredir("../../Libs")
require("Base.lua")
if CLIENT then
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
        ,getBoundingBoxM=function (self,Pos) --Could store a variable that says it changed then does the change when it asks for it...
            self:reapplyBox()
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
        ,getBoundingBoxM=function (self,Pos) --Could store a variable that says it changed then does the change when it asks for it...
            self:reapplyBox()
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
            return BoundingBox(Pos+self.RelativePos+self.BoundingBox.P,self.BoundingBox.S)
        end
        ,getBoundingBoxM=function (self,Pos) 
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
        ,getBoundingBoxM=function (self,Pos) 
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
            render.setMaterial(nil)
            render.pushMatrix(Mat*self.Matrix)
            render.setColor(B)
            render.drawPoly(self.Indexes)
            render.popMatrix()
        end
    })
end