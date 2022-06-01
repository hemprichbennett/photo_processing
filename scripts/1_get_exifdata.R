library(tidyr)
library(dplyr)
library(readr)
library(data.table)
library(magrittr)
library(exiftoolr)

# recursively get the full filenames of every file in our desired directory
all_filenames <- list.files('/Volumes/LaCie/photography_main/1_all_unedited',
                            recursive = T,
                            full.names = T)

# read in exif data that has been processed in previous runs of 
# this script, so that we can avoid unneccesarily rerunning 
# the operation on thousands of files

previous_runs <- fread(input = 'data/exif_data.csv', select = 'SourceFile')

# find the files that have NOT had their exif data parsed
# in a previous run of this script
filenames_to_run <- all_filenames[!all_filenames %in% previous_runs$SourceFile]


nfiles <- length(filenames_to_run)
max_per_batch <- 100
if(nfiles > max_per_batch){
  n_iterations <- ceiling(nfiles / max_per_batch)
  
  min_i <- 1
  max_i <- max_per_batch
  
  for(i in c(1:n_iterations)){
    print(i)
    desired_indexes <- seq(min_i, max_i)
    print(desired_indexes)
    exif_df <- exif_read(filenames_to_run[desired_indexes])
    
    # write the data
    print('saving file')
    write_csv(x = exif_df, path = 'data/exif_data.csv', append = T)
    # for every iteration apart from the penultimate one
    # assume that we need to increase the counters as much as 
    # possible for the next iteration
    if(i < n_iterations - 1){
      min_i <- min_i + max_per_batch
      max_i <- max_i + max_per_batch
    }else if( i == n_iterations -1){
      # for the penultimate iteration make sure to use the 
      # correct max index
      min_i <- min_i + max_per_batch
      max_i <- nfiles
    }
  }
  
  
}else{
  cat(nfiles, ' photos\n')
  
  exif_df <- exif_read(filenames_to_run)
  # write the data
  print('saving file')
  write_csv(x = exif_df, path = 'data/exif_data.csv', append = T)
  
  
  
}

