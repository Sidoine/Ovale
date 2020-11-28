local __exports = LibStub:NewLibrary("ovale/tools/TimeSpan", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local select = select
local wipe = wipe
local format = string.format
local concat = table.concat
local insert = table.insert
local remove = table.remove
local huge = math.huge
local INFINITY = huge
local self_pool = {}
local self_poolSize = 0
local self_poolUnused = 0
local CompareIntervals = function(startA, endA, startB, endB)
    if startA == startB and endA == endB then
        return 0
    elseif startA < startB and endA >= startB and endA <= endB then
        return -1
    elseif startB < startA and endB >= startA and endB <= endA then
        return 1
    elseif (startA == startB and endA > endB) or (startA < startB and endA == endB) or (startA < startB and endA > endB) then
        return -2
    elseif (startB == startA and endB > endA) or (startB < startA and endB == endA) or (startB < startA and endB > endA) then
        return 2
    elseif endA <= startB then
        return -3
    elseif endB <= startA then
        return 3
    end
    return 99
end

__exports.newTimeSpan = function()
    local obj = remove(self_pool)
    if obj then
        self_poolUnused = self_poolUnused - 1
    else
        obj = __exports.OvaleTimeSpan()
        self_poolSize = self_poolSize + 1
    end
    return obj
end
__exports.newFromArgs = function(...)
    return __exports.newTimeSpan():Copy(...)
end
__exports.newTimeSpanFromArray = function(a)
    if a then
        return __exports.newTimeSpan():copyFromArray(a)
    else
        return __exports.newTimeSpan()
    end
end
__exports.releaseTimeSpans = function(...)
    local argc = select("#", ...)
    for i = 1, argc, 1 do
        local a = select(i, ...)
        wipe(a)
        insert(self_pool, a)
    end
    self_poolUnused = self_poolUnused + argc
end
__exports.GetPoolInfo = function()
    return self_poolSize, self_poolUnused
end
__exports.OvaleTimeSpan = __class(nil, {
    Release = function(self)
        wipe(self)
        insert(self_pool, self)
        self_poolUnused = self_poolUnused + 1
    end,
    __tostring = function(self)
        if #self == 0 then
            return "empty set"
        else
            return format("(%s)", concat(self, ", "))
        end
    end,
    copyFromArray = function(self, A)
        local count = #A
        for i = 1, count, 1 do
            self[i] = A[i]
        end
        for i = count + 1, #self, 1 do
            self[i] = nil
        end
        return self
    end,
    Copy = function(self, ...)
        local count = select("#", ...)
        for i = 1, count, 1 do
            self[i] = select(i, ...)
        end
        for i = count + 1, #self, 1 do
            self[i] = nil
        end
        return self
    end,
    IsEmpty = function(self)
        return #self == 0
    end,
    IsUniverse = function(self)
        return self[1] == 0 and self[2] == INFINITY
    end,
    Equals = function(self, B)
        local A = self
        local countA = #A
        local countB = (B and #B) or 0
        if countA ~= countB then
            return false
        end
        for k = 1, countA, 1 do
            if A[k] ~= B[k] then
                return false
            end
        end
        return true
    end,
    HasTime = function(self, atTime)
        local A = self
        for i = 1, #A, 2 do
            if A[i] <= atTime and atTime <= A[i + 1] then
                return true
            end
        end
        return false
    end,
    NextTime = function(self, atTime)
        local A = self
        for i = 1, #A, 2 do
            if atTime < A[i] then
                return A[i]
            elseif A[i] <= atTime and atTime <= A[i + 1] then
                return atTime
            end
        end
    end,
    Measure = function(self)
        local A = self
        local measure = 0
        for i = 1, #A, 2 do
            measure = measure + (A[i + 1] - A[i])
        end
        return measure
    end,
    Complement = function(self, result)
        local A = self
        local countA = #A
        if countA == 0 then
            if result then
                result:copyFromArray(__exports.UNIVERSE)
            else
                result = __exports.newTimeSpanFromArray(__exports.UNIVERSE)
            end
        else
            result = result or __exports.newTimeSpan()
            local countResult = 0
            local i, k = 1, 1
            if A[i] == 0 then
                i = i + 1
            else
                result[k] = 0
                countResult = k
                k = k + 1
            end
            while i < countA do
                result[k] = A[i]
                countResult = k
                i, k = i + 1, k + 1
            end
            if A[i] < INFINITY then
                result[k], result[k + 1] = A[i], INFINITY
                countResult = k + 1
            end
            for j = countResult + 1, #result, 1 do
                result[j] = nil
            end
        end
        return result
    end,
    IntersectInterval = function(self, startB, endB, result)
        local A = self
        local countA = #A
        result = result or __exports.newTimeSpan()
        if countA > 0 and startB and endB then
            local countResult = 0
            local i, k = 1, 1
            while true do
                if i > countA then
                    break
                end
                local startA, endA = A[i], A[i + 1]
                local compare = CompareIntervals(startA, endA, startB, endB)
                if compare == 0 then
                    result[k], result[k + 1] = startA, endA
                    countResult = k + 1
                    break
                elseif compare == -1 then
                    if endA > startB then
                        result[k], result[k + 1] = startB, endA
                        countResult = k + 1
                        i, k = i + 2, k + 2
                    else
                        i = i + 2
                    end
                elseif compare == 1 then
                    if endB > startA then
                        result[k], result[k + 1] = startA, endB
                        countResult = k + 1
                    end
                    break
                elseif compare == -2 then
                    result[k], result[k + 1] = startB, endB
                    countResult = k + 1
                    break
                elseif compare == 2 then
                    result[k], result[k + 1] = startA, endA
                    countResult = k + 1
                    i, k = i + 2, k + 2
                elseif compare == -3 then
                    i = i + 2
                elseif compare == 3 then
                    break
                end
            end
            for n = countResult + 1, #result, 1 do
                result[n] = nil
            end
        end
        return result
    end,
    Intersect = function(self, B, result)
        local A = self
        local countA = #A
        local countB = (B and #B) or 0
        result = result or __exports.newTimeSpan()
        local countResult = 0
        if countA > 0 and countB > 0 then
            local i, j, k = 1, 1, 1
            while true do
                if i > countA or j > countB then
                    break
                end
                local startA, endA = A[i], A[i + 1]
                local startB, endB = B[j], B[j + 1]
                local compare = CompareIntervals(startA, endA, startB, endB)
                if compare == 0 then
                    result[k], result[k + 1] = startA, endA
                    countResult = k + 1
                    i, j, k = i + 2, j + 2, k + 2
                elseif compare == -1 then
                    if endA > startB then
                        result[k], result[k + 1] = startB, endA
                        countResult = k + 1
                        i, k = i + 2, k + 2
                    else
                        i = i + 2
                    end
                elseif compare == 1 then
                    if endB > startA then
                        result[k], result[k + 1] = startA, endB
                        countResult = k + 1
                        j, k = j + 2, k + 2
                    else
                        j = j + 2
                    end
                elseif compare == -2 then
                    result[k], result[k + 1] = startB, endB
                    countResult = k + 1
                    j, k = j + 2, k + 2
                elseif compare == 2 then
                    result[k], result[k + 1] = startA, endA
                    countResult = k + 1
                    i, k = i + 2, k + 2
                elseif compare == -3 then
                    i = i + 2
                elseif compare == 3 then
                    j = j + 2
                else
                    i = i + 2
                    j = j + 2
                end
            end
        end
        for n = countResult + 1, #result, 1 do
            result[n] = nil
        end
        return result
    end,
    Union = function(self, B, result)
        local A = self
        local countA = #A
        local countB = (B and #B) or 0
        if countA == 0 then
            if B then
                if result then
                    result:copyFromArray(B)
                else
                    result = __exports.newTimeSpanFromArray(B)
                end
            else
                result = __exports.EMPTY_SET
            end
        elseif countB == 0 then
            if result then
                result:copyFromArray(A)
            else
                result = __exports.newTimeSpanFromArray(A)
            end
        else
            result = result or __exports.newTimeSpan()
            local countResult = 0
            local i, j, k = 1, 1, 1
            local startTemp, endTemp = A[i], A[i + 1]
            local holdingA = true
            local scanningA = false
            while true do
                local startA, endA, startB, endB
                if i > countA and j > countB then
                    result[k], result[k + 1] = startTemp, endTemp
                    countResult = k + 1
                    k = k + 2
                    break
                end
                if scanningA and i > countA then
                    holdingA =  not holdingA
                    scanningA =  not scanningA
                else
                    startA, endA = A[i], A[i + 1]
                end
                if  not scanningA and j > countB then
                    holdingA =  not holdingA
                    scanningA =  not scanningA
                else
                    startB, endB = B[j], B[j + 1]
                end
                local startCurrent = (scanningA and startA) or startB or 0
                local endCurrent = (scanningA and endA) or endB or 0
                local compare = CompareIntervals(startTemp, endTemp, startCurrent, endCurrent)
                if compare == 0 then
                    if scanningA then
                        i = i + 2
                    else
                        j = j + 2
                    end
                elseif compare == -2 then
                    if scanningA then
                        i = i + 2
                    else
                        j = j + 2
                    end
                elseif compare == -1 then
                    endTemp = endCurrent
                    if scanningA then
                        i = i + 2
                    else
                        j = j + 2
                    end
                elseif compare == 1 then
                    startTemp = startCurrent
                    if scanningA then
                        i = i + 2
                    else
                        j = j + 2
                    end
                elseif compare == 2 then
                    startTemp, endTemp = startCurrent, endCurrent
                    holdingA =  not holdingA
                    scanningA =  not scanningA
                    if scanningA then
                        i = i + 2
                    else
                        j = j + 2
                    end
                elseif compare == -3 then
                    if holdingA == scanningA then
                        result[k], result[k + 1] = startTemp, endTemp
                        countResult = k + 1
                        startTemp, endTemp = startCurrent, endCurrent
                        scanningA =  not scanningA
                        k = k + 2
                    else
                        scanningA =  not scanningA
                        if scanningA then
                            i = i + 2
                        else
                            j = j + 2
                        end
                    end
                elseif compare == 3 then
                    startTemp, endTemp = startCurrent, endCurrent
                    holdingA =  not holdingA
                    scanningA =  not scanningA
                else
                    i = i + 2
                    j = j + 2
                end
            end
            for n = countResult + 1, #result, 1 do
                result[n] = nil
            end
        end
        return result
    end,
})
__exports.UNIVERSE = __exports.newFromArgs(0, INFINITY)
__exports.EMPTY_SET = __exports.newTimeSpan()
