import { OvaleQueue } from "../tools/Queue";
import { ipairs, LuaArray, lualength, kpairs } from "@wowts/lua";
import { wrap, LuaIterable } from "@wowts/coroutine";
import { find, sub } from "@wowts/string";

export type Tokenizer = (
    tok: string
) => [string | undefined, string | undefined];

export interface LexerFilter {
    space?: Tokenizer;
    comments?: Tokenizer;
}

export type TokenizerDefinition = { [1]: string; [2]: Tokenizer };

export class OvaleLexer {
    typeQueue = new OvaleQueue<string>("typeQueue");
    tokenQueue = new OvaleQueue<string>("tokenQueue");
    endOfStream: boolean | undefined = undefined;
    iterator: LuaIterable<[string | undefined, string | undefined]>;

    constructor(
        public name: string,
        stream: string,
        matches: LuaArray<TokenizerDefinition>,
        filter?: LexerFilter
    ) {
        this.iterator = this.scan(stream, matches, filter);
    }

    finished = false;
    private scan(
        s: string,
        matches: LuaArray<TokenizerDefinition>,
        filter?: LexerFilter
    ) {
        const me = this;

        const lex = function* (): IterableIterator<
            [string | undefined, string | undefined]
        > {
            if (s == "") {
                return;
            }
            const sz = lualength(s);
            let idx = 1;
            while (true) {
                for (const [, m] of ipairs(matches)) {
                    const pat = m[1];
                    const fun = m[2];
                    const [i1, i2] = find(s, pat, idx);
                    if (i1) {
                        const tok = sub(s, i1, i2);
                        idx = i2 + 1;
                        if (
                            !filter ||
                            (fun !== filter.comments && fun !== filter.space)
                        ) {
                            me.finished = idx > sz;
                            const [res1, res2] = fun(tok);
                            yield [res1, res2];
                        }
                        break;
                    }
                }
            }
        };
        return wrap(lex);
    }

    Release() {
        for (const [key] of kpairs(this)) {
            delete this[key];
        }
    }
    Consume(index?: number): [string | undefined, string | undefined] {
        index = index || 1;
        let tokenType, token;
        while (index > 0 && this.typeQueue.Size() > 0) {
            tokenType = this.typeQueue.RemoveFront();
            token = this.tokenQueue.RemoveFront();
            if (!tokenType) {
                break;
            }
            index = index - 1;
        }
        while (index > 0) {
            [tokenType, token] = this.iterator();
            if (!tokenType) {
                break;
            }
            index = index - 1;
        }
        return [tokenType, token];
    }
    Peek(index?: number): [string | undefined, string | undefined] {
        index = index || 1;
        let tokenType, token;
        while (index > this.typeQueue.Size()) {
            if (this.endOfStream) {
                break;
            } else {
                [tokenType, token] = this.iterator();
                if (!tokenType || !token) {
                    this.endOfStream = true;
                    break;
                }
                this.typeQueue.InsertBack(tokenType);
                this.tokenQueue.InsertBack(token);
            }
        }
        if (index <= this.typeQueue.Size()) {
            tokenType = this.typeQueue.At(index);
            token = this.tokenQueue.At(index);
        }
        return [tokenType, token];
    }
}
