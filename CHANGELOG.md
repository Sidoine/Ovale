# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

### [9.0.38](https://github.com/Sidoine/Ovale/compare/9.0.37...9.0.38) (2021-01-14)

### Bug Fixes

-   display the key if the help text doesn't exist ([446e76b](https://github.com/Sidoine/Ovale/commit/446e76b610fea8dea1d761c51646a681afcc0536))
-   pet cast were delaying player cast ([7c3c80a](https://github.com/Sidoine/Ovale/commit/7c3c80af89f239226486f3250931ea1478ef8c0e)), closes [#807](https://github.com/Sidoine/Ovale/issues/807)
-   **ui:** ovale was not hidding out of combat ([4e151d7](https://github.com/Sidoine/Ovale/commit/4e151d72f27b9e5a4ffa1d75f494af81da81f0c2))
-   **warrior:** add support for condemn ([e1e836c](https://github.com/Sidoine/Ovale/commit/e1e836cbf9fc2d089b19a9960b1011ab0b3cda80))

### [9.0.37](https://github.com/Sidoine/Ovale/compare/9.0.36...9.0.37) (2021-01-10)

### [9.0.36](https://github.com/Sidoine/Ovale/compare/9.0.35...9.0.36) (2021-01-09)

### [9.0.35](https://github.com/Sidoine/Ovale/compare/9.0.34...9.0.35) (2021-01-09)

### Bug Fixes

-   **warlock:** spell ids for affliction warlock ([67ccf0a](https://github.com/Sidoine/Ovale/commit/67ccf0a49b6a1d7fe14861a3fe3a4da4d463e230))
-   import last version of simc scripts ([0ed97dc](https://github.com/Sidoine/Ovale/commit/0ed97dc0b42b8601c45ebda2612655260915efe0))
-   **druid:** many fixes and improvements to feral script ([#803](https://github.com/Sidoine/Ovale/issues/803)) ([10a6054](https://github.com/Sidoine/Ovale/commit/10a6054bb1990876f749dcf359eb3aaadb3b7a11))
-   **runner:** fix ComputeArithmetic() for >? and <? operators ([#802](https://github.com/Sidoine/Ovale/issues/802)) ([22f28c1](https://github.com/Sidoine/Ovale/commit/22f28c141070cac126d812e1285f3ac223dd17dd))
-   vertical icons weren't working ([bfc5ae3](https://github.com/Sidoine/Ovale/commit/bfc5ae383f0ac2e18b9c48a131bef66e7e2b3054))

### [9.0.34](https://github.com/Sidoine/Ovale/compare/9.0.33...9.0.34) (2021-01-05)

### Bug Fixes

-   **best-action:** always use the correct texture for actions ([#798](https://github.com/Sidoine/Ovale/issues/798)) ([10d05e5](https://github.com/Sidoine/Ovale/commit/10d05e5e7c89e24ee86b4207887043f4fc0f4e90)), closes [#749](https://github.com/Sidoine/Ovale/issues/749)
-   improve and fix log messages ([#797](https://github.com/Sidoine/Ovale/issues/797)) ([a7e9b3a](https://github.com/Sidoine/Ovale/commit/a7e9b3a0430ed9bfa4a171a7a0267b438b39788f))
-   **hunter:** spell ids and steady focus ([3330ab8](https://github.com/Sidoine/Ovale/commit/3330ab85e3d0acb02a7683f09bb47b9b86463f66)), closes [#795](https://github.com/Sidoine/Ovale/issues/795)

### [9.0.33](https://github.com/Sidoine/Ovale/compare/9.0.32...9.0.33) (2021-01-05)

### Bug Fixes

-   call enemies(tagged=1) ([f6f36e8](https://github.com/Sidoine/Ovale/commit/f6f36e865e6efc6ccc1c7988f6855de4db4d9355)), closes [#475](https://github.com/Sidoine/Ovale/issues/475)
-   the constant values were propagating to parent nodes ([04c102c](https://github.com/Sidoine/Ovale/commit/04c102c842c24e056d68f014142c2a5ec5b57d43))
-   **conditions:** return a proper value for TimeToRunes() ([#793](https://github.com/Sidoine/Ovale/issues/793)) ([8f895c1](https://github.com/Sidoine/Ovale/commit/8f895c12c3c5962c41389b6821c9e75f581fac63))
-   **deathknight:** mark totem spells and fix sacrificial_pact ([#782](https://github.com/Sidoine/Ovale/issues/782)) ([9424a67](https://github.com/Sidoine/Ovale/commit/9424a67fc4c074ed7a51f66ff3f030584a68c675))
-   **demonhunter:** leaping not possible when rooted ([#785](https://github.com/Sidoine/Ovale/issues/785)) ([061d6cf](https://github.com/Sidoine/Ovale/commit/061d6cfb579d5e491ddfe9c34f695d218a944572))
-   **icon:** fix nil arguments to SetText() ([#781](https://github.com/Sidoine/Ovale/issues/781)) ([c296780](https://github.com/Sidoine/Ovale/commit/c296780d43126c866118277dfa94ce4927c328f7)), closes [#780](https://github.com/Sidoine/Ovale/issues/780)
-   **runes:** ensure GetRunesCooldown() returns >=0 ([#790](https://github.com/Sidoine/Ovale/issues/790)) ([dad666d](https://github.com/Sidoine/Ovale/commit/dad666d61de412fa22f941533cb52b2d8f03efbf))
-   check for correct buffs on pets ([#786](https://github.com/Sidoine/Ovale/issues/786)) ([1d0c864](https://github.com/Sidoine/Ovale/commit/1d0c8643320e6e87ea203620a31725229c728cd2))
-   **timespan:** improve check for a time contained in a timespan ([#787](https://github.com/Sidoine/Ovale/issues/787)) ([f5b7783](https://github.com/Sidoine/Ovale/commit/f5b77836bb69a0146cf062f17dbb68f57c83b59e))

### [9.0.32](https://github.com/Sidoine/Ovale/compare/9.0.31...9.0.32) (2020-12-29)

### Features

-   **simulationcraft:** improve meaning of "desired_targets" ([9c1a7d8](https://github.com/Sidoine/Ovale/commit/9c1a7d8e72f90b34d58db11a09173597ac470658)), closes [#236](https://github.com/Sidoine/Ovale/issues/236)

### Bug Fixes

-   **demonhunters:** some spell definitions for Havoc Demon Hunters ([#762](https://github.com/Sidoine/Ovale/issues/762)) ([607a235](https://github.com/Sidoine/Ovale/commit/607a2359557c9b3bfdfbae80eea495e05e7e5768))
-   cd icon ([#765](https://github.com/Sidoine/Ovale/issues/765)) ([98ad6f5](https://github.com/Sidoine/Ovale/commit/98ad6f5ad787489c20c06a9cb5460018d33846b6))
-   script translations of totem pets ([#768](https://github.com/Sidoine/Ovale/issues/768)) ([be32bcb](https://github.com/Sidoine/Ovale/commit/be32bcb155b6d2258ad9b2b792b04721dd6366b8))
-   **ast:** action AddListItem() should accept "default" as parameter ([11ea3a8](https://github.com/Sidoine/Ovale/commit/11ea3a8d97dfb3d7b1ce866969c6a279f54d1696))
-   **controls:** re-evaluate script when controls are modified ([059ba2e](https://github.com/Sidoine/Ovale/commit/059ba2e2698bf244b3773ee6dcb47e1f6c36ab16))

### [9.0.31](https://github.com/Sidoine/Ovale/compare/9.0.30...9.0.31) (2020-12-20)

### Bug Fixes

-   **druid:** sunfire_debuff hadn't the right id ([0937372](https://github.com/Sidoine/Ovale/commit/093737263e0f372b3fa03197e6c28eeb31fe3f76)), closes [#757](https://github.com/Sidoine/Ovale/issues/757)
-   **hunter:** kill short was not working for survival ([1dabbc3](https://github.com/Sidoine/Ovale/commit/1dabbc33daeaec80dfbdd13108bf9cfdd49dc338))
-   **spellflash:** bug with action icon frame ids ([e68218b](https://github.com/Sidoine/Ovale/commit/e68218b1216defbb02ea7f11b1a09846b4cdcd0e))

### [9.0.30](https://github.com/Sidoine/Ovale/compare/9.0.28...9.0.30) (2020-12-20)

### Bug Fixes

-   add missing sudden_death_buff ([8226eda](https://github.com/Sidoine/Ovale/commit/8226eda1d40630d7f02da3ec25586eb36e4b3b10))
-   execute_fury didn't have the health requirement ([2c348ac](https://github.com/Sidoine/Ovale/commit/2c348acdf97c35015f803d3312c5d7c89b5ed153))
-   spells that required either a spec or a talent weren't working ([5f46648](https://github.com/Sidoine/Ovale/commit/5f466489215175b18ea2832c24bb3e3796392a69))
-   update the license and include in the addon releases ([#755](https://github.com/Sidoine/Ovale/issues/755)) ([ec4ef7c](https://github.com/Sidoine/Ovale/commit/ec4ef7c22f85e0b85660ab9bd866f1c36f28c777))

### [9.0.28](https://github.com/Sidoine/Ovale/compare/9.0.27...9.0.28) (2020-12-19)

### Bug Fixes

-   it does not take INFINITY seconds when we already have more power than required ([#753](https://github.com/Sidoine/Ovale/issues/753)) ([1afa181](https://github.com/Sidoine/Ovale/commit/1afa1814af3c002158f8e4b9eccbbe0966aba2a7))
-   specialization spells ([0695abd](https://github.com/Sidoine/Ovale/commit/0695abdc3b057e9973f207f716b84a8917f073c4))
-   spellFlashCore wasn't working with bartender and more fixes ([5dc77ac](https://github.com/Sidoine/Ovale/commit/5dc77acb3a8a01f78f1402177b58548fd67f62d5))

### [9.0.27](https://github.com/Sidoine/Ovale/compare/9.0.26...9.0.27) (2020-12-19)

### Bug Fixes

-   check for time to Runes when computing Time to Power. ([#752](https://github.com/Sidoine/Ovale/issues/752)) ([3ddb48a](https://github.com/Sidoine/Ovale/commit/3ddb48aeac9be142fe603f911f3b7ef84b82b463))
-   register correct callback to AceTimer:ScheduleTimer() ([#742](https://github.com/Sidoine/Ovale/issues/742)) ([d8df7bd](https://github.com/Sidoine/Ovale/commit/d8df7bd244902f838153ba13587df80afd1af506))
-   spells are usable only if they meet all of their power requirements ([#746](https://github.com/Sidoine/Ovale/issues/746)) ([18d7714](https://github.com/Sidoine/Ovale/commit/18d77148dfd32c04b7b2c9f559b0aca624edb8c2)), closes [#737](https://github.com/Sidoine/Ovale/issues/737)
-   update to T26 SimulationCraft scripts ([bc3a3e1](https://github.com/Sidoine/Ovale/commit/bc3a3e1e564cfecaff1ddd248c3e6297ab42dfc9))

### [9.0.26](https://github.com/Sidoine/Ovale/compare/9.0.25...9.0.26) (2020-12-16)

### Bug Fixes

-   remove unnecessary use of "tostring" in isCovenant. ([#734](https://github.com/Sidoine/Ovale/issues/734)) ([b07880b](https://github.com/Sidoine/Ovale/commit/b07880bce0ac478117d42fc57ffb3c53b0c5613d))
-   show cooldown frame if a cooldown is active ([#743](https://github.com/Sidoine/Ovale/issues/743)) ([bead88d](https://github.com/Sidoine/Ovale/commit/bead88d403df49c26bb17d84daff9f56e0a52c35)), closes [#739](https://github.com/Sidoine/Ovale/issues/739)
-   update tstolua ([56fcf58](https://github.com/Sidoine/Ovale/commit/56fcf581f68357d8b0808edde610788791c23855)), closes [#745](https://github.com/Sidoine/Ovale/issues/745)

### [9.0.25](https://github.com/Sidoine/Ovale/compare/9.0.24...9.0.25) (2020-12-15)

### Bug Fixes

-   copy Bindings.xml to output ([926420b](https://github.com/Sidoine/Ovale/commit/926420baf98d8dcdf3c63d0dfe5e2a63ed692201)), closes [#738](https://github.com/Sidoine/Ovale/issues/738)
-   replace SpellFlash by LibButtonGlow-1.0 ([31b45e6](https://github.com/Sidoine/Ovale/commit/31b45e6e0447355ca3b836ded662b585736c3345)), closes [#700](https://github.com/Sidoine/Ovale/issues/700)
-   was always showing development version ([5a45f05](https://github.com/Sidoine/Ovale/commit/5a45f05a87ebed174fd524f6ca4ffe02e919fc35)), closes [#733](https://github.com/Sidoine/Ovale/issues/733)

### [9.0.24](https://github.com/Sidoine/Ovale/compare/9.0.23...9.0.24) (2020-12-14)

### Bug Fixes

-   **priest:** fix various bugs with shadow priest script ([523377a](https://github.com/Sidoine/Ovale/commit/523377aabcabe87668488142c1881fd15abacbb2)), closes [#732](https://github.com/Sidoine/Ovale/issues/732)

### [9.0.23](https://github.com/Sidoine/Ovale/compare/9.0.22...9.0.23) (2020-12-13)

### Bug Fixes

-   **runner:** the correct spell was not chosen in group ([431a644](https://github.com/Sidoine/Ovale/commit/431a644478a82d4830ad0ce88c23bf7be8c4901f)), closes [#723](https://github.com/Sidoine/Ovale/issues/723)
-   add max_xxx back ([b7f79a0](https://github.com/Sidoine/Ovale/commit/b7f79a067184b56976a2e4f0f1a175b39962b0f1))
-   **priest:** work on shadow priest script ([e4cd224](https://github.com/Sidoine/Ovale/commit/e4cd224c89d02218e5954cb0f1a64919196a6fed))
-   add value parameter to conditions ([02896fc](https://github.com/Sidoine/Ovale/commit/02896fcd3011aa17bb90f8e631b53d9759180ccb))
-   some buffs were named \_unused ([b619780](https://github.com/Sidoine/Ovale/commit/b619780d4d959c0fa9294068c66f7777be0bbe52))
-   undue syntax errors on action parameters ([7b6a118](https://github.com/Sidoine/Ovale/commit/7b6a118b94616244edc27e6aec8acb61f7ca1fd2))

### [9.0.22](https://github.com/Sidoine/Ovale/compare/v9.0.21...v9.0.22) (2020-12-09)

### Bug Fixes

-   spell auras that were hidden were overwriting those that were not ([41a78e4](https://github.com/Sidoine/Ovale/commit/41a78e43ed0f76e0760ca3081c7b209f50ab85c8)), closes [#684](https://github.com/Sidoine/Ovale/issues/684)
-   **hunter:** add conditions on kill_shot and harpoon ([f7140b6](https://github.com/Sidoine/Ovale/commit/f7140b670bdee0e663096ae735518e58a246aea7)), closes [#699](https://github.com/Sidoine/Ovale/issues/699)
-   convenant debug pannel was not displayed ([3b5fc92](https://github.com/Sidoine/Ovale/commit/3b5fc92e1a6beb0eb6aedb41a28d9d39a2532f2d)), closes [#726](https://github.com/Sidoine/Ovale/issues/726)
-   remove bitrotted and likely incorrect code regarding "nocd". ([#729](https://github.com/Sidoine/Ovale/issues/729)) ([f704bd0](https://github.com/Sidoine/Ovale/commit/f704bd0e42177b418dc56d1f3589b613c3f6a6d7))

## 9.0.21 (2020-12-07)

### Bug Fixes

-   relax condition on target parameter ([87f61a3](https://github.com/Sidoine/Ovale/commit/87f61a38dffb98866cdde4c3280f90d4e6ec3a04)), closes [#715](https://github.com/Sidoine/Ovale/issues/715)
