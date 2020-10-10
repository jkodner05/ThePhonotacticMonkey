
###########################
## 0. Read in data files ##
###########################
PSM_PM_Actual_flag = "PM"

data_source_dir = '' # e.g. path/to/ThePhonotacticMonkey/outputs/
working_dir = '' # e.g. path/to/ThePhonotacticMonkey/

if (PSM_PM_Actual_flag == "PSM") {
  outputPlotName = "allPlots-homophony-PSM.png"
  PSMInputFile = "output_CELEXSAMPA_PSM_1.csv"
} else if (PSM_PM_Actual_flag == "PM") {
  outputPlotName = "allPlots-homophony-PM.png"
  englishInputFile = "output_CELEXSAMPA_homophony.csv"
  dutchInputFile = "output_CELEXSAMPANL_homophony.csv"
  germanInputFile = "output_CELEXSAMPADE_homophony.csv"
} else {
  outputPlotName =  "allPlots-homophony-actual.png" 
  englishInputFile = "output_CELEXSAMPA_actual_homophony.csv"
  dutchInputFile = "output_CELEXSAMPANL_actual_homophony.csv"
  germanInputFile = "output_CELEXSAMPADE_actual_homophony.csv"
}

# Check if at least 3 arguments (to get directories and PM/Nat/PSM flag)
args = commandArgs(trailingOnly=TRUE)
if (length(args)>2) {
  working_dir = args[1]
  data_source_dir = args[2]
  PSM_PM_Actual_flag = args[3]
}

