use "$TEMP\applied", clear
sort id_cutoff_major score_raw
merge m:1 id_cutoff_major using  "$TEMP/applied_cutoffs_major.dta", keep(master match) keepusing(cutoff_rank_major cutoff_std_major R2_major N_below_major N_above_major)



gen score_relative = score_std_major-cutoff_std_major

br score_raw score_relative score_std_major cutoff* R2* N_* admitted  if id_cutoff_major == 1301

count if abs(score_relative)<0.5 & id_cutoff_major==1301
        +-------------------------------------------------------+
        | id_cut~f   rank_s~w   score_~d   cutoff~k   cutoff_~d |
        |-------------------------------------------------------|
  2231. |     1301        136   2.262033         99    .7337833 |
  2235. |     1303         58    1.24614         37    .1795247 |
  2249. |     1313         10   1.968187          8     .490847 |
  6475. |     1754         38   1.265544         22    -.073661 |
  7237. |     1788         53   1.672615         33    .1521805 |
  7494. |     1809         52   1.864995         35     .237875 |
  8616. |     1915         55   1.716701         29   -.0655429 |
  8630. |     1922         38   .5163425          8   -.9058858 |
  9106. |     1977         56   1.155728         32    .0331062 |
 11577. |     2179         12   1.371177          6    -.034659 |
 13116. |     2361        155   1.904147        121    .8052586 |
 13611. |     2441        478   3.148505        451     1.80999 |
 13929. |     2480         61   2.754734         54    1.116121 |
 15263. |     2535        245   2.794315        216    1.093884 |
 16050. |     2591        607   2.928592        585    1.914064 |
 16176. |     2603         49   2.839516         47    1.835168 |
 17107. |     2681        165   2.734024        151    1.500945 |
