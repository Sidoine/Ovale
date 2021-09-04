import aceEvent, { AceEvent } from "@wowts/ace_event-3.0";
import { LuaArray } from "@wowts/lua";
import { concat, insert } from "@wowts/table";
import { AceModule } from "@wowts/tsaddon";
import {
    GetSpellCount,
    GetTime,
    SpellId,
    TalentId,
    UnitCastingInfo,
} from "@wowts/wow-mock";
import { DebugTools, Tracer } from "../engine/debug";
import { SpellCastEventHandler, States, StateModule } from "../engine/state";
import { OptionUiGroup } from "../ui/acegui-helpers";
import { OvaleClass } from "../Ovale";
import { Aura, OvaleAuraClass } from "./Aura";
import { SpellCast } from "./LastSpell";
import { OvalePaperDollClass } from "./PaperDoll";
import { OvaleSpellBookClass } from "./SpellBook";
import { OvaleCombatClass } from "./combat";

type EclipseType = "lunar" | "solar";

export type EclipseState =
    | "any_next"
    | "in_both"
    | "in_lunar"
    | "in_solar"
    | "lunar_next"
    | "solar_next";

class EclipseData {
    starfire = 0;
    starfireMax = 0;
    wrath = 0;
    wrathMax = 0;
}

const balanceSpellId = {
    starfire: SpellId.starfire,
    wrath: SpellId.wrath_balance,
};

const balanceAffinitySpellId = {
    talent: TalentId.balance_affinity_talent,
    starfire: 197628,
    wrath: SpellId.wrath,
};

const celestialAlignmentId = SpellId.celestial_alignment;
const incarnationId = SpellId.incarnation_chosen_of_elune;
const eclipseLunarId = SpellId.eclipse_lunar_buff;
const eclipseSolarId = SpellId.eclipse_solar_buff;
const leafOnTheWaterId = 334604;

export class Eclipse extends States<EclipseData> implements StateModule {
    private module: AceModule & AceEvent;
    private tracer: Tracer;
    private hasEclipseHandlers = false;
    private isCasting = false;
    private adjustCount = false;
    private starfireId = 0;
    private wrathId = 0;

    private debugEclipse: OptionUiGroup = {
        type: "group",
        name: "Eclipse",
        args: {
            eclipse: {
                type: "input",
                name: "Eclipse",
                multiline: 25,
                width: "full",
                get: () => {
                    const output: LuaArray<string> = {};
                    insert(output, `Starfire spell ID: ${this.starfireId}`);
                    insert(output, `Wrath spell ID: ${this.wrathId}`);
                    insert(output, "");
                    insert(
                        output,
                        `Total Starfire(s) to Solar Eclipse: ${this.current.starfireMax}`
                    );
                    insert(
                        output,
                        `Total Wrath(s) to Lunar Eclipse: ${this.current.starfireMax}`
                    );
                    insert(output, "");
                    insert(
                        output,
                        `Starfire(s) to Solar Eclipse: ${this.current.starfire}`
                    );
                    insert(
                        output,
                        `Wrath(s) to Lunar Eclipse: ${this.current.wrath}`
                    );
                    return concat(output, "\n");
                },
            },
        },
    };

    constructor(
        private ovale: OvaleClass,
        debug: DebugTools,
        private aura: OvaleAuraClass,
        private combat: OvaleCombatClass,
        private paperDoll: OvalePaperDollClass,
        private spellBook: OvaleSpellBookClass
    ) {
        super(EclipseData);
        this.module = ovale.createModule(
            "Eclipse",
            this.onEnable,
            this.onDisable,
            aceEvent
        );
        this.tracer = debug.create(this.module.GetName());
        debug.defaultOptions.args["eclipse"] = this.debugEclipse;
    }

    private onEnable = () => {
        if (this.ovale.playerClass == "DRUID") {
            this.module.RegisterEvent(
                "PLAYER_ENTERING_WORLD",
                this.onUpdateEclipseHandlers
            );
            this.module.RegisterMessage(
                "Ovale_SpecializationChanged",
                this.onUpdateEclipseHandlers
            );
            this.module.RegisterMessage(
                "Ovale_TalentsChanged",
                this.onUpdateEclipseHandlers
            );
        }
    };

    private onDisable = () => {
        if (this.ovale.playerClass == "DRUID") {
            this.module.UnregisterEvent("PLAYER_ENTERING_WORLD");
            this.module.UnregisterMessage("Ovale_SpecializationChanged");
            this.module.UnregisterMessage("Ovale_TalentsChanged");
            this.unregisterEclipseHandlers();
        }
    };

