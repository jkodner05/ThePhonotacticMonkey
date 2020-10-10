
###########################
## 0. Read in data files ##
###########################
data_source_dir = '' # e.g. path/to/ThePhonotacticMonkey/outputs/
working_dir = '' # e.g. path/to/ThePhonotacticMonkey/

stoppingCondition = 'MatchBoth'
inputFileEPL = 'output_CELEXSAMPALEMMA_actual_newLM_metrics.csv'
inputFileNewFormsSingleLM = 'epl_onlyOED_NF_withLength_metrics.csv'
inputFileOldFormsSingleLM = 'epl_onlyOED_RF_withLength_metrics.csv'
inputFileOldStaleFormsSingleLM = 'epl_onlyOED_SF_withLength_metrics.csv'
inputFileOEDprime = 'output_CELEXSAMPA_PSM_1_OEDprimesource_175k_metrics.csv'
inputFileOEDprime_Chron = 'output_CELEXSAMPA_PSM_1_OEDprimesource_175k_grafted_chron.txt'

args = commandArgs(trailingOnly=TRUE)
if (length(args)>8) {
  working_dir = args[1]
  data_source_dir = args[2]
  stoppingCondition = args[3]
  inputFileEPL = args[4]
  inputFileNewFormsSingleLM = args[5]
  inputFileOldFormsSingleLM = args[6]
  inputFileOldStaleFormsSingleLM = args[7]
  inputFileOEDprime = args[8]
  inputFileOEDprime_Chron = args[9]
}

outputStatsFile = paste("PSM-OED-RFNFSF-", stoppingCondition, "__stats.txt", sep="")
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

dataAllEPL <- read.table(inputFileEPL,header=TRUE,sep=",", quote = "", skipNul = TRUE,fill = TRUE, comment.char = "", check.names = FALSE)
dataAllNF <- read.table(inputFileNewFormsSingleLM,header=TRUE,sep=",", quote = "", skipNul = TRUE,fill = TRUE, comment.char = "", check.names = FALSE)
dataAllRF <- read.table(inputFileOldFormsSingleLM,header=TRUE,sep=",", quote = "", skipNul = TRUE,fill = TRUE, comment.char = "", check.names = FALSE)
dataAllSF <- read.table(inputFileOldStaleFormsSingleLM,header=TRUE,sep=",", quote = "", skipNul = TRUE,fill = TRUE, comment.char = "", check.names = FALSE)
dataAllOEDprime <- read.table(inputFileOEDprime,header=TRUE,sep=",", quote = "", skipNul = TRUE,fill = TRUE, comment.char = "", check.names = FALSE)
dataAllOEDprime_Chron <- read.table(inputFileOEDprime_Chron,header=TRUE,sep="\t", quote = "", skipNul = TRUE,fill = TRUE, comment.char = "", check.names = FALSE)
###########################
###########################
###########################


##################################
## 1. Merge and Prep Dataframes ##
##################################
##### Prep OED #####
dataAllEPL$formSet <- ifelse(dataAllEPL$word %in% dataAllRF$word, 'RF',
                             ifelse(dataAllEPL$word %in% dataAllNF$word, 'NF',
                                    ifelse(dataAllEPL$word %in% dataAllSF$word, 'SF',
                                           'NonOED')))
# Check resultant lexicon sizes
OED_NF_Size <- nrow(subset(dataAllEPL, formSet == 'NF'))
OED_RF_Size <- nrow(subset(dataAllEPL, formSet == 'RF'))

dataAllEPL <- subset(dataAllEPL, formSet != 'NonOED')

#### OED prime intersection
dataAllEPL_RFSF <- subset(dataAllEPL, formSet == 'RF' | formSet == 'SF')
'%ni%' <- Negate('%in%')
count_added_to_OEDprimeNF = 0
OEDprimeNF_forms <- character(0)
count_added_to_OEDprimeRF = 0
OEDprimeRF_forms <- character(0)
count_notadded = 0
interator_index = 1

