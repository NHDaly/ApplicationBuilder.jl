try
  Pkg.installed("ApplicationBuilderRuntimeUtils")
catch
  Pkg.clone("https://github.com/NHDaly/ApplicationBuilderRuntimeUtils.jl.git")
end
