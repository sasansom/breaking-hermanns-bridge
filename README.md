Support data and programs for the article "Breaking Hermann's Bridge".

The dices/ subdirectory is a partial export of the [DICES](https://github.com/cwf2/dices)
repository at commit
[6fc7c12b361029523f39055f0b09fb4c14594747](https://github.com/cwf2/dices/tree/6fc7c12b361029523f39055f0b09fb4c14594747).
It is used to annotate
[SEDES](https://github.com/sasansom/sedes) CSV files with speaker information.

```
breaking-hermanns-bridge/dices$ (cd ~/dices && git archive --format tar 6fc7c12b361029523f39055f0b09fb4c14594747 README.md LICENSE data/1_0/) | tar -xf -
```

TODO:
* Document creation of HB_Database_Predraft.csv from SEDES, Perseus, and DICES.
* Have alternate Iliad 9.394 represented in the data.
* Compare lists of transgressions in Iliad and Odyssey with [Abritta 2018](https://empgriegos.wordpress.com/datos-experimentales/sobre-las-violaciones-del-puente-de-hermann/).
* Update for text changes [since 8fffa930](https://github.com/sasansom/sedes/compare/8fffa930aad32c1449fb2aec779f86a6eb3111f6...c08cb6fb7e7e68ddb851821e159fcf22dc2452a8).