## Cut prime-chron in half at the specified year boundary
# RFuSF is everything before `year': 56195
prime_pre1900 <- head(dataAllOEDprime_Chron, 56195)
prime_post1900 <- tail(dataAllOEDprime_Chron,-56195)

########################

if (stoppingCondition == "MatchRF") {
  ## Iteratate thorugh all post1900 forms counting both NF and RF
  while (count_added_to_OEDprimeRF < OED_RF_Size) {
    curr_entry = prime_post1900[interator_index,]
    curr_form = as.character(curr_entry[,4])
    if (curr_form %in% dataAllEPL_RFSF$word) {
      if (curr_form %ni% OEDprimeRF_forms) {
        OEDprimeRF_forms <- c(OEDprimeRF_forms, curr_form)
        count_added_to_OEDprimeRF = count_added_to_OEDprimeRF + 1
      }
    } else {
      if (curr_form %ni% OEDprimeNF_forms) {
        OEDprimeNF_forms <- c(OEDprimeNF_forms, curr_form)
        count_added_to_OEDprimeNF = count_added_to_OEDprimeNF + 1
      }
    }
    interator_index = interator_index + 1
    if (mod(interator_index, 5000) == 0 ) {
      print(paste0("Index: ", interator_index, ", RF-prime: ", count_added_to_OEDprimeRF, ", NF-prime: ", count_added_to_OEDprimeNF))
    }
  }
  
} else if (stoppingCondition == "MatchNF") {
  while (count_added_to_OEDprimeNF < OED_NF_Size) {
    curr_entry = prime_post1900[interator_index,]
    curr_form = as.character(curr_entry[,4])
    if (curr_form %in% dataAllEPL_RFSF$word) {
      if (curr_form %ni% OEDprimeRF_forms) {
        OEDprimeRF_forms <- c(OEDprimeRF_forms, curr_form)
        count_added_to_OEDprimeRF = count_added_to_OEDprimeRF + 1
      }
    } else {
      if (curr_form %ni% OEDprimeNF_forms) {
        OEDprimeNF_forms <- c(OEDprimeNF_forms, curr_form)
        count_added_to_OEDprimeNF = count_added_to_OEDprimeNF + 1
      }
    }
    interator_index = interator_index + 1
    if (mod(interator_index, 5000) == 0 ) {
      print(paste0("Index: ", interator_index, ", RF-prime: ", count_added_to_OEDprimeRF, ", NF-prime: ", count_added_to_OEDprimeNF))
    }
  }
} else if (stoppingCondition == "MatchBoth") {
  
  while (count_added_to_OEDprimeNF < OED_NF_Size) {
    curr_entry = prime_post1900[interator_index,]
    curr_form = as.character(curr_entry[,4])
    # check each form to see if it's in OED-RF or OED-SF
    if (curr_form %ni% dataAllEPL_RFSF$word) {
      if (curr_form %ni% OEDprimeNF_forms) {
        OEDprimeNF_forms <- c(OEDprimeNF_forms, curr_form)
        count_added_to_OEDprimeNF = count_added_to_OEDprimeNF + 1
      }
    } else {
      count_notadded = count_notadded + 1
    }
    interator_index = interator_index + 1
  }
  
  while (count_added_to_OEDprimeRF < OED_RF_Size) {
    curr_entry = prime_post1900[interator_index,]
    curr_form = as.character(curr_entry[,4])
    if (curr_form %in% dataAllEPL_RFSF$word) {
      if (curr_form %ni% OEDprimeRF_forms) {
        OEDprimeRF_forms <- c(OEDprimeRF_forms, curr_form)
        count_added_to_OEDprimeRF = count_added_to_OEDprimeRF + 1
      }
    } else {
      count_notadded = count_notadded + 1
    }
    interator_index = interator_index + 1
    if (mod(interator_index, 5000) == 0 ) {
      print(paste0("Index: ", interator_index, ", RF-prime: ", count_added_to_OEDprimeRF))
    }
  }
  
} else {
  print("Invalid stoppingCondition specified. Exiting without completing.")
  quit()
}

