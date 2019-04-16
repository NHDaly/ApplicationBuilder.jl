if Sys.iswindows()
	include("win-installer.jl")
end
TODO = nothing
function build_app_bundle(juliaprog_main::String;
				resources = String[],
				libraries = String[],
				builddir = "builddir",
				appname = "nothing",
                binary_name = splitext(basename(juliaprog_main))[1],
                verbose = false,
                cpu_target = nothing,
                commandline_app = TODO,
                snoopfile = nothing, autosnoop = TODO,
				create_installer = false)


	# Create build directory
	juliaprog_main = abspath(juliaprog_main)
    builddir = abspath(builddir)
	builddir = joinpath(builddir, appname)
	@info "Building at path $builddir"
	mkpath(builddir)

	core_path = joinpath(builddir, "bin")
	lib_path = joinpath(builddir, "lib")
	res_path = joinpath(builddir, "res")

	# Create resources and libraries dirctories
	mkpath(core_path)
	mkpath(lib_path)
	mkpath(res_path)

	delim = Sys.iswindows() ? '\\' : '/'

	@info "Copying resources:"
	for res in resources
		print("Copying $res...")
		cp(res, joinpath(res_path, split(res, delim)[end]), force = true)
		println("... done.")
	end

	@info "Copying libraries"
	for lib in libraries
		print("Copying $lib...")
		cp(lib, joinpath(lib_path, split(lib, delim)[end]), force = true)
		println("... done.")
	end

    # ----------- Compile a binary ---------------------
    # Compile the binary right into the app.
    println("~~~~~~ Compiling a binary from '$juliaprog_main'... ~~~~~~~")

    PackageCompiler.build_executable(juliaprog_main, binary_name;
            builddir=core_path, verbose=verbose, optimize="3",
            snoopfile=snoopfile, debug="0", cpu_target=cpu_target,
            compiled_modules="yes",
            #cc_flags=`-mmacosx-version-min=10.10 -headerpad_max_install_names`,
            )

    (create_installer && Sys.islinux()) && @warn("Cannot create installer on Linux")

    if Sys.iswindows()
        create_installer && win_installer(builddir, name = appname)
    end

    return 0
end
