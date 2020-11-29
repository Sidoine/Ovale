import { test, expect } from "@jest/globals";
import { It, Mock } from "typemoq";
import { registerScripts } from "./index";
import { OvaleScriptsClass } from "../engine/scripts";

test("Test scripts", () => {
    // Arrange
    const messages = new Map<string, number>();
    const scriptsMock = Mock.ofType<OvaleScriptsClass>();
    scriptsMock
        .setup((x) =>
            x.RegisterScript(
                It.isAny(),
                It.isAny(),
                It.isAnyString(),
                It.isAnyString(),
                It.isAnyString(),
                It.isAny()
            )
        )
        .callback(
            (
                className: string,
                specialization: string,
                name: string,
                description: string,
                code: string
            ) => {
                const regex = /message\("(.*?)"\)/g;
                let results;
                while ((results = regex.exec(code)) !== null) {
                    const message = results[1];
                    const value = messages.get(message);
                    if (value) {
                        messages.set(message, value + 1);
                    } else {
                        messages.set(message, 1);
                    }
                }
            }
        );

    // Act
    registerScripts(scriptsMock.object);

    // Assert
    expect(Array.from(messages.keys())).toEqual([]);
});
