library(lubridate)
library(magrittr)
library(exiftoolr)
library(dplyr)

# functions aren't yet being used, as I'm still working out the basic commands
# which will go in them
# GPS coordinate addition function ----------------------------------------

coord_function <- function(coord_location, image_in_location, 
                           image_out_location) {

  
  # check if the file already has coordinates!
}



# Function which the user calls -------------------------------------------

user_function <- function(add_coords, rename_files, coord_dir, image_dir) {
  
  exif_tib <- list.files(path = image_in_directory, full.names = T) %>%
    exif_read(tags = c('CreateDate', 'Model', 'FileName'))
  
  if (add_coords == T && rename_files == F) {

  }else if (rename_files == T && add_coords == F) {

  }else if (rename_files == T && add_coords == T){
    
  }
}



args <- as.character(commandArgs(trailingOnly = TRUE))

coord_boolean <- args[1]
rename_boolean <- args[2]
coord_directory <- args[3]
image_in_directory <- args[4]
image_out_directory <- args[5]
cat('coord addition is ', coord_boolean, 
    '. rename_boolean is ', rename_boolean,
    '. coord_directory is ', coord_directory,
    '. image_in_directory is', image_in_directory,
    '. image_out_directory is', image_out_directory)
exif_tib <- list.files(path = 'inphotos', full.names = T) %>%
  exif_read(tags = c('CreateDate', 'Model', 'FileName', 
                     'GPSAltitude', 'GPSLatitude', 'GPSLongitude'))

refined_tib <- list.files(path = 'inphotos', full.names = T) %>%
  exif_read(tags = c('CreateDate', 'Model', 'FileName', 
                     'GPSAltitude', 'GPSLatitude', 'GPSLongitude'))

modded_tib <- refined_tib %>%
  # make some better values
  mutate(better_timestamp = format_ISO8601(ymd_hms(CreateDate)),
         # the format_ISO8601 command sadly separates time with colons
         # which are annoying in filenames,  lets make them hyphens
         better_timestamp = gsub(':', '-', better_timestamp),
         #the camera names have spaces in, we want to ditch those
         better_model_name = gsub(' ', '-', Model),
         better_filename = paste(better_timestamp, better_model_name, FileName, sep = '_'))

# now we can simply copy the files using
file.copy(from = modded_tib$SourceFile,
          to = paste0('outphotos/', modded_tib$better_filename))
          

# for use in filtering gpx files
photo_dates <- date(modded_tib$better_timestamp) %>% unique()


# GPS stuff

# for some reason I can't get either tmaptools or plotKML to load, so for now I'm 
# throwing in the towel and using base R to work with the gpx files
gpx_import <- function(gpx_file_path){
  
  gpx_stuff <- readLines(gpx_file_path)
  
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
  dates <- date(times)
  
  activity_df <- data.frame(lats, lons, eles, times, dates)
  activity_df <- activity_df %>%
    filter(!is.na(times))
  return(activity_df)
}

# make a big ol tibble of all the activities in the gpx folder
all_locations <- list.files('Trails', full.names = T) %>%
  lapply(gpx_import) %>%
  bind_rows() %>%
  # then filter out the activities which were on days that no photos were 
  # taken, to speed things up later
  filter(dates %in% photo_dates)

is.na(modded_tib$GPSLatitude)

get_coords <- function(better_timestamp,  GPSAltitude, GPSLatitude, GPSLongitude){
  # if it's already got geotagging, we don't want to do anything to it
  if(!is.na(GPSAltitude) | !is.na(GPSLatitude) | !is.na(GPSLongitude)){
    stop()
  }
  tiny_tib <- all_locations %>%
    mutate(time_diff = difftime(times, better_timestamp)) %>%
    filter(time_diff == min(time_diff)) %>%
    # check if the time difference is less than or equal to 5 minutes. If not,
    # we don't want to use it
    mutate(to_use = time_diff <= as.duration('5 minutes'))
  
  
  
  return(tiny_tib)
}

# e.g.
get_coords(better_timestamp = modded_tib$better_timestamp[1], GPSAltitude = NA, GPSLongitude = NA, GPSLatitude = NA)


# we'll soon be able to make a column with the string returned by the above function using
temp <- mutate(modded_tib, z = get_coords(better_timestamp,  
                                  GPSAltitude, GPSLatitude, GPSLongitude))
