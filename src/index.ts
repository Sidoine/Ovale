import { registerScripts } from "./scripts/index";
import { IoC } from "./ioc";

const ioc = new IoC();
registerScripts(ioc.scripts);