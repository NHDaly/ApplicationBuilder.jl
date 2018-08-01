function get_commandline_applescript(exe_dir, executable_path)
    """
    set RootPath to POSIX path of (path to me)
    tell application id "com.apple.terminal"
      do script ("exec '" & RootPath & "$exe_dir/$executable_path'")
      activate
    end tell
    """
end

# Build a wrapper app that opens a terminal and runs the provided binary.
# Returns a new applet name only if binary_name is already "applet" (to prevent collision).
function build_commandline_app_bundle(builddir, binary_name, appname, verbose)
    println("~~~~~~ Creating commandline-app wrapper applet. ~~~~~~~")

    mkpath(builddir)  # Create builddir if it doesn't already exist.
    applescript_file = "$builddir/build_$appname.applescript"
    exe_dir = "Contents/MacOS"  # Put the binaries next to the applet in MacOS.
    verbose && println("    Creating Applescript wrapper file: $applescript_file")
    write(applescript_file, get_commandline_applescript(exe_dir, binary_name))

    app_path = "$builddir/$appname.app"
    run(`osacompile -o $app_path $applescript_file`)
    applet_name = "applet"
    if binary_name == applet_name  # Prevent collisions.
        applet_name = "applet_wrapper"
        Compat.mv("$app_path/Contents/MacOS/applet", "$app_path/Contents/MacOS/$applet_name", force=true)
    end
    # Remove unneeded applet files it creates.
    rm("$app_path/Contents/Resources/applet.icns")

    # Cleaning up temporary file:
    verbose && println("    Cleaning up temporary Applescript file: $applescript_file")
    rm(applescript_file)

    return applet_name
end
