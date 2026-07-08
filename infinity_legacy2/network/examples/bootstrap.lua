local root = fs.getDir(shell.getRunningProgram())
root = fs.combine(root, "..")

package.path =
    fs.combine(root, "?.lua") .. ";" ..
    fs.combine(root, "?/init.lua") .. ";" ..
    package.path

return root