local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrApplication = import 'LrApplication'

local myLogger = LrLogger('exportLogger')
myLogger:enable('print')

local function outputToLog(message)
    myLogger:trace(message)
end

local function callDesqueezeBashScript()
    LrTasks.startAsyncTask(function()

        local catalog = LrApplication.activeCatalog()
        local selectedPhotos = catalog:getTargetPhotos()

        if #selectedPhotos == 0 then
            LrDialogs.message("No Photos Selected", "Please select one or more DNG files.", "info")
            return
        end

        local dngPaths = {}
        for _, photo in ipairs(selectedPhotos) do
            local path = photo:getRawMetadata("path")
            if path:lower():match("%.dng$") then
                table.insert(dngPaths, '"' .. path .. '"')
            end
        end

        if #dngPaths == 0 then
            LrDialogs.message("No DNGs Found", "Selected photos do not include any DNG files.", "info")
            return
        end

        local scriptPath = LrPathUtils.child(_PLUGIN.path, 'scripts/desqueezer.sh')

        if not LrFileUtils.exists(scriptPath) then
            LrDialogs.message("Error", "The bash script was not found.", "critical")
            outputToLog("Error: Script not found at " .. scriptPath)
            return
        end

        local command = '/bin/bash "' .. scriptPath .. '" ' .. table.concat(dngPaths, " ")

        outputToLog("Running command: " .. command)

        local result = LrTasks.execute(command)

        if result == 0 then
            LrDialogs.message(
                "Desqueeze Complete",
                "Lightroom metadata was updated by an external tool.\n\nTo apply the changes:\nGo to Metadata → Read Metadata from File.",
                "info"
            )
        else
            LrDialogs.message("Error", "Script execution failed.")
            outputToLog("Script failed with exit code: " .. tostring(result))
        end
    end)
end

callDesqueezeBashScript()
