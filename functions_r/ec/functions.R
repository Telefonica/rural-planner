# This function recieves a png file, output file and boundaries limits. It creates a georeorefenced png file.

georeferencePNG <- function(file_in,file_out,west,north,east,south){
  gdal_translate(file_in,file_out,of = "PNG",a_srs = "EPSG:4326",a_ullr = paste(west,north,east,south,sep = " "), overwrite = TRUE)
}

# This function recieves a georeferenced png file and creates a raster layer with 2 levels divided by the threshold. 
# This process reduces the number of polygons uploaded to the databes. It unifies colors above and below the threshold.

simplifyRaster <- function(file_in,file_out,invertedColor,threshold){
  png <- raster(file_in)
  if(invertedColor){#Remap color
    png <- calc(png, fun=function(x){ x[x == 0] <- 5;#numero intermedio para evitar errores
    x[x == 3] <- 0;
    x[x == 5] <- 3;
    return(x)} )
  }
  
  png <- calc(png, fun=function(x){ x[x < threshold] <- 0; x[x > threshold] <- 1;return(x)} )
  writeRaster(png,filename=file_out,format = "GTiff", overwrite = TRUE)
}

# This function creates polygones from a raster file and saves it as shp files
# In windows you need to create environment variables OSGEO4W_ROOT = 'C:\Program Files\QGIS 2.18'
# Add to path variable : C:\Program Files\QGIS 2.18\bin


polygonizeRaster <- function(file_in,file_out){
  time <- proc.time()
  file_name <- tools::file_path_sans_ext(basename(file_out))
  
  r <- raster(file_in)
  print("ejecutado raster(file_in)")
  print(proc.time()-time)
  time<- proc.time()
  names(r) <- "DN"
  s <- rasterToPolygons(r)
  print("ejecutado rasterToPolygons")
  print(proc.time()-time)
  writeOGR(s, gsub(paste0('/',basename(file_out)),"",file_out), file_name, driver="ESRI Shapefile", overwrite = TRUE)
}

#functions to convert from tile to lat long

tile2long <- function(x,z){
  return (x/(2^z)*360-180)
}

tile2lat <- function(y,z){
  n <- pi-2*pi*y/2^z
  return (180/pi*atan(0.5*(exp(n)-exp(-n))))
}

#west,north,east,south
#-77.3780786616877 8.91725862609843 -75.900643793715 7.43662974893262
getBoundaries <- function(tileX,tileY,zoom){
  west <- tile2long(tileX,zoom)
  north <- tile2lat(tileY,zoom)
  east <- tile2long(tileX+1,zoom)
  south <- tile2lat(tileY+1,zoom)
  return(c(west,north,east,south))
}


downloadFile <- function (url_file,downloaded_png_file){
  tryCatch({
    getURLContent(url_file)
    download.file(url_file,destfile = downloaded_png_file,method = 'auto',quiet = T)
    return(TRUE)
  }
  ,error=function(e){
    return(FALSE)
  })
}

