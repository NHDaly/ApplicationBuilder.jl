function get_commandline_sh_script(exe_dir, executable_path)
"""
#!/bin/sh

osascript -e "
set RootPath to POSIX path of (path to me)
tell application id \\\"com.apple.terminal\\\"
    do script (\\\"exec '\\\" & RootPath & \\\"$exe_dir/$executable_path'\\\")
    activate
end tell
"
"""
end

# Build a wrapper app that opens a terminal and runs the provided binary.
# Returns a new applet name only if binary_name is already "applet" (to prevent collision).
function build_commandline_app_bundle(builddir, binary_name, appname, verbose)
    println("~~~~~~ Creating commandline-app wrapper applet. ~~~~~~~")

    mkpath(builddir)  # Create builddir if it doesn't already exist.

    app_path = "$builddir/$appname.app"
    exe_dir = "Contents/MacOS"  # Put the binaries next to the applet in MacOS.
    applet_name = "applet"
    if binary_name == applet_name  # Prevent collisions.
        applet_name = "applet_wrapper"
    end
    applet_path = "$app_path/$exe_dir/$applet_name"
    mkpath(dirname(applet_path))

    verbose && println("    Creating wrapper script: $applet_path")
    write(applet_path, get_commandline_sh_script(exe_dir, binary_name))
    run(`chmod +x $applet_path`)

    return applet_name
end