########################

OEDprimeNF_forms.df <- as.data.frame(OEDprimeNF_forms)
names(OEDprimeNF_forms.df)[names(OEDprimeNF_forms.df) == "OEDprimeNF_forms"] <- "word"
# intersect OEDprimeNF_formsList with dataAllOEDprime to get all the OEDprime-NF forms with metrics
OEDprime_NF <- merge(dataAllOEDprime, OEDprimeNF_forms.df, by.x = "word")
OEDprime_NF$formSet = 'NF-Prime'

# dataAllEPL_RFSF
nrow(dataAllEPL_RFSF) #there are 29050 old forms
nrow(subset(dataAllEPL_RFSF, formSet == 'RF')) # of which 11,239 got reused

OEDprimeRF_forms.df <- as.data.frame(OEDprimeRF_forms)
names(OEDprimeRF_forms.df)[names(OEDprimeRF_forms.df) == "OEDprimeRF_forms"] <- "word"
dataAllEPL_RFSF$newStatus <- ifelse(dataAllEPL_RFSF$word %in% OEDprimeRF_forms.df$word, 'prime-RF', 'prime-SF')

# Create a new OED-all (which includes prime-NF instead of real-NF)
OEDprime_NF$newStatus <- 'prime-NF'
dataAllEPL_prime <- rbind(dataAllEPL_RFSF, OEDprime_NF)
# Normalize phonsurprise and length based on that.

##### Add normed length and phonSurprise values #####
# OED
dataAllEPL$normedphonsuprise = (dataAllEPL$phonsuprise-mean(dataAllEPL$phonsuprise))/sd(dataAllEPL$phonsuprise)
dataAllEPL$normedLength = (dataAllEPL$numphones-mean(dataAllEPL$numphones))/sd(dataAllEPL$numphones)
dataAllEPL$normedFreq = (dataAllEPL$wordfreq-mean(dataAllEPL$wordfreq))/sd(dataAllEPL$wordfreq)
# OED-prime
dataAllEPL_prime$normedphonsuprise = (dataAllEPL_prime$phonsuprise-mean(dataAllEPL_prime$phonsuprise))/sd(dataAllEPL_prime$phonsuprise)
dataAllEPL_prime$normedLength = (dataAllEPL_prime$numphones-mean(dataAllEPL_prime$numphones))/sd(dataAllEPL_prime$numphones)
dataAllEPL_prime$normedFreq = (dataAllEPL_prime$wordfreq-mean(dataAllEPL_prime$wordfreq))/sd(dataAllEPL_prime$wordfreq)

##### Combine PSM and OED forms into single dataframe #####
dataAllEPL["genSource"] <- 'Actual-English'
dataAllEPL_prime["genSource"] <- 'Monkey-English'
dataAllEPL$newStatus <- 'NA'
PSM_OED_all <- rbind(dataAllEPL, dataAllEPL_prime)

##### All normed and unnormed
OED_RF <- subset(dataAllEPL, formSet == 'RF')
OED_SF <- subset(dataAllEPL, formSet == 'SF')
OED_NF <- subset(dataAllEPL, formSet == 'NF')
prime_RF <- subset(dataAllEPL_prime, newStatus == 'prime-RF')
prime_SF <- subset(dataAllEPL_prime, newStatus == 'prime-SF')
prime_NF <- subset(dataAllEPL_prime, newStatus == 'prime-NF')
###########################
###########################
###########################


#########################################
## 1. OED and PSM RF to SF Phone Plot ##
#########################################
##### OED Phone Plot #####
dataAllEPL$lengthBin <- compute_length_bin_fun(dataAllEPL, "numphones")

dataAllEPL %>%
  group_by(formSet,lengthBin) %>%
  compute_summary_fun(phonsuprise) -> trendsData_OED_RFSF_lengthBins
