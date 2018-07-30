function get_commandline_applescript(exe_dir, executable_path)
    """
    set RootPath to POSIX path of (path to me)
    tell application id "com.apple.terminal"
      do script ("exec '" & RootPath & "$exe_dir/$executable_path'")
      activate
    end tell
    """
end

function build_commandline_app_bundle(builddir, binary_name, appname, verbose)
    println("~~~~~~ Creating commandline-app wrapper applet. ~~~~~~~")

    mkpath(builddir)  # Create builddir if it doesn't already exist.
    applescript_file = "$builddir/build_$appname.applescript"
    exe_dir = "Contents/app"
    verbose && println("    Creating Applescript wrapper file: $applescript_file")
    write(applescript_file, get_commandline_applescript(exe_dir, binary_name))

    app_path = "$builddir/$appname.app"
    run(`osacompile -o $app_path $applescript_file`)
    mv("$app_path/Contents/MacOS/applet", "$app_path/Contents/MacOS/$binary_name")

    # Cleaning up temporary file:
    verbose && println("    Cleaning up temporary Applescript file: $applescript_file")
    rm(applescript_file)

    return joinpath(app_path,exe_dir)
end
