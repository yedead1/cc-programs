local args = { ... }

if #args < 3 then
    print("Usage: getfolder <user> <repo> <folder> [branch]")
    print("Example:")
    print("getfolder yedead1 cc-programs infinity_legacy2/network")
    return
end

local user   = args[1]
local repo   = args[2]
local folder = args[3]:gsub("^/", ""):gsub("/$", "")
local branch = args[4] or "main"

local apiURL = ("https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1")
    :format(user, repo, branch)

local function makeDirs(path)
    local cur = ""
    for part in string.gmatch(path, "[^/]+") do
        cur = cur == "" and part or fs.combine(cur, part)
        if not fs.exists(cur) then
            fs.makeDir(cur)
        end
    end
end

print("Reading repository tree...")

local response = http.get(apiURL, {
    ["User-Agent"] = "CC-Tweaked"
})

if not response then
    printError("Failed to contact GitHub.")
    return
end

local body = response.readAll()
response.close()

if not textutils.unserializeJSON then
    printError("Your CC:Tweaked version doesn't support JSON.")
    return
end

local tree = textutils.unserializeJSON(body)

if not tree or not tree.tree then
    printError("Failed to parse GitHub response.")
    return
end

local files = {}

for _, entry in ipairs(tree.tree) do
    if entry.type == "blob" then
        if entry.path:sub(1, #folder + 1) == folder .. "/" then
            table.insert(files, entry.path)
        end
    end
end

if #files == 0 then
    printError("Folder not found or contains no files.")
    return
end

print(("Found %d files."):format(#files))

-- Local directory will only be the final folder name
local targetDir = fs.getName(folder)

if not fs.exists(targetDir) then
    fs.makeDir(targetDir)
end

for i, path in ipairs(files) do

    -- Strip the requested folder prefix
    local relative = path:sub(#folder + 2)

    -- Save into the target directory
    local localPath = fs.combine(targetDir, relative)

    local dir = fs.getDir(localPath)
    if dir ~= "" then
        makeDirs(dir)
    end

    local rawURL = ("https://raw.githubusercontent.com/%s/%s/%s/%s")
        :format(user, repo, branch, path)

    write(("[%d/%d] %s ... "):format(i, #files, relative))

    local res = http.get(rawURL)

    if res then
        local h = fs.open(localPath, "w")
        h.write(res.readAll())
        h.close()
        res.close()
        print("OK")
    else
        print("FAILED")
    end
end

print()
print("Download complete.")