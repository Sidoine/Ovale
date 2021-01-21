import { select, wipe, LuaArray, lualength } from "@wowts/lua";
import { format } from "@wowts/string";
import { concat, insert, remove } from "@wowts/table";
import { huge } from "@wowts/math";

const infinity = huge;
const timeSpanPool: LuaArray<OvaleTimeSpan> = {};
let poolSize = 0;
let poolUnused = 0;

const compareIntervals = function (
    startA: number,
    endA: number,
    startB: number,
    endB: number
) {
    if (startA == startB && endA == endB) {
        return 0;
    } else if (startA < startB && endA >= startB && endA <= endB) {
        return -1;
    } else if (startB < startA && endB >= startA && endB <= endA) {
        return 1;
    } else if (
        (startA == startB && endA > endB) ||
        (startA < startB && endA == endB) ||
        (startA < startB && endA > endB)
    ) {
        return -2;
    } else if (
        (startB == startA && endB > endA) ||
        (startB < startA && endB == endA) ||
        (startB < startA && endB > endA)
    ) {
        return 2;
    } else if (endA <= startB) {
        return -3;
    } else if (endB <= startA) {
        return 3;
    }
    return 99;
};

export function newTimeSpan() {
    let obj = remove(timeSpanPool);
    if (obj) {
        poolUnused = poolUnused - 1;
    } else {
        obj = new OvaleTimeSpan();
        poolSize = poolSize + 1;
    }
    return obj;
}

export function newFromArgs(...parameters: number[]) {
    return newTimeSpan().copy(...parameters);
}

export function newTimeSpanFromArray(a?: OvaleTimeSpan) {
    if (a) {
        return newTimeSpan().copyFromArray(a);
    } else {
        return newTimeSpan();
    }
}

export function releaseTimeSpans(...parameters: OvaleTimeSpan[]) {
    const argc = select("#", parameters);
    for (let i = 1; i <= argc; i += 1) {
        const a = select(i, parameters);
        wipe(a);
        insert(timeSpanPool, a);
    }
    poolUnused = poolUnused + argc;
}

export function getPoolInfo() {
    return [poolSize, poolUnused];
}

export class OvaleTimeSpan implements LuaArray<number | undefined> {
    [key: number]: number;

    release() {
        wipe(this);
        insert(timeSpanPool, this);
        poolUnused = poolUnused + 1;
    }

    // eslint-disable-next-line @typescript-eslint/naming-convention
    __tostring() {
        if (lualength(this) == 0) {
            return "empty set";
        } else {
            return format("(%s)", concat(this, ", "));
        }
    }

    toString() {
        return this.__tostring();
    }

    copyFromArray(a: OvaleTimeSpan) {
        const count = lualength(a);
        for (let i = 1; i <= count; i += 1) {
            this[i] = a[i];
        }
        const length = lualength(this);
        for (let i = count + 1; i <= length; i += 1) {
            delete this[i];
        }
        return this;
    }

    copy(...parameters: number[]) {
        const count = select("#", parameters);
        for (let i = 1; i <= count; i += 1) {
            this[i] = select(i, parameters);
        }
        const length = lualength(this);
        for (let i = count + 1; i <= length; i += 1) {
            delete this[i];
        }
        return this;
    }

    isEmpty() {
        return lualength(this) == 0;
    }

    isUniverse() {
        return this[1] == 0 && this[2] == infinity;
    }

    equals(b: OvaleTimeSpan) {
        const a = this;
        const countA = lualength(a);
        const countB = (b && lualength(b)) || 0;
        if (countA != countB) {
            return false;
        }
        for (let k = 1; k <= countA; k += 1) {
            if (a[k] != b[k]) {
                return false;
            }
        }
        return true;
    }

    hasTime(atTime: number) {
        const a = this;
        for (let i = 1; i <= lualength(a); i += 2) {
            if (a[i] <= atTime && atTime < a[i + 1]) {
                return true;
            }
        }
        return false;
    }

    nextTime(atTime: number): number | undefined {
        const a = this;
        for (let i = 1; i <= lualength(a); i += 2) {
            if (atTime < a[i]) {
                return a[i];
            } else if (a[i] <= atTime && atTime <= a[i + 1]) {
                return atTime;
            }
        }
    }

