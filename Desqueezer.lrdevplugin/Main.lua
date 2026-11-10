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

		LrDialogs.showBezel("Desqueezing photos… please wait")

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

local function parseRatio(val)
	if val == nil then
		return nil
	end
	local str = tostring(val)
	-- Remove whitespace and replace comma with dot (e.g. "1,25" -> "1.25")
	str = str:gsub("%s+", ""):gsub(",", ".")
	local num = tonumber(str)
	if num and num > 0 then
		return num, str
	end
	return nil, str
end

local function formatFactor(num)
	-- Format up to 4 decimal places without trailing zeroes
	return tostring(tonumber(string.format("%.4f", num)))
end

local function getBaseRatio(props)
	if props.selectedRatio == "custom" then
		return parseRatio(props.customRatio)
	else
		return parseRatio(props.selectedRatio)
	end
end

local function getAdapterRatio(props)
	if props.selectedAdapterRatio == "custom" then
		return parseRatio(props.customAdapterRatio)
	else
		return parseRatio(props.selectedAdapterRatio)
	end
end

local function updateCalculation(props)
	local baseRatio, baseStr = getBaseRatio(props)

	if not props.hasAdapter then
		if baseRatio then
			props.isInputValid = true
			if props.selectedRatio == "custom" then
				props.calculationSummary = "Squeeze factor: " .. baseStr .. "x"
			else
				props.calculationSummary = ""
			end
		else
			props.isInputValid = false
			props.calculationSummary = "Please enter a valid squeeze factor."
		end
		return
	end

	local adapterRatio, adapterStr = getAdapterRatio(props)
	if baseRatio and adapterRatio then
		props.isInputValid = true
		local combined = baseRatio * adapterRatio
		local combinedStr = formatFactor(combined)
		props.calculationSummary =
			string.format("Combined squeeze factor: %s × %s = %sx", baseStr, adapterStr, combinedStr)
	else
		props.isInputValid = false
		props.calculationSummary = "Please enter valid numeric squeeze factors."
	end
end

local function showCustomDialogWithTransform()
	LrFunctionContext.callWithContext("RadioAndToggle", function(context)
		local f = LrView.osFactory()
		local props = LrBinding.makePropertyTable(context)

		props.selectedRatio = "1.5"
		props.customRatio = "1.25"
		props.hasAdapter = false
		props.selectedAdapterRatio = "1.25"
		props.customAdapterRatio = "1.25"
		props.verticalMode = false
		props.calculationSummary = ""
		props.isInputValid = true

		local function onRatioChange()
			updateCalculation(props)
		end

		props:addObserver("selectedRatio", onRatioChange)
		props:addObserver("customRatio", function(properties, key, newValue)
			if properties.selectedRatio ~= "custom" and newValue and newValue ~= "" then
				properties.selectedRatio = "custom"
			end
			updateCalculation(properties)
		end)
		props:addObserver("hasAdapter", onRatioChange)
		props:addObserver("selectedAdapterRatio", onRatioChange)
		props:addObserver("customAdapterRatio", function(properties, key, newValue)
			if properties.selectedAdapterRatio ~= "custom" and newValue and newValue ~= "" then
				properties.selectedAdapterRatio = "custom"
			end
			updateCalculation(properties)
		end)

		updateCalculation(props)

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
			f:radio_button({
				title = "Custom:",
				value = LrView.bind("selectedRatio"),
				checked_value = "custom",
				group = "ratio",
			}),
			f:edit_field({
				value = LrView.bind("customRatio"),
				width_in_chars = 5,
				immediate = true,
			}),
		})

		local adapterToggle = f:checkbox({
			title = "Using an anamorphic adapter / converter",
			value = LrView.bind("hasAdapter"),
		})

		local adapterRatioRow = f:row({
			spacing = f:control_spacing(),
			f:radio_button({
				title = "1.25",
				value = LrView.bind("selectedAdapterRatio"),
				checked_value = "1.25",
				group = "adapterRatio",
			}),
			f:radio_button({
				title = "1.33",
				value = LrView.bind("selectedAdapterRatio"),
				checked_value = "1.33",
				group = "adapterRatio",
			}),
			f:radio_button({
				title = "1.5",
				value = LrView.bind("selectedAdapterRatio"),
				checked_value = "1.5",
				group = "adapterRatio",
			}),
			f:radio_button({
				title = "Custom:",
				value = LrView.bind("selectedAdapterRatio"),
				checked_value = "custom",
				group = "adapterRatio",
			}),
			f:edit_field({
				value = LrView.bind("customAdapterRatio"),
				width_in_chars = 5,
				immediate = true,
			}),
		})

		local adapterSection = f:column({
			visible = LrView.bind("hasAdapter"),
			spacing = f:control_spacing(),
			margin_left = 15,
			f:static_text({ title = "Choose adapter squeeze factor:" }),
			adapterRatioRow,
			f:static_text({
				title = LrView.bind("calculationSummary"),
				font = "<system/small>",
				alignment = "left",
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
				bind_to_object = props,
				spacing = f:control_spacing(),

				f:static_text({ title = "Choose squeeze ratio:" }),
				ratioRow,
				f:spacer({ height = 5 }),
				adapterToggle,
				adapterSection,
				f:spacer({ height = 10 }),
				f:static_text({ title = "Choose desqueeze axis:" }),
				axisToggle,
				axisNote,
			}),
			actionBinding = {
				enabled = LrView.bind({
					key = "isInputValid",
					bind_to_object = props,
				}),
			},
		})

		if result == "ok" then
			local baseRatio, baseStr = getBaseRatio(props)
			if not baseRatio then
				LrDialogs.message(
					"Invalid Squeeze Factor",
					"Please enter a valid positive number for the squeeze ratio.",
					"critical"
				)
				return
			end

			local finalSqueezeStr = (props.selectedRatio == "custom") and baseStr or props.selectedRatio

			if props.hasAdapter then
				local adapterRatio, adapterStr = getAdapterRatio(props)
				if not adapterRatio then
					LrDialogs.message(
						"Invalid Adapter Squeeze Factor",
						"Please enter a valid positive number for the adapter squeeze ratio.",
						"critical"
					)
					return
				end
				finalSqueezeStr = formatFactor(baseRatio * adapterRatio)
			end

			local axis = props.verticalMode and "Vertical" or "Horizontal"
			callDesqueezeBashScript(finalSqueezeStr, axis)
		end
	end)
end

showCustomDialogWithTransform()
