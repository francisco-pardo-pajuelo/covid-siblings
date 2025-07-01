*- Revision Entrega-3
import delimited "C:\Users\franc\Dropbox\research\projectsX\18_aspirations_siblings_rank\DATA\IN\MINEDU\Entrega-3\MPD2025-EXT-0474065\BDSiagie.txt"

destring id_per_umc , replace
drop if id_per_umc==.
list id_per_umc nivel_educativo_siagie grado_siagie id_persona_madre_rec fecha_nacimiento_madre if id_per_umc<=30


/*
         +----------------------------------------------------------+
         | id_pe~mc   nivel_ed~e   grado_~e   i~madr~c   fech~madre |
         |----------------------------------------------------------|
      1. |        3   Secundaria    SEGUNDO   47973037              |
      2. |        9   Secundaria    TERCERO   83523569   1990-10-01 |
      3. |       11   Secundaria    SEGUNDO   23793920   1978-04-26 |
      4. |       12     Primaria      SEXTO   79463840   1991-09-03 |
      5. |       17     Primaria      SEXTO   85342289   1994-11-30 |
         |----------------------------------------------------------|
      6. |       19     Primaria    PRIMERO   90083542   1971-01-10 |
      7. |       20     Primaria    SEGUNDO   37413932              |
      8. |       21     Primaria     CUARTO   80663650   1987-12-25 |
      9. |       22     Primaria     CUARTO   17192953   1992-05-21 |
     10. |       23   Secundaria    SEGUNDO   48732593   1984-01-27 |
         |----------------------------------------------------------|
     11. |       25     Primaria    TERCERO   02393552   1986-12-19 |
     12. |       26   Secundaria    SEGUNDO   85623125   1984-02-15 |
         +----------------------------------------------------------+
*/

use "$TEMP\siagie_2020", clear

sort id_per_umc
list id_per_umc grade id_mother dob_mother if id_per_umc<=30

/*
         +-----------------------------------------+
         | id_per~c   grade   id_mot~r   dob_mot~r |
         |-----------------------------------------|
      1. |        1       5   70522257   25apr1978 |
      2. |       10       0   11382878   03jun1989 |
1107660. |        2       3   70522257   25apr1978 |
         +-----------------------------------------+
*/