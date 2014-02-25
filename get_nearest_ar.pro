FUNCTION FIT_AR_TRACK, lon, lat, time, time_range, PLOT = plot, VERBOSE = verbose, ERROR = error

;PURPOSE: Fit the longitude and latitude of a feature as a function of time. Return the
;           linear fit results.
;
;RETURNS: Structure
;
;KEYWORDS:
;       PLOT - show plot of the fit
;       VERBOSE - print some debugging information to the screen;       
;       ERROR - Set an error on the AR positions (default is 5 arcsec)
;
; WRITTEN: Steven Christe (5-Aug-2011)
;MODIFIED: Steven Christe (16-Dec-2013), added error in AR positions and now returns chisq

program_name = 'FIT_AR_TRACK'

IF NOT keyword_set(ERROR) THEN error = 5

;definition
;[intercept, slope, chisq, num points fit]
result = create_struct('lonfit', replicate(-1.0, 4), 'latfit', replicate(-1.0, 4))

num_points = n_elements(lon)

IF num_points GT 1 THEN BEGIN

    IF keyword_set(PLOT) THEN BEGIN  
        utplot, time, lon, yrange = [-90,90], /nodata
        outplot, time, lon, psym = 4
        outplot, time, lat, psym = 5
        uterrplot, time, lat-error, lat+error
        uterrplot, time, lon-error, lon+error
        ssw_legend, ['longitude', 'latitude'], psym = [4,5]
    ENDIF
    
    utbase = anytim(time_range[0])
    x = anytim(time) - utbase

    FOR i = 0, 1 DO BEGIN
        IF i EQ 0 THEN y = lon ELSE y = lat

        index = where(abs(y) LE 90, count)
        IF count GT 1.0 THEN BEGIN
            y = y[index]
            x = x[index]
            fit_results = linfit(x,y, measure_errors=replicate(error, count), chisq=chisq)            
            IF keyword_set(PLOT) THEN outplot, time, fit_results[1]*x + fit_results[0]
            
            ;store results
            IF i EQ 0 THEN BEGIN
                result.lonfit[0:1] = fit_results
                result.lonfit[2] = chisq
                result.lonfit[3] = count
            ENDIF ELSE BEGIN
                result.latfit[0:1] = fit_results
                result.latfit[2] = chisq
                result.latfit[3] = count
            ENDELSE
        ENDIF
    ENDFOR

    IF keyword_set(VERBOSE) THEN BEGIN
        print, program_name + '-> ' + 'Longitude fit (y = mt + b)'
        print, program_name + '-> ' + 'm = ', result.lonfit[1], ' b = ', result.lonfit[0], ' chisq = ', result.lonfit[2]
        print, program_name + '-> ' + 'Latitude fit (y = mt + b)'
        print, program_name + '-> ' + 'm = ', result.latfit[1], ' b = ', result.latfit[0], ' chisq = ', result.latfit[2]
    ENDIF

ENDIF 

RETURN, result

END

FUNCTION GET_NEAREST_AR, x_arcsec, y_arcsec, time, NAR = NAR, DEBUG = debug, PLOT = plot, DISTANCE = distance, VERBOSE = verbose, FIT_PARAMS = fit_params

;PURPOSE: Given a time and position find the nearest active region
;
;KEYWORDS:
;                          
;        
;
;REQUIREMENT: my_get_nar.pro, track_ar.pro
;
;EXAMPLE:
; WRITTEN: Steven Christe
;MODIFIED:  Natsuha Kuroda

;If flare position was invalid, return -1
;If the flare occurs at the west limb from newly emerged active region, this program may not associate the flare with that active region since there's possibly only one position available to plot

;NAR returns the AR structure for the active region

;Convert peak_time into ecs format for get_nar.pro

program_name = 'GET_NEAREST_AR'

peak_time = anytim(time, /ecs)
position = [x_arcsec, y_arcsec]

;IF (position[0] EQ 0.0) AND (position[1] EQ 0.0) THEN return, -1

;Determine the time range for predicted AR position vs. time plot

rotation = 27.2753          ;average rotation rate of the sun in days.
disk_days = rotation/2.0    ;average number of days to "renew" the disk

east_days = -disk_days/2.0
west_days = disk_days/2.0

;convert position to heliographic coordinates
lonlat = arcmin2hel(position[0]/60.0, position[1]/60.0, date = peak_time, off_limb = flare_offdisk)

flare_ondisk = flare_offdisk EQ 0

oneday_deg = 360.0/rotation
days_before = (lonlat[1]/oneday_deg) - east_days
days_after = west_days - (lonlat[1]/oneday_deg)

time_range = anytim(peak_time) + [-days_before, days_after]*60.0*60.0*24.0

IF keyword_set(VERBOSE) THEN print, program_name + '->' + 'Searching ' + anytim(time_range[0],/ecs) + ' to ' + anytim(time_range[1],/ecs)

;Obtain an array of all possible active region information within this time range
nar = my_get_nar(time_range)

IF datatype(nar) EQ 'STC' THEN BEGIN
    noaa = nar.noaa
    noaa = noaa[sort(noaa)]
    noaa = noaa[uniq(noaa)]

    dim_ar = n_elements(noaa)
ENDIF ELSE BEGIN
    dim_ar = 0
    print, program_name + '->' + 'Found No data!'
    stop
ENDELSE

IF keyword_set(VERBOSE) THEN print, program_name + '->' + 'Found ' + num2str(dim_ar) +  ' ARs '

