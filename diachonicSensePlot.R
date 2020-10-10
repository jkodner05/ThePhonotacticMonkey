
###########################
## 0. Read in data files ##
###########################
data_source_dir = '' # e.g. path/to/ThePhonotacticMonkey/outputs/
working_dir = '' # e.g. path/to/ThePhonotacticMonkey/
oedInputFile = "data/OEDbyyear.txt"
PSMInputFile = "output_CELEXSAMPA_PSM_1_chron.txt"

args = commandArgs(trailingOnly=TRUE)
if (length(args)>3) {
  working_dir = args[1]
  data_source_dir = args[2]
  oedInputFile = args[3]
  PSMInputFile = args[4]
}

outputPlotName = "PSM-OED-typeSenseRatio-byTime-trimmed-scaled-sideBySide.png"
outputStatsFile = "PSM-OED-typeSenseRatio__stats.txt"
lastCharWorkDir = substr(working_dir, nchar(working_dir), nchar(working_dir))
if (lastCharWorkDir == '/') {
  auxSource = paste(working_dir,"aux-functions.R",sep="")
  oedInputFile = paste(working_dir,oedInputFile,sep="")
} else {
  auxSource = paste(working_dir,"/aux-functions.R",sep="")
  oedInputFile = paste(working_dir,"/",oedInputFile,sep="")
}
source(auxSource)
load_in_libraries()
load_in_plot_aesthetics()
setwd(data_source_dir)

oedDataRaw=read.table(oedInputFile,sep="\t",row.names=NULL, col.names = c("Year", "Forms", "Senses"))
oedDataRaw <- oedDataRaw[-c(1),]
oedDataRaw[] <- lapply(oedDataRaw, function(x) if(is.factor(x)) factor(x) else x)

PSMDataRaw=read.table(PSMInputFile,sep="\t", comment.char = "", row.names=NULL, col.names = c("Year", "Forms", "Senses", "Newform", "X", "Y", "ispolyseme"))
PSMDataRaw <- PSMDataRaw[-c(1),]
PSMDataRaw[] <- lapply(PSMDataRaw, function(x) if(is.factor(x)) factor(x) else x)
###########################
###########################
###########################


##################################
## 1. Merge and Prep Dataframes ##
##################################

## In R 3.X this needed to be the syntax
# oedDataRaw$Year <- as.numeric(levels(oedDataRaw$Year))[oedDataRaw$Year] ## Something here is broken
# oedDataRaw$Forms <- as.numeric(levels(oedDataRaw$Forms))[oedDataRaw$Forms]
# oedDataRaw$Senses <- as.numeric(levels(oedDataRaw$Senses))[oedDataRaw$Senses]
# PSMDataRaw$Year <- as.numeric(levels(PSMDataRaw$Year))[PSMDataRaw$Year]
# PSMDataRaw$Forms <- as.numeric(levels(PSMDataRaw$Forms))[PSMDataRaw$Forms]
# PSMDataRaw$Senses <- as.numeric(levels(PSMDataRaw$Senses))[PSMDataRaw$Senses]

## Wokring for R 4.X 
oedDataRaw$Year <- as.numeric(oedDataRaw$Year)
oedDataRaw$Forms <- as.numeric(oedDataRaw$Forms)
oedDataRaw$Senses <- as.numeric(oedDataRaw$Senses)
PSMDataRaw$Year <- as.numeric(PSMDataRaw$Year)
PSMDataRaw$Forms <- as.numeric(PSMDataRaw$Forms)
PSMDataRaw$Senses <- as.numeric(PSMDataRaw$Senses)



oedDataRawPost1500 <- oedDataRaw[oedDataRaw$Year >= 1500,]


PSMDataTrimmed <- PSMDataRaw[PSMDataRaw$Year > 25000,]
### Add column which converts from PSMyears to range between 1500 and 1999
### Currently ranges from 25001 to 699999
PSMDataTrimmed$scaledYear = rescale(PSMDataTrimmed$Year, to = c(1500, 1999))
PSMDataTrimmed <- subset(PSMDataTrimmed, select=-c(Newform,X,Y,Year))

PSMDataTrimmedScaled <- subset(PSMDataTrimmed, abs(as.integer(scaledYear)-scaledYear) < 0.001)
PSMDataTrimmedScaled$scaledYear <- as.integer(PSMDataTrimmedScaled$scaledYear)
PSMDataTrimmedScaled %>% distinct(scaledYear, .keep_all = TRUE) -> PSMDataTrimmedScaled

