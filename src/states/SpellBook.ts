import { l } from "../ui/Localization";
import { Tracer, DebugTools } from "../engine/debug";
import { OvaleClass } from "../Ovale";
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
    IsSpellKnown,
    BOOKTYPE_PET,
    BOOKTYPE_SPELL,
    MAX_TALENT_TIERS,
    NUM_TALENT_COLUMNS,
} from "@wowts/wow-mock";
import { AceModule } from "@wowts/tsaddon";
import { OvaleDataClass } from "../engine/data";
import { isNumber, oneTimeMessage } from "../tools/tools";
import { OptionUiAll } from "../ui/acegui-helpers";

const parseHyperlink = function (hyperlink: string) {
    const [color, linkType, linkData, text] = match(
        hyperlink,
        "|?c?f?f?(%x*)|?H?([^:]*):?(%d*):?%d?|?h?%[?([^%[%]]*)%]?|?h?|?r?"
    );
    return [color, linkType, linkData, text];
};
const outputTableValues = function (output: LuaArray<string>, tbl: any) {
    const array: LuaArray<string> = {};
    for (const [k, v] of pairs(tbl)) {
        insert(array, `${tostring(v)}: ${tostring(k)}`);
    }
    sort(array);
    for (const [, v] of ipairs(array)) {
        output[lualength(output) + 1] = v;
    }
};