trendsData_OED_RFSF_lengthBins = as.data.frame(trendsData_OED_RFSF_lengthBins)
names(trendsData_OED_RFSF_lengthBins)[names(trendsData_OED_RFSF_lengthBins) == 'avg'] <- 'phonSurprise'
trendsData_OED_RFSF_lengthBins <- subset(trendsData_OED_RFSF_lengthBins, formSet != 'NF')
trendsData_OED_RFSF_lengthBins <- subset(trendsData_OED_RFSF_lengthBins, lengthBin != 'NA')
trendsData_OED_RFSF_lengthBins$lengthBin <- factor(trendsData_OED_RFSF_lengthBins$lengthBin, levels = c("3-4", "5-6", "7-8", "+9"))

actual_RFSF_plot_PS <- ggplot(trendsData_OED_RFSF_lengthBins, aes(x= factor(lengthBin), y = phonSurprise, colour=formSet, fill = formSet, group = as.factor(formSet)))
actual_RFSF_plot_PS + geom_errorbar(aes(ymin=phonSurprise-se, ymax=phonSurprise+se), width=0.5, position=pd, size=1) +
  geom_line(position=pd,size=2) + geom_point(position=pd, size=3) +
  labs(x = "Length in phones", y = "Phonotactic surprisal / length") +
  scale_fill_brewer(palette="Set1", aesthetics = c("colour", "fill"), name = "Word Type", labels = c(expression('RF'[E]), expression('SF'[E]))) +
  # homophony_polysemy_nolabel_theme() + 
  homophony_polysemy_labelednoLegend_theme() +
  scale_y_continuous(breaks=c(3.0,4.0,5.0),labels=c('3.0','4.0','5.0'), limits = c(3.0, 5.0)) -> actual_RFSF_plot_PS

########### Monkey English
dataAllEPL_prime$lengthBin <- compute_length_bin_fun(dataAllEPL_prime, "numphones")

dataAllEPL_prime %>%
  group_by(newStatus,lengthBin) %>%
  compute_summary_fun(phonsuprise) -> trendsData_prime_RFSF_lengthBins
trendsData_prime_RFSF_lengthBins = as.data.frame(trendsData_prime_RFSF_lengthBins)
names(trendsData_prime_RFSF_lengthBins)[names(trendsData_prime_RFSF_lengthBins) == 'avg'] <- 'phonSurprise'
trendsData_prime_RFSF_lengthBins <- subset(trendsData_prime_RFSF_lengthBins, newStatus != 'prime-NF')
trendsData_prime_RFSF_lengthBins <- subset(trendsData_prime_RFSF_lengthBins, lengthBin != 'NA')
trendsData_prime_RFSF_lengthBins$lengthBin <- factor(trendsData_prime_RFSF_lengthBins$lengthBin, levels = c("3-4", "5-6", "7-8", "+9"))

prime_RFSF_plot <- ggplot(trendsData_prime_RFSF_lengthBins, aes(x= factor(lengthBin), y = phonSurprise, colour=newStatus, fill = newStatus, group = as.factor(newStatus)))
prime_RFSF_plot + geom_errorbar(aes(ymin=phonSurprise-se, ymax=phonSurprise+se), width=0.5, position=pd, size=1) +
  geom_line(position=pd,size=2) + geom_point(position=pd, size=3) +
  labs(x = "Length in phones", y = "Phonotactic surprisal / length") +
  scale_fill_brewer(palette="Set1", aesthetics = c("colour", "fill"), name = "Word Type", labels = c(expression('RF'[ME]), expression('SF'[ME]))) +
  # homophony_polysemy_nolabel_theme() + 
  homophony_polysemy_labelednoLegend_theme() +
  scale_y_continuous(breaks=c(3.0,4.0,5.0),labels=c('3.0','4.0','5.0'), limits = c(3.0, 5.0))  -> prime_RFSF_plot
#######################
#######################
#######################


