function installer(builddir; name = "nothing", 
					license = joinpath(Sys.BINDIR, "..", "License.md"),
					icon = download("https://github.com/JuliaLang/julia/blob/master/contrib/windows/julia.ico", 
						joinpath(tempdir(), "julia.ico")))
	# check = success(`makensis`) 
	# !check && throw(ErrorException("NSIS not found in path. Exiting."))

	nsis_commands = """
	# Modern UI 
	!include "MUI2.nsh"

	# set the name of the installer
	Name "$(name)"
	Outfile "$(name)-x64.exe" 

	# Default install directory
	InstallDir "\$LOCALAPPDATA"

	!insertmacro MUI_PAGE_WELCOME
	!insertmacro MUI_PAGE_LICENSE "$(license)"
  	# !insertmacro MUI_PAGE_COMPONENTS
  	!insertmacro MUI_PAGE_DIRECTORY
  	!insertmacro MUI_PAGE_INSTFILES
  	!insertmacro MUI_PAGE_FINISH

  	!insertmacro MUI_LANGUAGE "English"

	# create a default section.
	Section "Install"

		SetOutPath "$(joinpath("\$INSTDIR", name))"
		File /nonfatal /a /r "$builddir"

		CreateShortcut "$(joinpath("\$INSTDIR", name, "$(name).lnk"))" "$(joinpath("\$INSTDIR", name, name, "core", "$(name).exe"))" "" "$(icon)" 0
		CreateShortcut "$(joinpath("\$DESKTOP", "$(name).lnk"))" "$(joinpath("\$INSTDIR", name, name, "core", "$(name).exe"))" "" "$(icon)" 0


	SectionEnd
	"""

	@info "Creating installer at $builddir"
	nsis_file = joinpath(builddir, "..", "$name.nsi")
	open(nsis_file, "w") do f
		write(f, nsis_commands)    
	end
	run(`makensis $nsis_file`)

	@info "Created installer successfully."

end
