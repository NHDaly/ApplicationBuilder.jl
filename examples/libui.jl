using Libui


using Libui

#const progressbar::Ptr{uiProgressBar} = C_NULL
#const spinbox::Ptr{uiProgressBar} = C_NULL
#const slider::Ptr{uiProgressBar} = C_NULL
#

function controlgallery()
	o = Libui.uiInitOptions(0)
	err = uiInit(Ref(o))

	menu = uiNewMenu("File")
	item = uiMenuAppendItem(menu, "Open")
	uiMenuItemOnClicked(item, cfunction(openClicked, Nothing, (Ptr{uiWindow},)), C_NULL)
	item = uiMenuAppendItem(menu, "Save")
	uiMenuItemOnClicked(item, cfunction(saveClicked, Nothing, (Ptr{uiWindow},)), C_NULL)
	item = uiMenuAppendQuitItem(menu)
	uiOnShouldQuit(cfunction(shouldQuit, Ptr{Nothing}, (Ptr{uiWindow},)), C_NULL)

	menu = uiNewMenu("Edit")
	item = uiMenuAppendCheckItem(menu, "Checkable Item")
	uiMenuAppendSeparator(menu)
	item = uiMenuAppendItem(menu, "Disabled Item")
	uiMenuItemDisable(item)
	item = uiMenuAppendPreferencesItem(menu)

	menu = uiNewMenu("Help")
	item = uiMenuAppendItem(menu, "Help")
	item = uiMenuAppendAboutItem(menu)

	mainwin = uiNewWindow("libui Control Gallery", 640, 480, 1)
	uiWindowSetMargined(mainwin, 1)
	uiWindowOnClosing(mainwin, cfunction(onClosing, Ptr{Nothing}, (Ptr{uiWindow},)), C_NULL)

	box = uiNewVerticalBox()
	uiBoxSetPadded(box, 1)
	uiWindowSetChild(mainwin, convert(Ptr{uiControl}, box))

	hbox = uiNewHorizontalBox()
	uiBoxSetPadded(hbox, 1)
	uiBoxAppend(box, convert(Ptr{uiControl}, hbox), 1)

	group = uiNewGroup("Basic Controls")
	uiGroupSetMargined(group, 1)
	uiBoxAppend(hbox, uiControl_(group), 0)

	inner = uiNewVerticalBox()
	uiBoxSetPadded(inner, 1)
	uiGroupSetChild(group, uiControl_(inner))

	uiBoxAppend(inner, uiControl_(uiNewButton("Button")), 0)
	uiBoxAppend(inner, uiControl_(uiNewCheckbox("Checkbox")), 0)
	entry = uiNewEntry()
	uiEntrySetText(entry, "Entry")
	uiBoxAppend(inner, uiControl_(entry), 0)
	uiBoxAppend(inner, uiControl_(uiNewLabel("Label")), 0)

	uiBoxAppend(inner, uiControl_(uiNewHorizontalSeparator()), 0)
	uiBoxAppend(inner, uiControl_(uiNewDatePicker()), 0)
	uiBoxAppend(inner, uiControl_(uiNewTimePicker()), 0)
	uiBoxAppend(inner, uiControl_(uiNewDateTimePicker()), 0)
	uiBoxAppend(inner, uiControl_(uiNewFontButton()), 0)
	uiBoxAppend(inner, uiControl_(uiNewColorButton()), 0)

	inner2 = uiNewVerticalBox()
	uiBoxSetPadded(inner2, 1)
	uiBoxAppend(hbox, uiControl_(inner2), 1)

	group = uiNewGroup("Numbers")
	uiGroupSetMargined(group, 1)
	uiBoxAppend(inner2, uiControl_(group), 0)

	inner = uiNewVerticalBox()
	uiBoxSetPadded(inner, 1)
	uiGroupSetChild(group, uiControl_(inner))

	uiSpinboxOnChanged(spinbox, cfunction(onSpinboxChanged, Nothing, (Ptr{uiSpinbox},)), C_NULL)
	uiBoxAppend(inner, uiControl_(spinbox), 0)

	uiSliderOnChanged(slider, cfunction(onSliderChanged, Nothing, (Ptr{uiSlider},)), C_NULL)
	uiBoxAppend(inner, uiControl_(slider), 0)

	uiBoxAppend(inner, uiControl_(progressbar), 0)

	group = uiNewGroup("Lists")
	uiGroupSetMargined(group, 1)
	uiBoxAppend(inner2, uiControl_(group), 0)

	inner = uiNewVerticalBox()
	uiBoxSetPadded(inner, 1)
	uiGroupSetChild(group, uiControl_(inner))

	cbox = uiNewCombobox()
	uiComboboxAppend(cbox, "Combobox Item 1")
	uiComboboxAppend(cbox, "Combobox Item 2")
	uiComboboxAppend(cbox, "Combobox Item 3")
	uiBoxAppend(inner, uiControl_(cbox), 0)

	ecbox = uiNewEditableCombobox()
	uiEditableComboboxAppend(ecbox, "Editable Item 1")
	uiEditableComboboxAppend(ecbox, "Editable Item 2")
	uiEditableComboboxAppend(ecbox, "Editable Item 3")
	uiBoxAppend(inner, uiControl_(ecbox), 0)

	rb = uiNewRadioButtons()
	uiRadioButtonsAppend(rb, "Radio Button 1")
	uiRadioButtonsAppend(rb, "Radio Button 2")
	uiRadioButtonsAppend(rb, "Radio Button 3")
	uiBoxAppend(inner, uiControl_(rb), 1)

	tab = uiNewTab()
	uiTabAppend(tab, "Page 1", uiControl_(uiNewHorizontalBox()))
	uiTabAppend(tab, "Page 2", uiControl_(uiNewHorizontalBox()))
	uiTabAppend(tab, "Page 3", uiControl_(uiNewHorizontalBox()))
	uiBoxAppend(inner2, uiControl_(tab), 1)

	uiControlShow(convert(Ptr{uiControl}, mainwin))
	uiMain()
	uiUninit()
end


# ---------------------------------------------------------------------------------------------
function onSpinboxChanged(spinbox::Ptr{uiSpinbox})
	update(uiSpinboxValue(spinbox))
	return
end

# ---------------------------------------------------------------------------------------------
function onSliderChanged(slider::Ptr{uiSlider})
	update(uiSliderValue(slider))
	return nothing
end

# ---------------------------------------------------------------------------------------------
function openClicked(mainwin::Ptr{uiWindow})
	filename = uiOpenFile(mainwin)
	if (filename == C_NULL)
		uiMsgBoxError(mainwin, "No file selected", "Don't be alarmed!")
		return
	end
	uiMsgBox(mainwin, "File selected", filename)
	uiFreeText(filename)
	return nothing
end

# ---------------------------------------------------------------------------------------------
function saveClicked(mainwin::Ptr{uiWindow})
	filename = uiSaveFile(mainwin)
	if (filename == C_NULL)
		uiMsgBoxError(mainwin, "No file selected", "Don't be alarmed!")
		return
	end
	uiMsgBox(mainwin, "File selected (don't worry, it's still there)", filename)
	uiFreeText(filename)
end

# ---------------------------------------------------------------------------------------------
function update(value::Integer)
	uiSpinboxSetValue(spinbox, value)
	uiSliderSetValue(slider, value)
	uiProgressBarSetValue(progressbar, value)
end



Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    global progressbar = uiNewProgressBar()
    global spinbox = uiNewSpinbox(0, 100)
    global slider = uiNewSlider(0, 100)


    controlgallery()

    return 0
end
