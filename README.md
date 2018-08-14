# Julia Application Builder
[![Build Status](https://travis-ci.org/NHDaly/ApplicationBuilder.jl.svg?branch=master)](https://travis-ci.org/NHDaly/ApplicationBuilder.jl) [![Coverage Status](https://coveralls.io/repos/github/NHDaly/ApplicationBuilder.jl/badge.svg?branch=master)](https://coveralls.io/github/NHDaly/ApplicationBuilder.jl?branch=master)

Build a distributable "App" from a julia program!

This tool compiles a julia program and bundles it up into a distributable application, on macOS, Windows and Linux!

The goal of this tool is to allow you to distribute an entirely standalone
application from your julia code. That is, someone should be able to download
your application and run it without having Julia installed.

There is both a native julia interface, in the `BuildApp` module, and a command-line interface, `build_app.jl`.

## BuildApp (The Julia interface)

To compile and bundle your julia program into a distributable app, use `BuildApp.build_app_bundle`:
```julia
julia> using ApplicationBuilder
help?> build_app_bundle()
  # 1 method for generic function "build_app_bundle":
  build_app_bundle(juliaprog_main; appname, builddir, resources, libraries, verbose, bundle_identifier, app_version, icns_file, certificate, entitlements_file)
```

Note that `BuildApp` is a separate module, and you have to first run `using ApplicationBuilder` to be able to import it.

## build_app.jl (The command-line tool)

Run `julia build_app.jl -h` for help:
```
usage: build_app.jl [-v] [-R <resource>] [-L <file>] [--icns <file>]
                    [-h] juliaprog_main [appname] [builddir]

positional arguments:
  juliaprog_main        Julia program to compile -- must define
                        julia_main()
  appname               name to call the generated .app bundle
  builddir              directory used for building, either absolute
                        or relative to the Julia program directory
                        (default: "builddir")

optional arguments:
  -v, --verbose         increase verbosity
  -R, --resource <resource>
                        specify files or directories to be copied to
                        MyApp.app/Contents/Resources/. This should be
                        done for all resources that your app will need
                        to have available at runtime. Can be repeated.
  -L, --lib <file>      specify user library files to be copied to
                        MyApp.app/Contents/Libraries/. This should be
                        done for all libraries that your app will need
                        to reference at runtime. Can be repeated.
  --icns <file>         .icns file to be used as the app's icon
  -h, --help            show this help message and exit

  examples:
     # Build HelloApp.app from hello.jl
     build_app.jl hello.jl HelloApp
     # Build MyGame, and copy in imgs/, mus.wav and all files in libs/
     build_app.jl -R imgs -R mus.wav -L lib/* main.jl MyGame
 ```

------------------

## Compatibility

`ApplicationBuilder` supports macOS, Windows, and Linux on `julia v0.6`. Support for `v0.7` is coming soon.

## Running an example:
After cloning the repository, you can build an App out of the example program, `examples/hello.jl`, like this:

```julia
julia> build_app_bundle("/Users/Daly/.julia/v0.6/ApplicationBuilder/examples/hello.jl", appname="HelloWorld", verbose=true);
```

or like this:

```bash
$ julia build_app.jl -v examples/hello.jl "HelloWorld"
```

This will produce `builddir/HelloWorld.app`, which you can double click, and it will indeed greet you!

The simple example HelloWorld.app has no binary dependencies -- that is, it
doesn't need any extra libraries besides Julia. Many Julia packages come bundled
with their own binary dependencies, and if you want to use them in your app,
you'll have to add those dependencies via the `libraries` (`-L`) option for libs
and `resources` (`-R`) for bundle resources.

# License
This project is licensed under the terms of the MIT license.
