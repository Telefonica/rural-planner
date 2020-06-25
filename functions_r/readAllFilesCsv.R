readAllFiles <- function(file_names,path){
  
  files <- read.csv(paste(path, file_names[1], sep="/"), fileEncoding = "latin1", stringsAsFactors = F)
  for (i in 2:length(file_names)) {
      files <- rbind(files,read.csv(paste(path,file_names[i], sep="/"), fileEncoding = "latin1", stringsAsFactors = F))
  }
  return(files)
}