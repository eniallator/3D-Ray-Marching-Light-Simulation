require 'lfs'

function assertEquals(val, other)
    -- Handling non-tables
    if type(val) ~= 'table' then
        assert(val == other)
    end
    if type(other) ~= 'table' then
        error()
    end

    -- Checking if they have the same set of keys
    local keys, key, _ = {}
    for key, _ in pairs(val) do
        keys[key] = ''
    end
    for key, _ in pairs(other) do
        if keys[key] == nil then
            error()
        end
        keys[key] = nil
    end
    for key, _ in pairs(keys) do
        error()
    end

    -- Same keys
    for key, _ in pairs(val) do
        if type(val[key]) == 'table' then
            assertEquals(val[key], other[key])
        else
            assert(val[key] == other[key])
        end
    end
end

local function walk(dir, files)
    local files = files or {}

    for file in lfs.dir(dir) do
        local path = dir .. '/' .. file

        if file:sub(1, 1) ~= '.' then
            if lfs.attributes(path, 'mode') == 'directory' then
                walk(path, files)
            elseif path:sub(-4) == '.lua' then
                table.insert(files, path)
            end
        end
    end

    return files
end

local test_files = walk('./tests')
local failures = {}
local numTests, numFailures = 0, 0

local i
for i = 1, #test_files do
    local file = test_files[i]
    local require_file = file:sub(3, -5):gsub('/', '.')
    local funcs = require(require_file)
    if type(funcs) == 'table' then
        for name, func in pairs(funcs) do
            numTests = numTests + 1
            local testId = require_file .. ' > ' .. name
            local success, errMsg = pcall(func)
            if not success then
                numFailures = numFailures + 1
                failures[testId] = errMsg or 'NO_STACKTRACE'
            end
            print(testId .. ' | ' .. (success and 'PASSED' or 'FAILED'))
        end
    end
end

print('\n(' .. (numTests - numFailures) .. '/' .. numTests .. ') tests passed\n')
if numFailures > 0 then
    print('FAILURES:\n')

    for name, stackTrace in pairs(failures) do
        print(name .. '\n' .. stackTrace .. '\n')
    end
end
