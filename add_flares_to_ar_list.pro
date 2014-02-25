PRO add_flares_to_ar_list, ar_list_filename, flarear_assoc_filename, flare_list

default, flarear_assoc, 'flareid_and_noaa.dat'
default, ar_list_filename, 'ar_list_filename'
default, flare_list, '/Users/schriste/Dropbox/idl/code/db/microflare_list/flare_list_quick.dat'

restore, ar_list_filename, /verbose
restore, flarear_assoc_filename, /verbose
restore, flare_list, /verbose


dim_ar = n_elements(ar_list)

FOR i = 0, dim_ar-1 DO BEGIN

    ; following lines gives all the flares associated with ar_list[i].noaa
    index = where(flareid_and_noaa.noaa EQ ar_list[i].noaa, nflares)
    IF nflares NE 0 THEN BEGIN
        FOR j = 0, nflares-1 DO BEGIN
            IF tag_exist(flare_list, 'id_number') THEN BEGIN
                con = strmid(anytim(ar_list[i].time,/ecs),0,10) EQ strmid(anytim(flare_list[index].peak_time,/ecs),0,10)
                index1 = where(con, count)
                ar_list[i].flareid[index1] = index
            ENDIF ELSE BEGIN
                ; write section for official flare list
            ENDELSE                
        ENDFOR
    ENDIF
    
    IF (i mod 100) EQ 0 THEN BEGIN
        save, ar_list, filename = ar_list_filename + '.mod'
    ENDIF 
    
ENDFOR

save, ar_list, filename = ar_list_filename + '.mod'

END