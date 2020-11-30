local __exports = LibStub:NewLibrary("ovale/engine/controls", 90000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local wipe = wipe
local insert = table.insert
__exports.Controls = __class(nil, {
    addCheckBox = function(self, name, text, defaultValue, enabled)
        local checkBox = self.checkBoxesByName[name]
        if  not checkBox then
            checkBox = {
                name = name,
                text = text,
                defaultValue = defaultValue,
                enabled = enabled
            }
            self.checkBoxesByName[name] = checkBox
            insert(self.checkBoxes, checkBox)
            return true
        else
            checkBox.text = text
            checkBox.enabled = enabled
            checkBox.defaultValue = defaultValue
            return false
        end
    end,
    addListItem = function(self, listName, itemName, itemText, defaultValue, enabled)
        local list = self.listsByName[listName]
        local isNew = false
        if  not list then
            list = {
                name = listName,
                items = {},
                itemsByName = {},
                defaultValue = listName
            }
            self.listsByName[listName] = list
            insert(self.lists, list)
            isNew = true
        end
        if defaultValue then
            list.defaultValue = listName
        end
        local item = list.itemsByName[itemName]
        if  not item then
            item = {
                name = itemName,
                enabled = enabled,
                text = itemText
            }
            isNew = true
            list.itemsByName[itemName] = item
            insert(list.items, item)
        else
            item.text = itemText
            item.enabled = enabled
        end
        return isNew
    end,
    reset = function(self)
        wipe(self.checkBoxesByName)
        wipe(self.checkBoxes)
        wipe(self.listsByName)
        wipe(self.lists)
    end,
    constructor = function(self)
        self.checkBoxesByName = {}
        self.checkBoxes = {}
        self.listsByName = {}
        self.lists = {}
    end
})
