using Glob, ArgParse

include("sign_mac_app.jl")

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
    "--bundle_identifier"
        arg_type = String
        default = nothing
        metavar = "com.user.appname"
        help = "the bundle identifier for this app. Default: 'com.<USER>.<appname>'."
    "--icns"
        arg_type = String
        default = nothing
        metavar = "<file>"
        help = ".icns file to be used as the app's icon"
    "--app_version"
        arg_type = String
        default = "0.1"
        #range_tester = (x -> r"^[0-9]+(\.[0-9]+)*$"(x))  # can the version have other characters in it? idk..
        metavar = "0.0.1"
        help = ".icns file to be used as the app's icon"
    "--certificate"
        arg_type = String
        default = nothing
        metavar = "<cert_name>"
        help = "name of the certificate to use to sign the app"
    "--entitlements"
        arg_type = String
        default = nothing
        metavar = "<file>"
        help = ".entitlements file. Must set --certificate to add entitlements."
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
builddir = parsed_args["builddir"]
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
println("~~~~~~ Creating mac app in \"$(pwd())/$builddir/$APPNAME.app\" ~~~~~~~")

appDir="$(pwd())/$builddir/$APPNAME.app/Contents"

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
    if isempty(glob(res))
         println("WARNING: Skipping empty resource '$res'!")
     else
         run_verbose(verbose, `cp -rf $(glob(res)) $resourcesDir/`) # note this copies the entire *dir* to Resources
     end
end
for lib in user_libs
    println("  .. $lib ..")
    if isempty(glob(lib))
         println("WARNING: Skipping empty resource '$lib'!")
     else
         run_verbose(verbose, `cp -rf $(glob(lib)) $libsDir/`) # note this copies the entire *dir* to Resources
     end
end

# ----------- Compile a binary ---------------------
# Compile the binary right into the app.
println("~~~~~~ Compiling a binary from '$jl_main_file'... ~~~~~~~")

# Provide an environment variable telling the code it's being compiled into a mac bundle.
env = copy(ENV)
env["LD_LIBRARY_PATH"]="$libsDir:$libsDir/julia"
env["COMPILING_APPLE_BUNDLE"]="true"
# Compile executable and copy julia libs to $launcherDir.
juliac_cmd = `julia $(Pkg.dir())/PackageCompiler/juliac.jl -aej -Cx86-64 --cc-flags='-mmacosx-version-min=10.10' $jl_main_file
                 "$(Pkg.dir())/PackageCompiler/examples/program.c" $launcherDir`
verbose && println("  $juliac_cmd")
verbose && insert!(juliac_cmd.exec, 3, "-v")
run(setenv(juliac_cmd, env))

run(`install_name_tool -add_rpath "@executable_path/../Libraries/" "$launcherDir/$binary_name"`)
#run(`install_name_tool -add_rpath "@executable_path/../Libraries/julia" "$launcherDir/$binary_name"`)

run(`install_name_tool -add_rpath "@executable_path/../Libraries/" "$launcherDir/$binary_name.dylib"`)
#run(`install_name_tool -add_rpath "@executable_path/../Libraries/julia" "$launcherDir/$binary_name.dylib"`)



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
    		<string>10.6</string>
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
if (icns_file == nothing) icns_file = julia_app_resources_dir()*"/julia.icns" end
cp(icns_file, "$resourcesDir/$APPNAME.icns", remove_destination=true);

# --------------- CLEAN UP before distributing ---------------
println("~~~~~~ Cleaning up temporary files... ~~~~~~~")

# Delete the tmp build files
function delete_if_present(file, path)
    files = glob(file,launcherDir)
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
