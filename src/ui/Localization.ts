import { GetLocale } from "@wowts/wow-mock";
import { setDEDE } from "./localization/de-DE";
import { getENUS } from "./localization/en-US";
import { setESES } from "./localization/es-ES";
import { setESMX } from "./localization/es-MX";
import { setFRFR } from "./localization/fr-FR";
import { setITIT } from "./localization/it-IT";
import { setKOKR } from "./localization/ko-KR";
import { setPTBR } from "./localization/pt-BR";
import { setRURU } from "./localization/ru-RU";
import { setZHCN } from "./localization/zh-CN";
import { setZHTW } from "./localization/zh-TW";

export const l = getENUS();

const locale = GetLocale();
if (locale == "deDE") {
    setDEDE(l);
} else if (locale == "esES") {
    setESES(l);
} else if (locale == "esMX") {
    setESMX(l);
} else if (locale == "frFR") {
    setFRFR(l);
} else if (locale == "itIT") {
    setITIT(l);
} else if (locale == "koKR") {
    setKOKR(l);
} else if (locale == "ptBR") {
    setPTBR(l);
} else if (locale == "ruRU") {
    setRURU(l);
} else if (locale == "zhCN") {
    setZHCN(l);
} else if (locale == "zhTW") {
    setZHTW(l);
}
