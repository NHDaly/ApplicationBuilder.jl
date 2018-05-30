# macOS Julia Application Builder
[![Build Status](https://travis-ci.org/NHDaly/ApplicationBuilder.jl.svg?branch=master)](https://travis-ci.org/NHDaly/ApplicationBuilder.jl) [![Coverage Status](https://coveralls.io/repos/github/NHDaly/ApplicationBuilder.jl/badge.svg?branch=master)](https://coveralls.io/github/NHDaly/ApplicationBuilder.jl?branch=master)

## build_app.jl

Build a distributable Mac `.app` from a julia program!

This tool compiles a julia program and bundles it up into a distributable macOS application.

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

Right now, this tool only works for building `macOS` applications, but will
hopefully eventually cover all OSes.

The goal of this tool is to allow you to distribute an entirely standalone
application from your julia code. That is, someone should be able to download
your application and run it without having Julia installed.

## Running an example:
After cloning the repository, you can build an App out of the example program, `examples/hello.jl`, like this:

```bash
$ julia build_app.jl -v examples/hello.jl "HelloWorld"
```

This will produce `builddir/HelloWorld.app`, which you can double click, and it will indeed greet you!

The simple example HelloWorld.app has no binary dependencies -- that is, it
doesn't need any extra libraries besides Julia. Many Julia packages come bundled
with their own binary dependencies, and if you want to use them in your app,
you'll have to add those dependencies via the flags `-L` for libs and `-R` for
bundle resources.

# License
This project is licensed under the terms of the MIT license.
