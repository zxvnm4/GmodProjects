--@include BaseLib.lua
require("BaseLib.lua")
    function unpack (t, i)
      i = i or 1
      if t[i] ~= nil then
        return t[i], unpack(t, i + 1)
      end
    end
Job = ZClass(function(self,Parent,Started,Finished)
    self.JobsCompleted=0
    self.JobsStarted=0
    self.Parent=Parent
    self.OnFinished=Finished
    self.OnStarted=Started
end,{
    NewJob=function(self)
        self.JobsStarted=self.JobsStarted+1
        return self.JobsStarted
    end
    ,StartedJob=function(self)
        if self.JobsCompleted==0 then
            self.OnStarted(self)
            if self.Parent~=nil then
                self.Parent:OnFinished()
            end
        end
    end
    ,FinishedJob=function(self) 
        self.JobsCompleted=self.JobsCompleted+1
        if self.JobsCompleted==self.JobsStarted then
            self.OnFinished(self)
            if self.Parent~=nil then
                self.Parent:OnFinished()
            end
        end
    end
})
Scheduler = ZClass(function(self)
        self.Schedule=nil
end,{
    CurrentTick=function(self)
        return 0
    end,
    NewEventAtStart=function(self,t)
    
    end
    ,EmptyEvents=function(self)
        
    end
    ,NewScheduledEvent=function(self,time,func,data)
        if time<=self:CurrentTick() then
            
            func(data[1],data[2],time)
            return nil
        end
        local B={Next=nil,Back=nil,Time=time,Func=func,Data=data}
        local Nx=self.Schedule
        if nil==self.Schedule then
            self.Schedule=B
            self:NewEventAtStart(time)
            return B
        end
        while Nx~=nil do
            if Nx.Time>=time then
                if Nx==self.Schedule then
                    self.Schedule=B
                    self:NewEventAtStart(time)
                else
                    B.Back=Nx.Back
                    Nx.Back.Next=B
                end
                B.Next=Nx
                Nx.Back=B
                return B
            end
            if Nx.Next==nil then
                B.Back=Nx
                Nx.Next=B
                return B
            end
            Nx=Nx.Next
        end

        return B
    end
    ,RemoveScheduledEvent=function(self,Node)
        local ContinueStuff=true
        if self.Schedule~=nil then
            if Node.Back~=nil then
                Node.Back.Next=Node.Next
            end
            if Node.Next~=nil then
                Node.Next.Back=Node.Back 
            end
            if self.Schedule.Next~=nil then
                if self.Schedule.Next==Node then
                    self.Schedule=self.Schedule.Next
                    self:NewEventAtStart(self.Schedule.Time)
                end
            else
                self.Schedule=nil
                self:EmptyEvents()
            end
        end
    end
    ,Next=function(self)
        if self.Schedule~=nil then
            local C=self.Schedule
            --printTable(C.Data)
            --print(self,unpack(C.Data),C.Time)
            C.Func(C.Data[1],C.Data[2],C.Time)
            if C.Next~=nil then
                self.Schedule=C.Next
                self.Schedule.Back=nil
                if self.Schedule.Time<=self:CurrentTick() then
                    self:Next()
                else
                    self:NewEventAtStart(self.Schedule.Time)
                end
            else
                self.Schedule=nil
                self:EmptyEvents()
            end
        else
            self:EmptyEvents()
        end
    end
    ,TimerTick=function(self)
        self:Next()
    end
})
TimerScheduler = ZClass(function(self) Scheduler.const(self) end,Scheduler,{
    CurrentTick=function(self)
        return timer.systime()
    end   
    ,NewEventAtStart=function(self,time)
        timer.remove("Scheduler")
        print(time-timer.systime())
        timer.create( "Scheduler", time-timer.systime(), 0,function() 
        if self.Schedule.Time<=self:CurrentTick() then
            self:TimerTick()
        end
        end )
    end
    ,EmptyEvents=function(self)
        timer.stop("Scheduler")
    end
})
TickScheduler = ZClass(function(S)
    Scheduler.const(S)
    S.Schedule=nil
    S.Ticks=0
end,Scheduler,{
    CurrentTick=function(self)
        return self.Ticks
    end   
    ,TimerTick=function(self,tick)
        if self.Schedule~=nil then
            if self.Schedule.Time<=self.Ticks then
                self:Next()
            end
        end
        self.Ticks=self.Ticks+tick
    end
})
RenderScheduler = ZClass(function(S)
    S.TimerListID=0
    S.TimerList={}
    S.TickSchedule=TickScheduler()
    S.TimerSchedule=TimerScheduler()
end,{
    Create=function(self,Tick,MinInterval,MaxInterval,MaxQuota,Priority,Func)
        self.TimerListID=self.TimerListID+1--1  2  3  3        4         5           6        7       8      9
        self.TimerList[self.TimerListID]= {nil,nil,0,Tick,MinInterval,MaxInterval,MaxQuota,Priority,Running,Func,Data}
        self:Start(self.TimerListID)
        return self.TimerListID
    end
    ,Remove=function(self,id)
        self:Stop(id)
        self.TimerList[id]=nil
    end
    ,TimerTick=function(self,id,time)
        local Timer=self.TimerList[id]
        if not Timer[8] then return end
        Timer[3]=timer.systime()+Timer[4]
        Timer[1]=self.TimerSchedule:NewScheduledEvent(time+Timer[5],self.TimerTick,{self,id})
        if Timer[2]~=nil then
            self.TickSchedule:RemoveScheduledEvent(Timer[2])
        end
        Timer[2]=self.TickSchedule:NewScheduledEvent(self.TickSchedule.Ticks+Timer[3],self.TickTick,{self,id})
        Timer[9]()
    end
    ,TickTick=function(self,id,time)
        local Timer=self.TimerList[id]
        if not Timer[8] then return end
        if Timer[3]<timer.systime() then
            if Timer[1]~=nil then
                self.TimerSchedule:RemoveScheduledEvent(Timer[1])
            end
            Timer[3]=timer.systime()+Timer[4]
            Timer[1]=self.TimerSchedule:NewScheduledEvent(timer.systime()+Timer[5],self.TimerTick,{self,id})
        end
        Timer[2]=self.TickSchedule:NewScheduledEvent(time+Timer[3],self.TickTick,{self,id})
    end
    ,Start=function(self,id)
        local Timer=self.TimerList[id]
        Timer[1]=self.TimerSchedule:NewScheduledEvent(timer.systime()+Timer[5],self.TimerTick,{self,id})
        Timer[2]=self.TickSchedule:NewScheduledEvent(self.TickSchedule.Ticks+Timer[3],self.TickTick,{self,id})
        Timer[3]=timer.systime()+Timer[4]
    end
})
--[[
So Basically it's like this On Time/Tick/Job/CPUQuotaCheck it will see if Time/Tick/Job/CPUQuota are all good, if they are then issue the event.

So it uses a global tick scheduler
Hmm, for the sake of efficiency I probably should be using a globalized CPUQuotaChecker tooooo
How would that work anyway? Two inputQuotas, LowMaxQuota and HighMaxQuota HighMaxQuota is First curquota once reached, curquota is LowMaxQuota and once that is reached curquota is HighMaxQuota
The globalized part is simply just OrderedList(high low), cycle through entries until the entries is smaller than current quota.
Issue with using max quota to balance things is... it's stupid actually huh.

Clogging up the system a novel by... ah who cares
So here is a thought, prioritization!
Realtime! 1 100% - It's first on the list and runs no matter what
High Priority! 2 80% - It's second on the list and it will allow something below to run 20% of the time
Mid Priority! 3 70% - It's third on the list and it will allow something below to run 30% of the time
Low Priority! 4 100% - It's forth on the list and there isn't anything below it to run.

In terms of the changing the Change maker, it's simple.
Although it's only half effective in the end really.

Instead of ChangeList[Obj.id][first come first serve]=command
It's PriorityOrderedList<Obj.id,PriorityOrderedList<command>>
PriorityOrderedList is setup like...
class PriorityOrderedList()
    List<Key,[PriorityNum,id]> LocList --Is it odd, I'm starting to miss C++
    List<PriorityNum,RandomList<id,Data>> DataList --Serious stuff here right now, am I insane?
    Const Priorities= [0,0.2,0.3,0]
    void PriorityForEach(Func)
        LocList=List<PriorityNum,count>
        for i,k in DataList do
            for i2=LocList[i]+1,#k then
                k2=k[i2]
                if Priorities[i] ~= 0 and DataList.max()~=i then
                    if Rand() <= Priorities[i] then
                        i3 = DataList.randomchoice(blacklist=range(1,i)+LocList.AllExceptValuesEqualTo(DataList.ListOfCountOfElements()))
                        k2 = DataList[i3][++LocList[i3] ]
                    end
                end
                Func(k2[1],k2[2])
            end
            LocList[i]=#k
        end
    end
    void RegForeach = LocList.Foreach
    void New(priority,id,data)
        id2=DataList[priority].append(data)
        LocList[id]=[priority,id2]
    end
    value Get(id)
        Pri,id=LocList[id]
        return DataList[Pri][id][2]
    end
end
class List()
    

end
class RandomList()
    id append(self,k)
        self[math.rand(1,#self)]
    end
end
]]