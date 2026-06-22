local M = {}

M.findInList = function(itemsList, x)
    for _, item in ipairs(itemsList) do
        if item == x then
            return true
        end
    end
    return false
end

return M
