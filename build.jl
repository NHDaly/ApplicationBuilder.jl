using Glob

APPNAME="PowerPong"

jl_main_file = "pongmain.jl"
binary_name = match(r"([^/.]+)\.jl$", jl_main_file).captures[1]
bundle_identifier = lowercase("com.$(ENV["USER"]).$APPNAME")
bundle_version = "0.1"
#icns_file = nothing
icns_file = "icns.icns"
user_assets_dir = "assets"    # Contents will be copied to Resources/assets/
user_libs_dir = "libs"        # Contents will be copied to Libraries/

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
println("~~~~~~ Copying '$user_libs_dir' & '$user_assets_dir' to bundle... ~~~~~~~")

# Copy assets and libs early so they're available during compilation.
#  This is mostly relevant if you have .dylibs in your assets, which the compiler wants to look at.
isdir(user_assets_dir) && run(`cp -rf $user_assets_dir $resourcesDir/`) # note this copies the entire *dir* to Resources
isdir(user_libs_dir) && run(`cp -rf $(glob("*",user_libs_dir)) $libsDir/`) # note this copies the entire *dir* to Resources

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
rm("$launcherDir/tmp_v$(string(Base.VERSION))", recursive=true)

# Remove debug .dylib libraries and precompiled .ji's
run(`rm -r $(glob("*.dSYM",libsDir))`)
run(`rm -r $(glob("*.dSYM","$libsDir/julia"))`)
run(`rm -r $(glob("*.backup","$libsDir/julia"))`)
run(`rm -r $(glob("*.ji","$libsDir/julia"))`)
run(`rm -r $(glob("*.o","$libsDir/julia"))`)

println("~~~~~~ Done building 'builddir/$APPNAME.app'! ~~~~~~~")
