PRO get_ar_list, time_range = time_range, OUTPUT_FILENAME = output_filename

default, output_filename, 'ar_list.dat'
default, time_range, ['2002/03/04 17:49:14.000', '2003/03/04 17:49:14.000']

num_days = (anytim(time_range[1]) - anytim(time_range[0]))/(24*60*60)

min_nar = my_get_nar(time_range[0])
max_nar = my_get_nar(time_range[1])

max_noaa = max(max_nar.noaa)
min_noaa = min(min_nar.noaa)

; max number of entries for any AR
dim = 25

ar_list = create_struct( 'ORIG_DATE', strarr(dim), 'TIME', strarr(dim), 'POSITION', fltarr(2, dim), 'NOAA', 0, 'AREA', fltarr(dim),  'RADIUS', fltarr(dim), 'DAY', fltarr(dim), 'NUM_SPOTS', fltarr(dim), 'ST$MACINTOSH', fltarr(16, dim), 'MACINTOSH', strarr(dim), 'LONG_EXT', fltarr(dim), 'ST$MAG_TYPE', fltarr(16,dim), 'MAG_TYPE', strarr(dim), 'ORIG_POSITION', fltarr(2, dim), 'lonlat', fltarr(2,dim), 'fill', 0, 'flareid', fltarr(100))
ar_list = replicate(ar_list, max_noaa-min_noaa)

FOR i = 0, 10-1 DO BEGIN

    cur_day = anytim(anytim(time_range[0]) + 24d*60*60*i,/yoh)

    nar = my_get_nar(cur_day)
    
    dim = n_elements(nar)
    FOR j = 0, dim-1 DO BEGIN
        result_index = where(ar_list.noaa EQ nar[j].noaa, count)
        IF count EQ 0 THEN BEGIN
            index = where(ar_list.noaa EQ 0)
            result_index = min(index)
            fill_index = 0
        ENDIF ELSE BEGIN
            fill_index = ar_list[result_index].fill
        ENDELSE

        ar_list[result_index].time[fill_index+1] = nar[j].time
        ar_list[result_index].area[fill_index+1] = nar[j].area        
        ar_list[result_index].orig_date[fill_index+1] = nar[j].orig_date
        ar_list[result_index].position[*,fill_index+1] = nar[j].position
        ar_list[result_index].noaa = nar[j].noaa
        ar_list[result_index].radius[fill_index+1] = nar[j].radius
        ar_list[result_index].area[fill_index+1] = nar[j].area
        ar_list[result_index].macintosh[fill_index+1] = nar[j].macintosh
        ar_list[result_index].num_spots[fill_index+1] = nar[j].num_spots
        ar_list[result_index].mag_type[fill_index+1] = nar[j].mag_type
        ar_list[result_index].orig_position[*, fill_index+1] = nar[j].orig_position
        ar_list[result_index].lonlat[*, fill_index+1] = nar[j].lonlat
        ar_list[result_index].long_ext[fill_index+1] = nar[j].long_ext
        ar_list[result_index].ST$MAG_TYPE[*, fill_index+1] = nar[j].ST$MAG_TYPE
        ar_list[result_index].day[fill_index+1] = nar[j].day
        
        ar_list[result_index].fill = fill_index+1

    ENDFOR
    
    IF (i mod 100) EQ 0 THEN BEGIN
        save, ar_list, filename = output_filename
    ENDIF 

ENDFOR

save, ar_list, filename = output_filename

END