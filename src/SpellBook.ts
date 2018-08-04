import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import aceEvent from "@wowts/ace_event-3.0";
import { ipairs, pairs, tonumber, tostring, wipe, lualength } from "@wowts/lua";
import { match, gsub } from "@wowts/string";
import { concat, insert, sort } from "@wowts/table";
import { GetActiveSpecGroup, GetFlyoutInfo, GetFlyoutSlotInfo, GetSpellBookItemInfo, GetSpellInfo, GetSpellLink, GetSpellTabInfo, GetSpellTexture, GetTalentInfo, HasPetSpells, IsHarmfulSpell, IsHelpfulSpell, BOOKTYPE_PET, BOOKTYPE_SPELL, MAX_TALENT_TIERS, NUM_TALENT_COLUMNS } from "@wowts/wow-mock";

export let OvaleSpellBook:OvaleSpellBookClass;

let MAX_NUM_TALENTS = NUM_TALENT_COLUMNS * MAX_TALENT_TIERS;
{
    let debugOptions = {
        spellbook: {
            name: L["Spellbook"],
            type: "group",
            args: {
                spellbook: {
                    name: L["Spellbook"],
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: function (info) {
                        return OvaleSpellBook.DebugSpells();
                    }
                }
            }
        },
        talent: {
            name: L["Talents"],
            type: "group",
            args: {
                talent: {
                    name: L["Talents"],
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: function (info) {
                        return OvaleSpellBook.DebugTalents();
                    }
                }
            }
        }
    }
    for (const [k, v] of pairs(debugOptions)) {
        OvaleDebug.options.args[k] = v;
    }
}
const ParseHyperlink = function(hyperlink) {
    let [color, linkType, linkData, text] = match(hyperlink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d*):?%d?|?h?%[?([^%[%]]*)%]?|?h?|?r?");
    return [color, linkType, linkData, text];
}
const OutputTableValues = function(output, tbl) {
    let array = {
    }
    for (const [k, v] of pairs(tbl)) {
        insert(array, `${tostring(v)}: ${tostring(k)}`);
    }
    sort(array);
    for (const [, v] of ipairs(array)) {
        output[lualength(output) + 1] = v;
    }
}

let output = {}

