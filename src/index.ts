import { registerScripts } from "./scripts/index";
import { IoC } from "./ioc";

export const ioc = new IoC();
registerScripts(ioc.scripts);