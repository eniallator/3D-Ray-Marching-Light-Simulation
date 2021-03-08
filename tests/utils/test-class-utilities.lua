local classUtilities = require 'src.utils.class-utilities'

local test = {}

function test.validateOrComplain_ValidNoTable()
    classUtilities.validateOrComplain(1, 'number')
end

function test.validateOrComplain_ValidFlatTable()
    classUtilities.validateOrComplain({1, true, 'foo'}, {'number', 'boolean', 'string'})
end

function test.validateOrComplain_ValidNestedTable()
    classUtilities.validateOrComplain({{1, true, 'foo'}, 1}, {{'number', 'boolean', 'string'}, 'number'})
end

function test.validateOrComplain_InvalidNoTable()
    local success, msg =
        pcall(
        function()
            classUtilities.validateOrComplain(true, 'number')
        end
    )
    assert(not success, msg)
end

function test.validateOrComplain_InvalidFlatTable()
    local success, msg =
        pcall(
        function()
            classUtilities.validateOrComplain({true, true, 'foo'}, {'number', 'boolean', 'string'})
        end
    )
    assert(not success, msg)
end

function test.validateOrComplain_InvalidNestedTable()
    local success, msg =
        pcall(
        function()
            classUtilities.validateOrComplain({{1, true, 1}, 1}, {{'number', 'boolean', 'string'}, 'number'})
        end
    )
    assert(not success, msg)
end

return test