##########################################
## 2. OED and PSM RF to SF Phone Stats ##
##########################################
# RF forms have significantly lower phonSurprise than SF under both OED and PSM #
OED_data_RF_SF <- subset(dataAllEPL, formSet != 'NF')
OED_prime_data_RF_SF <- subset(dataAllEPL_prime, newStatus != 'prime-NF')
write("PSM/OED RF vs. SF phonSurprise comparison", file = outputStatsFile, sep="")
s0 = summary(glm(normedphonsuprise ~ formSet * normedLength, data= OED_data_RF_SF))
s1 = summary(glm(normedphonsuprise ~ newStatus * normedLength, data= OED_prime_data_RF_SF))
capture.output(s0, file = outputStatsFile, append=TRUE)
capture.output(s1, file = outputStatsFile, append=TRUE)
#######################
#######################
#######################


##########################################
## 3. OED and PSM RF to SF Word Length ##
##########################################
OED_WL_plot_RFSF <- ggplot(OED_data_RF_SF, aes(x=numphones, color=formSet, fill=formSet))
OED_WL_plot_RFSF + geom_density(position="identity", size=1, alpha=0.5, adjust=bw(0.6, OED_data_RF_SF$numphones)) +
  homophony_polysemy_labeled_theme() + 
  theme(legend.position = c(0.6, 0.8)) + 
  scale_fill_brewer(palette="Set1", aesthetics = c("colour", "fill"), name = "Word Type", labels = c(expression('RF'[E]), expression('SF'[E]))) +
  ylim(0.0, density_plot_ymax) +
  xlim(0, 18) +
  labs(x = "Length in phones", y = "Density") -> OED_WL_plot_RFSF
mu_OED <- ddply(OED_data_RF_SF, "formSet", summarise, grp.mean=mean(numphones))
OED_WL_plot_RFSF + geom_vline(data=mu_OED, size=2, aes(xintercept=grp.mean, color=formSet),
               linetype="dashed") -> OED_WL_plot_RFSF

######## OED prime RF
prime_WL_plot_RFSF <- ggplot(OED_prime_data_RF_SF, aes(x=numphones, color=newStatus, fill=newStatus))
prime_WL_plot_RFSF + geom_density(position="identity", size=1, alpha=0.5, adjust=bw(0.9, dataAllEPL_RFSF$numphones)) +
  homophony_polysemy_labeled_theme() + 
  theme(legend.position = c(0.6, 0.8)) + 
  scale_fill_brewer(palette="Set1", aesthetics = c("colour", "fill"), name = "Word Type", labels = c(expression('RF'[ME]), expression('SF'[ME]))) +
  ylim(0.0, density_plot_ymax) +
  xlim(0, 18) +
  labs(x = "Length in phones", y = "Density") -> prime_WL_plot_RFSF
mu_OED <- ddply(dataAllEPL_RFSF, "newStatus", summarise, grp.mean=mean(numphones))
prime_WL_plot_RFSF + geom_vline(data=mu_OED, size=2, aes(xintercept=grp.mean, color=newStatus),
                               linetype="dashed") -> prime_WL_plot_RFSF
#######################
#######################
#######################


###############################################
## 4. OED and PSM RF to SF Word Length Stats ##
###############################################
# RF forms are significantly shorter than SF under both OED and PSM #
write("PSM/OED RF vs. SF length comparison", file = outputStatsFile, sep="", append=TRUE)
s0.wl = summary(glm(normedLength ~ formSet, data= OED_data_RF_SF))
s1.wl = summary(glm(normedLength ~ newStatus, data= OED_prime_data_RF_SF))
capture.output(s0.wl, file = outputStatsFile, append=TRUE)
capture.output(s1.wl, file = outputStatsFile, append=TRUE)

write("PSM/OED RF vs. SF length t.test", file = outputStatsFile, sep="", append=TRUE)
t0.wl = t.test(subset(OED_data_RF_SF, formSet == 'RF')$numphones, subset(OED_data_RF_SF, formSet == 'SF')$numphones)
t1.wl = t.test(subset(OED_prime_data_RF_SF, newStatus == 'prime-RF')$numphones, subset(OED_prime_data_RF_SF, newStatus == 'prime-SF')$numphones)
capture.output(t0.wl, file = outputStatsFile, append=TRUE)
capture.output(t1.wl, file = outputStatsFile, append=TRUE)
#######################
#######################
#######################