    private onUpdateEclipseHandlers = (event: string) => {
        const isBalanceDruid = this.paperDoll.isSpecialization("balance");
        const hasBalanceAffinity =
            this.spellBook.getTalentPoints(balanceAffinitySpellId.talent) > 0;
        if (isBalanceDruid || hasBalanceAffinity) {
            if (isBalanceDruid) {
                this.starfireId = balanceSpellId.starfire;
                this.wrathId = balanceSpellId.wrath;
            } else if (hasBalanceAffinity) {
                this.starfireId = balanceAffinitySpellId.starfire;
                this.wrathId = balanceAffinitySpellId.wrath;
            } else {
                this.starfireId = 0;
                this.wrathId = 0;
            }
            this.registerEclipseHandlers();
            this.updateSpellMaxCounts(event);
            this.updateSpellCounts(event);
        } else {
            this.unregisterEclipseHandlers();
        }
    };

    private registerEclipseHandlers = () => {
        if (!this.hasEclipseHandlers) {
            this.tracer.debug("Installing eclipse event handlers.");
            this.module.RegisterEvent(
                "UNIT_SPELLCAST_FAILED",
                this.onUnitSpellCastStop
            );
            this.module.RegisterEvent(
                "UNIT_SPELLCAST_FAILED_QUIET",
                this.onUnitSpellCastStop
            );
            this.module.RegisterEvent(
                "UNIT_SPELLCAST_INTERRUPTED",
                this.onUnitSpellCastStop
            );
            this.module.RegisterEvent(
                "UNIT_SPELLCAST_START",
                this.onUnitSpellCastStart
            );
            this.module.RegisterEvent(
                "UNIT_SPELLCAST_STOP",
                this.onUnitSpellCastStop
            );
            this.module.RegisterEvent(
                "UNIT_SPELLCAST_SUCCEEDED",
                this.onUnitSpellCastSucceeded
            );
            this.module.RegisterEvent(
                "UPDATE_SHAPESHIFT_COOLDOWN",
                this.onUpdateShapeshiftCooldown
            );
            this.module.RegisterMessage(
                "Ovale_AuraAdded",
                this.onOvaleAuraAddedOrRemoved
            );
            this.module.RegisterMessage(
                "Ovale_AuraRemoved",
                this.onOvaleAuraAddedOrRemoved
            );
            this.hasEclipseHandlers = true;
        }
    };

    private unregisterEclipseHandlers = () => {
        if (this.hasEclipseHandlers) {
            this.tracer.debug("Removing eclipse event handlers.");
            this.module.UnregisterEvent("UNIT_SPELLCAST_FAILED");
            this.module.UnregisterEvent("UNIT_SPELLCAST_FAILED_QUIET");
            this.module.UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
            this.module.UnregisterEvent("UNIT_SPELLCAST_START");
            this.module.UnregisterEvent("UNIT_SPELLCAST_STOP");
            this.module.UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
            this.module.UnregisterEvent("UPDATE_SHAPESHIFT_COOLDOWN");
            this.module.UnregisterMessage("Ovale_AuraAdded");
            this.module.UnregisterMessage("Ovale_AuraRemoved");
            this.hasEclipseHandlers = false;
        }
    };

    private onUnitSpellCastStart = (
        event: string,
        unit: string,
        castGUID: string,
        spellId: number
    ) => {
        if (
            unit == "player" &&
            (spellId == this.starfireId || spellId == this.wrathId)
        ) {
            // Sanity-check that the current spellcast is what was expected.
            const [name, , , , , , , , castSpellId] = UnitCastingInfo(unit);
            if (name && spellId == castSpellId) {
                this.isCasting = true;
            }
        }
    };

    private onUnitSpellCastStop = (
        event: string,
        unit: string,
        castGUID: string,
        spellId: number
    ) => {
        if (
            unit == "player" &&
            (spellId == this.starfireId || spellId == this.wrathId)
        ) {
            this.isCasting = false;
            this.adjustCount = false;
        }
    };

    private onUnitSpellCastSucceeded = (
        event: string,
        unit: string,
        castGUID: string,
        spellId: number
    ) => {
        const current = this.current;
        if (
            unit == "player" &&
            (spellId == celestialAlignmentId ||
                spellId == incarnationId ||
                spellId == this.starfireId ||
                spellId == this.wrathId)
        ) {
            this.tracer.debug(`${event}: ${spellId}`);
            this.isCasting = false;
            this.updateSpellCounts(event);
            if (this.adjustCount) {
                if (spellId == this.starfireId && current.starfire > 0) {
                    current.starfire = current.starfire - 1;
                    this.tracer.debug(
                        "%s: adjust starfire: %d",
                        event,
                        current.starfire
                    );
                } else if (spellId == this.wrathId && current.wrath > 0) {
                    current.wrath = current.wrath - 1;
                    this.tracer.debug(
                        "%s: adjust wrath: %d",
                        event,
                        current.wrath
                    );
                }
                this.adjustCount = false;
            }
        }
    };

