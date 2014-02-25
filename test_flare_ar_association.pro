PRO test_flare_ar_association, time_range, seed, numflares

;PURPOSE - 
;
;KEYWORDS
;       seed - the seed for the random number generator to choose random flares
;       numflares - the number of flares to choose
;       time_range - the time range to choose flares from
;
;WRITTEN: Steven Christe (16-dec-2013)

DEFAULT, time_range, ['2002/03/01 12:00', '2013/03/01 12:00']
DEFAULT, seed, 12539
DEFAULT, numflares, 1000

result = create_struct('flare_id', 0.0, 'ar_id', 0.0)
result = replicate(result, numflares)

flare_list_obj = obj_new('hsi_flare_list')
;load the whole flare list - sorry kinda slow
flare_list = flare_list_obj -> getdata(obs_time_interval = time_range)
dim = n_elements(flare_list)

index = floor(randomu(seed, numflares) * dim)
index = index[sort(index)]

test_list = flare_list[index]

FOR i = 0, numflares-1 DO BEGIN
    result[i].flare_id = test_list[i].id_number
    
    xy = test_list[i].position
    con1 = xy[0] NE 0.0
    con2 = xy[1] NE 0.0
    IF con1 and con2 THEN result[i].ar_id = get_nearest_ar(test_list[i].position[0], test_list[i].position[1], test_list[i].peak_time)
    
    IF (i mod 100) EQ 0 THEN BEGIN
        print, i
        save, result, filename = 'ar_association.dat'
    ENDIF
ENDFOR
stop
save, result, filename = 'ar_association.dat'

END