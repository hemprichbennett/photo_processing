library(tidyr)
library(dplyr)
library(readr)
library(data.table)
library(magrittr)
library(bit64)
library(exiftoolr)


save_exif <- function(){
  outfile <- bind_rows(exif_tibs)
  write_csv(x = outfile, path = exif_filename)
}

# recursively get the full filenames of every file in our desired directory
all_filenames <- list.files('/Volumes/LaCie/photography_main/1_all_unedited',
                            recursive = T,
                            full.names = T)

# read in exif data that has been processed in previous runs of 
# this script, so that we can avoid unneccesarily rerunning 
# the operation on thousands of files

exif_filename <- 'data/exif_data.csv'

dropcols <- c('ExifVersion', 'FlashpixVersion', 'InteropVersion', 'PrintIMVersion',
			'ShutterSpeedValue')
exif_tibs <- list()
e <- 1
if(file.exists(exif_filename)){
  previous_runs <- fread(input = exif_filename, fill = T)
  exif_tibs[[e]] <- previous_runs
  e <- e + 1
  # find the files that have NOT had their exif data parsed
  # in a previous run of this script
  filenames_to_run <- all_filenames[!all_filenames %in% previous_runs$SourceFile]
}else{
  filenames_to_run <- all_filenames
}


nfiles <- length(filenames_to_run)
max_per_batch <- 100
if(nfiles > max_per_batch){
  n_iterations <- ceiling(nfiles / max_per_batch)
  
  min_i <- 1
  max_i <- max_per_batch
  
  for(i in c(1:n_iterations)){
    #print(i)
    #if(i == 3){break()}
    cat('Starting iteration', i, 'of', n_iterations, '\n')
    desired_indexes <- seq(min_i, max_i)
    
    exif_df <- exif_read(filenames_to_run[desired_indexes], tags = 'All') 
    
    to_drop <- dropcols[dropcols %in% colnames(exif_df)]
    exif_df <- exif_df %>%
      select(-to_drop)
    exif_tibs[[e]] <- exif_df
    e <- e + 1
    # write the data
    cat('Saving iteration', i, 'of', n_iterations, '\n\n\n')
    save_exif()

    
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
  
	exif_df <- exif_read(filenames_to_run, tags = 'All') 
    
    to_drop <- dropcols[dropcols %in% colnames(exif_df)]
    exif_df <- exif_df %>%
      select(-to_drop)
    exif_tibs[[e]] <- exif_df
  # write the data
  print('saving file')
  save_exif()
  
  
  
}

