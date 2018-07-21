module ApplicationBuilder

# This package provides two separate modules, one for building applications, and
# one that provides utilities for the julia code to support being built as an
# application bundle. They are separated to isolate the application code from
# the build-time functions.
#
# User application code should use the following module:
#   using ApplicationBuilder.App
#
# Build-script code should use the following module:
#   using ApplicationBuilder; using BuildApp;

push!(LOAD_PATH, @__DIR__) # Expose all modules in this package.

"""
    ApplicationBuilder.App

Provides utilities for applications built by this package.

Provides `change_dir_if_bundle()`, which should be called
by bundled applications before accessing any resources from the filesystem.
"""
module App

@static if is_apple()
    if get(ENV, "COMPILING_APPLE_BUNDLE", "false") == "true"
        function change_dir_if_bundle()
            full_binary_name = PROGRAM_FILE  # PROGRAM_FILE is set manually in program.c
            if is_apple()
                # On Apple devices, if this is running inside a .app bundle, it starts
                # us with pwd="/". Change dir to the Resources dir instead.
                # Can find the code's path from what the full_binary_name ends in.
                m = match(r".app/Contents/MacOS/[^/]+$", full_binary_name)
                if m != nothing
                    resources_dir = joinpath(dirname(dirname(full_binary_name)), "Resources")
                    cd(resources_dir)
                end
                println("change_dir_if_bundle(): Changed to new pwd: $(pwd())")
                return pwd()
            end
        end
    else
        function change_dir_if_bundle()
            println("change_dir_if_bundle(): Did not change pwd: $(pwd())")
            return pwd()
        end
    end
end

@static if is_linux() || is_windows()

	function change_dir_if_bundle()
		binary_path = split(string(Base.julia_cmd()), ' ')[1][2:end]
		newpath = dirname(dirname(binary_path))
		cd(newpath)
		println("New pwd = $(pwd())")
	end

end

@static if is_windows()
    include("installer.jl")
end


end # module

end # module
