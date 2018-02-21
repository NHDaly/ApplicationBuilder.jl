APPNAME="PowerPong"

jl_main_file = "pongmain.jl"
binary_name = match(r"([^/.]+)\.jl$", jl_main_file).captures[1]
bundle_identifier = "com.nhdaly.$binary_name"
bundle_version = "0.1"
#icns_file = nothing
icns_file = "icns.icns"
assets_dir = "assets"    # These will be copied to Resources/

# NOTES:
# TODO: Make a new Package for the SDL binaries so you don't have to dowload
# them and also don't bloat SDL2.jl
# TODO: Send a PR to rename SDL.jl package to SDL2.jl

# ----------- Initialize App ---------------------
appDir="$(pwd())/builddir/$APPNAME.app/Contents"
println("~~~~~~ Creating mac app in $appDir ~~~~~~~")

launcherDir="$appDir/MacOS"
resourcesDir="$appDir/Resources"

#jlPkgDir="$appDir/Resources/julia_pkgs/"


mkpath(launcherDir)
mkpath(resourcesDir)
#mkpath(jlPkgDir)

# ----------- Compile a binary ---------------------
# Compile the binary right into the app.
println("~~~~~~ Compiling a binary from '$jl_main_file'... ~~~~~~~")
run(`julia $(Pkg.dir())/PackageCompiler/juliac.jl -ae $jl_main_file
     "$(Pkg.dir())/PackageCompiler/examples/program.c" $launcherDir`)

# Keep everything absolute directories.
#binary_fullpath = "$(pwd())/builddir/$output_binary_name"
#dylib_fullpath = "$(pwd())/builddir/$output_binary_name"


run(`cp -r $assets_dir $resourcesDir/`) # note this copies the entire *dir* to Resources
## Copy binary and .dylib to .app destination. Note that we're renaming them.
#cp(binary_fullpath, "$launcherDir/$APPNAME", remove_destination=true)
#cp(dylib_fullpath, "$launcherDir/$APPNAME.dylib", remove_destination=true)
#run(`chmod +x "$launcherDir/$APPNAME"`)
#run(`chmod +x "$launcherDir/$APPNAME.dylib"`)
## Now fix the LC_LOAD_DYLIB path to point to the new .dylib name, since we renamed them:
#run(`install_name_tool -change "@rpath/$output_binary_name.dylib"
#         "@executable_path/$APPNAME.dylib" "$launcherDir/$APPNAME"`)
#run(`install_name_tool -change "@rpath/$output_binary_name.dylib"
#         "@rpath/$APPNAME.dylib" "$launcherDir/$APPNAME.dylib"`)

# ----------- Copy julia libs ---------------------

libsDir="$appDir/Libraries"
mkpath(libsDir)

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

run(`install_name_tool -add_rpath "@executable_path/../Libraries/" "$launcherDir/$binary_name"`)
run(`install_name_tool -add_rpath "@executable_path/../Libraries/julia" "$launcherDir/$binary_name"`)

run(`install_name_tool -add_rpath "@executable_path/../Libraries/" "$launcherDir/$binary_name.dylib"`)
run(`install_name_tool -add_rpath "@executable_path/../Libraries/julia" "$launcherDir/$binary_name.dylib"`)



# ---------- Create Info.plist to tell it where to find stuff! ---------
# This lets you have a different app name from your jl_main_file.

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

## ----------- Copy Packages ---------------------
#version=(jl_v=Base.VERSION; "v$(jl_v.major).$(jl_v.minor)")
#mkpath("$jlPkgDir/$version")
#
## INIT package dir
#function set_julia_dir(dir::String)
#    ENV["JULIA_PKGDIR"] = dir
#    Pkg.init()
#    Pkg.__init__()
#    pop!(Base.LOAD_CACHE_PATH)
#    return Pkg.dir()
#end
#
#origPkgDir = Pkg.dir()
#newPkgDir = set_julia_dir(jlPkgDir)
#
#origPkgDir
#package_names = filter(r".*\.jl", readlines("REQUIRES"))
#for pkg in package_names
#    pkgName = split(pkg, ".jl")[1]
#    #run(`cp -r "$origPkgDir/$pkgName" "$newPkgDir/$pkgName"`)
#    #run(`echo "$pkgName" >> "$newPkgDir/REQUIRE"`)
#    try
#        Pkg.clone("$origPkgDir/$pkgName/.git", pkgName)
#    catch end
#end
#
#set_julia_dir(origPkgDir)

# ~~~~~~~~~~~ CLEAN UP before distributing ~~~~~~~~~~
# When you're all done, right before releasing, be sure to delete your tmp build files.
rm("$launcherDir/tmp_v$(string(Base.VERSION))", recursive=true)
# Remove debug .dylib libraries and precompiled .ji's
using Glob
run(`rm -r $(glob("*.dSYM",libsDir))`)
run(`rm -r $(glob("*.dSYM","$libsDir/julia"))`)
run(`rm -r $(glob("*.dSYM.backup","$libsDir/julia"))`)
run(`rm -r $(glob("*.backup","$libsDir/julia"))`)
run(`rm -r $(glob("*.ji","$libsDir/julia"))`)
run(`rm -r $(glob("*.o","$libsDir/julia"))`)
