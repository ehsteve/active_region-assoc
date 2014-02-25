PRO main

restore, '/Users/schriste/Dropbox/idl/code/db/microflare_list/flare_list_quick.dat', /verbose

time_str = break_time(anytim_now())
file_ext = '.dat'

flareid_and_noaa_fname = 'flareid_and_noaa' + '_' + time_str + file_ext
ar_list_fname = 'ar_list' + '_' + time_str + file_ext

nflares = n_elements(flare_list.start_time)
time_range = [flare_list[0].start_time, flare_list[nflares-1].end_time]

;creates a list of flare with associated ars
associate_flarelist_and_ar, flare_list, output_filename = flareid_and_noaa_fname

;creates list of ar with associated flares
get_ar_list, time_range=time_range, output_filename = ar_list_fname

add_flares_to_ar_list, ar_list_fname, flareid_and_noaa_fname

END