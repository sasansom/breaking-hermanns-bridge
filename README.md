Support data and programs for the article "Breaking Hermann's Bridge".

The database spreadsheet can be found and downloaded [here]([url](https://github.com/sasansom/breaking-hermanns-bridge/blob/3377255161137608f373336c3593640755d601fc/HB_Database.csv)).

The dices/ subdirectory is a partial export of the [DICES](https://github.com/cwf2/dices)
repository at commit
[f1b50a8f](https://github.com/cwf2/dices/tree/f1b50a8fb7620ad5886bc402d7f4ce1d28b287ad).
It is used to annotate
[SEDES](https://github.com/sasansom/sedes) CSV files with speaker information.

```
breaking-hermanns-bridge/dices$ (cd ~/dices && git archive --format tar f1b50a8fb7620ad5886bc402d7f4ce1d28b287ad README.md LICENSE data/1_0/) | tar -xf -
```

## TODO

* Document creation of HB_Database_Predraft.csv from SEDES, Perseus, and DICES.
