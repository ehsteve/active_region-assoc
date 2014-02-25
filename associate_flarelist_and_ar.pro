PRO ASSOCIATE_FLARELIST_AND_AR, flare_list, OUTPUT_FILENAME = output_filename

default, output_filename, 'flareid_and_noaa.dat'

;NAME: ASSOCIATE_FLARE_LIST_AND_AR
;
;INPUT: list = flare_list, can be the microflare list or the official rhessi flare list
;
;WRITTEN: Steven Christe (7-Jan-2014)

nflares = n_elements(flare_list)

fit_params = create_struct('lonfit', fltarr(4), 'latfit', fltarr(4))

flareid_and_noaa = create_struct('flareid', 0.0, 'noaa', 0.0, 'fit_params', fit_params, 'distance', 0.0)
flareid_and_noaa = replicate(flareid_and_noaa, nflares)

FOR i = 0, nflares-1 DO BEGIN

    x = flare_list[i].position[0]
    y = flare_list[i].position[1]
    peak_time = flare_list[i].peak_time
    con1 = x NE 0
    con2 = y NE 0
    ; if both positions are zero then flare location is probably bad
    IF con1 and con2 THEN BEGIN
        noaa = get_nearest_ar(x, y, peak_time, nar = my_nar, fit_params = fp, distance = d)
        if tag_exist(flare_list, 'id_number') THEN flareid_and_noaa[i].flareid = flare_list[i].id_number $
            ELSE flareid_and_noaa[i].flareid = i
        flareid_and_noaa[i].noaa = noaa
        flareid_and_noaa[i].fit_params = fp
        flareid_and_noaa[i].distance = d  
              
    ENDIF
    
    IF (i mod 100) EQ 0 THEN BEGIN
        print, i
        save, flareid_and_noaa, filename = output_filename
    ENDIF
ENDFOR

save, flareid_and_noaa, filename = output_filename

END