
library(lubridate)
library(magrittr)
library(dplyr)
library(readr)
library(stringr)
todays_run <- readGPX('data/raw_data/tomtom/5/running_2021-08-22_11-16-05.gpx') 

gpx_stuff <- readLines('Trails/Sunday Morning Walk.gpx')

# remove the first two lines as they're worthless to us
gpx_stuff <- gpx_stuff[-c(1:2)]

lats <- gsub('.+lat=|lon=.+', '', gpx_stuff)
lats <- gsub("[^0-9.-]", "", lats)
lats <- as.numeric(lats)
lons <- gsub('.+lon=|><ele.+', '', gpx_stuff)
lons <- gsub("[^0-9.-]", "", lons)
lons <- as.numeric(lons)
eles <- gsub('.+<ele>|</ele>.+', '', gpx_stuff)
eles <- as.numeric(eles)
times <- gsub('.+<time>|</time>.+', '', gpx_stuff)
times <- gsub('T', ' ', times)
#times <- gsub('\\..+', '', times)
times <- ymd_hms(times)

activity_df <- data.frame(lats, lons, eles, times)
activity_df <- activity_df %>%
  filter(!is.na(times))


photos <- list.files(path = 'Photos', pattern = 'CR2', full.names = T)

# get rid of pesky spaces in their names
file.rename(from = photos,
            to = gsub(' ', '_', photos))

photos <- list.files(path = 'Photos', pattern = 'CR2', full.names = T)
photo_time <- file.info(photos)$mtime %>% ymd_hms(.)
photo_df <- data.frame(photos, photo_time, lat = NA, lon = NA, ele = NA, nsec_diff = NA)

for(i in 1:nrow(photo_df)){
  temp <- activity_df %>%
    mutate(time_diff = abs(activity_df$times - photo_time[i]))
  
  best_match <- filter(temp, time_diff == min(time_diff))
  photo_df$lat[i] <- best_match$lats
  photo_df$lon[i] <- best_match$lons
  photo_df$ele[i] <- best_match$eles
  photo_df$nsec_diff[i] <- best_match$time_diff
}

# commands borrowed from https://www.how-hard-can-it.be/exiftool-bash-macos/

for(i in 1:nrow(photo_df)){
  if(photo_df$lon[i] > 0){
    longitude <- 'E'
  }else{
    longitude <- 'W'
  }
  if(photo_df$lat[i] > 0){
    latitude <- 'N'
  }else{
    latidude <- 'S'
  }
  # add the coordinates
  exif_str <- paste0('exiftool -GPSLongitudeRef=', longitude,
                     ' -GPSLongitude=', photo_df$lon[i],
                     ' -GPSLatitudeRef=', latitude, 
                     ' -GPSLatitude=', photo_df$lat[i], ' ', photo_df$photos[i],
                     ' -overwrite_original')
  
  system(exif_str)
  
  # and finally, add a GPS date stamp
  datestampstr <- paste0('exiftool ',  photo_df$photos[i],
                         ' "-GPSDateStamp<ModifyDate" -globalTimeShift -overwrite_original')
  system(datestampstr)
}

# i don't know why it kept the originals even after the -overwrite_original flags,
# but this kills them
file.remove(list.files(path = 'Photos', pattern = '_original$', full.names = T))