############################################
## 5. Actual vs. Monkey RF/SF Frequencies ##
############################################
ActualPre <- subset(PSM_OED_all, genSource == 'Actual-English')
ActualPre <- subset(ActualPre, formSet != 'NF')
ActualPre$logfreq <- log(ActualPre$wordfreq)
MonkeyPre <- subset(PSM_OED_all, genSource == 'Monkey-English')
MonkeyPre <- subset(MonkeyPre, newStatus != 'prime-NF')
MonkeyPre$logfreq <- log(MonkeyPre$wordfreq)

# Regression to predict frequency from set/status and length (plus interaction)
write("PSM/OED RF Frequency regressions", file = outputStatsFile, sep="", append=TRUE)
rf.s0.freq = summary(glm(logfreq ~ formSet * normedLength, data= ActualPre))
rf.s1.freq = summary(glm(logfreq ~ newStatus * normedLength, data= MonkeyPre))
capture.output(rf.s0.freq, file = outputStatsFile, append=TRUE)
capture.output(rf.s1.freq, file = outputStatsFile, append=TRUE)

RF_freq_plot <- ggplot(ActualPre, aes(x=as.numeric(logfreq), color=formSet, fill=formSet))
RF_freq_plot + geom_density(position="identity", size=1, alpha=0.5, adjust=bw(0.6, ActualPre$logfreq)) +
  homophony_polysemy_nolabel_theme() +
  scale_fill_brewer(palette="Set1", aesthetics = c("colour", "fill"), name = "Word Type", labels = c(expression('RF'[E]), expression('SF'[E]))) +
  ylim(0.0, 0.3) +
  xlim(-2,10) +
  labs(x = "Negative log probability", y = "Density") -> RF_freq_plot
mu_OED <- ddply(ActualPre, "formSet", summarise, grp.mean=mean(logfreq))
RF_freq_plot + geom_vline(data=mu_OED, size=2, aes(xintercept=grp.mean, color=formSet),
                          linetype="dashed") -> RF_freq_plot

Monkey_RF_freq_plot <- ggplot(MonkeyPre, aes(x=as.numeric(logfreq), color=newStatus, fill=newStatus))
Monkey_RF_freq_plot + geom_density(position="identity", size=1, alpha=0.5, adjust=bw(0.6, MonkeyPre$logfreq)) +
  homophony_polysemy_nolabel_theme() +
  scale_fill_brewer(palette="Set1", aesthetics = c("colour", "fill"), name = "Actual English\nWord Type", labels = c(expression('RF'[ME]), expression('SF'[ME]))) +
  ylim(0.0, 0.3) +
  xlim(-2,10) +
  labs(x = "Negative log probability", y = "Density") -> Monkey_RF_freq_plot
mu_OED <- ddply(MonkeyPre, "newStatus", summarise, grp.mean=mean(logfreq))
Monkey_RF_freq_plot + geom_vline(data=mu_OED, size=2, aes(xintercept=grp.mean, color=newStatus),
                                 linetype="dashed") -> Monkey_RF_freq_plot
#######################
#######################
#######################


###############################################
## 6. Monkey and Actual RF/SF Tri-pane plots ##
###############################################
combinedPlot_RF_Actual_Triple = plot_grid(OED_WL_plot_RFSF, RF_freq_plot, actual_RFSF_plot_PS,
                                          label_x = 0.5,
                                          label_y = 0.3,
                                          ncol = 3, align = 'h', hjust = 4)
outputPlotLine = paste("Actual-", stoppingCondition, "-RFs-triple.png", sep="")
ggsave(filename=outputPlotLine, width = 60, height = 24, units = "cm")

combinedPlot_RF_Actual_Triple = plot_grid(prime_WL_plot_RFSF, Monkey_RF_freq_plot, prime_RFSF_plot,
                                          label_x = 0.5,
                                          label_y = 0.3,
                                          ncol = 3, align = 'h', hjust = 4)
