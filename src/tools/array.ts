import { LuaArray, lualength } from "@wowts/lua";
import { floor } from "@wowts/math";
import { insert, remove } from "@wowts/table";

type LessThanFunction<T> = (a: T, b: T) => boolean;

function lessThanDefault<T>(a: T, b: T) {
    return a < b;
}

function equal<T>(a: T, b: T, lessThan: LessThanFunction<T>) {
    return !lessThan(a, b) && !lessThan(b, a);
}

/* binarySearchRight() returns the rightmost index of a sorted array
 * where the value can be inserted and still maintain the sorted order.
 */
function binarySearchRight<T>(
    t: LuaArray<T>,
    value: T,
    lessThan?: LessThanFunction<T>
) {
    lessThan = lessThan || lessThanDefault;
    let [low, high] = [1, lualength(t)];
    while (low <= high) {
        const mid = low + floor((high - low) / 2);
        if (lessThan(value, t[mid])) {
            high = mid - 1;
        } else {
            low = mid + 1;
        }
    }
    return low;
}

/* binarySearch() returns the rightmost index of a sorted array where a
 * matching value is found, or undefined otherwise.
 */
export function binarySearch<T>(
    t: LuaArray<T>,
    value: T,
    lessThan?: LessThanFunction<T>
) {
    lessThan = lessThan || lessThanDefault;
    const index = binarySearchRight(t, value, lessThan);
    if (index > 1 && equal(t[index - 1], value, lessThan)) {
        return index - 1;
    }
    return undefined;
}

/* binaryRemove() removes all elements from a sorted array that match the
 * given value.
 */
export function binaryRemove<T>(
    t: LuaArray<T>,
    value: T,
    lessThan?: LessThanFunction<T>
) {
    lessThan = lessThan || lessThanDefault;
    let index = binarySearchRight(t, value, lessThan);
    while (index > 1 && equal(t[index - 1], value, lessThan)) {
        remove(t, index - 1);
        index -= 1;
    }
}

/* binaryInsert() inserts the value into a sorted array.
 */
export function binaryInsert<T>(
    t: LuaArray<T>,
    value: T,
    lessThan?: LessThanFunction<T>
) {
    lessThan = lessThan || lessThanDefault;
    let index = binarySearchRight(t, value, lessThan);
    insert(t, index, value);
}

/* binaryInsertUnique() inserts the value into a sorted array only if the
 * value does not already exist in the array.
 */
export function binaryInsertUnique<T>(
    t: LuaArray<T>,
    value: T,
    lessThan?: LessThanFunction<T>
) {
    lessThan = lessThan || lessThanDefault;
    let index = binarySearchRight(t, value, lessThan);
    if (index == 1 || !equal(t[index - 1], value, lessThan)) {
        insert(t, index, value);
    }
}