    measure() {
        const a = this;
        let measure = 0;
        for (let i = 1; i <= lualength(a); i += 2) {
            measure = measure + (a[i + 1] - a[i]);
        }
        return measure;
    }

    complement(result?: OvaleTimeSpan) {
        const a = this;
        const countA = lualength(a);
        if (countA == 0) {
            if (result) {
                result.copyFromArray(universe);
            } else {
                result = newTimeSpanFromArray(universe);
            }
        } else {
            result = result || newTimeSpan();
            let countResult = 0;
            let [i, k] = [1, 1];
            if (a[i] == 0) {
                i = i + 1;
            } else {
                result[k] = 0;
                countResult = k;
                k = k + 1;
            }
            while (i < countA) {
                result[k] = a[i];
                countResult = k;
                [i, k] = [i + 1, k + 1];
            }
            if (a[i] < infinity) {
                [result[k], result[k + 1]] = [a[i], infinity];
                countResult = k + 1;
            }
            for (let j = countResult + 1; j <= lualength(result); j += 1) {
                delete result[j];
            }
        }
        return result;
    }

    intersectInterval(startB: number, endB: number, result?: OvaleTimeSpan) {
        const a = this;
        const countA = lualength(a);
        result = result || newTimeSpan();
        if (countA > 0) {
            let countResult = 0;
            let [i, k] = [1, 1];
            while (true) {
                if (i > countA) {
                    break;
                }
                const [startA, endA] = [a[i], a[i + 1]];
                const compare = compareIntervals(startA, endA, startB, endB);
                if (compare == 0) {
                    [result[k], result[k + 1]] = [startA, endA];
                    countResult = k + 1;
                    break;
                } else if (compare == -1) {
                    if (endA > startB) {
                        [result[k], result[k + 1]] = [startB, endA];
                        countResult = k + 1;
                        [i, k] = [i + 2, k + 2];
                    } else {
                        i = i + 2;
                    }
                } else if (compare == 1) {
                    if (endB > startA) {
                        [result[k], result[k + 1]] = [startA, endB];
                        countResult = k + 1;
                    }
                    break;
                } else if (compare == -2) {
                    [result[k], result[k + 1]] = [startB, endB];
                    countResult = k + 1;
                    break;
                } else if (compare == 2) {
                    [result[k], result[k + 1]] = [startA, endA];
                    countResult = k + 1;
                    [i, k] = [i + 2, k + 2];
                } else if (compare == -3) {
                    i = i + 2;
                } else if (compare == 3) {
                    break;
                }
            }
            for (let n = countResult + 1; n <= lualength(result); n += 1) {
                delete result[n];
            }
        }
        return result;
    }

    intersect(b: OvaleTimeSpan, result?: OvaleTimeSpan) {
        const a = this;
        const countA = lualength(a);
        const countB = (b && lualength(b)) || 0;
        result = result || newTimeSpan();
        let countResult = 0;
        if (countA > 0 && countB > 0) {
            let [i, j, k] = [1, 1, 1];
            while (true) {
                if (i > countA || j > countB) {
                    break;
                }
                const [startA, endA] = [a[i], a[i + 1]];
                const [startB, endB] = [b[j], b[j + 1]];
                const compare = compareIntervals(startA, endA, startB, endB);
                if (compare == 0) {
                    [result[k], result[k + 1]] = [startA, endA];
                    countResult = k + 1;
                    [i, j, k] = [i + 2, j + 2, k + 2];
                } else if (compare == -1) {
                    if (endA > startB) {
                        [result[k], result[k + 1]] = [startB, endA];
                        countResult = k + 1;
                        [i, k] = [i + 2, k + 2];
                    } else {
                        i = i + 2;
                    }
                } else if (compare == 1) {
                    if (endB > startA) {
                        [result[k], result[k + 1]] = [startA, endB];
                        countResult = k + 1;
                        [j, k] = [j + 2, k + 2];
                    } else {
                        j = j + 2;
                    }
                } else if (compare == -2) {
                    [result[k], result[k + 1]] = [startB, endB];
                    countResult = k + 1;
                    [j, k] = [j + 2, k + 2];
                } else if (compare == 2) {
                    [result[k], result[k + 1]] = [startA, endA];
                    countResult = k + 1;
                    [i, k] = [i + 2, k + 2];
                } else if (compare == -3) {
                    i = i + 2;
                } else if (compare == 3) {
                    j = j + 2;
                } else {
                    i = i + 2;
                    j = j + 2;
                }
            }
        }
        for (let n = countResult + 1; n <= lualength(result); n += 1) {
            delete result[n];
        }
        return result;
    }

