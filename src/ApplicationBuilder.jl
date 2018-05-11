module ApplicationBuilder

using Glob, PackageCompiler

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

end # module

function build_app_bundle(parsed_args)

    jl_main_file = parsed_args["juliaprog_main"]
    binary_name = match(r"([^/.]+)\.jl$", jl_main_file).captures[1]

    APPNAME=parsed_args["appname"]
    APPNAME == nothing && (APPNAME = binary_name)

    builddir = abspath(parsed_args["builddir"])
    bundle_identifier = parsed_args["bundle_identifier"]
    if bundle_identifier == nothing
        bundle_identifier = replace(lowercase("com.$(ENV["USER"]).$APPNAME"), r"\s", "")
        println("  Calculated bundle_identifier: '$bundle_identifier'")
    end
    app_version = parsed_args["app_version"]
    icns_file = parsed_args["icns"]
    user_resources = parsed_args["resource"]
    user_libs = parsed_args["lib"]        # Contents will be copied to Libraries/
    verbose = parsed_args["verbose"]
    certificate = parsed_args["certificate"]
    entitlements_file = parsed_args["entitlements"]

    # ----------- Input sanity checking --------------

    if !isfile(jl_main_file) throw(ArgumentError("Cannot build application. No such file '$jl_main_file'")) end
    # Bundle identifier requirements: https://apple.stackexchange.com/a/238381/52530
    if contains(bundle_identifier, r"\s") throw(ArgumentError("Bundle identifier must not contain whitespace.")) end
    if contains(bundle_identifier, r"[^A-Za-z0-9-.]") throw(ArgumentError("Bundle identifier must contain only alphanumeric characters (A-Z,a-z,0-9), hyphen (-), and period (.).")) end

    # ----------- Initialize App ---------------------
    println("~~~~~~ Creating mac app in \"$builddir/$APPNAME.app\" ~~~~~~~")

    appDir="$builddir/$APPNAME.app/Contents"

    launcherDir="$appDir/MacOS"
    resourcesDir="$appDir/Resources"
    libsDir="$appDir/Libraries"

    mkpath(launcherDir)
    mkpath(resourcesDir)
    mkpath(libsDir)

    # ----------- Copy user libs & assets -------------
    println("~~~~~~ Copying user-specified libraries & resources to bundle... ~~~~~~~")
    # Copy assets and libs early so they're available during compilation.
    #  This is mostly relevant if you have .dylibs in your assets, which the compiler needs to look at.

    run_verbose(verbose, cmd) = (verbose && println("    julia> run($cmd)") ; run(cmd))

    function copy_file_dir_or_glob(pattern, dest)
        if isfile(pattern)
            run_verbose(verbose, `cp -f $pattern $dest/`) # Copy the file to dest
        elseif isdir(pattern)
          run_verbose(verbose, `cp -rf $pattern $dest/`) # Copy the entire *dir* (not its contents) to dest.
        elseif pattern[1] == '/'
            files = glob(pattern[2:end], pattern[1:1])
            run_verbose(verbose, `cp -rf $files $dest/`) # Copy the specified glob pattern to dest.
        elseif !isempty(glob(pattern))
            run_verbose(verbose, `cp -rf $(glob(pattern)) $dest/`) # Copy the specified glob pattern to dest.
        else
            warn("Skipping unknown file '$pattern'!")
        end
    end

    function clean_file_pattern(pattern, errorMsg_fileCmd)
        clean_pattern = strip(pattern)
        if isempty(clean_pattern)
            throw(ArgumentError("ERROR: $errorMsg_fileCmd '$pattern' must not be empty."))
        elseif clean_pattern[1] == '~'
            clean_pattern = homedir() * pattern[2:end]
        end
        return clean_pattern
    end
    println("  Resources:")
    for res in user_resources
        res = clean_file_pattern(res, "-R")
        print("    - $res ...")
        copy_file_dir_or_glob(res, resourcesDir)
        println("............ done")
    end
    println("  Libraries:")
    for lib in user_libs
        lib = clean_file_pattern(lib, "-L")
        print("    - $lib ...")
        copy_file_dir_or_glob(lib, libsDir)
        println("............ done")
    end

    # ----------- Compile a binary ---------------------
    # Compile the binary right into the app.
    println("~~~~~~ Compiling a binary from '$jl_main_file'... ~~~~~~~")

    custom_program_c = "$(Pkg.dir())/ApplicationBuilder/src/program.c"
    # Provide an environment variable telling the code it's being compiled into a mac bundle.
    withenv("LD_LIBRARY_PATH"=>"$libsDir:$libsDir/julia",
            "COMPILING_APPLE_BUNDLE"=>"true") do
        verbose && println("  PackageCompiler.static_julia(...)")
        # Compile executable and copy julia libs to $launcherDir.
        PackageCompiler.static_julia(jl_main_file;
                cprog=custom_program_c, builddir=launcherDir, verbose=verbose,
                autodeps=true, executable=true, julialibs=true, optimize="3",
                debug="0", cpu_target="x86-64",
                cc_flags="-mmacosx-version-min=10.10")
    end

    for b in ["$launcherDir/$binary_name", "$launcherDir/$binary_name.dylib"]
        run_verbose(verbose, `install_name_tool -add_rpath "@executable_path/../Frameworks/" $b`)
        run_verbose(verbose, `install_name_tool -add_rpath "@executable_path/../Libraries/" $b`)
    end

    # In order to pass Apple's GateKeeper, the App must not reference any external Julia libs.
    for binary_file in glob("*", launcherDir)
        try
            #  an example output line from otool: "         path /Applications/Dev Apps/Julia-0.6.app/Contents/Resources/julia/lib (offset 12)"
            external_julia_deps = readlines(pipeline(`otool -l $binary_file`, `grep '/julia'`,
                                                    `sed 's/\s*path//'`, # remove leading "  path"
                                                    `sed 's/(.*)$//'`)) # remove trailing parens
            for line in external_julia_deps
                path = strip(line)
                run_verbose(verbose, `install_name_tool -delete_rpath "$path" $binary_file`)
            end
        end
        # Also need to strip any non-x86 architectures to make Apple happy.
        # (It looks like this only affects libgcc_s.1.dylib.)
        try
            if success(pipeline(`file $binary_file`, `grep 'i386'`))
                run_verbose(verbose, `lipo $binary_file -thin x86_64 -output $binary_file`)
            end
        end
    end

    # ---------- Create Info.plist to tell it where to find stuff! ---------
    # This lets you have a different app name from your jl_main_file.
    println("~~~~~~ Generating 'Info.plist' for '$bundle_identifier'... ~~~~~~~")

    info_plist() = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        	<key>CFBundleAllowMixedLocalizations</key>
        	<true/>
        	<key>CFBundleDevelopmentRegion</key>
        	<string>en</string>
        	<key>CFBundleDisplayName</key>
        	<string>$APPNAME</string>
        	<key>CFBundleExecutable</key>
        	<string>$binary_name</string>
        	<key>CFBundleIconFile</key>
        	<string>$APPNAME.icns</string>
        	<key>CFBundleIdentifier</key>
        	<string>$bundle_identifier</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
        	<key>CFBundleName</key>
        	<string>$APPNAME</string>
        	<key>CFBundlePackageType</key>
        	<string>APPL</string>
        	<key>CFBundleShortVersionString</key>
        	<string>$app_version</string>
        	<key>CFBundleVersion</key>
        	<string>$app_version</string>
        	<key>NSHighResolutionCapable</key>
            <string>YES</string>
        	<key>LSMinimumSystemVersionByArchitecture</key>
        	<dict>
        		<key>x86_64</key>
        		<string>10.10</string>
        	</dict>
        	<key>LSRequiresCarbon</key>
        	<true/>
        	<key>NSHumanReadableCopyright</key>
        	<string>© 2018 $bundle_identifier </string>
        </dict>
        </plist>
        """

    verbose && println(info_plist())
    write("$appDir/Info.plist", info_plist());

    # Copy Julia icons
    julia_app_resources_dir() = joinpath(Base.JULIA_HOME, "..","..")
    if (icns_file == nothing)
        icns_file = joinpath(julia_app_resources_dir(),"julia.icns")
        verbose && println("Attempting to copy default icons from Julia.app: $icns_file")
    end
    if isfile(icns_file)
        cp(icns_file, "$resourcesDir/$APPNAME.icns", remove_destination=true);
    else
        warn("Skipping nonexistent icons file: '$icns_file'")
    end

    # --------------- CLEAN UP before distributing ---------------
    println("~~~~~~ Cleaning up temporary files... ~~~~~~~")

    # Delete the tmp build files
    function delete_if_present(file, path)
        files = glob(file, path)
        if !isempty(files) run(`rm -r $(files)`) end
    end
    delete_if_present("*.ji",launcherDir)
    delete_if_present("*.o",launcherDir)

    # Remove debug .dylib libraries and any precompiled .ji's
    delete_if_present("*.dSYM",libsDir)
    delete_if_present("*.dSYM","$libsDir/julia")
    delete_if_present("*.backup","$libsDir/julia")
    delete_if_present("*.ji","$libsDir/julia")
    delete_if_present("*.o","$libsDir/julia")

    println("~~~~~~ Signing the binary and all libraries ~~~~~~~")
    if certificate != nothing
        sign_application_libs(launcherDir, certificate)
        if entitlements_file != nothing
            set_entitlements("$launcherDir/$binary_name", certificate, entitlements_file)
        end
    end

    println("~~~~~~ Done building '$builddir/$APPNAME.app'! ~~~~~~~")
end

end # module
