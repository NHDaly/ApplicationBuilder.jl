APPNAME="PowerPong"

# ----------- Initialize App ---------------------
mkpath("builddir")
# Keep everything absolute directories.
appDir="$(pwd())/builddir/$APPNAME.app/Contents"

launcherDir="$appDir/MacOS"
resourcesDir="$appDir/Resources"
scriptsDir="$appDir/Resources/scripts"

jlPkgDir="$appDir/Resources/julia_pkgs/"


mkpath(launcherDir)
mkpath(scriptsDir)
mkpath(jlPkgDir)

julia_scripts = filter(r".*\.jl", readlines(`ls`))
run(`cp $julia_scripts $scriptsDir/`)
run(`cp -r assets $resourcesDir/`) # note this copies the entire *dir* to Resources
# Copy launch script -- note deleting the `.sh`
cp("$APPNAME.sh", "$launcherDir/$APPNAME", remove_destination=true)
run(`chmod +x "$launcherDir/$APPNAME"`)

# ----------- Copy Packages ---------------------
version=(jl_v=Base.VERSION; "v$(jl_v.major).$(jl_v.minor)")
mkpath("$jlPkgDir/$version")

# INIT package dir
function set_julia_dir(dir::String)
    ENV["JULIA_PKGDIR"] = dir
    Pkg.init()
    Pkg.__init__()
    pop!(Base.LOAD_CACHE_PATH)
    return Pkg.dir()
end

origPkgDir = Pkg.dir()
newPkgDir = set_julia_dir(jlPkgDir)

origPkgDir
package_names = filter(r".*\.jl", readlines("REQUIRES"))
for pkg in package_names
    pkgName = split(pkg, ".jl")[1]
    #run(`cp -r "$origPkgDir/$pkgName" "$newPkgDir/$pkgName"`)
    #run(`echo "$pkgName" >> "$newPkgDir/REQUIRE"`)
    try
        Pkg.clone("$origPkgDir/$pkgName/.git", pkgName)
    catch end
end

set_julia_dir(origPkgDir)


# ---------- Copy Julia --------------------
run(`cp -r "/Applications/Julia-0.6.app" "$launcherDir/"`)
try  # okay if the alias already exists (if you're re-running this script).
    run(`ln -s "./Julia-0.6.app/Contents/Resources/julia/bin/julia" "$launcherDir/julia"`)
end

# ------- MUST BE SURE TO DO THIS LAST STEP RIGHT BEFORE SHIPPING!! ----------
# The shipped binary cannot contain any precompiled cache .ji files. You *must*
#  delete them before shipping.
run(`rm -rf $jlPkgDir/lib/`)  # for some reason it chokes on the cached .ji files.
