local Vec2Mt={}
Vec2Mt.__add=function(a,b)
    return vec2(a.x+b.x,a.y+b.y)
end
Vec2Mt.__sub=function(a,b)
    return vec2(a.x-b.x,a.y-b.y)
end
Vec2Mt.__mul=function(a,b)
    if type(b)=="number" then
    return vec2(a.x*b,a.y*b)
    else
        return vec2(a.x*b.x,a.y*b.y)
    end
end
Vec2Mt.__div=function(a,b)
    if type(b)=="number" then
        return vec2(a.x/b,a.y/b)
    else
        return vec2(a.x/b.x,a.y/b.y)
    end
end
Vec2Mt.__eq=function(a,b)
    return a.x==b.x and b.y==b.y
end
Vec2Mt.__tostring=function(a)
    return "("..tostring(a.x)..","..tostring(a.y)..")"
end
local VecSuper={}
VecSuper.lengthSq=function(a)
    return a.x*a.x+a.y*a.y
end
VecSuper.length=function(a)
    return math.sqrt(a.x*a.x+a.y*a.y)
end
Vec2Mt.__index=function(self,key)
    if VecSuper[key] then return VecSuper[key] end
    if key=="x" then return self[1] end
    if key=="y" then return self[2] end
    return self[key]
end
function vec2(x,y)
    if y==nil then
        y=x
    end
    T={x,y}
    setmetatable(T, Vec2Mt)
    return T 
end
function VecMatMul(Vec,Mat)
    X=Vec.x*Mat:getField(1,1)+Vec.y*Mat:getField(1,2)+Vec.z*Mat:getField(1,3)+1*Mat:getField(1,4)
    Y=Vec.x*Mat:getField(2,1)+Vec.y*Mat:getField(2,2)+Vec.z*Mat:getField(2,3)+1*Mat:getField(2,4)
    Z=Vec.x*Mat:getField(3,1)+Vec.y*Mat:getField(3,2)+Vec.z*Mat:getField(3,3)+1*Mat:getField(3,4)
    return Vector(X,Y,Z)
end