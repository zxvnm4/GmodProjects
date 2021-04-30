local function ZClassGetSuperClasses(self,ret,K)
    local C=#self[2] 
    for i=1,C do 
        B=self[2][1+C-i]
        if type(B)=="table" then
            if B.C123456789==true then
                local BA=ZClassGetSuperClasses(B,ret,K)
                if BA~=nil then
                    return BA
                end
            else
                if B.Variables~=nil then
                    if B.Variables[K]~=nil then
                        return rawget(ret,B.Variables[K])
                    end
                end
                if B[K]~=nil then
                    return B[K]
                end
            end
        end 
    end
    return nil
end
local function ZClassGetSuperClassesNew(self,ret,K,V)
    local C=#self[2] 
    for i=1,C do 
        B=self[2][1+C-i]
        if type(B)=="table" then
            if B.C123456789==true then
                if ZClassGetSuperClassesNew(B,ret,K,V) then
                    return true
                end
            else
                if i==1 and B.Variables~=nil and B.Variables[K]~=nil then
                    rawset(ret, B.Variables[K], V)
                    return true
                end
            end
        end 
    end
    return false
end
function ZClass(Constructor,...) --I made this to fulfill 2 criteria, one to decrease ram usage and two to be easy to implement
    --Can be more efficient yo!
    local ClassTy={Constructor,{...}}
    ClassTy.C123456789=true
    local First=true
    setmetatable(ClassTy,{
    __index=function(self,K)
        if K=="const" then
            return self[1]
        end
        if K=="__setVar" then
            return function(self,K,V)
                local F=#self[2]
                if self[2][F].C123456789 == true then
                    F=F+1
                end
                if F==0 then F=1 end
                if self[2][F]==nil then
                    self[2][F]={}
                    self[2][F].Variables = {}
                end
                if self[2][F].Variables == nil then
                    self[2][F].Variables = {}
                end
                self[2][F].Variables[K] = V
                
            end
        end
        return ZClassGetSuperClasses(self,{},K)
    end,
    __call=function(self2,...)
        local ret = {}
        local NMeta = {
            __super = self2,
            __index = function(S,K)
                local self=getmetatable(S).__super
                if K=="const" then
                    return self[1]
                end
                return ZClassGetSuperClasses(self,S,K)
            end,
            __newindex = function(S,K,V)
                local self=getmetatable(S).__super
                if not ZClassGetSuperClassesNew(self,ret,K,V) then
                    print(K,V)
                    AWJIA()
                    rawset(S, K, V)
                end
            end
        }
        if First then
            local Num=0
            setmetatable(ret, {
                __super = self2,
                __index = function(S,K)
                    local self=getmetatable(S).__super
                    if K=="const" then
                        return self[1]
                    end
                    return ZClassGetSuperClasses(self,S,K)
                end,
                __newindex = function(S,K,V)
                    local self=getmetatable(S).__super
                    if type(K)=="number" then
                        rawset(S, K, V)
                        return
                    end
                    if not ZClassGetSuperClassesNew(self,ret,K,V) then
                        if First then
                            Num=Num+1
                            self:__setVar(K,Num)
                            rawset(S, Num, V)
                        else
                            rawset(S, K, V)
                        end
                    end
                end
            })
        else
            setmetatable(ret, NMeta)
        end
        self2[1](ret,...)
        if First then
            setmetatable(ret, NMeta)
        end
        First=false
        
        return ret
    end})
    return ClassTy
end

function ZTemplateClass(Constructor,Templates,...) --I made this to fulfill 2 criteria, one to decrease ram usage and two to be easy to implement
    local ClassTy={Constructor,{...}}
    ClassTy.C123456789=true
    setmetatable(ClassTy,{
    __index=function(self,K)
        if K=="const" then
            return self[1]
        end
    end,
    __call=function(self2,...)
        local ret = {}
        local GeneratedTemplate={self2[1],{}}
        local Arguments={}
        local TTemplates={}
        local T=1
        for i,k in pairs(self2[2]) do
            GeneratedTemplate[2][i]=k
        end
        for i,k in pairs({...}) do
            if T<=Templates then
                TTemplates[#TTemplates+1]=k
                GeneratedTemplate[2][#GeneratedTemplate[2]+1]=k
            else
                Arguments[#Arguments+1]=k
            end
            T=T+1
        end
        setmetatable(ret, {
            __super = GeneratedTemplate,
            __index = function(S,K)
                local self=getmetatable(S).__super
                if K=="const" then
                    return self[1]
                end
                return ZClassGetSuperClasses(self,ret,K)
            end
        })
        self2[1](ret,TTemplates,unpack(Arguments))
        return ret
    end})
    return ClassTy
end