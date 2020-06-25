###########################################
#READ DATA FROM CLOUDRF AREA COVERAGE API#

makeRequest <- function(i, input_data, input_path, out_shp_folder){
  for(j in (i)){
    #Prepare request
    url <- input_data$url[j]
    payload <- gsub(" ","",paste('uid=',input_data$uid[j],
                                           '&key=',input_data$key[j],
                                          '&lat=',input_data$lat[j],
                                          '&lon=',input_data$lon[j],
                                          '&txh=',input_data$txh[j],
                                          '&frq=',input_data$frq[j],
                                          '&rxh=',input_data$rxh[j],
                                          '&dis=',input_data$dis[j],
                                          '&txw=',input_data$txw[j],
                                          '&aeg=',input_data$txg[j],
                                          '&rxg=',input_data$rxg[j],
                                          '&pm=',input_data$pm[j],
                                          '&pe=',input_data$pe[j],
                                          '&res=',input_data$res[j],
                                          '&rad=',input_data$rad[j],
                                          '&out=',input_data$out[j],
                                          '&rxs=',input_data$rxs[j],
                                          '&ant=',input_data$ant[j],
                                          '&azi=',input_data$azi[j],
                                          '&cli=',input_data$cli[j],
                                          '&file=',input_data$file[j],
                                          '&nam=',input_data$nam[j],
                                          '&net=',input_data$net[j],
                                          '&out=',input_data$out[j],
                                          '&pol=',input_data$pol[j],
                                          '&red=',input_data$red[j],
                                          '&ter=',input_data$ter[j],
                                          '&tlt=',input_data$tlt[j],
                                          '&hbw=',input_data$hbw[j],
                                          '&fbr=',input_data$fbr[j],
                                          '&vbw=',input_data$vbw[j],
                                          '&col=',input_data$col[j],
                                          '&engine=',input_data$engine[j],
                                          '&txg=',input_data$txg[j],
                                          '&ber=',input_data$ber[j],
                                          '&clh=',input_data$clh[j],
                                          '&ked=',input_data$ked[j],
                                          '&bwi=',input_data$bwi[j],
                                          '&blu=',input_data$blu[j],
                                          '&cll=',input_data$cll[j],
                                          '&grn=',input_data$grn[j],
                                          '&mod=',input_data$mod[j],
                                          '&rel=',input_data$rel[j], 
                                          '&nf=', input_data$nf[j])) 
  
    #Make the request for get shp files
  
    doc <- POST(url = paste(url,payload, sep = "?"), encode = "form")
    x <- fromJSON(content(doc, type = 'application/z-www-form-urlencoded', as = "text"))
    print(paste0("Iteration ", j, "/", nrow(input_data), " calculated."))
    file_name <- paste0(input_data$nam[j])
  
    #Download shp files
    download.file(x$shp,paste(input_path,out_shp_folder,file_name, sep = '/'))
    
    rm(x)
    rm(doc)
  
    Sys.sleep(1)
  }

}
