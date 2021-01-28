--@include BaseLib.lua
require("BaseLib.lua")



--[[
    After Initialization(perms success,songlistload,stuff)
        
        Run SynchronizationTable.Start()

    GlobalPresists(They are set prior to initialization and presist)={"SongList":SongList,"ObjectTable":Objects,}
    Pointer Example
        Location = {Str/Int,Str/Int,Str/Int,...}
    SynchronizationManager Example
        ModifyStateTables(Pointer,Data,overwrite(?)) -- {"Meow":{"Drat":Fat}} -> ModifyStateTables("Meow",{"Whoah":"Cool"}) -> {"Meow":{"Whoah":"Cool"}}
                                        -- T={"Meow":{"Drat":Fat}} -> ModifyStateTables(T.Meow,{"Whoah":"Cool"}) -> {"Meow":{"Whoah":"Cool"}}
                                        -- {"Meow":{"Drat":Fat}} -> ModifyStateTables({"Meow","Drat"},"Fattry") -> {"Meow":{"Drat":"Fattry"}}
                                        -- {"Meow":{"Drat":Fat}} -> ModifyStateTables({"Meow"},Pointer("Global","Position")) -> {"Meow":Pointer("Global","Position")}
                                        -- Makes changes approrately
                                        -- XXX Checks the past states if it has it already? 
                                        -- XXX Maybe have overwrite as a thing
                                        -- ERROR BAD DESIGN DETECTED OOOWOWOWOWOWOWOWOWOWO For get about overwrite
        --Need to abstractify things, to work functions that make changes instead, like the inputThread>renderThread syncronization in APIGUI? Does this already work with that?
        --What About Pointers eh? What if I point to something that doesn't exist because it hasn't been added yet? If I keep thing temporally organized that shouldn't be an issue?
        FinishedStateTable(Pointer) -- Basically, if a paststate doesn't have any dependancies for a the pointer, it will remove it, and if it's empty it will remove the paststate(??), thats it, it's to save space. 
        CurrentPointerTable = {}

        --Okay change of plans, we are using this model--
        Data=Empty|Info|Pointer
        Entry=Segment(Current), Segment(Past), Data
        Segment = Name, ParentSegment, (Segment,...)|Entry
        
        PastState = ((Requestor,...),(Segment,...))
        PastStates = (PastState,...)
        Current = (Segment,...)
        On Removal
        ---------
        PointerTable= {} --It points to all the changes
        EmptyEntry=This is just a label that represnts to EMPTY this location in the table.
        DataEntry=This represents the data to fill this entry with
        PastState = (NumbRequired(?)/Dependancies(?),PointerTable(?))
            --This is a dependancy sorta deal, based on minimums, so if any dependancy filter accepts an entry then it's good
            --It doesn't store data, like how I thought before, but it simply points to data in the CurrentState table. 
        RequesterGroupsTable={{Filter,{CurrentStateN(?)/PastStateEntry(?),...},OnEntryAdd(Pointer,Data)},...}

    Idea!
        FromSynchronizationTable
            OnEntryAdd() will add to the table
        ToCurGetSynchronizationTable Extends protected SynchronizationManager
            Basically, uh, this depends on metatable functions, but it will make the SyncManagerManager just simply be a set and the get is just the current state stored.
        ToFromSynchronizationTable Extends protected SynchronizationManager
            Basically, uh, this depends on metatable functions, but it will make the SyncManagerManager abstracted, set will be send, and get will recieve.
    
]]