const OvaleSpellBookBase = OvaleProfiler.RegisterProfiling(OvaleDebug.RegisterDebugging(Ovale.NewModule("OvaleSpellBook", aceEvent)))
class OvaleSpellBookClass extends OvaleSpellBookBase {
    ready = false;
    spell = {    }
    spellbookId = {
        [BOOKTYPE_PET]: {
        },
        [BOOKTYPE_SPELL]: {
        }
    }
    isHarmful = {    }
    isHelpful = {    }
    texture = {    }
    talent = {    }
    talentPoints = {    }

    
    OnInitialize(): void {
        this.RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "Update");
        this.RegisterEvent("CHARACTER_POINTS_CHANGED", "UpdateTalents");
        this.RegisterEvent("PLAYER_ENTERING_WORLD", "Update");
        this.RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateTalents");
        this.RegisterEvent("SPELLS_CHANGED", "UpdateSpells");
        this.RegisterEvent("UNIT_PET");
    }
    OnDisable(): void {
        this.UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
        this.UnregisterEvent("CHARACTER_POINTS_CHANGED");
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_TALENT_UPDATE");
        this.UnregisterEvent("SPELLS_CHANGED");
        this.UnregisterEvent("UNIT_PET");
    }
    UNIT_PET(unitId: string): void {
        if (unitId == "player") {
            this.UpdateSpells();
        }
    }
    Update(): void
     {
        this.UpdateTalents();
        this.UpdateSpells();
        this.ready = true;
    }
    UpdateTalents(): void {
        this.Debug("Updating talents.");
        wipe(this.talent);
        wipe(this.talentPoints);
        let activeTalentGroup = GetActiveSpecGroup();
        for (let i = 1; i <= MAX_TALENT_TIERS; i += 1) {
            for (let j = 1; j <= NUM_TALENT_COLUMNS; j += 1) {
                let [talentId, name,, selected,, , , ,,, selectedByLegendary] = GetTalentInfo(i, j, activeTalentGroup);
                if (talentId) {
                    let combinedSelected = selected || selectedByLegendary;
                    let index = 3 * (i - 1) + j;
                    if (index <= MAX_NUM_TALENTS) {
                        this.talent[index] = name;
                        if (combinedSelected) {
                            this.talentPoints[index] = 1;
                        } else {
                            this.talentPoints[index] = 0;
                        }
                        this.Debug("    Talent %s (%d) is %s.", name, index, combinedSelected && "enabled" || "disabled");
                    }
                }
            }
        }
        Ovale.needRefresh();
        this.SendMessage("Ovale_TalentsChanged");
    }
    UpdateSpells(): void {
        wipe(this.spell);
        wipe(this.spellbookId[BOOKTYPE_PET]);
        wipe(this.spellbookId[BOOKTYPE_SPELL]);
        wipe(this.isHarmful);
        wipe(this.isHelpful);
        wipe(this.texture);
        for (let tab = 1; tab <= 2; tab += 1) {
            let [name, , offset, numSpells] = GetSpellTabInfo(tab);
            if (name) {
                this.ScanSpellBook(BOOKTYPE_SPELL, numSpells, offset);
            }
        }
        let [numPetSpells, ] = HasPetSpells();
        if (numPetSpells) {
            this.ScanSpellBook(BOOKTYPE_PET, numPetSpells);
        }
        Ovale.needRefresh();
        this.SendMessage("Ovale_SpellsChanged");
    }
    ScanSpellBook(bookType: string, numSpells: number, offset?: number) {
        offset = offset || 0;
        this.Debug("Updating '%s' spellbook starting at offset %d.", bookType, offset);
        for (let index = offset + 1; index <= offset + numSpells; index += 1) {
            let [skillType, spellId] = GetSpellBookItemInfo(index, bookType);
            if (skillType == "SPELL" || skillType == "PETACTION") {
                let spellLink = GetSpellLink(index, bookType);
                if (spellLink) {
                    let [, , linkData, spellName] = ParseHyperlink(spellLink);
                    let id = tonumber(linkData);
                    let name = GetSpellInfo(id);
                    this.spell[id] = name;
                    this.isHarmful[id] = IsHarmfulSpell(index, bookType);
                    this.isHelpful[id] = IsHelpfulSpell(index, bookType);
                    this.texture[id] = GetSpellTexture(index, bookType);
                    this.spellbookId[bookType][id] = index;
                    this.Debug("    %s (%d) is at offset %d (%s).", name, id, index, gsub(spellLink, "|", "_"));
                    if (spellId && id != spellId) {
                        let name = (skillType == "PETACTION") && spellName || GetSpellInfo(spellId);
                        this.spell[spellId] = name;
                        this.isHarmful[spellId] = this.isHarmful[id];
                        this.isHelpful[spellId] = this.isHelpful[id];
                        this.texture[spellId] = this.texture[id];
                        this.spellbookId[bookType][spellId] = index;
                        this.Debug("    %s (%d) is at offset %d.", name, spellId, index);
                    }
                }
            } else if (skillType == "FLYOUT") {
                let flyoutId = spellId;
                let [, , numSlots, isKnown] = GetFlyoutInfo(flyoutId);
                if (numSlots > 0 && isKnown) {
                    for (let flyoutIndex = 1; flyoutIndex <= numSlots; flyoutIndex += 1) {
                        let [id, overrideId, isKnown, spellName] = GetFlyoutSlotInfo(flyoutId, flyoutIndex);
                        if (isKnown) {
                            let name = GetSpellInfo(id);
                            this.spell[id] = name;
                            this.isHarmful[id] = IsHarmfulSpell(spellName);
                            this.isHelpful[id] = IsHelpfulSpell(spellName);
                            this.texture[id] = GetSpellTexture(index, bookType);
                            this.spellbookId[bookType][id] = undefined;
                            this.Debug("    %s (%d) is at offset %d.", name, id, index);
                            if (id != overrideId) {
                                let name = GetSpellInfo(overrideId);
                                this.spell[overrideId] = name;
                                this.isHarmful[overrideId] = this.isHarmful[id];
                                this.isHelpful[overrideId] = this.isHelpful[id];
                                this.texture[overrideId] = this.texture[id];
                                this.spellbookId[bookType][overrideId] = undefined;
                                this.Debug("    %s (%d) is at offset %d.", name, overrideId, index);
                            }
                        }
                    }
                }
            } else if (skillType == "FUTURESPELL") {
            } else if (!skillType) {
                break;
            }
        }
    }
    GetCastTime(spellId: number): number {
        if (spellId) {
            let [name, , , castTime] = this.GetSpellInfo(spellId);
            if (name) {
                if (castTime) {
                    castTime = castTime / 1000;
                } else {
                    castTime = 0;
                }
            } else {
                castTime = undefined;
            }
            return castTime;
        }
    }
    GetSpellInfo(spellId: number): [string, string, string, number, number, number, number] {
        let [index, bookType] = this.GetSpellBookIndex(spellId);
        if (index && bookType) {
            return GetSpellInfo(index, bookType);
        } else {
            return GetSpellInfo(spellId);
        }
    }
    GetSpellName(spellId: number): string {
        if (spellId) {
            let spellName = this.spell[spellId];
            if (!spellName) {
                spellName = this.GetSpellInfo(spellId);
            }
            return spellName;
        }
    }
    GetSpellTexture(spellId: number): string {
        return this.texture[spellId];
    }
    GetTalentPoints(talentId: number): number {
        let points = 0;
        if (talentId && this.talentPoints[talentId]) {
            points = this.talentPoints[talentId];
        }
        return points;
    }
    AddSpell(spellId: number, name) {
        if (spellId && name) {
            this.spell[spellId] = name;
        }
    }
    IsHarmfulSpell(spellId: number): boolean {
        return (spellId && this.isHarmful[spellId]) && true || false;
    }
    IsHelpfulSpell(spellId: number): boolean {
        return (spellId && this.isHelpful[spellId]) && true || false;
    }
    IsKnownSpell(spellId: number): boolean {
        return (spellId && this.spell[spellId]) && true || false;
    }
    IsKnownTalent(talentId: number): boolean {
        return (talentId && this.talentPoints[talentId]) && true || false;
    }
    GetSpellBookIndex(spellId: number): [number, string] {
        let bookType = BOOKTYPE_SPELL;
        while (true) {
            let index = this.spellbookId[bookType][spellId];
            if (index) {
                return [index, bookType];
            } else if (bookType == BOOKTYPE_SPELL) {
                bookType = BOOKTYPE_PET;
            } else {
                break;
            }
        }
        return [undefined, undefined];
    }
    IsPetSpell(spellId: number): boolean {
        let [, bookType] = this.GetSpellBookIndex(spellId);
        return bookType == BOOKTYPE_PET;
    }

    DebugSpells() { // TODO return type
        wipe(output);
        OutputTableValues(output, this.spell);
        let total = 0;
        for (const [] of pairs(this.spell)) {
            total = total + 1;
        }
        output[lualength(output) + 1] = `Total spells: ${total}`;
        return concat(output, "\n");
    }
    DebugTalents() { // TODO return type
        wipe(output);
        OutputTableValues(output, this.talent);
        return concat(output, "\n");
    }
}

OvaleSpellBook = new OvaleSpellBookClass();
