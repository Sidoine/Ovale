import { SpellData } from "./importspells";

function getDuration(duration: number) {
    return `${duration/1000} second${duration > 1000 ? 's' : ''}`;
}

function parseToken(token: string, spell: SpellData, spellDataById: Map<number, SpellData>) {
    const otherSpellDesc = token.match(/^@spelldesc(\d+)$/);
    if (otherSpellDesc) {
        const otherSpell = spellDataById.get(parseInt(otherSpellDesc[1]));
        if (otherSpell && otherSpell.desc && otherSpell !== spell) return parseDescription(otherSpell.desc, otherSpell, spellDataById);
    }

    const reference = token.match(/^\d+/);
    if (reference) {
        token = token.substring(reference[0].length);
        const referenceSpell = spellDataById.get(parseInt(reference[0]));
        if (!referenceSpell) return undefined;
        spell = referenceSpell;
    }
    if (token === 'd') {
        return getDuration(spell.duration);
    }
    const match = token.match(/^s(\d)$/);
    if (match) {
        const i = parseInt(match[1]);
        if (i > 0 && spell.spellEffects && spell.spellEffects.length >= i) {
            const spellEffect = spell.spellEffects[i - 1];
            if (spellEffect.sp_coeff) {
                return `(${spellEffect.sp_coeff * 100}% of Spell Power)`;
            }
        }
    }
    return undefined;
}

export function parseDescription(description: string, spell: SpellData, spellDataById: Map<number, SpellData>) {
    if (!description) return undefined;
    description = description.replace(/\$(@?[a-z0-9]+)/g, (complete, token) => parseToken(token, spell, spellDataById) || complete);
    return description;
}
