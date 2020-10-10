
###########################
## 0. Read in data files ##
###########################
PM_Actual_flag = "Nat"

data_source_dir = '' # e.g. path/to/ThePhonotacticMonkey/outputs/
working_dir = '' # e.g. path/to/ThePhonotacticMonkey/

if (PM_Actual_flag == "PM") {
  outputPlotName = "allPlots-polysemy-PM.png"
  nounInputFile = "output_PM_CELEXSAMPALEMMA_noun.csv"
  verbInputFile = "output_PM_CELEXSAMPALEMMA_verb.csv"
  adjInputFile = "output_PM_CELEXSAMPALEMMA_adj.csv"
} else {
  outputPlotName =  "allPlots-polysemy-actual.png" 
  nounInputFile = "output_CELEXSAMPALEMMA_actual_noun.csv"
  verbInputFile = "output_CELEXSAMPALEMMA_actual_verb.csv"
  adjInputFile = "output_CELEXSAMPALEMMA_actual_adj.csv"
}

# Check if at least 3 arguments (to get directories and PM/Nat/PSM flag)
args = commandArgs(trailingOnly=TRUE)
if (length(args)>6) {
  working_dir = args[1]
  data_source_dir = args[2]
  PM_Actual_flag = args[3]
  nounInputFile = args[4]
  verbInputFile = args[5]
  adjInputFile = args[6]
  outputPlotName = args[7]
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

nounDataRaw=dataclean(read.csv(nounInputFile,header=T))
verbDataRaw=dataclean(read.csv(verbInputFile,header=T))
adjDataRaw=dataclean(read.csv(adjInputFile,header=T))
###########################
###########################
###########################


##################################
## 1. Merge and Prep Dataframes ##
##################################
A_nounData = nounDataRaw
B_nounData = nounDataRaw
C_nounData = nounDataRaw
A_verbData = verbDataRaw
B_verbData = verbDataRaw
C_verbData = verbDataRaw
A_adjData = adjDataRaw
B_adjData = adjDataRaw
C_adjData = adjDataRaw

meanSensesPerSyllableNoun = aggregate(numwordsensesm1 ~ numsylls, A_nounData, FUN=mean)
meanSensesPerSyllableNoun[is.na(meanSensesPerSyllableNoun)] = 0  
aggregate(numwordsensesm1 ~ numsylls, A_nounData, FUN=length)

meanSensesPerSyllableVerb = aggregate(numwordsensesm1 ~ numsylls, A_verbData, FUN=mean)
meanSensesPerSyllableVerb[is.na(meanSensesPerSyllableVerb)] = 0  
aggregate(numwordsensesm1 ~ numsylls, A_verbData, FUN=length)

meanSensesPerSyllableAdj = aggregate(numwordsensesm1 ~ numsylls, A_adjData, FUN=mean)
meanSensesPerSyllableAdj[is.na(meanSensesPerSyllableAdj)] = 0  
aggregate(numwordsensesm1 ~ numsylls, A_adjData, FUN=length)

B_nounData_agro = aggrdata_exact_numgroups(B_nounData$numwordsensesm1, B_nounData$wordneglogprob, 20)
B_verbData_agro = aggrdata_exact_numgroups(B_verbData$numwordsensesm1, B_verbData$wordneglogprob, 20)
B_adjData_agro = aggrdata_exact_numgroups(B_adjData$numwordsensesm1, B_adjData$wordneglogprob, 20)

# Filter out extremely low probability tail
B_nounData_agro = subset(B_nounData_agro, indepvar <= 20.0)
B_verbData_agro = subset(B_verbData_agro, indepvar <= 20.0)
B_adjData_agro = subset(B_adjData_agro, indepvar <= 20.0)

C_nounData_agro = aggrdata_exact_numgroups(C_nounData$numwordsensesm1, C_nounData$phonsuprise, 20)
C_verbData_agro = aggrdata_exact_numgroups(C_verbData$numwordsensesm1, C_verbData$phonsuprise, 20)
C_adjData_agro = aggrdata_exact_numgroups(C_adjData$numwordsensesm1, C_adjData$phonsuprise, 20)

# Filter out extremely long words 
C_nounData_agro = subset(C_nounData_agro, indepvar <= 6.0)
C_verbData_agro = subset(C_verbData_agro, indepvar <= 6.0)
C_adjData_agro = subset(C_adjData_agro, indepvar <= 6.0)
###########################
###########################
###########################


##################################
## 2. Define plotting aesthetic ##
##################################
if (PM_Actual_flag == "PM") {
  legendLabel = "PM-English POS"
} else {
  legendLabel = "Natural-English POS"
}

alphabeticalColoringOrder = c("Blue", "#002f7a", "#68a2ff")
###########################
###########################
###########################


###################################################
## 3. Plot numSylls over num additional meanings ##
###################################################
plotObjectA = ggplot() + 
  geom_line(data=meanSensesPerSyllableNoun,aes(x=numsylls, y=numwordsensesm1, color="Noun"),size=lineSize) +
  geom_point(data=meanSensesPerSyllableNoun,aes(x=numsylls, y=numwordsensesm1, color="Noun"),size=dotSize) +
  geom_line(data=meanSensesPerSyllableVerb,aes(x=numsylls, y=numwordsensesm1, color="Verb"),size=lineSize) +
  geom_point(data=meanSensesPerSyllableVerb,aes(x=numsylls, y=numwordsensesm1, color="Verb"),size=dotSize) +
  geom_line(data=meanSensesPerSyllableAdj,aes(x=numsylls, y=numwordsensesm1, color="Adj"),size=lineSize) +
  geom_point(data=meanSensesPerSyllableAdj,aes(x=numsylls, y=numwordsensesm1, color="Adj"),size=dotSize) +
  scale_y_log10(breaks=c(0.001,0.100,10.000),labels=c(0.001,0.100,10.000)) +
  scale_color_manual(values=alphabeticalColoringOrder,
                     name = legendLabel,
                     breaks = c("Noun","Verb","Adj")) +
  expand_limits(y=c(0.001,12)) +
  ylab("Mean number of additional senses") +
  xlab("Length in syllables") +
  homophony_polysemy_labeled_theme()
###########################
###########################
###########################


#####################################################
## 4. Plot neglogprob over num additional meanings ##
#####################################################
plotObjectB = ggplot() + 
  geom_line(data=B_nounData_agro,aes(x=indepvar, y=x, color="Noun"),size=lineSize) +
  geom_point(data=B_nounData_agro,aes(x=indepvar, y=x, color="Noun"),size=dotSize) +
  geom_line(data=B_verbData_agro,aes(x=indepvar, y=x, color="Verb"),size=lineSize) +
  geom_point(data=B_verbData_agro,aes(x=indepvar, y=x, color="Verb"),size=dotSize) +
  geom_line(data=B_adjData_agro,aes(x=indepvar, y=x, color="Adj"),size=lineSize) +
  geom_point(data=B_adjData_agro,aes(x=indepvar, y=x, color="Adj"),size=dotSize) +
  scale_y_log10(breaks=c(0.001,0.100,10.000),labels=c(0.001,0.100,10.000)) +
  scale_x_continuous(breaks=c(5,10,15,20),labels=c(5,10,15,20)) +
  scale_color_manual(values=alphabeticalColoringOrder) +
  expand_limits(y=c(0.001,12),x=c(5,20)) +
  xlab("Negative log probability") +
  homophony_polysemy_nolabel_theme()
###########################
###########################
###########################


#######################################################
## 5. Plot PhonSurprise over num additional meanings ##
#######################################################
plotObjectC = ggplot() +
  geom_line(data=C_nounData_agro,aes(x=indepvar, y=x, color="Noun"),size=lineSize) +
  geom_point(data=C_nounData_agro,aes(x=indepvar, y=x, color="Noun"),size=dotSize) +
  geom_line(data=C_verbData_agro,aes(x=indepvar, y=x, color="Verb"),size=lineSize) +
  geom_point(data=C_verbData_agro,aes(x=indepvar, y=x, color="Verb"),size=dotSize) +
  geom_line(data=C_adjData_agro,aes(x=indepvar, y=x, color="Adj"),size=lineSize) +
  geom_point(data=C_adjData_agro,aes(x=indepvar, y=x, color="Adj"),size=dotSize) +
  scale_y_log10(breaks=c(0.001,0.100,10.000),labels=c(0.001,0.100,10.000)) +
  scale_x_continuous(breaks=c(2,3,4,5,6),labels=c(2,3,4,5,6)) +
  scale_color_manual(values=alphabeticalColoringOrder) +
  expand_limits(y=c(0.001,12),x=c(2,6)) +
  xlab("Phonotactic surprisal / length") +
  homophony_polysemy_nolabel_theme()
###########################
###########################
###########################


##################################
## 6. Combine side-by-side plot ##
##################################
combinedPlotObject = plot_grid(plotObjectA,
                               plotObjectB,
                               plotObjectC,
                               labels = c('(X)','(Y)','(Z)'),
                               label_size = axisTextSize,
                               label_x = 0.6,
                               label_y = 0.35,
                               ncol = 3,
                               align = 'h',
                               hjust = 4)
ggsave(filename=outputPlotName,
       width = 60, height = 24, units = "cm")

print("Generated Polysemy Plot")
###########################
###########################
###########################
