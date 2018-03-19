using Glob

"""
    sign_application_libs(launcherDir, cert)
    
Sign `app_bundle` and all julia libs with `cert` certificate name.
"""
function sign_application_libs(launcherDir, cert)
    # Repeat signing all libs a few times in order to allow for dependency chains.
    ll_signed = false
    for _ in 1:20
        all_signed = sign_all_unsigned(launcherDir, cert)
        if all_signed ; break ; end
    end
end

function sign_all_unsigned(launcherDir, cert_name)
  all_signed = true
  for l in glob("*", launcherDir)
      # If it's not already signed, sign it.
      if !success(`codesign --display --extract-certificates $l`)
          # note that this will fail if dependencies aren't signed.
          try  # failure throws exception
              print(readstring(`codesign -s "$cert_name" $l`))
          catch
          end
          all_signed = false
      end
  end
  return all_signed
end

"""
    set_entitlements(binary_path, cert, entitlements_file)

Set entitlements `entitlements_file` on binary `binary_path`.
"""
function set_entitlements(binary_path, cert, entitlements_file)
    run(`codesign --entitlements $entitlements_file -fs "$cert" "$binary_path"`)
end
