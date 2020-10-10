
###########################
## 0. Read in data files ##
###########################
PSM_PM_Actual_flag = "Nat"

data_source_dir = '' # e.g. path/to/ThePhonotacticMonkey/outputs/
working_dir = '' # e.g. path/to/ThePhonotacticMonkey/

if (PSM_PM_Actual_flag == "PSM") {
  outputPlotName = "allPlots-sylls-PSM.png"
  PSMInputFile = "output_CELEXSAMPA_PSM_1_sylls.csv"
} else if (PSM_PM_Actual_flag == "PM") {
  outputPlotName = "allPlots-sylls-PM.png"
  englishInputFile = "output_CELEXSAMPA_homophony_sylls.csv"
  dutchInputFile = "output_CELEXSAMPANL_homophony_sylls.csv"
  germanInputFile = "output_CELEXSAMPADE_homophony_sylls.csv"
} else {
  outputPlotName =  "allPlots-sylls-actual.png" 
  englishInputFile = "output_CELEXSAMPA_actual_homophony_sylls.csv"
  dutchInputFile = "output_CELEXSAMPANL_actual_homophony_sylls.csv"
  germanInputFile = "output_CELEXSAMPADE_actual_homophony_sylls.csv"
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
  PSMDataRaw=sylldataclean(read.csv(PSMInputFile,header=T))
} else {
  englishDataRaw=sylldataclean(read.csv(englishInputFile,header=T))
  dutchDataRaw=sylldataclean(read.csv(dutchInputFile,header=T))
  germanDataRaw=sylldataclean(read.csv(germanInputFile,header=T))
}
###########################
###########################
###########################


