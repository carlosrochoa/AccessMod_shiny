#      ___                                  __  ___            __   ______
#     /   |  _____ _____ ___   _____ _____ /  |/  /____   ____/ /  / ____/
#    / /| | / ___// ___// _ \ / ___// ___// /|_/ // __ \ / __  /  /___ \
#   / ___ |/ /__ / /__ /  __/(__  )(__  )/ /  / // /_/ // /_/ /  ____/ /
#  /_/  |_|\___/ \___/ \___//____//____//_/  /_/ \____/ \__,_/  /_____/
#
# Module manage_data 
#
# USER INTERFACE

fluidRow(
  div(class="col-xs-12 col-md-4",
    amAccordionGroup(id='manageData',itemList=list(
        'addData'=list(
          title=div(icon('plus-circle'),'Import'),
          content=tagList(
            selectInput('dataClass','Select data class:',choices=""),
            textInput('dataTag','Add short tags',value=''),
            uiOutput('msgModuleData'),
            amFileInput('btnDataNew',label='Choose and import data') 
            )
          ),
        'filtData'=list(
          title=div(icon('filter'),'Filter'),
          content=tagList(
            conditionalPanel(
              condition = "input.checkFilterLastOutput == false",
              radioButtons('typeDataChoice','Data type',
                c("Vectors" = "vector",
                  "Rasters" = "raster",
                  "Tables"  = "table",
                  "Lists"  = "list",
                  "All"    = "all"),
                selected   = "all",
                inline=TRUE
                ),
              textInput(inputId = 'filtData','Text (any field, case sensitive)',''), 
              selectInput(inputId = 'filtDataTags','Tags filter',choices='',selected='',multiple=T)
              ),
            tags$input(type="checkbox",id="checkShowLastOutputButton",style="display:none"),
            conditionalPanel(
              condition="input.checkShowLastOutputButton === true",
              checkboxInput('checkFilterLastOutput',"Filter last analysis only")
              ),
            conditionalPanel(condition="input.showAdvancedTools === true",
              checkboxInput("internalDataChoice",'Show internal data',value=FALSE)
              )
            )
          ),
        'renameData'=list(
          title=div(icon('refresh'),'Rename'),
          content=tagList(
            actionButton('btnUpdateName','Update modified tag(s)'),
            tags$small(class="text-muted",'Manually modify the tag(s) in the adjacent table and click on the button to implement the change (does not work with the DEM)')
            )
          ),
        'archiveData'=list(
          title=div(icon('download'),'Archive'),
          content= tagList(
            textInput('txtArchiveName','File prefix. Default is "am5"'),
            actionButton('createArchive','Create archive'),
            tags$small(class="text-muted",'Click to archive the data appearing as selected in the right table'),
            hr(),
            selectInput('selArchive','Select archive',choices=""),
            tags$small(class="text-muted",'Click on the buttons below to download or delete the selected archive'),
            actionButton('getArchive','Export archive'),
            actionButton('btnDeleteArchive','Delete archive')
            )
          ),
        'remData'=list(
          title=div(icon('trash-o'),'Delete'),
          content=tagList(
            actionButton('delDataSelect','Delete permanently'),
            tags$small(class="text-muted",'This action will delete the selected data'),
            p(id="txtDelMessage","")
            )
          )
        )) 
    ),
  div(class="col-xs-12 col-md-8",
    amCenterTitle('Available data',sub="Data imported in the project or generated by AccessMod."),
    tags$div(
      class="amTableControls",
      tags$a(
        onclick="hotableSetColValues('dataListTable',{col:'Select',set:true})",
        ' [ All ]'
        ),' ',
      tags$a(
        onclick="hotableSetColValues('dataListTable',{col:'Select',set:false})",
        ' [ None ]'
        ),' ',
      HTML("<div data-opt={\"col\":\"Select\",\"valueSet\":true,\"valueUnset\":false,\"labelSet\":\"Select\",\"labelUnset\":\"Unselect\"} id=\"dataListTableSelectTools\"></div>")
      ),
    hotable('dataListTable')
    )
  )


