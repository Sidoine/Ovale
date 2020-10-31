import { L } from "./Localization";
import { Tracer, OvaleDebugClass } from "./Debug";
import { OvaleClass } from "./Ovale";
import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import {
    ipairs,
    pairs,
    tonumber,
    tostring,
    wipe,
    lualength,
    LuaArray,
    LuaObj,
} from "@wowts/lua";
import { match, gsub } from "@wowts/string";
import { concat, insert, sort } from "@wowts/table";
import {
    GetActiveSpecGroup,
    GetFlyoutInfo,
    GetFlyoutSlotInfo,
    GetSpellBookItemInfo,
    GetSpellInfo,
    GetSpellLink,
    GetSpellTabInfo,
    GetSpellTexture,
    GetTalentInfo,
    HasPetSpells,
    IsHarmfulSpell,
    IsHelpfulSpell,
    BOOKTYPE_PET,
    BOOKTYPE_SPELL,
    MAX_TALENT_TIERS,
    NUM_TALENT_COLUMNS,
} from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { OvaleDataClass } from "./Data";
import { isNumber, OneTimeMessage } from "./tools";
import { OptionUiAll } from "./acegui-helpers";

let MAX_NUM_TALENTS = NUM_TALENT_COLUMNS * MAX_TALENT_TIERS;

const ParseHyperlink = function (hyperlink: string) {
    let [color, linkType, linkData, text] = match(
        hyperlink,
        "|?c?f?f?(%x*)|?H?([^:]*):?(%d*):?%d?|?h?%[?([^%[%]]*)%]?|?h?|?r?"
    );
    return [color, linkType, linkData, text];
};
const OutputTableValues = function (output: LuaArray<string>, tbl: any) {
    let array: LuaArray<string> = {};
    for (const [k, v] of pairs(tbl)) {
        insert(array, `${tostring(v)}: ${tostring(k)}`);
    }
    sort(array);
    for (const [, v] of ipairs(array)) {
        output[lualength(output) + 1] = v;
    }
};

let output: LuaArray<string> = {};

type BookType = "pet" | "spell";

export class OvaleSpellBookClass {
    ready = false;
    spell: LuaArray<string> = {};
    spellbookId: { [key in BookType]: LuaArray<number> } = {
        [BOOKTYPE_PET]: {},
        [BOOKTYPE_SPELL]: {},
    };
    isHarmful: LuaArray<boolean> = {};
    isHelpful: LuaArray<boolean> = {};
    texture: LuaArray<string> = {};
    talent: LuaArray<string> = {};
    talentPoints: LuaArray<number> = {};

    private module: AceModule & AceEvent;
    private tracer: Tracer;