    union(b: OvaleTimeSpan, result?: OvaleTimeSpan): OvaleTimeSpan {
        const a = this;
        const countA = lualength(a);
        const countB = (b && lualength(b)) || 0;
        if (countA == 0) {
            if (b) {
                if (result) {
                    result.copyFromArray(b);
                } else {
                    result = newTimeSpanFromArray(b);
                }
            } else {
                result = emptySet;
            }
        } else if (countB == 0) {
            if (result) {
                result.copyFromArray(a);
            } else {
                result = newTimeSpanFromArray(a);
            }
        } else {
            result = result || newTimeSpan();
            let countResult = 0;
            let [i, j, k] = [1, 1, 1];
            let [startTemp, endTemp] = [a[i], a[i + 1]];
            let holdingA = true;
            let scanningA = false;
            while (true) {
                let startA,
                    endA,
                    startB: number | undefined,
                    endB: number | undefined;
                if (i > countA && j > countB) {
                    [result[k], result[k + 1]] = [startTemp, endTemp];
                    countResult = k + 1;
                    k = k + 2;
                    break;
                }
                if (scanningA && i > countA) {
                    holdingA = !holdingA;
                    scanningA = !scanningA;
                } else {
                    [startA, endA] = [a[i], a[i + 1]];
                }
                if (!scanningA && j > countB) {
                    holdingA = !holdingA;
                    scanningA = !scanningA;
                } else {
                    [startB, endB] = [b[j], b[j + 1]];
                }
                const startCurrent = (scanningA && startA) || startB || 0;
                const endCurrent = (scanningA && endA) || endB || 0;
                const compare = compareIntervals(
                    startTemp,
                    endTemp,
                    startCurrent,
                    endCurrent
                );
                if (compare == 0) {
                    if (scanningA) {
                        i = i + 2;
                    } else {
                        j = j + 2;
                    }
                } else if (compare == -2) {
                    if (scanningA) {
                        i = i + 2;
                    } else {
                        j = j + 2;
                    }
                } else if (compare == -1) {
                    endTemp = endCurrent;
                    if (scanningA) {
                        i = i + 2;
                    } else {
                        j = j + 2;
                    }
                } else if (compare == 1) {
                    startTemp = startCurrent;
                    if (scanningA) {
                        i = i + 2;
                    } else {
                        j = j + 2;
                    }
                } else if (compare == 2) {
                    [startTemp, endTemp] = [startCurrent, endCurrent];
                    holdingA = !holdingA;
                    scanningA = !scanningA;
                    if (scanningA) {
                        i = i + 2;
                    } else {
                        j = j + 2;
                    }
                } else if (compare == -3) {
                    if (holdingA == scanningA) {
                        [result[k], result[k + 1]] = [startTemp, endTemp];
                        countResult = k + 1;
                        [startTemp, endTemp] = [startCurrent, endCurrent];
                        scanningA = !scanningA;
                        k = k + 2;
                    } else {
                        scanningA = !scanningA;
                        if (scanningA) {
                            i = i + 2;
                        } else {
                            j = j + 2;
                        }
                    }
                } else if (compare == 3) {
                    [startTemp, endTemp] = [startCurrent, endCurrent];
                    holdingA = !holdingA;
                    scanningA = !scanningA;
                } else {
                    i = i + 2;
                    j = j + 2;
                }
            }
            for (let n = countResult + 1; n <= lualength(result); n += 1) {
                delete result[n];
            }
        }
        return result;
    }
}

export const universe = newFromArgs(0, infinity);
export const emptySet = newTimeSpan();
