# macOS Julia Application Builder

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
     build.jl hello.jl HelloApp
     # Build MyGame, and copy in imgs/, mus.wav and all files in libs/
     build.jl -R imgs -R mus.wav -L lib/* main.jl MyGame
 ```

 ------------------

Right now, this tool only works for building macOS applications, but will
hopefully eventually cover all OSes.

The goal of this tool is to allow you to distribute an entirely standalone
application from your julia code. That is, someone should be able to download
your application and run it without having Julia installed.

# License
This project is licensed under the terms of the MIT license.