;Calculate the linear fit parameters for all possible ARs
FOR i = 0, dim_ar-1 DO BEGIN

    index = where(nar.noaa EQ noaa[i], count)
    
    lon = nar[index].lonlat[0]
    lat = nar[index].lonlat[1]
    t = nar[index].orig_date
    
    IF keyword_set(VERBOSE) THEN print, program_name + '->' + 'Fitting noaa ', noaa[i]
    
    IF i EQ 0 THEN arlinfit = fit_ar_track(lon, lat, t, time_range, PLOT = plot, VERBOSE = verbose) ELSE $   
                  arlinfit = [arlinfit, fit_ar_track(lon, lat, t, time_range, plot = plot, VERBOSE = verbose)]
    IF keyword_set(DEBUG) THEN pause  
ENDFOR

;Find where there were bad fits
valid = arlinfit.lonfit[0] NE -1 AND arlinfit.lonfit[1] NE -1 AND arlinfit.latfit[0] NE -1 AND arlinfit.latfit[1] NE -1
index = where(valid EQ 1, good_fit_count)

IF good_fit_count GE 1.0 THEN BEGIN
    
    arlinfit = arlinfit[index]
    noaa = noaa[index]
    
    ;Calculate the closest AR
    utbase = anytim(time_range[0])
    arpos_x = fltarr(good_fit_count)
    arpos_y = fltarr(good_fit_count)
    ar_ondisk = fltarr(good_fit_count)
    distance = fltarr(good_fit_count)

    FOR i = 0, good_fit_count-1 DO BEGIN
        t = anytim(peak_time)-utbase
        mlat = arlinfit[i].latfit[1]
        blat = arlinfit[i].latfit[0]       
        mlon = arlinfit[i].lonfit[1]
        blon = arlinfit[i].lonfit[0]
        
        arpos = 60.0*hel2arcmin(mlat*t+blat, mlon*t+blon, vis, date = peak_time)
        arpos_x[i] = arpos[0]
        arpos_y[i] = arpos[1]
        ar_ondisk[i] = vis
        
        distance[i] = sqrt(((arpos_x[i] - position[0])^2)+((arpos_y[i] - position[1])^2))
        
        ; if the flare is on the disk than the originating active region must also be
        IF flare_ondisk EQ 1 AND ar_ondisk[i] EQ 0 THEN distance[i] = 1d10
    ENDFOR
    
    IF keyword_set(VERBOSE) THEN print, program_name + '-> Time ' + peak_time
    IF keyword_set(VERBOSE) THEN print, program_name + '-> Position (lon/lat)' + ' Flare position:', lonlat
    IF keyword_set(VERBOSE) THEN print, program_name + '-> ' + ' Flare_offdisk?: ', flare_offdisk
    
    min_distance = min(distance, mindex)
    
    closest_ar = noaa[mindex]
    index_nar = where(nar.noaa EQ closest_ar)
    last_index_nar = index_nar[n_elements(index_nar)-1]
    nar_result = nar[last_index_nar]
    
    ar_position = [arpos_x[mindex], arpos_y[mindex]]
    IF keyword_set(VERBOSE) THEN print, program_name + '->' + ' AR position:', arcmin2hel(arpos_x[mindex]/60.0, arpos_y[mindex]/60.0, date=peak_time)
    IF keyword_set(VERBOSE) THEN print, program_name + '->' + ' Distance to AR:', min_distance
    
    IF keyword_set(PLOT) THEN BEGIN
        loadct, 0
        hsi_linecolors
        map = make_map(findgen(2,2), time = peak_time)
        ondisk_color = 250
        behinddisk_color = 150
        flare_color = 6
        ar_sym = 1
        flare_sym = 5
        
        plot_map, map, xrange = [-1000,1000], yrange=[-1000,1000], /limb, grid = 20
    
        index = where(ar_ondisk EQ 1.0, count)
        FOR i = 0, count-1 DO oplot, [arpos_x[index[i]]], [arpos_y[index[i]]], psym = ar_sym, color = ondisk_color
        FOR i = 0, count-1 DO xyouts, $
            [arpos_x[index[i]]], [arpos_y[index[i]]], num2str(noaa[index[i]]), charsize = 1.0, color = ondisk_color
    
        index = where(ar_ondisk EQ 0.0, count)
        FOR i = 0, count-1 DO oplot, [arpos_x[index[i]]], [arpos_y[index[i]]], psym = ar_sym, color = behinddisk_color
        FOR i = 0, count-1 DO xyouts, $
            [arpos_x[index[i]]], [arpos_y[index[i]]], num2str(noaa[index[i]]), charsize = 1.0, color = behinddisk_color
    
        ; plot the location of the flare
        oplot, [position[0]], [position[1]], psym = flare_sym, color = flare_color
        ; plot the location of the nearest ar
        oplot, [ar_position[0]], [ar_position[1]], psym = ar_sym, color = flare_color
        xyouts, $
            ar_position[0], ar_position[1], num2str(closest_ar), charsize = 1.0, color = flare_color
    
        ssw_legend, ['on disk', 'behind disk', 'flare'], psym = [ar_sym, ar_sym, flare_sym], color = [ondisk_color, behinddisk_color, flare_color], textcolor = [ondisk_color, behinddisk_color, flare_color]
    ENDIF

ENDIF ELSE return, -1

IF keyword_set(DEBUG) THEN stop

nar = my_get_nar(time)
IF datatype(nar) EQ 'STC' THEN BEGIN
    index = where(nar.noaa EQ closest_ar)
    IF index NE -1 THEN nar = nar[index]
ENDIF

distance = min_distance
fit_params = arlinfit[mindex]

return, closest_ar

END