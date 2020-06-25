readAllFiles <- function(file_names, input_path){

  files <- readRDS(paste(input_path, file_names[1], sep = "/"))
  for (i in 2:length(file_names)) {
    
    files <- rbind(files, readRDS(paste(input_path, file_names[i], sep = "/")))
  }
  return(files)
}