    private onUpdateShapeshiftCooldown = (event: string) => {
        /* When out of combat, this event seems to fire regularly
         * every few seconds when the spell counts reset.
         */
        if (!this.combat.isInCombat(undefined)) {
            this.updateSpellCounts(event);
        }
    };

    private onOvaleAuraAddedOrRemoved = (
        event: string,
        atTime: number,
        guid: string,
        auraId: number,
        caster: string
    ) => {
        if (guid == this.ovale.playerGUID) {
            if (auraId == leafOnTheWaterId) {
                this.updateSpellMaxCounts(event, atTime);
            } else if (auraId == eclipseLunarId || auraId == eclipseSolarId) {
                if (event == "Ovale_AuraRemoved" && this.isCasting) {
                    /*
                     * GetSpellCounts() does not yet return the correct
                     * information at UNIT_SPELLCAST_SUCCEEDED time if the
                     * count changes mid-cast. If the player is mid-cast
                     * when the Eclipse ends, then we need to adjust the
                     * count.
                     */
                    this.adjustCount = true;
                }
                this.updateSpellCounts(event);
            }
        }
    };

    private updateSpellMaxCounts = (event: string, atTime?: number) => {
        atTime = atTime || GetTime();
        const aura = this.aura.getAura(
            "player",
            leafOnTheWaterId,
            atTime,
            "HELPFUL"
        );
        let starfireMax = 2;
        let wrathMax = 2;
        if (aura) {
            starfireMax = 1;
            wrathMax = 1;
        }
        const current = this.current;
        if (
            current.starfireMax != starfireMax ||
            current.wrathMax != wrathMax
        ) {
            current.starfireMax = starfireMax;
            current.wrathMax = wrathMax;
            this.tracer.debug(
                "%s: starfireMax: %d, wrathMax: %d",
                event,
                starfireMax,
                wrathMax
            );
            this.ovale.needRefresh();
        }
    };

    private updateSpellCounts = (event: string) => {
        const current = this.current;
        const starfire = GetSpellCount(this.starfireId);
        const wrath = GetSpellCount(this.wrathId);
        if (current.starfire != starfire || current.wrath != wrath) {
            current.starfire = starfire;
            current.wrath = wrath;
            this.tracer.debug(
                "%s: starfire: %d, wrath: %d",
                event,
                starfire,
                wrath
            );
            this.ovale.needRefresh();
        }
    };

    // State module

    initializeState() {}

    resetState() {
        const current = this.current;
        const state = this.next;
        state.starfire = current.starfire || 0;
        state.starfireMax = current.starfireMax;
        state.wrath = current.wrath || 0;
        state.wrathMax = current.wrathMax;
    }

    cleanState() {}

    applySpellAfterCast: SpellCastEventHandler = (
        spellId: number,
        targetGUID: string,
        startCast: number,
        endCast: number,
        channel: boolean,
        spellcast: SpellCast
    ) => {
        const state = this.next;
        const prevStarfire = state.starfire;
        const prevWrath = state.wrath;
        let starfire = prevStarfire;
        let wrath = prevWrath;

        // Decrement the counters based on the casted spell.
        if (spellId == celestialAlignmentId) {
            // Celestial Alignment triggers both Eclipse states.
            starfire = 0;
            wrath = 0;
            this.tracer.log(
                "Spell ID '%d' Celestial Alignment resets counts to 0.",
                spellId
            );
            // Celestial Alignment has a default base duration of 20 seconds.
            const duration =
                this.aura.getBaseDuration(
                    celestialAlignmentId,
                    undefined,
                    endCast
                ) || 20;
            this.triggerEclipse(endCast, "lunar", duration);
            this.triggerEclipse(endCast, "solar", duration);
        } else if (spellId == incarnationId) {
            // Incarnation triggers both Eclipse states.
            starfire = 0;
            wrath = 0;
            this.tracer.log(
                "Spell ID '%d' Incarnation: Chosen of Elune resets counts to 0.",
                spellId
            );
            // Incarnation has a default base duration of 20 seconds.
            const duration =
                this.aura.getBaseDuration(incarnationId, undefined, endCast) ||
                30;
            this.triggerEclipse(endCast, "lunar", duration);
            this.triggerEclipse(endCast, "solar", duration);
        } else {
            if (spellId == this.starfireId && prevStarfire > 0) {
                starfire = prevStarfire - 1;
                this.tracer.log(
                    "Spell ID '%d' Starfire decrements count to %d.",
                    spellId,
                    starfire
                );
            } else if (spellId == this.wrathId && prevWrath > 0) {
                wrath = prevWrath - 1;
                this.tracer.log(
                    "Spell ID '%d' Wrath decrements count to %d.",
                    spellId,
                    wrath
                );
            }
            if (prevStarfire > 0 && starfire == 0) {
                // Eclipse (Solar) has a default base duration of 15 seconds.
                const duration =
                    this.aura.getBaseDuration(
                        eclipseSolarId,
                        undefined,
                        endCast
                    ) || 15;
                this.triggerEclipse(endCast, "solar", duration);
                wrath = 0;
            }
            if (prevWrath > 0 && wrath == 0) {
                // Eclipse (Lunar) has a default base duration of 15 seconds.
                const duration =
                    this.aura.getBaseDuration(
                        eclipseLunarId,
                        undefined,
                        endCast
                    ) || 15;
                this.triggerEclipse(endCast, "lunar", duration);
                starfire = 0;
            }
        }
        // Update the counter state.
        state.starfire = starfire;
        state.wrath = wrath;
    };

