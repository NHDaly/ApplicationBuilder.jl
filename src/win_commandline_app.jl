function get_commandline_sh_script(appname)
    """
    @echo off
    set source_dir=%~dp0
    call "%source_dir%$(appname).exe" %*
    """
end
    
# Build a wrapper app that opens a terminal and runs the provided binary.
# Returns a new script name only if binary_name is already "appname" (to prevent collision).
function build_commandline_app_bundle(builddir, binary_name, appname, verbose)
    println("~~~~~~ Creating commandline-app wrapper script. ~~~~~~~")

    mkpath(builddir)  # Create builddir if it doesn't already exist.

    app_path = joinpath(builddir, appname)
    exe_dir = "bin"  # Put the binaries next to the applet in MacOS.
    script_name = "$(binary_name).bat"
    if binary_name == appname  # Prevent collisions.
        script_name = "$(binary_name)_.bat"
    end
    script_path = joinpath(app_path, exe_dir, script_name)
    mkpath(dirname(script_path))

    verbose && println("    Creating wrapper script: $script_path")
    write(script_path, get_commandline_sh_script(appname))
    run(`chmod u+x $script_path`)

    return script_name
end