    constructor(
        private ovale: OvaleClass,
        ovaleDebug: OvaleDebugClass,
        private ovaleData: OvaleDataClass
    ) {
        let debugOptions: LuaObj<OptionUiAll> = {
            spellbook: {
                name: L["Spellbook"],
                type: "group",
                args: {
                    spellbook: {
                        name: L["Spellbook"],
                        type: "input",
                        multiline: 25,
                        width: "full",
                        get: (info: any) => {
                            return this.DebugSpells();
                        },
                    },
                },
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
                        get: (info: any) => {
                            return this.DebugTalents();
                        },
                    },
                },
            },
        };
        for (const [k, v] of pairs(debugOptions)) {
            ovaleDebug.defaultOptions.args[k] = v;
        }
        this.module = ovale.createModule(
            "OvaleSpellBook",
            this.OnInitialize,
            this.OnDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private OnInitialize = () => {
        this.module.RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", this.Update);
        this.module.RegisterEvent(
            "CHARACTER_POINTS_CHANGED",
            this.UpdateTalents
        );
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.Update);
        this.module.RegisterEvent("PLAYER_TALENT_UPDATE", this.UpdateTalents);
        this.module.RegisterEvent("SPELLS_CHANGED", this.UpdateSpells);
        this.module.RegisterEvent("UNIT_PET", this.UNIT_PET);
    };
    private OnDisable = () => {
        this.module.UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
        this.module.UnregisterEvent("CHARACTER_POINTS_CHANGED");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_TALENT_UPDATE");
        this.module.UnregisterEvent("SPELLS_CHANGED");
        this.module.UnregisterEvent("UNIT_PET");
    };
    private UNIT_PET = (unitId: string) => {
        if (unitId == "player") {
            this.UpdateSpells();
        }
    };
    private Update = () => {
        this.UpdateTalents();
        this.UpdateSpells();
        this.ready = true;
    };
    private UpdateTalents = (): void => {
        this.tracer.Debug("Updating talents.");
        wipe(this.talent);
        wipe(this.talentPoints);
        let activeTalentGroup = GetActiveSpecGroup();
        for (let i = 1; i <= MAX_TALENT_TIERS; i += 1) {
            for (let j = 1; j <= NUM_TALENT_COLUMNS; j += 1) {
                let [
                    talentId,
                    name,
                    ,
                    selected,
                    ,
                    ,
                    ,
                    ,
                    ,
                    ,
                    selectedByLegendary,
                ] = GetTalentInfo(i, j, activeTalentGroup);
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
                        this.tracer.Debug(
                            "    Talent %s (%d) is %s.",
                            name,
                            index,
                            (combinedSelected && "enabled") || "disabled"
                        );
                    }
                }
            }
        }
        this.ovale.needRefresh();
        this.module.SendMessage("Ovale_TalentsChanged");
    };
    private UpdateSpells = (): void => {
        wipe(this.spell);
        wipe(this.spellbookId[BOOKTYPE_PET]);
        wipe(this.spellbookId[BOOKTYPE_SPELL]);
        wipe(this.isHarmful);
        wipe(this.isHelpful);
        wipe(this.texture);
        for (let tab = 1; tab <= 3; tab += 1) {
            let [name, , offset, numSpells] = GetSpellTabInfo(tab);
            if (name) {
                this.ScanSpellBook(BOOKTYPE_SPELL, numSpells, offset);
            }
        }
        let [numPetSpells] = HasPetSpells();
        if (numPetSpells) {
            this.ScanSpellBook(BOOKTYPE_PET, numPetSpells);
        }
        this.ovale.needRefresh();
        this.module.SendMessage("Ovale_SpellsChanged");
    };
    ScanSpellBook(bookType: BookType, numSpells: number, offset?: number) {
        offset = offset || 0;
        this.tracer.Debug(
            "Updating '%s' spellbook starting at offset %d.",
            bookType,
            offset
        );
        for (let index = offset + 1; index <= offset + numSpells; index += 1) {
            let [skillType, spellId] = GetSpellBookItemInfo(index, bookType);
            if (skillType == "SPELL" || skillType == "PETACTION") {
                let spellLink = GetSpellLink(index, bookType);
                if (spellLink) {
                    let [, , linkData, spellName] = ParseHyperlink(spellLink);
                    let id = tonumber(linkData);
                    let [name] = GetSpellInfo(id);
                    if (name) {
                        this.spell[id] = name;
                        this.isHarmful[id] = IsHarmfulSpell(index, bookType);
                        this.isHelpful[id] = IsHelpfulSpell(index, bookType);
                        this.texture[id] = GetSpellTexture(index, bookType);
                        this.spellbookId[bookType][id] = index;
                        this.tracer.Debug(
                            "    %s (%d) is at offset %d (%s).",
                            name,
                            id,
                            index,
                            gsub(spellLink, "|", "_")
                        );
                        if (spellId && id != spellId) {
                            let name;
                            if (skillType == "PETACTION" && spellName) {
                                name = spellName;
                            } else {
                                [name] = GetSpellInfo(spellId);
                            }
                            if (name) {
                                this.spell[spellId] = name;
                                this.isHarmful[spellId] = this.isHarmful[id];
                                this.isHelpful[spellId] = this.isHelpful[id];
                                this.texture[spellId] = this.texture[id];
                                this.spellbookId[bookType][spellId] = index;
                                this.tracer.Debug(
                                    "    %s (%d) is at offset %d.",
                                    name,
                                    spellId,
                                    index
                                );
                            }
                        }
                    }
                }
            } else if (skillType == "FLYOUT") {
                let flyoutId = spellId;
                let [, , numSlots, isKnown] = GetFlyoutInfo(flyoutId);
                if (numSlots > 0 && isKnown) {
                    for (
                        let flyoutIndex = 1;
                        flyoutIndex <= numSlots;
                        flyoutIndex += 1
                    ) {
                        let [
                            id,
                            overrideId,
                            isKnown,
                            spellName,
                        ] = GetFlyoutSlotInfo(flyoutId, flyoutIndex);
                        if (isKnown) {
                            let [name] = GetSpellInfo(id);
                            if (name) {
                                this.spell[id] = name;
                                this.isHarmful[id] = IsHarmfulSpell(spellName);
                                this.isHelpful[id] = IsHelpfulSpell(spellName);
                                this.texture[id] = GetSpellTexture(
                                    index,
                                    bookType
                                );
                                delete this.spellbookId[bookType][id];
                                this.tracer.Debug(
                                    "    %s (%d) is at offset %d.",
                                    name,
                                    id,
                                    index
                                );
                            }

                            if (id != overrideId) {
                                let [name] = GetSpellInfo(overrideId);
                                if (name) {
                                    this.spell[overrideId] = name;
                                    this.isHarmful[overrideId] = this.isHarmful[
                                        id
                                    ];
                                    this.isHelpful[overrideId] = this.isHelpful[
                                        id
                                    ];
                                    this.texture[overrideId] = this.texture[id];
                                    delete this.spellbookId[bookType][
                                        overrideId
                                    ];
                                    this.tracer.Debug(
                                        "    %s (%d) is at offset %d.",
                                        name,
                                        overrideId,
                                        index
                                    );
                                }
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
    GetCastTime(spellId: number): number | undefined {
        if (spellId) {
            let [name, , , castTime] = this.GetSpellInfo(spellId);
            if (name) {
                if (castTime) {
                    castTime = castTime / 1000;
                } else {
                    castTime = 0;
                }
            } else {
                return undefined;
            }
            return castTime;
        }
    }
    GetSpellInfo(
        spellId: number
    ): [
        string | undefined,
        string | undefined,
        string,
        number,
        number,
        number,
        number
    ] {
        let [index, bookType] = this.GetSpellBookIndex(spellId);
        if (index && bookType) {
            return GetSpellInfo(index, bookType);
        } else {
            return GetSpellInfo(spellId);
        }
    }
    GetSpellName(spellId: number): string | undefined {
        let spellName: string | undefined = this.spell[spellId];
        if (!spellName) {
            [spellName] = this.GetSpellInfo(spellId);
        }
        return spellName;
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
    AddSpell(spellId: number, name: string) {
        if (spellId && name) {
            this.tracer.Debug("Adding spell %s (%d)", name, spellId);
            this.spell[spellId] = name;
        }
    }
    IsHarmfulSpell(spellId: number): boolean {
        return (spellId && this.isHarmful[spellId] && true) || false;
    }
    IsHelpfulSpell(spellId: number): boolean {
        return (spellId && this.isHelpful[spellId] && true) || false;
    }
    IsKnownSpell(spellId: number): boolean {
        return (spellId && this.spell[spellId] && true) || false;
    }
    IsKnownTalent(talentId: number): boolean {
        return (talentId && this.talentPoints[talentId] && true) || false;
    }

    getKnownSpellId(spell: number | string) {
        if (isNumber(spell)) return spell;
        const spells = this.ovaleData.buffSpellList[spell];
        if (!spells) {
            OneTimeMessage(`Unknown spell list ${spell}`);
            return undefined;
        }
        for (const [spellId] of pairs(spells)) {
            if (this.spell[spellId]) return spellId;
        }
        return undefined;
    }

    GetSpellBookIndex(spellId: number): [number?, BookType?] {
        let bookType: BookType = BOOKTYPE_SPELL;
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

    DebugSpells() {
        // TODO return type
        wipe(output);
        OutputTableValues(output, this.spell);
        let total = 0;
        for (const [] of pairs(this.spell)) {
            total = total + 1;
        }
        output[lualength(output) + 1] = `Total spells: ${total}`;
        return concat(output, "\n");
    }
    DebugTalents() {
        // TODO return type
        wipe(output);
        OutputTableValues(output, this.talent);
        return concat(output, "\n");
    }
}
