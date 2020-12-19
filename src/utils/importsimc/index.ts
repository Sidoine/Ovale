import { existsSync, mkdirSync } from "fs";
import { getSpellData } from "./importspells";
import { writeToWowmock } from "./wow-mock";
import { ClassScripts } from "./class-scripts";
import { exportCommon } from "./common-script";
import { exportData } from "./export-data";

const outputDirectory = "src/scripts";
const simcDirectory = process.argv[2];
const profilesDirectory = simcDirectory + "/profiles/Tier26";

if (!existsSync(outputDirectory)) mkdirSync(outputDirectory);

const spellData = getSpellData(simcDirectory);

// function escapeString(s: string) {
//     if (!s) return s;
//     return s.replace(/"/, '\\"');
// }

if (existsSync("../wow-mock")) {
    writeToWowmock(spellData);
}

const classScripts = new ClassScripts(
    spellData,
    profilesDirectory,
    outputDirectory
);
classScripts.importClassScripts(process.argv[3]);

exportCommon(spellData);
exportData(spellData);
