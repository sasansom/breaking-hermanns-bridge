Copy of preprocessed SEDES corpus files and outputs.

Taken from commit [64de3077](https://github.com/sasansom/sedes/tree/64de3077374e8bbbc26ba59e7abc2545fc2abc80),
however will one change to line 3.394 in iliad.xml:

```diff
diff --git a/corpus/iliad.xml b/corpus/iliad.xml
index 9507740..5797d1e 100644
--- a/corpus/iliad.xml
+++ b/corpus/iliad.xml
@@ -5606,7 +5606,7 @@
 <l>ou)de/ min w(=s game/w: o(\ d' *)axaiw=n a)/llon e(le/sqw,</l>
 <l>o(/s tis oi(= t' e)pe/oike kai\ o(\s basileu/tero/s e)stin.</l>
 <l>h)\n ga\r dh/ me saw=si qeoi\ kai\ oi)/kad' i(/kwmai,</l>
-<l>*phleu/s qh/n moi e)/peita gunai=ka/ ge ma/ssetai au)to/s.</l>
+<l>*phleu/s qh/n moi e)/peita gunai=ka/ game/ssetai au)to/s.</l>
 <l n="395">pollai\ *)axaii/+des ei)si\n a)n' *(ella/da te *fqi/hn te</l>
 <l>kou=rai a)risth/wn, oi(/ te ptoli/eqra r(u/ontai,</l>
 <l>ta/wn h(/n k' e)qe/lwmi fi/lhn poih/som' a)/koitin.</l>
```

```
src/join-expectancy corpus/*.csv expectancy.all.csv > joined.all.csv
```
