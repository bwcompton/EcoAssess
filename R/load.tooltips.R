# load.tooltips.R - load all tooltip + About markdown into globals at startup.
# Auto-loaded from R/ so make.ui can reference each tooltip by name.
# B. Compton



# tool tips
ecoConnectDisplayTooltip <- includeMarkdown('inst/tooltipEcoConnectDisplay.md')
projectAreaToolTip <- includeMarkdown('inst/tooltipProjectArea.md')
drawTooltip <- includeMarkdown('inst/tooltipDraw.md')
uploadTooltip <- includeMarkdown('inst/tooltipUpload.md')
restartTooltip <- includeMarkdown('inst/tooltipRestart.md')
getReportTooltip <- includeMarkdown('inst/tooltipGetReport.md')
generateReportTooltip <- includeMarkdown('inst/tooltipGenerateReport.md')
connectTooltip <- includeMarkdown('inst/tooltipConnect.md')
ieiTooltip <- includeMarkdown('inst/tooltipIei.md')
basemapTooltip <- includeMarkdown('inst/tooltipBasemap.md')
opacityTooltip <- includeMarkdown('inst/tooltipOpacity.md')
usermapTooltip <- includeMarkdown('inst/tooltipUsermap.md')

# Massachusetts-version tool tips
regionalVersionTooltip <- includeMarkdown('inst/tooltipRegionalVersion.md')
massachusettsVersionTooltip <- includeMarkdown('inst/tooltipMassachusettsVersion.md')
showPOSTooltip <- includeMarkdown('inst/tooltipShowPOS.md')
showParcelsTooltip <- includeMarkdown('inst/tooltipShowParcels.md')
selectParcelsTooltip <- includeMarkdown('inst/tooltipSelectParcels.md')


# help docs
aboutTool <- includeMarkdown('inst/aboutTool.md')
aboutecoConnect <- includeMarkdown('inst/aboutEcoConnect.md')
aboutIEI <- includeMarkdown('inst/aboutIEI.md')
aboutWhatsNew <- includeMarkdown('inst/aboutWhatsnew.md')
