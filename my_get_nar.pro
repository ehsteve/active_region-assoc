FUNCTION my_get_nar, time_range, NODIFFROT = nodiffrot

;PURPOSE - Retrieves AR data using get_nar and parses it for a more useful output.
;       
;
;EXAMPLE - result = my_get_nar(['2004/02/01 06:00','2004/02/01 09:00'])
;
;REQUIRED - get_nar.pro
;
;For definition of structure see: http://www.swpc.noaa.gov/ftpdir/forecasts/SRS/README
;
; WRITTEN - Steven Christe (20-Oct-2008)
;MODIFIED - Steven Christe (16-Nov-2010): Added drot_nar call to rotate the nar information 
;               to the time that was actually asked for from the time that was returned from get_nar
;           Steven Christe (17-Dec-2013) - added fix to modify noaa numbers when they roll over
;

millionth_to_arcsec2 = 5.85

IF n_elements(time_range) EQ 1 THEN tr = anytim(anytim(time_range) + [0, 24*60*60d], /yoh) $
    ELSE tr = anytim(time_range, /yoh)

numdays = ceil(time_diff(tr[0], tr[1], unit = 'day')) + 4

num = 0
FOR i = 0, numdays[0]-1 DO BEGIN
    cur_date = anytim(tr[0]) + i*60.0*60.0*24.0
    cur_date = anytim(cur_date, /ecs)
    ar_data = get_nar(strmid(cur_date[0],0,10), /quiet)
    IF datatype(ar_data) EQ 'STC' THEN BEGIN
        IF num EQ 0 THEN BEGIN        
            noaa = ar_data.noaa
            arinfo = ar_data
        ENDIF ELSE BEGIN
            noaa = [noaa, ar_data.noaa]
            arinfo = [arinfo, ar_data]
        ENDELSE
        num++
    ENDIF  
ENDFOR

IF NOT exist(noaa) THEN RETURN, -1
;Eliminate the dupilicate entries
noaa = arinfo.noaa
noaa = noaa[sort(noaa)]
noaa = noaa[uniq(noaa)]

FOR i = 0, n_elements(noaa)-1 DO BEGIN

   index = where(arinfo.noaa EQ noaa[i], count)
   ;stop
   
   day = arinfo[index].day
   s = sort(day)
   day = day[s]
   u = uniq(day)
   nar = arinfo[index[s[u]]]
   
   IF NOT exist(new_arinfo) THEN BEGIN
      new_arinfo = nar
   ENDIF ELSE BEGIN
      new_arinfo = [new_arinfo, nar]
   ENDELSE    

ENDFOR
arinfo = new_arinfo

IF ( exist(arinfo) ) THEN BEGIN
    
    ;IF ((NOT keyword_set(NODIFFROT)) AND (n_elements(time_range) EQ 1 )) THEN ar_data = drot_nar(ar_data, time_range)

    ar_dim = n_elements(arinfo)
    ;stop

    ar_report = create_struct( 'ORIG_DATE', "", 'TIME', "", 'POSITION', fltarr(2), 'NOAA', 0, 'AREA', 0.0,  'RADIUS', 0.0, 'DAY', 0, 'NUM_SPOTS', 0.0, 'ST$MACINTOSH', fltarr(3), 'MACINTOSH', strarr(1), 'LONG_EXT', 0, 'ST$MAG_TYPE', fltarr(16), 'MAG_TYPE', strarr(1), 'ORIG_POSITION', fltarr(2), 'lonlat', fltarr(2))
    ;DOM stands for Day of Mission
    ar_report = replicate(ar_report, ar_dim)
    
    FOR i = 0, ar_dim-1 DO BEGIN
        ar_report[i].ST$MAG_TYPE = arinfo[i].ST$MAG_TYPE
        ar_report[i].MAG_TYPE[0] = string(byte(arinfo[i].ST$MAG_TYPE))

        ar_report[i].ST$MACINTOSH = arinfo[i].ST$MACINTOSH

        ar_report[i].MACINTOSH[0] = string(byte(arinfo[i].ST$MACINTOSH))

        ar_report[i].orig_date = anytim([0,arinfo[i].day], /yoh)
        ar_report[i].time = anytim(time_range[0],/yoh)
        ar_report[i].lonlat = arinfo[i].location
        ar_report[i].orig_position = [arinfo[i].x, arinfo[i].y]

        ar_report[i].position = rot_xy(ar_report[i].orig_position[0], ar_report[i].orig_position[1], tstart = anytim(ar_report[i].orig_date,/yoh), tend = anytim(time_range[0],/yoh))

        ar_report[i].noaa = arinfo[i].noaa
        ;check to see if the noaa number has rolled over if so add 10000
        IF ((anytim(anytim([0,arinfo[i].day], /yoh)) GE anytim('15-Jun-02')) AND $
            (arinfo[i].noaa LE 9000)) THEN $
            ar_report[i].noaa = arinfo[i].noaa + 10000

        ar_report[i].area = arinfo[i].area

        ar_report[i].day = arinfo[i].day
        ar_report[i].NUM_SPOTS = arinfo[i].NUM_SPOTS
        ar_report[i].LONG_EXT = arinfo[i].LONG_EXT

        ;Enter the radius of the active region
        ar_report[i].radius = sqrt(arinfo[i].area*millionth_to_arcsec2/!PI)
    ENDFOR
                
    ;Sort by date
    ar_report = ar_report[sort(ar_report.day)]
    
    IF (n_elements(time_range) EQ 1) THEN index = where(strmid(ar_report.orig_date,0,9) EQ strmid(anytim(time_range[0],/yoh),0,9)) ELSE BEGIN
      con1 = anytim(ar_report.orig_date) LE anytim(time_range[1])
      con2 = anytim(ar_report.orig_date) GE anytim(time_range[0])
      index = where(con1 AND con2)
    ENDELSE
        RETURN, ar_report[index]
    
ENDIF ELSE RETURN, -1

END