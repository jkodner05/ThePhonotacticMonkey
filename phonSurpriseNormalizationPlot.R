
###########################
## 0. Read in data files ##
###########################
data_source_dir = '' # e.g. path/to/ThePhonotacticMonkey/outputs/
working_dir = '' # e.g. path/to/ThePhonotacticMonkey/
goodNormingFile = "output_CELEXSAMPA_actual_homophony.csv"
NPlus2NormingFile = "output_CELEXSAMPA_NPLUS2_actual_homophony.csv"
outputPlotNameDiff = "PhonSurpriseNormingDiffPlot.png"
outputStatsName = "PhonSurpriseNormingDiff__stats.txt"

args = commandArgs(trailingOnly=TRUE)
if (length(args)>3) {
  working_dir = args[1]
  data_source_dir = args[2]
  goodNormingFile = args[3]
  NPlus2NormingFile = args[4]
}

lastCharWorkDir = substr(working_dir, nchar(working_dir), nchar(working_dir))
if (lastCharWorkDir == '/') {
  auxSource = paste(working_dir,"aux-functions.R",sep="")
} else {
  auxSource = paste(working_dir,"/aux-functions.R",sep="")
}
source(auxSource)
load_in_libraries()
load_in_plot_aesthetics()
setwd(data_source_dir)

goodNormingData = read.csv(goodNormingFile,header=T)
NPlus2NormingData = read.csv(NPlus2NormingFile,header=T)

names(goodNormingData)[names(goodNormingData) == 'phonsuprise'] <- 'phonsupriseGoodNorm'
names(NPlus2NormingData)[names(NPlus2NormingData) == 'phonsuprise'] <- 'phonsupriseNPLUS2Norm'
mergedData <- merge(goodNormingData, NPlus2NormingData, sort = FALSE)
mergedData <- subset(mergedData, numphones >= 2 & numphones <= 10)
mergedData$numphones <- as.factor(mergedData$numphones)
mergedData <- subset(mergedData, select = -c(wordfreq, wordneglogprob, wordsensesneglogprob, numsylls))
mergedData$normingDiff <- mergedData$phonsupriseGoodNorm - mergedData$phonsupriseNPLUS2Norm
###########################
###########################
###########################


#################################
## 1. Plot skew by word length ##
#################################
p <- ggplot(mergedData, aes(factor(numphones), normingDiff))
theme_set(single_pane_theme())
theme_update(legend.position = c(.8, .85))
p + geom_violin(trim=FALSE, fill='#FF6666', colour = "#FF6666") + # , size = 1.5
  geom_boxplot(width=0.1, outlier.size = 0) +
  labs(title = "Effect of N+1 vs. N+2 Normalization", x = "Length (phones)", y = "Difference in Phon Surprise Estimation") +
  single_pane_theme()
ggsave(filename=outputPlotNameDiff, width = 30, height = 24, units = "cm")
###########################
###########################
###########################


######################################
## 2. Stats for skew by word length ##
######################################
cor(mergedData$normingDiff, as.numeric(mergedData$numphones))
linearMod <- lm(normingDiff ~ as.numeric(numphones), data=mergedData)
s0 = summary(linearMod)
write("PhonSurprise Norming (N+1 vs. N+2) Difference Stats", file = outputStatsName, sep="")
capture.output(s0, file = outputStatsName, append=TRUE)
###########################
###########################
###########################