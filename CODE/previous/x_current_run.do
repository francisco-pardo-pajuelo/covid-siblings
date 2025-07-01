setup
em
sibling_id


do "$CODE\A00_clean_final"



/*
open	
list aux_id_per_umc aux_fam_order_4 fam_order_4 _m if id_fam_4 == -80254984
	br  *fam*4 if id_fam_4 == -80254984

         +--------------------------------------------------+
         | aux_id~c   aux_fa~4   fam_or~4            _merge |
         |--------------------------------------------------|
      1. | 11019764          1          2   Master only (1) |
      2. | 11019764          1          3   Master only (1) | -80254985
      3. |  9383583          2          3   Master only (1) | -80254979
      4. |  9383583          2          4   Master only (1) |
         +--------------------------------------------------+

		 */
	
	use "$OUT\students",clear
	
	list id_per_umc fam_order_4 if id_fam_4 == -80254985