mergedPSMOEDData <- merge(PSMDataTrimmedScaled, oedDataRawPost1500, by.x="scaledYear", by.y="Year",  sort = FALSE)
colnames(mergedPSMOEDData)[colnames(mergedPSMOEDData)=="Forms.x"] <- "PSM_forms"
colnames(mergedPSMOEDData)[colnames(mergedPSMOEDData)=="Senses.x"] <- "PSM_senses"
colnames(mergedPSMOEDData)[colnames(mergedPSMOEDData)=="Forms.y"] <- "OED_forms"
colnames(mergedPSMOEDData)[colnames(mergedPSMOEDData)=="Senses.y"] <- "OED_senses"
###########################
###########################
###########################


####################################
## 2. OED and PSM Form/Sense Plot ##
####################################
options(scipen=10000)
plotYearLabels = c(1500,1650,1800,1950)

# Plot both PSM and OED side by side
ratioPlotPost1500 <- ggplot()
ratioPlotPost1500 +  geom_line(data=oedDataRawPost1500,aes(x=Year, y=Forms, color="Forms"),size=2) +
  geom_line(data=oedDataRawPost1500,aes(x=Year, y=Senses, color="Senses"),size=2) +
  labs(title = "OED", x = "Year", y = "Type Count", color = "Type\n") +
  scale_x_continuous(breaks=plotYearLabels,labels=plotYearLabels) +
  scale_y_continuous(labels = comma) +
  scale_fill_brewer(palette="Set1", aesthetics = c("color", "fill"), name = "Type") +
  single_pane_theme() + 
  theme(legend.position = c(.15, .8)) -> ratioPlotPost1500

PSMratioPlotScaled <- ggplot()
PSMratioPlotScaled +  geom_line(data=PSMDataTrimmedScaled,aes(x=scaledYear, y=Forms, color="Forms"),size=2) +
  geom_line(data=PSMDataTrimmedScaled,aes(x=scaledYear, y=Senses, color="Senses"),size=2) +
  labs(title = "PSM", x = "PSM scaled Year", y = "", color = "Type\n") +
  scale_x_continuous(breaks=plotYearLabels,labels=plotYearLabels) +
  scale_y_continuous(labels = comma) +
  scale_fill_brewer(palette="Set1", aesthetics = c("color", "fill"), name = "Type") +
  single_pane_theme() -> PSMratioPlotScaled

combinedPlotObject = plot_grid(ratioPlotPost1500,
                               PSMratioPlotScaled,
                               label_x = 0.5,
                               label_y = 0.3,
                               ncol = 2,
                               align = 'h',
                               hjust = 4)
ggsave(filename=outputPlotName, width = 60, height = 24, units = "cm")
###########################
###########################
###########################


##################
## 3. Run Stats ##
##################
# Compare sense/form ratios under OED and PSM

# Last row
# tail(mergedPSMOEDData, 1)
# scaledYear PSM_forms  PSM_senses   OED_forms   OED_senses
# 1999       156912     700000       152698      689166
OED_ratio = 152698/689166
PSM_ratio = 156912/700000

mergedPSMOEDData$OED_FS_ratio <- mergedPSMOEDData$OED_forms / mergedPSMOEDData$OED_senses
mergedPSMOEDData$PSM_FS_ratio <- mergedPSMOEDData$PSM_forms / mergedPSMOEDData$PSM_senses

# Model Comparison
lm.0 <- lm(OED_FS_ratio ~ PSM_FS_ratio, data = mergedPSMOEDData)
lm.1 <- lm(OED_FS_ratio ~ PSM_FS_ratio * as.numeric(scaledYear), data = mergedPSMOEDData)
lm.2 <- lm(OED_FS_ratio ~ as.numeric(scaledYear), data = mergedPSMOEDData)
write("PSM/OED type/sense ratio statistical comparison", file = outputStatsFile, sep="")
anova.out = anova(lm.2, lm.1)
s0 = summary(lm.0)
s1 = summary(lm.1)
s2 = summary(lm.2)
capture.output(anova.out, file = outputStatsFile, append=TRUE)
capture.output(s0, file = outputStatsFile, append=TRUE)
capture.output(s1, file = outputStatsFile, append=TRUE)
capture.output(s2, file = outputStatsFile, append=TRUE)
###########################
###########################
###########################
