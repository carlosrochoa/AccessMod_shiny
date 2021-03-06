
#
# General validation and error message
#



# preventive field validation
# TODO: this validation step was written for one module:
# With almost all modules depending on it, this should be rewritten.
idModule="module_analysis"

observe({
  amErrorAction(title='Module 2,3,4,6: validation',{
    #
    # init messages
    #

    err = character(0)
    info = character(0)
    dubious = character(0)
    out  = character(0)
    msgList = character(0)

    #
    # store current module
    #

    module2    <- isTRUE(input$moduleSelector == 'module_2')
    module3    <- isTRUE(input$moduleSelector == 'module_3')
    module4    <- isTRUE(input$moduleSelector == 'module_4')
    module5    <- isTRUE(input$moduleSelector == 'module_5')
    module6    <- isTRUE(input$moduleSelector == 'module_6')

    isAnisotropic <- isTRUE(input$typeAnalysis == 'anisotropic')
    isIsotropic <-  isTRUE(input$typeAnalysis == 'isotropic')

    if(module5){
      ttInRange <- TRUE
      maxTT <- 0

      # Check if data exist
      layerOkTT    <- isTRUE(!is.null(amNameCheck(dataList,input$travelTimeSelect,'raster')))
      layerOkZones <- isTRUE(!is.null(amNameCheck(dataList,input$zoneSelect,'vector')))
      layerOkPop       <- isTRUE(!is.null(amNameCheck(dataList,input$popSelect,'raster')))

      if(layerOkTT){
        maxTT <- round(amGetRasterStat(input$travelTimeSelect,c("max"))) 
        selectTT <- input$sliderTimeAnalysis
        ttInRange <- isTRUE(selectTT >= 0 && selectTT <= maxTT)
      }

    }else{

      #
      # Clean tags
      #

      tagsClean  <- amGetUniqueTags(input$costTag) 

      #
      # Control maps and values
      #

      # Check if data exist
      merged     <- isTRUE(!is.null(amNameCheck(dataList,input$mergedSelect,'raster')))
      hf         <- isTRUE(!is.null(amNameCheck(dataList,input$hfSelect,'vector')))
      pop        <- isTRUE(!is.null(amNameCheck(dataList,input$popSelect,'raster')))
      popRes     <- isTRUE(!is.null(amNameCheck(dataList,input$popResSelect,'raster')))


      # table validation
      hfOnBarrier <- any(tblHfSubset()$amOnBarrier=='yes')
      hfOnZero <- any(tblHfSubset()$amOnZero=='yes')

      if(module4){
        hfOnBarrier = hfOnBarrier || any(tblHfSubsetTo()$amOnBarrier=='yes') 
        hfOnZero = hfOnZero || any(tblHfSubsetTo()$amOnZero=='yes') 
        refLimitClosest = isTRUE(input$checkReferralLimitClosest)
      }


      # check if there is at least one facility selectected.
      hfNoSelected            <- isTRUE(!any(tblHfSubset()$amSelect))
      hfNoSelectedTo          <- isTRUE(!any(tblHfSubsetTo()$amSelect))
      # check for speed of  0 kmh
      # tblModel          <- isTRUE(!any(hotToDf(input$speedRasterTable)$speed <1))
      #tblModelSpeed          <- isTRUE(all(hotToDf(input$speedRasterTable)$speed > 0 ))
      # parameter validation
      unlimitedTT       <- isTRUE(
        input$maxTravelTime == 0
        )
      #wrongTT <- !isTRUE(module4) && isTRUE( 
      wrongTT <- isTRUE( 
        !is.numeric(input$maxTravelTime) || 
          amNoDataCheck(input$maxTravelTime) ||
          input$maxTravelTime < 0 ||
          input$maxTravelTime > 2147483647
        )
      #
      # Parameters control.
      #

      if(module3){
        # simple character control (user cannot put custom value)
        hfIdx           <- isTRUE(nchar(input$hfIdxField)>0)
        capField        <- isTRUE(nchar(input$hfCapacityField)>0)
        hfBuffer        <- isTRUE(input$hfOrder == 'circBuffer')
        popBuffer       <- isTRUE(input$popBufferRadius > listen$mapMeta$grid$nsres)
        zonalPop        <- isTRUE('zonalPop' %in% input$mod3param)

        if(zonalPop){
          zonalSelect <- isTRUE(!is.null(amNameCheck(dataList,input$zoneSelect,'vector')))
          zoneId      <- isTRUE(length(input$zoneId)>0)
          zoneLabel   <- isTRUE(length(input$zoneLabel)>0)
        }

        hfOrderInconsistency       <- isTRUE(input$hfOrder!='tableOrder' && !'rmPop' %in% input$mod3param)
        zonalCoverageInconsistency <- isTRUE(zonalPop && !'rmPop' %in% input$mod3param)
        # data overwrite warning module 3 : validate each output !
        # TODO: inform user of all provided output. Warning if risk of overwrite.
      }

      if(module6){
        tblCapTypeOk              <- TRUE
        tblCapMissingOk           <- TRUE
        tblCapOverlapOK           <- TRUE
        tblCapInRangeOk           <- TRUE
        tblCapGreaterThanPrevOk   <- TRUE
        tblCapWithoutButHfSelect  <- FALSE
        tblSuitOk                 <- FALSE
        tblSuitOnlyDynFac         <- FALSE
        tblSuitLayerMissing       <- character(0)
        tblSuitLayerOk            <- TRUE
        tblExclOk                 <- FALSE
        tblExclLayerMissing       <- character(0)
        tblExclLayerOk            <- TRUE
        tblCapBeginWithZero       <- TRUE
        tblCapMinMaxOk            <- TRUE
        tblCapLabelOk             <- TRUE
        popSelect                 <- TRUE
        maxScUpPopGoalNoLimit     <- FALSE
        maxScUpTimeNoLimit        <- FALSE
        maxScUpHfNoLimit          <- FALSE
        allScUpNoLimit            <- FALSE

        tblCapacityNew <- hotToDf(input$capacityTable)
        tblSuit <- hotToDf(input$suitabilityTable)
        tblExcl <- hotToDf(input$exclusionTable)
        withoutFacility <- isTRUE(input$useExistingHf == "FALSE")
        popResidualIsResidual <- isTRUE(amGetClass(input$popResidualSelect)=="rPopulationResidual")

        popNotResidualButHfSelect <- FALSE
        popResidualButNoHfSelect <- FALSE
        # options
        # computation limit
        maxScUpHf <- input$maxScUpNewHf
        maxScUpTime <- input$maxScUpTime
        maxScUpPopGoal <- input$maxScUpPopGoal




        # auto correction
        if(isTRUE(maxScUpPopGoal>100)){
          updateNumericInput(session,"maxScUpPopGoal",value=100)
        }

        maxScUpHfNoLimit <- isTRUE(maxScUpHf<1)
        maxScUpTimeNoLimit <- isTRUE(maxScUpTime <1)
        maxScUpPopGoalNoLimit <- isTRUE(maxScUpPopGoal <1)


        allScUpNoLimit <- all(
          c(
            maxScUpPopGoalNoLimit,
            maxScUpHfNoLimit,
            maxScUpTimeNoLimit
            )
          )


        if(withoutFacility) {
          if(!hfNoSelected && hf){
            tblCapWithoutButHfSelect <- TRUE 
          }
          # manually validate hf layer and hf on barrier.
          hfNoSelected <- FALSE
          hfOnBarrier <- FALSE
          hfOnZero <- FALSE
          hf <- TRUE
        }else{
          # if there is hf select without a population residual
          if(!hfNoSelected && !popResidualIsResidual){
            popNotResidualButHfSelect <- TRUE

          }
          if(hfNoSelected && popResidualIsResidual){
            popResidualButNoHfSelect <- TRUE
          }
        }

        # validate suitability table 
        if(!is.null(tblSuit)){
          tblSuitOk <- nrow(na.omit(tblSuit))>0 
        }
        if(tblSuitOk){
          # if without facility and all layer in suitability are dynamic facility
          tblSuitOnlyDynFac <- withoutFacility && all(tblSuit$layer == config$dynamicFacilities) && !hfNoSelected && hf

          # validate layer names 
          suitLayers <- tblSuit$layer[! tblSuit$layer %in% config$dynamicLayers ] 
          tblSuitLayerMissing <- suitLayers[!sapply(suitLayers,amMapExists)]
          if( length(tblSuitLayerMissing) >0 ) {
            tblSuitLayerOk <- isTRUE( length(tblSuitLayerMissing) == 0)
          }
        }

        if(!is.null(tblExcl)){
          tblExclOk <- TRUE
        }


        if(tblExclOk){ 
          exclLayers <- tblExcl$layer[! tblExcl$layer %in% config$dynamicLayers ] 
          if( length(tblExclLayerMissing) >0 ) {
            tblExclLayerMissing <- exclLayers[!sapply(exclLayers,amMapExists)]
            tblExclLayerOk<- isTRUE( length(tblSuitLayerMissing) == 0)
          }
        }

        #  validate null
        if(!is.null(tblCapacityNew)){
          #  validate missing value
          tblCapMissingOk <-isTRUE(all(
              sapply(tblCapacityNew,function(x){a=all(stringr::str_length(x)>0)})
              ))

          if(tblCapMissingOk)(
            # validate type
            tblCapTypeOk <- all(
              is.numeric(tblCapacityNew$min),
              is.numeric(tblCapacityNew$max),
              is.numeric(tblCapacityNew$capacity), 
              is.character(tblCapacityNew$label)
              )

            )
          # validate overlap min max and capacity in range.
          if(tblCapMissingOk){

            # max greater than min
            tblCapMinMaxOk<-all(tblCapacityNew$min<tblCapacityNew$max)
            tblCapBeginWithZero <- isTRUE(tblCapacityNew$min[1] == 0)
            # checking previous row values
            nR<-nrow(tblCapacityNew)
            if(nR>1){
              for(i in 2:nR){
                # Capacity is greater than previous capacity 
                tblCapGreaterThanPrevOk <- all(tblCapGreaterThanPrevOk,isTRUE(tblCapacityNew[i,'capacity']>tblCapacityNew[i-1,'capacity'])) 
                # min max+1 overlap
                tblCapOverlapOK<-all(tblCapOverlapOK,isTRUE(tblCapacityNew[i,'min'] > tblCapacityNew[i-1,'max'])) 
              }
            }
            # capacity in min max range
            tblCapInRangeOk <- isTRUE(
              all(tblCapacityNew$capacity <= tblCapacityNew$max & tblCapacityNew$capacity >= tblCapacityNew$min)
              )
            # unique labels
            tblCapLabelOk<-isTRUE(length(unique(tblCapacityNew$label))==length(tblCapacityNew$label))

          }
        }
      }


    }
    #
    # Collect messages in err and info 
    #


    if(module5){
      #
      # zonal analysis
      #
      if(!ttInRange) err = c(err,sprintf("Please enter a travel time between 0 and %1$s.",maxTT))
      if(!layerOkZones) err = c(err,"Zone layer missing.")
      if(!layerOkPop) err = c(err,"Population layer missing.")
      if(!layerOkTT) err = c(err,"Travel time layer missing.")
    }else{
      #
      # Other modules
      #
      if(wrongTT) err = c(err,'Please enter a valid maximum travel time between 0 and 2147483647')
      if(!hf) err = c(err,'Facilities layer missing.') 
      if(hfOnBarrier) err = c(err, "There are facilities located on barrier. Unselect them or correct the original layer.")
      if(hfOnZero) err = c(err, "There are facilities located on a land cover area where a speed of 0 km/h is set. Unselect them or change the scenario to proceed")
      if(!merged) err = c(err,'Merged land cover layer missing.')
      if(unlimitedTT) info = c(info,'Maximum travel time set to zero. A value of zero will use the default travel time, which is currently defined as 32767 minutes ( 22 days, 18 hours and 7 minutes)')

      if(unlimitedTT && module2 ) info = c(info, "Using a maximum travel time of zero, computed travel time greater than 32737 will be coded as -1")
      if(unlimitedTT && !module2 ) info = c(info, "Using a maximum travel time of zero, computed travel time greater than 32737 will be ignored")
       
      if(module2 | module6){
        if(hfNoSelected) err = c(err, 'Please select at least one facility.')
      }
      if(module3 | module6){ 
        if(!pop) err = c(err,'Please select a population layer.')
      }

      if(module3){

        if(!hfIdx) err = c(err,'No group/id field set for hf.')
        if(hfNoSelected) err = c(err, 'Select at least one facility.')
        if(!capField) err = c(err,'No capacity field set for hf.')

        if(hfBuffer)if(!popBuffer) err = c(err,'Circular buffer must be higher than project resolution.')
        #if(!popBarrier) info = c(info,'Map of population on barrier will NOT be computed.')
        if(hfOrderInconsistency) info=c(info,"If covered population is not removed at each iteration, facilities processing order should be set to 'Order from facilities table.'")
        if(zonalPop){
          if(!zonalSelect) err=c(err,'Please select a zone layer or uncheck the Generate zonal statistics option under settings.')
          if(!zoneId) err =c(err,'Zonal id column missing.')
          if(!zoneLabel) err =c(err,'Zonal label column missing.')
        }
        if(zonalCoverageInconsistency) err = c(err,'If covered population is not removed at each iteration, zonal analysis could not be performed.')

        #
        # if check population
        #
        # population on barrier

        if( isTRUE(length(err) <1) && isTRUE(popOnBarrierStat()$sum > 0) ) info = c(info,sprintf("Population encoutered on barrier in %s cells for a total of %s individuals ( %s %% of the initial population ). This population will not be part of the analysis",
            popOnBarrierStat()$cells,
            popOnBarrierStat()$sum,
            popOnBarrierStat()$percent
            ))

      }
      if(module4){
        if(hfNoSelected) err = c(err, "Select at least one facility in table 'FROM'.")
        if(hfNoSelectedTo) err = c(err,"Select at least one facility in table 'TO'. ")
      }
      if(module6){
        if(allScUpNoLimit){
          info = c(info, "All scaling up goals are set to 0 (or less) and are considered as unlimited. Scaling up analysis will stop when no more candidates are found or if 100% of the population is covered.")
        }else{
          if(maxScUpPopGoalNoLimit) info = c(info, "Population coverage set to zero or less : coverage will be 100% ")
          if(maxScUpTimeNoLimit) info = c(info, "Time limitation set to zero or less : unlimited processing time.")
          if(maxScUpHfNoLimit)  info = c(info, "Number of facilities to create set to zero or less : unlimited facilities creation.")
        }

        if(popNotResidualButHfSelect) dubious = c(dubious, "Existing facilities have been selected while the selected residual population layer is not labelled as residual. Please check if this is correct before computing.")
        if(popResidualButNoHfSelect)  dubious = c(dubious, "Population residual is of subclass 'residual', but no facilies has been selected. Please verify.")
        if(!withoutFacility) info = c(info,"The 'start using selected existing facilities' option has been checked. Please make sure that these facilities have been used to generate the residual population layer.")
        #if(hfNoSelected && !pop) err = c(err,'Scaling up : if no facility is selected, you must choose a population map.')
        #if(!hfNoSelected && popRes) err = c(err,'Scaling up : if .')
        if(!tblSuitLayerOk) err = c(err, paste("Table of suitability: layer missing :",tblSuitLayerMissing))
        if(!tblExclLayerOk) err = c(err, paste("Table of exclusion: layer missing :",tblExclLayerMissing))
        if(!tblSuitOk) err = c(err, "Table of suitability factors: missing value")
        if(!tblCapMissingOk) err = c(err,'Table of scaling up capacity: missing value')
        if(!tblCapTypeOk) err = c(err,'Table of scaling up capacity: type error.')
        if(!tblCapMinMaxOk) err =c(err,"Table of scaling up capacity:  min greater than or equal to max.")
        if(!tblCapBeginWithZero) err =c(err,"Table of scaling up capacity:  the first minimal capacity value in column 'min' should be zero.")
        if(!tblCapGreaterThanPrevOk) err = c(err,"Table of scaling up capacity: capacity is not incremental")
        if(!tblCapInRangeOk) info =c(info,"Table of scaling up capacity: there is capacity value(s) not in range [min,max].")
        if(!tblCapOverlapOK) err =c(err,"Table of scaling up capacity: min value can't be equal or less than previous max value.")
        if(tblCapWithoutButHfSelect) info = c(info, "Existing facilities have been selected while the \"start with empty layer\" is being checked. Those facilities will be ignored.")
        if(tblSuitOnlyDynFac) err = c(err,"Without existing facilities selected, dynamic facilities can't be the only layer in suitability table. Please add at least another non-dynamic layer.")

        if(!tblCapLabelOk) err =c(err,"Table scaling up capacity: duplicate labels.")
        #if(hfNoSelected) err = c(err, "Select at least one facility.") 
      }

      # output name text. 
      if(!isTRUE(length(tagsClean)>0)){
        err <- c(err,'Please enter at least one tag.')
      }
    }

    #
    # create HTML for validation message list.
    #

    if(length(err)>0){
      plur <- if(length(err)>1) "s"
      err <- HTML(paste("<div>",icon('exclamation-triangle'),err,'</div>',collapse=""))
      msgList <- tagList(tags$b(sprintf('Issue%s:',plur)),err)
      disBtn <- TRUE
    }else{
      disBtn <- FALSE

      #
      # Ressource validation
      #

      rEst <- amGetRessourceEstimate(input$hfSelect)

      rRequired <- rEst$required
      rAvailable <- rEst$available
      info <-c(info, sprintf("Estimation of required memory %1$d MB ( available %2$d MB )",
          rRequired$memory,
          rAvailable$memory
          ))
      info <- c(info, sprintf("Estimation of disk space required = %1$d MB ( available %2$d MB )",
          rRequired$disk,
          rAvailable$disk
          ))

      if(length(info)>0) {
        info <- HTML(paste("<div>",icon('info-circle'),info,'</div>',collapse=""))
        msgList <- tagList(tags$b("Information:"),info)
      }

      if(length(dubious)>0) {
        dubious <- HTML(paste("<div>",icon('question-circle'),dubious,'</div>',collapse=""))
        msgList <- tagList(msgList,tags$b("Information:"),dubious)
      }


    }

   
    #
    # If no errors, naming datasets that will be produced. 
    # 

    if(length(err)==0){

      classMod = character(0)

      switch(input$moduleSelector,
        "module_2"={classMod=c(
          "tScenarioOut",
          if(isAnisotropic) "rSpeed",
          if(isIsotropic) "rFriction",
          "rTravelTime"
          )},
        "module_3"={classMod=c(
          "tScenarioOut",
          if(isAnisotropic) "rSpeed",
          if(isIsotropic) "rFriction",
          "tCapacityStat",
          if(zonalPop) "tZonalStat",
          "rPopulationResidual",
          "rPopulationOnBarrier",
          "vCatchment"
          )},
        "module_4"={classMod=c(
          "tScenarioOut",
          if(isAnisotropic) "rSpeed",
          if(isIsotropic) "rFriction",
          "tReferral",
          if(!refLimitClosest) "tReferralDist",
          "tReferralTime"
          )},
        "module_5"={classMod=c(
          )},
        "module_6"={classMod=c(
          "tScenarioOut",
          if(isAnisotropic) "rSpeed",
          if(isIsotropic) "rFriction",
          "rPopulationResidual",
          "vFacilityNew",
          "tCapacityOut",
          "tCapacityStatNew",
          "vCatchmentNew",
          "tExclusionOut",
          "tSuitabilityOut"
          )}
          )


      if(!module5){

      # vNames has 4 group : ui; file; fileMapset and html version
      vNames <- amCreateNames(classMod,tagsClean,dataList)


      # save for launch analysis
      listen$outputNames <- vNames
      
      # display html version
      out <- tagList(
        tags$b('Output dataset:'), 
        HTML(paste("<div>",icon('sign-out'),vNames$html,"<div/>",collapse=""))
        )
      #
      }
      # Set final message 
      #
    }else{
      out = character(0)
    }
    msgList <- tagList(msgList,out)
    amActionButtonToggle(session=session,'btnComputeAccessibility',disable=disBtn)
    amActionButtonToggle(session=session,'btnZonalStat',disable=disBtn)
    output$msgModule3 <-renderUI({msgList})

})

},suspended=TRUE) %>% amStoreObs(idModule,"validate_accessibility")







