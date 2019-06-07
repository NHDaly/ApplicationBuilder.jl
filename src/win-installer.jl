JULIA_HOME = get(ENV, "JULIA_HOME", "")
LICENSE_PATH = joinpath(abspath(JULIA_HOME, ".."), "License.md")

baremodule SetupCompilers
	iss="iss"
	nsis="nsis"
end

function win_installer(builddir; name = "nothing",
				license = LICENSE_PATH, installer_compiler=SetupCompilers.iss)

	# check = success(`makensis`)
	# !check && throw(ErrorException("NSIS not found in path. Exiting."))

	commands = if installer_compiler == SetupCompilers.nsis 
		"""
		# set the name of the installer
		Name "$(name)"
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
	elseif installer_compiler == SetupCompilers.iss
		"""
		; $name InnoSetup Compiler 
		; This software is property of Gabriel Freire. All Rights reserved.
		; Copyright 2019
		; Requires InnoSetup Latest (5.5 tested)
		; This script compiles the setup file for $name in the SETUP folder
	
		#define MyAppName "$name"
		#define MyAppVersion "1.0"
		#define ApplicationVersion GetStringFileInfo("$(joinpath(builddir, name, "bin", "$(name).exe"))", "FileVersion")
		#define MyAppExeName "$name.exe"
	
	
		[Setup]
		AppId={{802D0907-22CE-4E43-8FAB-017F687159C4}
		AppName={#MyAppName}
		AppVersion={#ApplicationVersion}
		AppVerName={#MyAppName}
		VersionInfoVersion={#ApplicationVersion}
		DefaultDirName={pf}\\{#MyAppName}
		DisableDirPage=yes
		DisableProgramGroupPage=yes
		OutputDir=.\\
		OutputBaseFilename=$(name * "Setup")
		UninstallDisplayIcon={app}\\{#MyAppExeName}
		Compression=lzma
		SolidCompression=yes
		; Tell Windows Explorer to reload the environment
		ChangesEnvironment=yes
	
		[CustomMessages]
		AppAddPath=Add application directory to your environmental path (required)
	
		[Languages]
		Name: "english"; MessagesFile: "compiler:Default.isl"
	
		[Tasks]
		Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
		Name: modifypath; Description:{cm:AppAddPath}; Flags: unchecked
	
		[Registry]
		Root: HKCU; Subkey: "Environment"; ValueType:expandsz; ValueName: "Path"; ValueData: "{olddata};{app}\\bin"; Flags: preservestringtype
		
		[Files]
		Source: "$(joinpath(builddir, name, "bin") * "\\*")"; DestDir: "{app}\\bin"; Flags: ignoreversion
		Source: "$(joinpath(builddir, name, "res") * "\\*")"; DestDir: "{app}\\res"; Flags: ignoreversion
		Source: "$(joinpath(builddir, name, "lib") * "\\*")"; DestDir: "{app}\\lib"; Flags: ignoreversion
	
		[Code]
	
		var CancelWithoutPrompt: boolean;
	
		function InitializeSetup(): Boolean;
		begin
		CancelWithoutPrompt := false;
		result := true;
		Log('{#ApplicationVersion}');
		end;
	
		procedure CancelButtonClick(CurPageID: Integer; var Cancel, Confirm: Boolean);
		begin
		if CurPageID=wpInstalling then
			Confirm := not CancelWithoutPrompt;
		end;
	
		[Icons]
		Name: "{commonprograms}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"
		Name: "{commondesktop}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"; Tasks: desktopicon
		Name: "{commonstartup}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"; 
		"""
	else
		throw(ArgumentError("Unknown compiler: $installer_compiler"))
	end

	ext = if installer_compiler == SetupCompilers.nsis
		"nsi"
	elseif installer_compiler == SetupCompilers.iss
		"iss"
	end

	@info "Creating installer at $builddir"
	compiler_file = joinpath(abspath(builddir, ".."), "$name.$ext")
	open(compiler_file, "w") do f
		write(f, commands)
	end
	# run(`makensis $nsis_file`)

	@info "Created installer successfully."

end