    private triggerEclipse = (
        atTime: number,
        eclipseType: EclipseType,
        duration: number
    ) => {
        if (eclipseType == "lunar" || eclipseType == "solar") {
            this.tracer.log("Triggering %s eclipse.", eclipseType);
            const auraId =
                (eclipseType == "lunar" && eclipseLunarId) || eclipseSolarId;
            this.aura.addAuraToGUID(
                this.ovale.playerGUID,
                auraId,
                this.ovale.playerGUID,
                "HELPFUL",
                undefined,
                atTime,
                atTime + duration,
                atTime
            );
        }
    };

    private getEclipseAuras = (atTime: number): (Aura | undefined)[] => {
        const lunar = this.aura.getAura(
            "player",
            eclipseLunarId,
            atTime,
            "HELPFUL"
        );
        const solar = this.aura.getAura(
            "player",
            eclipseSolarId,
            atTime,
            "HELPFUL"
        );
        return [lunar, solar];
    };

    /* this.getSpellCounts() has the same return values as API function
     * GetSpellCount(): 0, 1, or 2 for the number of spells needed to
     * enter the next eclipse.
     */
    getSpellCounts(atTime: number): number[] {
        const state = this.next;
        let starfire = state.starfire;
        let wrath = state.wrath;
        if (starfire == 0 && wrath == 0) {
            const [lunar, solar] = this.getEclipseAuras(atTime);
            const inLunar =
                (lunar && this.aura.isActiveAura(lunar, atTime)) || false;
            const inSolar =
                (solar && this.aura.isActiveAura(solar, atTime)) || false;
            if (!inLunar && !inSolar) {
                const lunarEnding = (lunar && lunar.ending) || 0;
                const solarEnding = (solar && solar.ending) || 0;
                if (this.aura.isWithinAuraLag(lunarEnding, solarEnding)) {
                    // exit both eclipses
                    starfire = state.starfireMax;
                    wrath = state.wrathMax;
                } else if (lunarEnding < solarEnding) {
                    // exit solar eclipse
                    wrath = state.wrathMax;
                } else if (lunarEnding > solarEnding) {
                    // exit lunar eclipse
                    starfire = state.starfireMax;
                }
            }
        }
        this.tracer.log(
            "Spell counts at time = %f: starfire = %d, wrath = %d",
            atTime,
            starfire,
            wrath
        );
        return [starfire, wrath];
    }

    getEclipse = (atTime: number): EclipseState => {
        let eclipse: EclipseState = "any_next";
        const [starfire, wrath] = this.getSpellCounts(atTime);
        if (starfire > 0 && wrath > 0) {
            eclipse = "any_next";
        } else if (starfire > 0 && wrath == 0) {
            eclipse = "solar_next";
        } else if (starfire == 0 && wrath > 0) {
            eclipse = "lunar_next";
        } else {
            // (starfire == 0 && wrath == 0)
            const [lunar, solar] = this.getEclipseAuras(atTime);
            const inLunar =
                (lunar && this.aura.isActiveAura(lunar, atTime)) || false;
            const inSolar =
                (solar && this.aura.isActiveAura(solar, atTime)) || false;
            if (inLunar && inSolar) {
                eclipse = "in_both";
            } else if (inLunar) {
                eclipse = "in_lunar";
            } else if (inSolar) {
                eclipse = "in_solar";
            }
        }
        return eclipse;
    };
}
