--@include BaseLib.lua
--@include Vector2.lua
require("BaseLib.lua")
require("Vector2.lua")

BoundingVolume = ZClass(function(self)
    self.Type="Null"
end,{
    check=function(self,BV)
        if type(BV)=="vector" then 
            return self:checkPoint(BV)
        else
            if BV.Type=="Box" then
                return self:checkArea(BV)
            end
        end
        return false
    end
    ,between=function(self,BV)
        if BV.Type=="Box" then
            return self:betweenArea(BV)
        end
        return
    end
    ,within=function(self,BV)
        if BV.Type=="Box" then
            return self:withinArea(BV)
        end
        return false
    end
    ,checkArea=function(BB) return false end
    ,checkPoint=function(Pos) return false end
})
BoundingBox = ZClass(function(self,Pos,Size)
    BoundingVolume.const(self)
    self.Type="Box"
    self.P=Pos
    self.S=Size
end,BoundingVolume,{
    checkArea=function(self,BB) 
        local XOut,YOut = false
        if self.S.x>BB.S.x then
            if self.P.x<=BB.P.x+BB.S.x and self.P.x+self.S.x>=BB.P.x then
                XOut= true
            end
        else
            if BB.P.x<=self.P.x+self.S.x and BB.P.x+BB.S.x>=self.P.x then
                XOut= true
            end
        end
        if self.S.y>BB.S.y then
            if self.P.y<=BB.P.y+BB.S.y and self.P.y+self.S.y>=BB.P.y then
                YOut= true
            end
        else
            if BB.P.y<=self.P.y+self.S.y and BB.P.y+BB.S.y>=self.P.y then
                YOut= true
                
            end
        end
        return (YOut&&XOut)
    end
    ,checkPoint=function(self,Pos) 
        if self.P.x<=Pos.x and self.P.x+self.S.x>=Pos.x then
            if self.P.y<=Pos.y and self.P.y+self.S.y>=Pos.y then
                return true
            end
        end
        return false
    end
    ,withinArea=function(self,BB) 
        if self.P.x>BB.P.x+BB.S.x and self.P.x>BB.P.x and self.P.x+self.S.x<BB.P.x and self.P.x+self.S.x<BB.P.x+BB.S.x then
            if self.P.y>BB.P.y+BB.S.y and self.P.y>BB.P.y and self.P.y+self.S.y<BB.P.y and self.P.y+self.S.y<BB.P.y+BB.S.y then
                return true
            end
        end
        return false
    end
    ,betweenArea=function(self,BB)
        local X=math.max(self.P.x,BB.P.x)
        local Y=math.max(self.P.y,BB.P.y)
        return BoundingBox(vec2(X,Y),vec2(math.min(self.P.x+self.S.x,BB.P.x+BB.S.x)-X,math.min(self.P.y+self.S.y,BB.P.y+BB.S.y)-Y))
    end
    ,combineArea=function(self,BB)
        local X1=math.min(self.P.x,BB.P.x)
        local Y1=math.min(self.P.y,BB.P.y)
        local X2=math.max(self.P.x+self.S.x,BB.P.x+BB.S.x)
        local Y2=math.max(self.P.y+self.S.y,BB.P.y+BB.S.y)
        return BoundingBox(vec2(X1,Y1),vec2(X2-X1,Y2-Y1))
    end
})
function GetPolyBoundingBox(Poly)
    local Min=vec2(10000000,10000000)
    local Max=vec2(0,0)
    for i,k in pairs(Poly) do
        Min.x=math.min(k.x,Min.x)
        Min.y=math.min(k.y,Min.y)
        Max.x=math.max(k.x,Max.x)
        Max.y=math.max(k.y,Max.y)
    end
    return BoundingBox(Min,Max-Min)
end