outputPlotLine = paste("Monkey-", stoppingCondition, "-RFs-triple.png", sep="")
ggsave(filename=outputPlotLine, width = 60, height = 24, units = "cm")
#######################
#######################
#######################


#################################
## 7. NF Length Plot and Stats ##
#################################
PSM_OED_onlyNF <- subset(PSM_OED_all, formSet == 'NF' | newStatus == 'prime-NF')
NF_WL_plot <- ggplot(PSM_OED_onlyNF, aes(x=numphones, color=genSource, fill=genSource))
NF_WL_plot + geom_density(position="identity", size=1, alpha=0.5, adjust=bw(0.6, PSM_OED_onlyNF$numphones)) +
  scale_fill_manual(values=c("#5e3c99", "#e66101"), aesthetics = c("color", "fill"), name = "Lexicon", labels = c(bquote('Actual English, NF'[E]), bquote('Monkey English, NF'[ME]))) +
  ylim(0.0, density_plot_ymax) +
  xlim(0, 18) +
  labs(x = "Length in phones", y = "Density") +
  single_pane_theme() + 
  theme(legend.position = c(.7, .85)) -> NF_WL_plot
mu_OED <- ddply(PSM_OED_onlyNF, "genSource", summarise, grp.mean=mean(numphones))
NF_WL_plot + geom_vline(data=mu_OED, size=2, aes(xintercept=grp.mean, color=genSource),
                        linetype="dashed") -> NF_WL_plot

# Monkey NFs are shorter than actual NFs
write("PSM/OED NF length t.test", file = outputStatsFile, sep="", append=TRUE)
nf.t0.wl = t.test(subset(PSM_OED_onlyNF, genSource == 'Actual-English')$normedLength, subset(PSM_OED_onlyNF, genSource == 'Monkey-English')$normedLength)
nf.t1.wl = t.test(subset(PSM_OED_onlyNF, genSource == 'Actual-English')$numphones, subset(PSM_OED_onlyNF, genSource == 'Monkey-English')$numphones)
capture.output(nf.t0.wl, file = outputStatsFile, append=TRUE)
capture.output(nf.t1.wl, file = outputStatsFile, append=TRUE)

# Monkey NFs are shorter than pre-1900 forms
write("Monkey NFs vs. pre-1900 forms length comparison", file = outputStatsFile, sep="", append=TRUE)
nf.t2.wl = t.test(subset(PSM_OED_onlyNF, genSource == 'Monkey-English')$numphones, OED_data_RF_SF$numphones)
capture.output(nf.t2.wl, file = outputStatsFile, append=TRUE)
#######################
#######################
#######################


#######################################
## 8. NF PhonSurprise Plot and Stats ##
#######################################
PSM_OED_onlyNF$lengthBin <- compute_length_bin_fun(PSM_OED_onlyNF, "numphones")

PSM_OED_onlyNF %>%
  group_by(genSource,lengthBin) %>%
  compute_summary_fun(phonsuprise) -> trendsData_NF_lengthBins
trendsData_NF_lengthBins = as.data.frame(trendsData_NF_lengthBins)
names(trendsData_NF_lengthBins)[names(trendsData_NF_lengthBins) == 'avg'] <- 'phonSurprise'
trendsData_NF_lengthBins <- subset(trendsData_NF_lengthBins, lengthBin != 'NA')
trendsData_NF_lengthBins$lengthBin <- factor(trendsData_NF_lengthBins$lengthBin, levels = c("3-4", "5-6", "7-8", "+9"))

NF_PS_plot <- ggplot(trendsData_NF_lengthBins, aes(x= factor(lengthBin), y = phonSurprise, colour=genSource, fill = genSource, group = as.factor(genSource)))
NF_PS_plot + geom_errorbar(aes(ymin=phonSurprise-se, ymax=phonSurprise+se), width=0.5, position=pd, size=1) +
  geom_line(position=pd,size=2) + geom_point(position=pd, size=3) +
  labs(x = "Length in phones", y = "Phonotactic surprisal / length") +
  scale_fill_manual(values=c("#5e3c99", "#e66101"), aesthetics = c("color", "fill"), name = "Lexicon", labels = c(bquote('Actual English, NF'[E]), bquote('Monkey English, NF'[ME]))) +
  single_pane_theme() + 
  theme(legend.position = c(.7, .85)) -> NF_PS_plot