##################################
## 1. Merge and Prep Dataframes ##
##################################
if (PSM_PM_Actual_flag == "PSM") {
  A_PSMData = PSMDataRaw
  B_PSMData = PSMDataRaw
  C_PSMData = PSMDataRaw
  
  meanSensesPerSyllablePSM = aggregate(wordspersyllm1 ~ numphones, A_PSMData, FUN=mean)
  meanSensesPerSyllablePSM[is.na(meanSensesPerSyllablePSM)] = 0  
  aggregate(wordspersyllm1 ~ numphones, A_PSMData, FUN=length)
  
  B_PSMData_agro = aggrdata_exact_numgroups(B_PSMData$wordspersyllm1, B_PSMData$syllneglogprob, 20)
  
  # Filter out extremely low probability tail at 17 to Match PTG
  B_PSMData_agro = subset(B_PSMData_agro, indepvar <= 17.0)
  
  C_PSMData_agro = aggrdata_exact_numgroups(C_PSMData$wordspersyllm1, C_PSMData$phonsurprise, 20)
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
  
  meanSensesPerSyllableEnglish = aggregate(wordspersyllm1 ~ numphones, A_englishData, FUN=mean)
  meanSensesPerSyllableEnglish[is.na(meanSensesPerSyllableEnglish)] = 0  
  aggregate(wordspersyllm1 ~ numphones, A_englishData, FUN=length)
  
  meanSensesPerSyllableDutch = aggregate(wordspersyllm1 ~ numphones, A_dutchData, FUN=mean)
  meanSensesPerSyllableDutch[is.na(meanSensesPerSyllableDutch)] = 0  
  aggregate(wordspersyllm1 ~ numphones, A_dutchData, FUN=length)
  
  meanSensesPerSyllableGerman = aggregate(wordspersyllm1 ~ numphones, A_germanData, FUN=mean)
  meanSensesPerSyllableGerman[is.na(meanSensesPerSyllableGerman)] = 0  
  aggregate(wordspersyllm1 ~ numphones, A_germanData, FUN=length)
  
  
  B_englishData_agro = aggrdata_exact_numgroups(B_englishData$wordspersyllm1, B_englishData$syllneglogprob, 20)
  B_germanData_agro = aggrdata_exact_numgroups(B_germanData$wordspersyllm1, B_germanData$syllneglogprob, 20)
  B_dutchData_agro = aggrdata_exact_numgroups(B_dutchData$wordspersyllm1, B_dutchData$syllneglogprob, 20)
  
  # Filter out extremely low probability tail at 17 to Match PTG
  B_englishData_agro = subset(B_englishData_agro, indepvar <= 17.0)
  B_germanData_agro = subset(B_germanData_agro, indepvar <= 17.0)
  B_dutchData_agro = subset(B_dutchData_agro, indepvar <= 17.0)
  
  C_englishData_agro = aggrdata_exact_numgroups(C_englishData$wordspersyllm1, C_englishData$phonsurprise, 20)
  C_germanData_agro = aggrdata_exact_numgroups(C_germanData$wordspersyllm1, C_germanData$phonsurprise, 20)
  C_dutchData_agro = aggrdata_exact_numgroups(C_dutchData$wordspersyllm1, C_dutchData$phonsurprise, 20)
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


###############################################
## 3. Plot numPhones over Syll Informativity ##
###############################################
if (PSM_PM_Actual_flag == 'PSM') {
  plotObjectA = ggplot() + 
    geom_line(data=meanSensesPerSyllablePSM,aes(x=numphones, y=wordspersyllm1, color="PSM-English"),size=lineSize) +
    geom_point(data=meanSensesPerSyllablePSM,aes(x=numphones, y=wordspersyllm1, color="PSM-English"),size=dotSize) +
    scale_y_log10(breaks=c(1,10,100,1000),labels=c(1,10,100,1000)) +
    scale_color_manual(values=alphabeticalColoringOrder,
                       name = legendLabel,
                       breaks = c("PSM-English"),
                       labels = c("PSM-English"))
} else {
  plotObjectA = ggplot() + 
    geom_line(data=meanSensesPerSyllableEnglish,aes(x=numphones, y=wordspersyllm1, color="English"),size=lineSize) +
    geom_point(data=meanSensesPerSyllableEnglish,aes(x=numphones, y=wordspersyllm1, color="English"),size=dotSize) +
    geom_line(data=meanSensesPerSyllableGerman,aes(x=numphones, y=wordspersyllm1, color="German"),size=lineSize) +
    geom_point(data=meanSensesPerSyllableGerman,aes(x=numphones, y=wordspersyllm1, color="German"),size=dotSize) +
    geom_line(data=meanSensesPerSyllableDutch,aes(x=numphones, y=wordspersyllm1, color="Dutch"),size=lineSize) +
    geom_point(data=meanSensesPerSyllableDutch,aes(x=numphones, y=wordspersyllm1, color="Dutch"),size=dotSize) +
    scale_y_log10(breaks=c(1,10,100,1000),labels=c(1,10,100,1000)) +
    scale_color_manual(values=alphabeticalColoringOrder,
                       name = legendLabel,
                       breaks = c("English","German","Dutch"))
}

plotObjectA <- plotObjectA + 
  expand_limits(y=c(1,1000)) +
  ylab("Syllable Informativity") +
  xlab("Length in phones") +
  homophony_polysemy_labeled_theme()
###########################
###########################
###########################


####################################################
## 4. Plot syllneglogprob over Syll Informativity ##
####################################################
if (PSM_PM_Actual_flag == 'PSM') {
  plotObjectB = ggplot() + 
    geom_line(data=B_PSMData_agro,aes(x=indepvar, y=x, color="PSM"),size=lineSize) +
    geom_point(data=B_PSMData_agro,aes(x=indepvar, y=x, color="PSM"),size=dotSize)
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
  scale_y_log10(breaks=c(1,10,100,1000),labels=c(1,10,100,1000)) +
  scale_x_continuous(breaks=c(5,10,15,20,25),labels=c(5,10,15,20,25)) +
  scale_color_manual(values=alphabeticalColoringOrder) +
  expand_limits(y=c(1,1000),x=c(5,20)) +
  xlab("Negative log probability") +
  homophony_polysemy_nolabel_theme()
###########################
###########################
###########################


####################################################
## 5. Plot phoneSurprise over Syll Informativity ##
####################################################
if (PSM_PM_Actual_flag == 'PSM') {
  plotObjectC = ggplot() +
    geom_line(data=C_PSMData_agro,aes(x=indepvar, y=x, color="PSM"),size=lineSize) +
    geom_point(data=C_PSMData_agro,aes(x=indepvar, y=x, color="PSM"),size=dotSize)
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
  scale_y_log10(breaks=c(1,10.000,100.000,1000),labels=c(1,10.000,100.000,1000)) +
  scale_x_continuous(breaks=c(2,3,4,5,6,7,8,9,10),labels=c(2,3,4,5,6,7,8,9,10)) +
  scale_color_manual(values=alphabeticalColoringOrder) +
  expand_limits(y=c(1,1000),x=c(2,10)) +
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

print("Generated Syllable Informativity Plot")
###########################
###########################
###########################