const output: LuaArray<string> = {};

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
        ovaleDebug: DebugTools,
        private ovaleData: OvaleDataClass
    ) {
        const debugOptions: LuaObj<OptionUiAll> = {
            spellbook: {
                name: l["spellbook"],
                type: "group",
                args: {
                    spellbook: {
                        name: l["spellbook"],
                        type: "input",
                        multiline: 25,
                        width: "full",
                        get: (info: any) => {
                            return this.debugSpells();
                        },
                    },
                },
            },
            talent: {
                name: l["talents"],
                type: "group",
                args: {
                    talent: {
                        name: l["talents"],
                        type: "input",
                        multiline: 25,
                        width: "full",
                        get: (info: any) => {
                            return this.debugTalents();
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
            this.handleInitialize,
            this.handleDisable,
            aceEvent
        );
        this.tracer = ovaleDebug.create(this.module.GetName());
    }

    private handleInitialize = () => {
        this.module.RegisterEvent(
            "ACTIVE_TALENT_GROUP_CHANGED",
            this.handleUpdate
        );
        this.module.RegisterEvent(
            "CHARACTER_POINTS_CHANGED",
            this.handleUpdateTalents
        );
        this.module.RegisterEvent("PLAYER_ENTERING_WORLD", this.handleUpdate);
        this.module.RegisterEvent(
            "PLAYER_TALENT_UPDATE",
            this.handleUpdateTalents
        );
        this.module.RegisterEvent("SPELLS_CHANGED", this.handleUpdateSpells);
        this.module.RegisterEvent("UNIT_PET", this.handleUnitPet);
    };
    private handleDisable = () => {
        this.module.UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
        this.module.UnregisterEvent("CHARACTER_POINTS_CHANGED");
        this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.module.UnregisterEvent("PLAYER_TALENT_UPDATE");
        this.module.UnregisterEvent("SPELLS_CHANGED");
        this.module.UnregisterEvent("UNIT_PET");
    };
    private handleUnitPet = (unitId: string) => {
        if (unitId == "player") {
            this.handleUpdateSpells();
        }
    };
    private handleUpdate = () => {
        this.handleUpdateTalents();
        this.handleUpdateSpells();
        this.ready = true;
    };
    private handleUpdateTalents = (): void => {
        this.tracer.debug("Updating talents.");
        wipe(this.talent);
        wipe(this.talentPoints);
        const activeTalentGroup = GetActiveSpecGroup();
        for (let i = 1; i <= MAX_TALENT_TIERS; i += 1) {
            for (let j = 1; j <= NUM_TALENT_COLUMNS; j += 1) {
                const [
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
                    const combinedSelected = selected || selectedByLegendary;
                    this.talent[talentId] = name;
                    if (combinedSelected) {
                        this.talentPoints[talentId] = 1;
                    } else {
                        this.talentPoints[talentId] = 0;
                    }
                    this.tracer.debug(
                        "    Talent %s (%d) is %s.",
                        name,
                        talentId,
                        (combinedSelected && "enabled") || "disabled"
                    );
                }
            }
        }
        this.ovale.needRefresh();
        this.module.SendMessage("Ovale_TalentsChanged");
    };
    private handleUpdateSpells = (): void => {
        wipe(this.spell);
        wipe(this.spellbookId[BOOKTYPE_PET]);
        wipe(this.spellbookId[BOOKTYPE_SPELL]);
        wipe(this.isHarmful);
        wipe(this.isHelpful);
        wipe(this.texture);
        for (let tab = 1; tab <= 3; tab += 1) {
            const [name, , offset, numSpells] = GetSpellTabInfo(tab);
            if (name) {
                this.scanSpellBook(BOOKTYPE_SPELL, numSpells, offset);
            }
        }
        const [numPetSpells] = HasPetSpells();
        if (numPetSpells) {
            this.scanSpellBook(BOOKTYPE_PET, numPetSpells);
        }
        this.ovale.needRefresh();
        this.module.SendMessage("Ovale_SpellsChanged");
    };
    scanSpellBook(bookType: BookType, numSpells: number, offset?: number) {
        offset = offset || 0;
        this.tracer.debug(
            "Updating '%s' spellbook starting at offset %d.",
            bookType,
            offset
        );
        for (let index = offset + 1; index <= offset + numSpells; index += 1) {
            const [skillType, spellId] = GetSpellBookItemInfo(index, bookType);
            if (skillType == "SPELL" || skillType == "PETACTION") {
                const spellLink = GetSpellLink(index, bookType);
                if (spellLink) {
                    const [, , linkData, spellName] = parseHyperlink(spellLink);
                    const id = tonumber(linkData);
                    const [name] = GetSpellInfo(id);
                    if (name) {
                        this.spell[id] = name;
                        this.isHarmful[id] = IsHarmfulSpell(index, bookType);
                        this.isHelpful[id] = IsHelpfulSpell(index, bookType);
                        this.texture[id] = GetSpellTexture(index, bookType);
                        this.spellbookId[bookType][id] = index;
                        this.tracer.debug(
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
                                this.tracer.debug(
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
                const flyoutId = spellId;
                const [, , numSlots, isKnown] = GetFlyoutInfo(flyoutId);
                if (numSlots > 0 && isKnown) {
                    for (
                        let flyoutIndex = 1;
                        flyoutIndex <= numSlots;
                        flyoutIndex += 1
                    ) {
                        const [
                            id,
                            overrideId,
                            isKnown,
                            spellName,
                        ] = GetFlyoutSlotInfo(flyoutId, flyoutIndex);
                        if (isKnown) {
                            const [name] = GetSpellInfo(id);
                            if (name) {
                                this.spell[id] = name;
                                this.isHarmful[id] = IsHarmfulSpell(spellName);
                                this.isHelpful[id] = IsHelpfulSpell(spellName);
                                this.texture[id] = GetSpellTexture(
                                    index,
                                    bookType
                                );
                                delete this.spellbookId[bookType][id];
                                this.tracer.debug(
                                    "    %s (%d) is at offset %d.",
                                    name,
                                    id,
                                    index
                                );
                            }

                            if (id != overrideId) {
                                const [name] = GetSpellInfo(overrideId);
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
                                    this.tracer.debug(
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
            } else if (!skillType) {
                break;
            }
        }
    }
    getCastTime(spellId: number): number | undefined {
        if (spellId) {
            let [name, , , castTime] = this.getSpellInfo(spellId);
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
    getSpellInfo(
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
        const [index, bookType] = this.getSpellBookIndex(spellId);
        if (index && bookType) {
            return GetSpellInfo(index, bookType);
        } else {
            return GetSpellInfo(spellId);
        }
    }
    getSpellName(spellId: number): string | undefined {
        let spellName: string | undefined = this.spell[spellId];
        if (!spellName) {
            [spellName] = this.getSpellInfo(spellId);
        }
        return spellName;
    }
    getSpellTexture(spellId: number): string {
        return this.texture[spellId];
    }
    getTalentPoints(talentId: number): number {
        let points = 0;
        if (talentId && this.talentPoints[talentId]) {
            points = this.talentPoints[talentId];
        }
        return points;
    }
    addSpell(spellId: number, name: string) {
        if (spellId && name) {
            this.tracer.debug("Adding spell %s (%d)", name, spellId);
            this.spell[spellId] = name;
        }
    }
    isHarmfulSpell(spellId: number): boolean {
        return (spellId && this.isHarmful[spellId] && true) || false;
    }
    isHelpfulSpell(spellId: number): boolean {
        return (spellId && this.isHelpful[spellId] && true) || false;
    }
    isKnownSpell(spellId: number): boolean {
        /**
         * A spell is known if it's in the spellbook, or is a temporary spell
         * or action granted by an encounter that may not be in the spellbook.
         */

        let isKnown = this.spell[spellId] !== undefined;
        if (!isKnown) {
            if (spellId > 0) {
                isKnown = IsSpellKnown(spellId) || IsSpellKnown(spellId, true);
                if (isKnown) {
                    this.tracer.log(
                        "Spell ID '%s' is not in the spellbook, but is still known.",
                        spellId
                    );
                }
            }
        }
        return (isKnown && true) || false;
    }
    isKnownTalent(talentId: number): boolean {
        return (talentId && this.talentPoints[talentId] && true) || false;
    }

    getKnownSpellId(spell: number | string) {
        if (isNumber(spell)) return spell;
        const spells = this.ovaleData.buffSpellList[spell];
        if (!spells) {
            oneTimeMessage(`Unknown spell list ${spell}`);
            return undefined;
        }
        for (const [spellId] of pairs(spells)) {
            if (this.spell[spellId]) return spellId;
        }
        return undefined;
    }

    getSpellBookIndex(spellId: number): [number?, BookType?] {
        let bookType: BookType = BOOKTYPE_SPELL;
        while (true) {
            const index = this.spellbookId[bookType][spellId];
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
    isPetSpell(spellId: number): boolean {
        const [, bookType] = this.getSpellBookIndex(spellId);
        return bookType == BOOKTYPE_PET;
    }

    debugSpells() {
        // TODO return type
        wipe(output);
        outputTableValues(output, this.spell);
        let total = 0;
        for (const [] of pairs(this.spell)) {
            total = total + 1;
        }
        output[lualength(output) + 1] = `Total spells: ${total}`;
        return concat(output, "\n");
    }
    debugTalents() {
        // TODO return type
        wipe(output);
        outputTableValues(output, this.talent);
        return concat(output, "\n");
    }
}
