--@includedir ../Libs
--@includedir Whole
--@includedir Objects
--@includedir Icons
requiredir("../Libs",{"BaseLib.lua"})
requiredir("Whole")
if CLIENT then
    requiredir("Objects")
    requiredir("Icons")

end