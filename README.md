Investigating the Flare Productivity of Active Regions
======================================================

Outputs
-------

* flareid_and_noaa.dat - contains association between flare id number as well as active region number as well as meta data on fit
* active region list - contains all active regions and nar data for every day they were visible
* (micro)flare list - contains all (micro)flare data

Functions
---------

get_ar_list.pro - creates active region list
get_nearest_ar.pro - given a time and position finds associated AR
test_flare_ar_association.pro - Produces AR associations for random flares in the official RHESSI flare list.
my_get_nar - custom wrapper around get_nar which produces a structure with more useful/usable data

