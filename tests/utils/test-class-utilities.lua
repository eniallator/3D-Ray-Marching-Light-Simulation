local classUtilities = require 'src.utils.class-utilities'

local test = {}

function test.validateOrComplainValidNoTable()
    classUtilities.validateOrComplain(1, 'number')
end

function test.validateOrComplainValidFlatTable()
    classUtilities.validateOrComplain({1, true, 'foo'}, {'number', 'boolean', 'string'})
end

function test.validateOrComplainValidNestedTable()
    classUtilities.validateOrComplain({{1, true, 'foo'}, 1}, {{'number', 'boolean', 'string'}, 'number'})
end

function test.validateOrComplainInvalidNoTable()
    local success, msg =
        pcall(
        function()
            classUtilities.validateOrComplain(true, 'number')
        end
    )
    assert(not success, msg)
end

function test.validateOrComplainInvalidFlatTable()
    local success, msg =
        pcall(
        function()
            classUtilities.validateOrComplain({true, true, 'foo'}, {'number', 'boolean', 'string'})
        end
    )
    assert(not success, msg)
end

function test.validateOrComplainInvalidNestedTable()
    local success, msg =
        pcall(
        function()
            classUtilities.validateOrComplain({{1, true, 1}, 1}, {{'number', 'boolean', 'string'}, 'number'})
        end
    )
    assert(not success, msg)
end

return test