if (PSM_PM_Actual_flag == "PSM" & length(args)>4) {
  PSMInputFile = args[4]
  outputPlotName = args[5]
} else if (PSM_PM_Actual_flag != "PSM" & length(args)>6) {
  englishInputFile = args[4]
  dutchInputFile = args[5]
  germanInputFile = args[6]
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

if (PSM_PM_Actual_flag == "PSM") {
  PSMDataRaw=dataclean(read.csv(PSMInputFile,header=T))
} else {
  englishDataRaw=dataclean(read.csv(englishInputFile,header=T))
  dutchDataRaw=dataclean(read.csv(dutchInputFile,header=T))
  germanDataRaw=dataclean(read.csv(germanInputFile,header=T))
}
###########################
###########################
###########################


##################################
## 1. Merge and Prep Dataframes ##
##################################
if (PSM_PM_Actual_flag == "PSM") {
  A_PSMDataRaw = PSMDataRaw
  B_PSMDataRaw = PSMDataRaw
  C_PSMDataRaw = PSMDataRaw
  
  meanSensesPerSyllablePSM = aggregate(numwordsensesm1 ~ numsylls, A_PSMDataRaw, FUN=mean)
  meanSensesPerSyllablePSM[is.na(meanSensesPerSyllablePSM)] = 0  
  aggregate(numwordsensesm1 ~ numsylls, A_PSMDataRaw, FUN=length)
  
  B_PSMDataRaw_agro = aggrdata_exact_numgroups(B_PSMDataRaw$numwordsensesm1, B_PSMDataRaw$wordneglogprob, 20)
  # Filter out extremely low probability tail
  B_PSMDataRaw_agro = subset(B_PSMDataRaw_agro, indepvar <= 19.0)
  
  C_PSMDataRaw_agro = aggrdata_exact_numgroups(C_PSMDataRaw$numwordsensesm1, C_PSMDataRaw$phonsuprise, 20)
  # Filter out extremely long words 
  C_PSMDataRaw_agro = subset(C_PSMDataRaw_agro, indepvar <= 6.0)
} else {
  A_englishData = englishDataRaw
  B_englishData = englishDataRaw
  C_englishData = englishDataRaw
  A_dutchData = dutchDataRaw
  B_dutchData = dutchDataRaw
  C_dutchData = dutchDataRaw
  A_germanData = germanDataRaw
  B_germanData = germanDataRaw
  C_germanData = germanDataRaw
  
  meanSensesPerSyllableEnglish = aggregate(numwordsensesm1 ~ numsylls, A_englishData, FUN=mean)
  meanSensesPerSyllableEnglish[is.na(meanSensesPerSyllableEnglish)] = 0  
  aggregate(numwordsensesm1 ~ numsylls, A_englishData, FUN=length)
  
  meanSensesPerSyllableDutch = aggregate(numwordsensesm1 ~ numsylls, A_dutchData, FUN=mean)
  meanSensesPerSyllableDutch[is.na(meanSensesPerSyllableDutch)] = 0  
  aggregate(numwordsensesm1 ~ numsylls, A_dutchData, FUN=length)
  
  meanSensesPerSyllableGerman = aggregate(numwordsensesm1 ~ numsylls, A_germanData, FUN=mean)
  meanSensesPerSyllableGerman[is.na(meanSensesPerSyllableGerman)] = 0  
  aggregate(numwordsensesm1 ~ numsylls, A_germanData, FUN=length)
  
  B_englishData_agro = aggrdata_exact_numgroups(B_englishData$numwordsensesm1, B_englishData$wordneglogprob, 20)
  B_germanData_agro = aggrdata_exact_numgroups(B_germanData$numwordsensesm1, B_germanData$wordneglogprob, 20)
  B_dutchData_agro = aggrdata_exact_numgroups(B_dutchData$numwordsensesm1, B_dutchData$wordneglogprob, 20)
  
  # Filter out extremely low probability tail
  B_englishData_agro = subset(B_englishData_agro, indepvar <= 20.0)
  B_germanData_agro = subset(B_germanData_agro, indepvar <= 20.0)
  B_dutchData_agro = subset(B_dutchData_agro, indepvar <= 20.0)
  
  C_englishData_agro = aggrdata_exact_numgroups(C_englishData$numwordsensesm1, C_englishData$phonsuprise, 20)
  C_germanData_agro = aggrdata_exact_numgroups(C_germanData$numwordsensesm1, C_germanData$phonsuprise, 20)
  C_dutchData_agro = aggrdata_exact_numgroups(C_dutchData$numwordsensesm1, C_dutchData$phonsuprise, 20)
  
  # Filter out extremely long words 
  C_englishData_agro = subset(C_englishData_agro, indepvar <= 6.0)
  C_germanData_agro = subset(C_germanData_agro, indepvar <= 6.0)
  C_dutchData_agro = subset(C_dutchData_agro, indepvar <= 6.0)
}
###########################
###########################
###########################


##################################
## 2. Define plotting aesthetic ##
##################################
if (PSM_PM_Actual_flag == "PSM") {
  legendLabel = "PSM-Lexicon"
} else if (PSM_PM_Actual_flag == "PM") {
  legendLabel = "PM-Lexicon"
} else {
  legendLabel = "Natural-Lexicon"
}

if (PSM_PM_Actual_flag == "PSM") {
  alphabeticalColoringOrder = c("skyblue3")
} else {
  alphabeticalColoringOrder = c("#226900", "skyblue3", "Red")
}
###########################
###########################
###########################


###################################################
## 3. Plot numSylls over numSenses or homophones ##
###################################################
if (PSM_PM_Actual_flag == 'PSM') {
  plotObjectA = ggplot() + 
    geom_line(data=meanSensesPerSyllablePSM,aes(x=numsylls, y=numwordsensesm1, color="PSM-English"),size=lineSize) +
    geom_point(data=meanSensesPerSyllablePSM,aes(x=numsylls, y=numwordsensesm1, color="PSM-English"),size=dotSize) +
    scale_y_log10(breaks=c(0.001,0.100,10.000),labels=c(0.001,0.100,10.000)) +
    scale_color_manual(values=alphabeticalColoringOrder,
                       name = legendLabel,
                       breaks = c("PSM-English"))
} else {
  plotObjectA = ggplot() + 
    geom_line(data=meanSensesPerSyllableEnglish,aes(x=numsylls, y=numwordsensesm1, color="English"),size=lineSize) +
    geom_point(data=meanSensesPerSyllableEnglish,aes(x=numsylls, y=numwordsensesm1, color="English"),size=dotSize) +
    geom_line(data=meanSensesPerSyllableGerman,aes(x=numsylls, y=numwordsensesm1, color="German"),size=lineSize) +
    geom_point(data=meanSensesPerSyllableGerman,aes(x=numsylls, y=numwordsensesm1, color="German"),size=dotSize) +
    geom_line(data=meanSensesPerSyllableDutch,aes(x=numsylls, y=numwordsensesm1, color="Dutch"),size=lineSize) +
    geom_point(data=meanSensesPerSyllableDutch,aes(x=numsylls, y=numwordsensesm1, color="Dutch"),size=dotSize) +
    scale_y_log10(breaks=c(0.001,0.100,10.000),labels=c(0.001,0.100,10.000)) +
    scale_color_manual(values=alphabeticalColoringOrder,
                       name = legendLabel,
                       breaks = c("English","German","Dutch"))
}

plotObjectA <- plotObjectA + 
  expand_limits(y=c(0.001,12)) +
  ylab("Mean number of homophones") +
  xlab("Length in syllables") +
  homophony_polysemy_labeled_theme()
###########################
###########################
###########################


#########################################################
## 4. Plot wordneglogprob over numSenses or homophones ##
#########################################################
if (PSM_PM_Actual_flag == 'PSM') {
  plotObjectB = ggplot() + 
    geom_line(data=B_PSMDataRaw_agro,aes(x=indepvar, y=x, color="PSM-English"),size=lineSize) +
    geom_point(data=B_PSMDataRaw_agro,aes(x=indepvar, y=x, color="PSM-English"),size=dotSize)
} else {
  plotObjectB = ggplot() + 
    geom_line(data=B_englishData_agro,aes(x=indepvar, y=x, color="English"),size=lineSize) +
    geom_point(data=B_englishData_agro,aes(x=indepvar, y=x, color="English"),size=dotSize) +
    geom_line(data=B_germanData_agro,aes(x=indepvar, y=x, color="German"),size=lineSize) +
    geom_point(data=B_germanData_agro,aes(x=indepvar, y=x, color="German"),size=dotSize) +
    geom_line(data=B_dutchData_agro,aes(x=indepvar, y=x, color="Dutch"),size=lineSize) +
    geom_point(data=B_dutchData_agro,aes(x=indepvar, y=x, color="Dutch"),size=dotSize)
}

plotObjectB <- plotObjectB + 
  scale_y_log10(breaks=c(0.001,0.100,10.000),labels=c(0.001,0.100,10.000)) +
  scale_x_continuous(breaks=c(5,10,15,20),labels=c(5,10,15,20)) +
  scale_color_manual(values=alphabeticalColoringOrder) +
  expand_limits(y=c(0.001,12),x=c(5,20)) +
  ylab("Mean number of homophones") +
  xlab("Negative log probability") +
  homophony_polysemy_nolabel_theme()
###########################
###########################
###########################


#######################################################
## 5. Plot phonSurprise over numSenses or homophones ##
#######################################################
if (PSM_PM_Actual_flag == 'PSM') {
  plotObjectC = ggplot() +
    geom_line(data=C_PSMDataRaw_agro,aes(x=indepvar, y=x, color="PSM-English"),size=lineSize) +
    geom_point(data=C_PSMDataRaw_agro,aes(x=indepvar, y=x, color="PSM-English"),size=dotSize)
} else {
  plotObjectC = ggplot() +
    geom_line(data=C_englishData_agro,aes(x=indepvar, y=x, color="English"),size=lineSize) +
    geom_point(data=C_englishData_agro,aes(x=indepvar, y=x, color="English"),size=dotSize) +
    geom_line(data=C_germanData_agro,aes(x=indepvar, y=x, color="German"),size=lineSize) +
    geom_point(data=C_germanData_agro,aes(x=indepvar, y=x, color="German"),size=dotSize) +
    geom_line(data=C_dutchData_agro,aes(x=indepvar, y=x, color="Dutch"),size=lineSize) +
    geom_point(data=C_dutchData_agro,aes(x=indepvar, y=x, color="Dutch"),size=dotSize)
}

plotObjectC <- plotObjectC + 
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

print("Generated Homophony Plot")
###########################
###########################
###########################