# add a density plot here
## Shorter words have higher surprisal, ME has more short words, so by default it should have higher surprisal. But it doesn't
NF_PS_density_plot <- ggplot(PSM_OED_onlyNF, aes(x=phonsuprise, color=genSource, fill=genSource))
NF_PS_density_plot + geom_density(position="identity", size=1, alpha=0.5, adjust=bw(0.6, PSM_OED_onlyNF$phonsuprise)) +
  scale_fill_manual(values=c("#5e3c99", "#e66101"), aesthetics = c("color", "fill"), name = "Lexicon", labels = c(bquote('Actual English, NF'[E]), bquote('Monkey English, NF'[ME]))) +
  ylim(0.0, 0.5) +
  xlim(0.0, 12) +
  labs(x = "Phonotactic surprisal / length", y = "Density") +
  single_pane_theme() + 
  theme(legend.position = c(.7, .85)) -> NF_PS_density_plot
mu_OED <- ddply(PSM_OED_onlyNF, "genSource", summarise, grp.mean=mean(phonsuprise))
NF_PS_density_plot + geom_vline(data=mu_OED, size=2, aes(xintercept=grp.mean, color=genSource),
                        linetype="dashed") -> NF_PS_density_plot

# Monkey NFs are significantly lower PhonSurprise than OED NFs
write("PSM/OED NF PhonSurprise t.test", file = outputStatsFile, sep="", append=TRUE)
nf.t0.ps = t.test(subset(PSM_OED_onlyNF, genSource == 'Actual-English')$phonsuprise, subset(PSM_OED_onlyNF, genSource == 'Monkey-English')$phonsuprise)
capture.output(nf.t0.ps, file = outputStatsFile, append=TRUE)
write("PSM/OED NF PhonSurprise t.test (normed)", file = outputStatsFile, sep="", append=TRUE)
nf.t1.ps = t.test(subset(PSM_OED_onlyNF, genSource == 'Actual-English')$normedphonsuprise, subset(PSM_OED_onlyNF, genSource == 'Monkey-English')$normedphonsuprise)
capture.output(nf.t1.ps, file = outputStatsFile, append=TRUE)
write("PSM/OED NF PhonSurprise regression", file = outputStatsFile, sep="", append=TRUE)
nf.s0.ps = summary(glm(normedphonsuprise ~ genSource * normedLength, data= PSM_OED_onlyNF))
capture.output(nf.s0.ps, file = outputStatsFile, append=TRUE)
#######################
#######################
#######################


#################################################
## 9. Combine NF Comparison plots side by side ##
#################################################
combinedPlot_NF = plot_grid(NF_PS_density_plot, NF_WL_plot,
                            label_x = 0.5,
                            label_y = 0.3,
                            ncol = 2, align = 'h', hjust = 4)
outputPlotLine = paste("Actual-v-Monkey-", stoppingCondition, "-NFs-WL-PS--Density-Overlay.png", sep="")
ggsave(filename=outputPlotLine, width = 60, height = 30, units = "cm")

# justMonkeyNFs <- subset(PSM_OED_onlyNF, genSource == 'Monkey-English')
# couldBeMonkeyNFs <- subset(prime_post1900, (newform %ni% justMonkeyNFs$word))
# couldBeMonkeyNFs <- subset(couldBeMonkeyNFs, (newform %ni% dataAllEPL$word))
# couldBeMonkeyNFs <- subset(couldBeMonkeyNFs, ispolyseme == "False")
# nrow(couldBeMonkeyNFs)
# write.csv(couldBeMonkeyNFs, "CouldBeMonkeyNFs_MatchRFsize.csv")
#######################
#######################
#######################
