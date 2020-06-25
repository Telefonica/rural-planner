mergeDataFrames <-function(x,y) {
  dfTemp<- merge(x, y, by='settlement_id', all=TRUE)
  
  dfTemp$latitude <- ifelse(is.na(dfTemp$latitude.x),dfTemp$latitude.y,dfTemp$latitude.x)
  dfTemp$longitude <- ifelse(is.na(dfTemp$longitude.x),dfTemp$longitude.y,dfTemp$longitude.x)
  dfTemp$settlement_name <- ifelse(is.na(dfTemp$settlement_name.x),dfTemp$settlement_name.y,dfTemp$settlement_name.x)
  dfTemp$source <- ifelse(is.na(dfTemp$latitude.x)&(!is.na(dfTemp$latitude.y)),dfTemp$source.y,dfTemp$source.x)
  dfTemp$latitude.x<-NULL
  dfTemp$latitude.y<-NULL
  dfTemp$longitude.x<-NULL
  dfTemp$longitude.y<-NULL
  dfTemp$settlement_name.x<-NULL
  dfTemp$settlement_name.y<-NULL
  dfTemp$source.x<-NULL
  dfTemp$source.y<-NULL
  
  return(dfTemp)
}