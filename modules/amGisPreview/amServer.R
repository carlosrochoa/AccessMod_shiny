#      ___                                  __  ___            __   ______
#     /   |  _____ _____ ___   _____ _____ /  |/  /____   ____/ /  / ____/
#    / /| | / ___// ___// _ \ / ___// ___// /|_/ // __ \ / __  /  /___ \
#   / ___ |/ /__ / /__ /  __/(__  )(__  )/ /  / // /_/ // /_/ /  ____/ /
#  /_/  |_|\___/ \___/ \___//____//____//_/  /_/ \____/ \__,_/  /_____/
## map preview 

source("tools/R/amLeafletPatch.R")


#observe({

#amModEnabled<-listen$tabControl_module_preview  

#if(isTRUE(!is.null(amModEnabled) && amModEnabled)){
# directory for map cache
addResourcePath('mapCache',config$pathCacheDir)

idModule <- "module_toolbox"
satArcGisAttrib<-"i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community"
satLayer <-  "http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"

# create leaflet map

observe({
  output$mapPreview <- renderLeaflet({
    leaflet()%>%
      mapOptions(zoomToLimits = "first")
  })
},suspended=TRUE) %>% amStoreObs(idModule,"render_leaflet")

observe({
  if(input$selBaseMap != "empty"){
    amDebugMsg("Base map triggered")
    leafletProxy("mapPreview") %>%
      addProviderTiles(
        input$selBaseMap,
        layerId="baselayer"
        )
  }else{
    leafletProxy("mapPreview") %>%
      removeTiles("baselayer") 
  }
},suspended=TRUE) %>% amStoreObs(idModule,"base_map")


observe({
  maps <- dataList$raster
  updateSelectInput(session,"mapToPreview",choices=maps)
},suspended=TRUE) %>% amStoreObs(idModule,"raster_list")

observe({
  m <- listen$mapMeta
  bbx<-as.numeric(unlist(m$latlong$bbx$ext))
  leafletProxy("mapPreview") %>%
    fitBounds(bbx[1],bbx[3],bbx[2],bbx[4]) 
},suspended=TRUE) %>% amStoreObs(idModule,"map_meta")



observe({
  clickCoord <- input$mapPreview_click
  mapToPreview <- amNameCheck(dataList,input$mapToPreview,'raster')
  isolate({
    if(!is.null(mapToPreview) && !is.null(clickCoord)){
      clickCoord<-c(x=clickCoord$lng, y=clickCoord$lat)
      tbl<-amRastQueryByLatLong(
        clickCoord,
        mapToPreview,
        projOrig=listen$mapMeta$orig$proj,
        projDest=listen$mapMeta$latlong$proj)
    }else{
      tbl=data.frame(long='-',lat='-',value='-',label='-')
    }
    output$previewValueTable<-renderHotable(tbl,readOnly=T,fixed=2,stretch='last')   
  })
},suspended=TRUE) %>% amStoreObs(idModule,"render_click")

# set a region to extract from grass
observe({ 

  amErrorAction({
    # preview parameter list
    pL = list(
      leafletBounds = input$mapPreview_bounds,# leaflet bounds change
      mapToPreview  = amNameCheck(dataList,input$mapToPreview,'raster'), # map from dataList$raster
      opacity       = input$previewOpacity, # opacity change
      meta      = isolate(listen$mapMeta)
      )

    isolate({
      ready <- !any(TRUE %in% sapply(pL,is.null))
      if(ready){

        # render map : png path and boundingbox
        mapPreview <- amGrassLatLongPreview(
          mapToPreview=pL$mapToPreview,
          bbxSpLatLongLeaf=amBbxLeafToSp(pL$leafletBounds),
          bbxSpLatLongOrig=amBboxSp(pL$meta,proj='latlong'),
          mapCacheDir=config$pathCacheDir,
          resGrassEW=pL$meta$grid$ewres,
          resMax=300,
          projOrig=listen$mapMeta$orig$proj,
          projDest=listen$mapMeta$latlong$proj 
          )

        if(is.null(mapPreview)) return(NULL)

        # where to save image cache
        previewPath<-file.path('mapCache',basename(mapPreview$pngMap))

        # retrieve resulting intersecting bounding box
        bbx <- mapPreview$bbx

        leafletProxy("mapPreview") %>%
          addPng(
            layerId="layerPreview",
            lat1=bbx['y','min'],
            lng1=bbx['x','min'],
            lat2=bbx['y','max'],
            lng2=bbx['x','max'],
            imgUrl=previewPath,
            options=list(
              opacity=pL$opacity
              )
            )

      }
    })

  },title='Map preview generator')
},suspended=TRUE) %>% amStoreObs(idModule,"map_move")

