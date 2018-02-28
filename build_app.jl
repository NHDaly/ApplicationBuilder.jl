using Glob, ArgParse

s = ArgParseSettings()

@add_arg_table s begin
    "juliaprog_main"
        arg_type = String
        required = true
        help = "Julia program to compile -- must define julia_main()"
    "appname"
        arg_type = String
        default = nothing
        help = "name to call the generated .app bundle"
    "builddir"
        arg_type = String
        default = "builddir"
        help = "directory used for building, either absolute or relative to the Julia program directory"
    "--verbose", "-v"
        action = :store_true
        help = "increase verbosity"
    "--resource", "-R"
        arg_type = String
        action = :append_arg  # Can specify multiple
        default = nothing
        metavar = "<resource>"
        help = """specify files or directories to be copied to
                  MyApp.app/Contents/Resources/. This should be done for all
                  resources that your app will need to have available at
                  runtime. Can be repeated."""
    "--lib", "-L"
        arg_type = String
        action = :append_arg  # Can specify multiple
        default = nothing
        metavar = "<file>"
        help = """specify user library files to be copied to
                  MyApp.app/Contents/Libraries/. This should be done for all
                  libraries that your app will need to reference at
                  runtime. Can be repeated."""
    "--icns"
        arg_type = String
        default = nothing
        metavar = "<file>"
        help = ".icns file to be used as the app's icon"
end
s.epilog = """
    examples:\n
    \ua0\ua0 # Build HelloApp.app from hello.jl\n
    \ua0\ua0 build.jl hello.jl HelloApp\n
    \ua0\ua0 # Build MyGame, and copy in imgs/, mus.wav and all files in libs/\n
    \ua0\ua0 build.jl -R imgs -R mus.wav -L lib/* main.jl MyGame
    """

parsed_args = parse_args(ARGS, s)

APPNAME=parsed_args["appname"]

jl_main_file = parsed_args["juliaprog_main"]
binary_name = match(r"([^/.]+)\.jl$", jl_main_file).captures[1]
bundle_identifier = lowercase("com.$(ENV["USER"]).$APPNAME")
bundle_version = "0.1"
icns_file = parsed_args["icns"]
user_resources = parsed_args["resource"]
user_libs = parsed_args["lib"]        # Contents will be copied to Libraries/
verbose = parsed_args["verbose"]

# ----------- Initialize App ---------------------
println("~~~~~~ Creating mac app in $(pwd())/builddir/$APPNAME.app ~~~~~~~")

appDir="$(pwd())/builddir/$APPNAME.app/Contents"

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

for res in user_resources
    println("  .. $res ..")
    run_verbose(verbose, `cp -rf $(glob(res)) $resourcesDir/`) # note this copies the entire *dir* to Resources
end
for lib in user_libs
    println("  .. $lib ..")
    run_verbose(verbose, `cp -rf $(glob(lib)) $libsDir/`) # note this copies the entire *dir* to Resources
end

# ----------- Copy julia system libs ---------------------
println("~~~~~~ Copying julia system libs to bundle... ~~~~~~~")

function julia_app_resources_dir()
    cmd_strings = Base.shell_split(string(Base.julia_cmd()))
    dashJ_cmd = cmd_strings[3]
    julia_dir = dashJ_cmd[findfirst("/", dashJ_cmd)[1]:findlast("/Contents/Resources", dashJ_cmd)[end]]
end
function julia_libs_dir()
    julia_app_resources_dir()*"/julia/lib", julia_app_resources_dir()*"/julia/lib/julia"
end

julia_lib, julia_lib_julia = julia_libs_dir()
run(`cp -r $julia_lib/ $libsDir`)

# ----------- Compile a binary ---------------------
# Compile the binary right into the app.
println("~~~~~~ Compiling a binary from '$jl_main_file'... ~~~~~~~")

# Provide an environment variable telling the code it's being compiled into a mac bundle.
env = copy(ENV)
env["LD_LIBRARY_PATH"]="$libsDir:$libsDir/julia"
env["COMPILING_APPLE_BUNDLE"]="true"
run(setenv(`julia $(Pkg.dir())/PackageCompiler/juliac.jl -ae $jl_main_file
             "$(Pkg.dir())/PackageCompiler/examples/program.c" $launcherDir`,
           env))

run(`install_name_tool -add_rpath "@executable_path/../Libraries/" "$launcherDir/$binary_name"`)
run(`install_name_tool -add_rpath "@executable_path/../Libraries/julia" "$launcherDir/$binary_name"`)

run(`install_name_tool -add_rpath "@executable_path/../Libraries/" "$launcherDir/$binary_name.dylib"`)
run(`install_name_tool -add_rpath "@executable_path/../Libraries/julia" "$launcherDir/$binary_name.dylib"`)



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
    	<string>$bundle_version</string>
    	<key>CFBundleName</key>
    	<string>$APPNAME</string>
    	<key>CFBundlePackageType</key>
    	<string>APPL</string>
    	<key>CFBundleShortVersionString</key>
    	<string>$bundle_version</string>
    	<key>CFBundleSignature</key>
    	<string></string>
    	<key>CFBundleVersion</key>
    	<string>$bundle_version</string>
        <key>NSHighResolutionCapable</key>
        <string>YES</string>
    	<key>LSMinimumSystemVersionByArchitecture</key>
    	<dict>
    		<key>x86_64</key>
    		<string>10.6</string>
    	</dict>
    	<key>LSRequiresCarbon</key>
    	<true/>
    	<key>NSHumanReadableCopyright</key>
    	<string>© 2016 $bundle_identifier </string>
    </dict>
    </plist>
    """

write("$appDir/Info.plist", info_plist());

# Copy Julia icons
if (icns_file == nothing) icns_file = julia_app_resources_dir()*"/julia.icns" end
cp(icns_file, "$resourcesDir/$APPNAME.icns", remove_destination=true);

# --------------- CLEAN UP before distributing ---------------
println("~~~~~~ Cleaning up temporary files... ~~~~~~~")

# Delete the tmp build files
run(`rm -r $(glob("*.ji",launcherDir))`)
run(`rm -r $(glob("*.o",launcherDir))`)

# Remove debug .dylib libraries and precompiled .ji's
run(`rm -r $(glob("*.dSYM",libsDir))`)
run(`rm -r $(glob("*.dSYM","$libsDir/julia"))`)
run(`rm -r $(glob("*.backup","$libsDir/julia"))`)
run(`rm -r $(glob("*.ji","$libsDir/julia"))`)
run(`rm -r $(glob("*.o","$libsDir/julia"))`)

println("~~~~~~ Done building 'builddir/$APPNAME.app'! ~~~~~~~")
