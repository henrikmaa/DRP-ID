playersJob = {}
---------------------------------------------------------------------------
-- Job Core Events (DO NOT TOUCH!)
---------------------------------------------------------------------------
RegisterServerEvent("DRP_JobCore:StartUp")
AddEventHandler("DRP_JobCore:StartUp", function()
    local src = source
    local otherJobData
    local character = exports["drp_id"]:GetCharacterData(src)
    local characterJob = exports["externalsql"]:AsyncQuery({
		query = "SELECT job FROM `characters` WHERE `id` = :character_id",
		data = {character_id = character.charid}
    })
    local job = string.upper(characterJob["data"][1].job)
    local jobLabel = GetJobLabels(job)
    if DoesJobExist(job) then
        if jobLabel == "Police" or jobLabel == "Sheriff" or jobLabel == "State" then
            local jobData = exports["externalsql"]:AsyncQuery({
                query = "SELECT * FROM police WHERE `char_id` = :charid",
                data = {
                    charid = character.charid
                }
            })
            otherJobData = {rank = jobData.data[1].rank, department = jobData.data[1].department}
        else
            otherJobData = false
        end
        table.insert(playersJob, {source = src, job = job, jobLabel = jobLabel, otherJobData = otherJobData})
    else
        print("job does not exist, please refer to the config to see if you have defined this job correctly!")
    end
end)
---------------------------------------------------------------------------
-- Job Core Events (DO NOT TOUCH!)
---------------------------------------------------------------------------
RegisterServerEvent("DRP_JobCore:ReloadTable")
AddEventHandler("DRP_JobCore:ReloadTable", function(source)
    local src = source
    local character = exports["drp_id"]:GetCharacterData(src)
    local characterJob = exports["externalsql"]:AsyncQuery({
		query = "SELECT job FROM `characters` WHERE `id` = :character_id",
		data = {character_id = character.charid}
    })
    local job = string.upper(characterJob["data"][1].job)
    local jobLabel = GetJobLabels(job)
    if DoesJobExist(job) then
        if jobLabel == "Police" or jobLabel == "Sheriff" or jobLabel == "State" then
            local jobData = exports["externalsql"]:AsyncQuery({
                query = "SELECT * FROM police WHERE `char_id` = :charid",
                data = {
                    charid = character.charid
                }
            })
            otherJobData = {rank = jobData.data[1].rank, department = jobData.data[1].department}
        else
            otherJobData = false
        end
        table.insert(playersJob, {source = src, job = job, jobLabel = jobLabel, otherJobData = otherJobData})
        Wait(2000)
        TriggerClientEvent("DRP_Core:Success", src, "Job Manager", tostring("We have managed to get this information, you are a "..job), 2500, false, "leftCenter")
    else
        print("job does not exist, please refer to the config to see if you have defined this job correctly!")
    end
end)
---------------------------------------------------------------------------
-- Check if player left, then remove their data in the table
---------------------------------------------------------------------------
AddEventHandler("playerDropped", function()
    local src = source
    for a = 1, #playersJob do
        if playersJob[a].source == src then
            table.remove(playersJob, a)
        end
    end
end)
---------------------------------------------------------------------------
-- Job Command
---------------------------------------------------------------------------
RegisterCommand("job", function(source, args, raw)
    local src = source
    local myJob = GetPlayerJob(src)
    if myJob ~= false then
        TriggerClientEvent("DRP_Core:Info", src, "Job Manager", tostring("Your job is "..myJob.jobLabel..""), 2500, false, "leftCenter")
    else
        TriggerClientEvent("DRP_Core:Error", src, "Job Manager", tostring("Please Wait While Job Offices Gets Your Data..."), 2500, false, "leftCenter")
        TriggerEvent("DRP_JobCore:ReloadTable", src)
    end
end, false)
---------------------------------------------------------------------------
-- Add Salary To Character
---------------------------------------------------------------------------
RegisterServerEvent("DRP_JobCore:Salary")
AddEventHandler("DRP_JobCore:Salary", function()
    local src = source
    local character = exports["drp_id"]:GetCharacterData(src)
    TriggerEvent("DRP_Bank:AddBankMoney", character, JobsCoreConfig.SalaryAmount)
end)
---------------------------------------------------------------------------
-- Get Players Job and Info about that job Function. Usage exports:["drp_jobcore"]:GetPlayerJob(source)
---------------------------------------------------------------------------
function GetPlayerJob(player)
    for a = 1, #playersJob do
        if playersJob[a] ~= nil then
            if playersJob[a].source == player then
                return playersJob[a]
            end
        else
            return false
        end
    end
    return false
end
exports("GetPlayerJob", GetPlayerJob)
---------------------------------------------------------------------------
-- This is the main export usage exports:["drp_jobcore"]:RequestJobChange(source, job, jobLabel, otherData)
---------------------------------------------------------------------------
function RequestJobChange(source, job, label, otherData) -- USE THIS ALL THE TIME
    local currentJob = GetPlayerJob(source)
    local label = label
    if currentJob.job == job then
        TriggerClientEvent("DRP_Core:Error", source, "Job Manager", tostring("You're already working"), 2500, false, "leftCenter")
    else
        if not job and not label and not otherData then
            if currentJob.job == "UNEMPLOYED" then
                TriggerClientEvent("DRP_Core:Error", source, "Job Manager", tostring("You're already not working"), 2500, false, "leftCenter")
            else
                SetPlayerJob(source, "UNEMPLOYED", "Unemployed", false)
                TriggerClientEvent("DRP_Core:Info", source, "Job Manager", tostring("You are now not working"), 2500, false, "leftCenter")
                return true
            end
        else
            if DoesJobExist(job) then
                if otherData ~= false then
                    SetPlayerJob(source, job, label, otherData)
                    return true
                else
                    SetPlayerJob(source, job, label, false)
                    TriggerClientEvent("DRP_Core:Info", source, "Job Manager", tostring("You are now "..label), 2500, false, "leftCenter")
                    return true
                end
            else
                print("Job Does Not Exist, Make sure your Server Developer has added job name into drp_jobcore/config.lua")
            end
        end
    end
end
---------------------------------------------------------------------------
-- Check Job Info if is exisits Usage exports:["drp_jobcore"]:DoesJobExist(job)
---------------------------------------------------------------------------
function DoesJobExist(job)
    for a = 1, #JobsCoreConfig.Jobs do
        if JobsCoreConfig.Jobs[a] == job then
            return true
        end
    end
    return false
end
---------------------------------------------------------------------------
-- Get Labels from Job Usage exports["drp_jobcore"]:GetJobLabels(job)
---------------------------------------------------------------------------
function GetJobLabels(job)
    return JobsCoreConfig.StaticJobLabels[job]
end
exports("GetJobLabels", GetJobLabels)
---------------------------------------------------------------------------
-- Set Player Job Function this is NOT an export. Should not be triggered on its own, request job does that all for you
---------------------------------------------------------------------------
function SetPlayerJob(player, job, label, otherData)
    local job = job
    local character = exports["drp_id"]:GetCharacterData(player)
    -- Handling the job in the database, this will update the job which is all it needs as the other functions do the rest
    exports["externalsql"]:AsyncQuery({
        query = "UPDATE `characters` SET `job` = :job WHERE `id` = :charid",
        data = {job = job, charid = character.charid}
    })
    -- Handling the table data via a loop
    for a = 1, #playersJob do
        if playersJob[a].source == player then
            playersJob[a].job = job
            playersJob[a].jobLabel = label
            playersJob[a].otherJobData = otherData
            break
        end
    end
end