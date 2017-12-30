export declare type Constructor<T> = new (...argv: any[]) => T;
export interface Library<T> {
    Embed<U>(base: Constructor<U>): Constructor<T & U>;
}
export declare function newClass(base: any, prototype: any): any;
