--@name
--@author Zxvnm4
--@shared
--@model models/spacecode/sfchip_medium.mdl
--@include ../Base.lua
require("../Base.lua")
SettingsPage = ZClass(function(self,MusicPlayer)
    self.Root=MusicPlayer.Main
    self.LayoutN=self.Root:AddLayout()
    self.MusicPlayer=MusicPlayer
    self.Screen=MusicPlayer.Screen
end,{
    SwitchTo = function(self)
        SwitchLayout(self.Root,self.LayoutN)
    end
    ,LoadPage = function(self)

    end
})