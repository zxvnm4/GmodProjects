--@includedir ../../Libs
requiredir("../../Libs")
if CLIENT then
    function CheckQuota()
        if coroutine.running() then
            if quotaTotalAverage()>=quotaMax()*0.75 then
                coroutine.yield()
            end
        end
    end
end