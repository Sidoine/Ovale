import { readFileSync,  writeFileSync } from "fs";

const directory = process.argv[2];
const spellDataFile = readFileSync(`${directory}/engine/dbc/generated/sc_spell_data.inc`, { encoding: "utf8" });

function getColumns($data: string): [any[], number] {
    const columns = [];
    let i = 0;
    for (; i < $data.length; i++){
        while ($data[i] === ' ') i++;
        const c = $data[i];
        if (c === '"') {
            let start = ++i;
            while ($data[i] !== '"') {
                if ($data[i] === '\\') {
                    i++;
                }
                i++;
            }
            const text = $data.substring(start, i);
            columns.push(text);
        } else if (c >= '0' && c <= '9'  || c === '-') {
            let start = i++;
            while ($data[i] >= '0' && c <= '9' || c === 'x') {
                i++;
            }
            const number = $data.substring(start, i);
            columns.push(parseInt(number));
        } else if (c === '{') {
            const innerData = getColumns($data.substr(i + 1));
            columns.push(<(number | string)[]>innerData[0]);
            i += innerData[1]  + 2;
        } else if (c === '}') {
            break;
        }
        while ($data[i] === ' ') i++;
        if ($data[i] === ',') i++;
    }
    return [columns, i];
}

let output: { [key: string]: any[][] } = {};
let zone: any[][];
for (let $line of spellDataFile.split("\n"))
{
    $line = $line.replace(/\/\/.*/, '');
    let match: RegExpMatchArray;
	if (match = $line.match(/static struct (\w+)/)) {
        zone = [];
        output[match[1]] = zone;
        
	}
	else if (match = $line.match(/{(.*)}/))
	{
        let $data = match[1];
        const [columns] = getColumns($data);
        zone.push(columns);
	}
}

interface SpellData {
    name: string;
    id: number;
    /** 3 Hotfix bitmap
    Each field points to a field in this struct, starting from
    the first field. The most significant bit
    (0x8000 0000 0000 0000) indicates the presence of hotfixed
    effect data for this spell.*/
    hotfix: number;
    /** 4 Projectile Speed */
    prj_speed: number;
    /** 5 Spell school mask */
    school: number;
    /** 6 Class mask for spell */
    class_mask: number;
    /** 7 Racial mask for the spell */
    race_mask: number; 
    /** 8 Array index for gtSpellScaling.dbc. -1 means the first non-class-specific sub array, and so on, 0 disabled */
    scaling_type: number;       
    /** 9 Max scaling level(?), 0 == no restrictions, otherwise min( player_level, max_scaling_level ) */
    max_scaling_level: number;  
    /** 10 Spell learned on level. NOTE: Only accurate for "class abilities" */
    spell_level: number;
    /** 11 Maximum level for scaling */
    max_level: number;
    // SpellRange.dbc
    /** 12 Minimum range in yards */
    min_range: number;
    /** 13 Maximum range in yards */
    max_range: number;
    // SpellCooldown.dbc
    /** 14 Cooldown in milliseconds */
    cooldown: number;           
    /** 15 GCD in milliseconds */
    gcd: number;                
    /** 16 Category cooldown in milliseconds */
    category_cooldown: number;  
    // SpellCategory.dbc
    /** 17 Number of charges */
    charges: number;            
    /** 18 Cooldown duration of charges */
    charge_cooldown: number;    
    // SpellCategories.dbc
    /** 19 Spell category (for shared cooldowns, effects?) */
    category: number;           
    // SpellDuration.dbc
    /** 20 Spell duration in milliseconds */
    duration: number;           
    // SpellAuraOptions.dbc
    /** 21 Maximum stack size for spell */
    max_stack: number;          
    /** 22 Spell proc chance in percent */
    proc_chance: number;        
    /**  23 Per proc charge amount */
    proc_charges: number;       
    /** 24 Proc flags */
    proc_flags: number;         
    /** 25 ICD */
    internal_cooldown: number;  
    /** 26 Base real procs per minute */
    rppm: number;               
    // SpellEquippedItems.dbc
    /** 27  */
    equipped_class: number;         
    /** 28 */
    equipped_invtype_mask: number; 
    /** 29 */
    equipped_subclass_mask: number;
    // SpellScaling.dbc
    /** // 30 Minimum casting time in milliseconds */
    cast_min: number;           
    /** // 31 Maximum casting time in milliseconds */
    cast_max: number;           
    /** // 32 A divisor used in the formula for casting time scaling (20 always?) */
    cast_div: number;           
    /** // 33 A scaling multiplier for level based scaling */
    c_scaling: number;          
    /** // 34 A scaling divisor for level based scaling */
    c_scaling_level: number;    
    // SpecializationSpells.dbc
    /** // Not included in hotfixed data, replaces spell with specialization specific spell */
    replace_spell_id: number;   
    // Spell.dbc flags
    /** // 35 Spell.dbc "flags", record field 1..10, note that 12694 added a field here after flags_7 */
    attributes: number[]; 
    /** 36 SpellClassOptions.dbc flags */
    class_flags: number[]; 
    /** 37 SpellClassOptions.dbc spell family */
    class_flags_family: number; 
    // SpellShapeshift.db2
    /** 38 Stance mask (used only for druid form restrictions?) */
    stance_mask: number;        
    // SpellMechanic.db2
    /** 39 */
    mechanic: number;           
    /** 40 Azerite power id */
    power_id: number;           
    // Textual data
    /** 41 Spell.dbc description stringblock */
    desc: string;               
    /** 42 Spell.dbc tooltip stringblock */
    tooltip: string;            
    // SpellDescriptionVariables.dbc
    /** 43 Spell description variable stringblock, if present */
    desc_vars: string;          
    // SpellIcon.dbc
    /** 44 */
    rank_str: string;           
  
    /** 45 */
    req_max_level: number;
}
const spellData: SpellData[] = [];
for (const row of output.spell_data_t) {
    const spell: SpellData = {
        name: row[0],
        id: row[1],
        hotfix: row[2],
        prj_speed: row[3],
        school: row[4],
        class_mask: row[5],
        race_mask: row[6],
        scaling_type: row[7],
        max_scaling_level: row[8],
        spell_level: row[9],
        max_level: row[10],
        min_range: row[11],
        max_range: row[12],
        cooldown: row[13],
        gcd: row[14],
        category_cooldown: row[15],
        charges: row[16],
        charge_cooldown: row[17],
        category: row[18],
        duration: row[19],
        max_stack: row[20],
        proc_chance: row[21],
        proc_charges: row[22],
        proc_flags: row[23],
        internal_cooldown: row[24],
        rppm: row[25],
        equipped_class: row[26],
        equipped_invtype_mask: row[27],
        equipped_subclass_mask: row[28],
        cast_min: row[29],
        cast_max: row[30],
        cast_div: row[31],
        c_scaling: row[32],
        c_scaling_level: row[33],
        replace_spell_id: row[34],
        attributes: row[35],
        class_flags: row[36],
        class_flags_family: row[37],
        stance_mask: row[38],
        mechanic: row[39],
        power_id: row[40],
        desc: row[41],
        tooltip: row[42],
        desc_vars: row[43],
        rank_str: row[44],
        req_max_level: row[45],
    };
    spellData.push(spell);
}

writeFileSync("test.json", JSON.stringify(spellData, undefined, 4));