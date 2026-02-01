local Addon, ns = ...
if (not ns.IsRetail or not EditModeManagerFrame) then
	return
end

EditModeManagerFrame:UnregisterAllEvents()
EditModeManagerFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")

hooksecurefunc(EditModeManagerFrame, "EnterEditMode", HideUIPanel)
