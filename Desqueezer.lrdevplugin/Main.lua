local LrTasks = import("LrTasks")
local LrDialogs = import("LrDialogs")
local LrLogger = import("LrLogger")
local LrPathUtils = import("LrPathUtils")
local LrFileUtils = import("LrFileUtils")
local LrApplication = import("LrApplication")
local LrFunctionContext = import("LrFunctionContext")
local LrView = import("LrView")
local LrBinding = import("LrBinding")

local myLogger = LrLogger("exportLogger")
myLogger:enable("print")

local function outputToLog(message)
	myLogger:trace(message)
end

local function callDesqueezeBashScript(squeezeFactor, axis)
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
			LrDialogs.message(
				"No DNGs Found",
				"Selected photos do not include any DNG files. Please convert your photos first.",
				"info"
			)
			return
		end

		local scriptPath = LrPathUtils.child(_PLUGIN.path, "scripts/desqueezer.sh")

		if not LrFileUtils.exists(scriptPath) then
			LrDialogs.message("Error", "The bash script was not found.", "critical")
			outputToLog("Error: Script not found at " .. scriptPath)
			return
		end

		local command = '/bin/bash "'
			.. scriptPath
			.. '" '
			.. squeezeFactor
			.. " "
			.. axis
			.. " "
			.. table.concat(dngPaths, " ")

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

local function showCustomDialogWithTransform()
	LrFunctionContext.callWithContext("RadioAndToggle", function(context)
		local f = LrView.osFactory()
		local props = LrBinding.makePropertyTable(context)

		props.selectedRatio = "1.5"
		props.verticalMode = false

		local ratioRow = f:row({
			spacing = f:control_spacing(),
			f:radio_button({
				title = "1.33",
				value = LrView.bind("selectedRatio"),
				checked_value = "1.33",
				group = "ratio",
			}),
			f:radio_button({
				title = "1.5",
				value = LrView.bind("selectedRatio"),
				checked_value = "1.5",
				group = "ratio",
			}),
			f:radio_button({
				title = "1.6",
				value = LrView.bind("selectedRatio"),
				checked_value = "1.6",
				group = "ratio",
			}),
			f:radio_button({
				title = "1.8",
				value = LrView.bind("selectedRatio"),
				checked_value = "1.8",
				group = "ratio",
			}),
			f:radio_button({
				title = "2.0",
				value = LrView.bind("selectedRatio"),
				checked_value = "2.0",
				group = "ratio",
			}),
		})

		local axisToggle = f:checkbox({
			title = "Vertical Anamorphic",
			value = LrView.bind("verticalMode"),
		})

		local axisNote = f:static_text({
			title = "If checked, the photo will get desqueezed along the shorter edge.",
			font = "<system/small>",
			alignment = "left",
		})

		local result = LrDialogs.presentModalDialog({
			title = "Select lens squeeze factor & axis",
			contents = f:column({
				bindToObject = props,
				spacing = f:control_spacing(),

				f:static_text({ title = "Choose squeeze ratio:" }),
				ratioRow,
				f:spacer({ height = 10 }),
				f:static_text({ title = "Choose desqueeze axis:" }),
				axisToggle,
				axisNote,
			}),
		})

		if result == "ok" then
			local axis = props.verticalMode and "Vertical" or "Horizontal"
			callDesqueezeBashScript(props.selectedRatio, props.verticalMode and "Vertical" or "Horizontal")
		end
	end)
end

showCustomDialogWithTransform()
