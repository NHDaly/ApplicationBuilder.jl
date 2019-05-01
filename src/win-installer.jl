JULIA_HOME = ENV["JULIA_HOME"]
LICENSE_PATH = joinpath(abspath(JULIA_HOME, ".."), "License.md")

function win_installer(builddir; name = "nothing",
				license = LICENSE_PATH)

	# check = success(`makensis`)
	# !check && throw(ErrorException("NSIS not found in path. Exiting."))

	nsis_commands = """
	# set the name of the installer
	Outfile "$(name)_Installer.exe"

	# Default install directory
	InstallDir "\$LOCALAPPDATA"

	Page license
	Page directory
	Page instfiles

	LicenseData "$license"

	# create a default section.
	Section "Install"

		SetOutPath "$(joinpath("\$INSTDIR", name))"
		File /nonfatal /a /r "$builddir"

		CreateShortcut "$(joinpath("\$INSTDIR", name, "$name.lnk"))" "$(joinpath(builddir, "core", "blink.exe"))"

	SectionEnd
	"""

	@info "Creating installer at $builddir"
	nsis_file = joinpath(abspath(builddir, ".."), "$name.nsi")
	open(nsis_file, "w") do f
		write(f, nsis_commands)
	end
	run(`makensis $nsis_file`)

	@info "Created installer successfully."

end
