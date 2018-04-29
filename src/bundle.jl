function bundle(script::String; 
				resources = String[],
				libraries = String[],
				builddir = "builddir",
				appname = "nothing", 
				create_installer = false)


	# Create build directory
	base_path = dirname(script)
	builddir = joinpath(base_path, builddir, appname)
	println("Building at path $builddir")
	mkpath(builddir)

	core_path = joinpath(builddir, "core")
	lib_path = joinpath(builddir, "lib")
	res_path = joinpath(builddir, "res")

	# Create resources and libraries dirctories
	mkpath(core_path)
	mkpath(lib_path)
	mkpath(res_path)

	delim = is_windows() ? '\\' : '/'

	for res in resources
		cp(res, joinpath(res_path, split(res, delim)[end]), remove_destination = true)
	end

	for lib in libraries
		cp(lib, joinpath(lib_path, split(lib, delim)[end]), remove_destination = true)
	end

	build_executable(script, builddir = core_path)

	create_installer && installer(builddir, name = appname)

end
