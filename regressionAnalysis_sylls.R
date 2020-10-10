
###########################
## 0. Read in data files ##
###########################
working_dir = '' # e.g. path/to/ThePhonotacticMonkey/
output_dir = '' # e.g. path/to/ThePhonotacticMonkey/
input_pointer = '' # e.g. path/to/ThePhonotacticMonkey/

args = commandArgs(trailingOnly=TRUE)
if (length(args)>2) {
  working_dir = args[1]
  output_dir = args[2]
  input_pointer = args[3]
}

lastCharWorkDir = substr(working_dir, nchar(working_dir), nchar(working_dir))
if (lastCharWorkDir == '/') {
  auxSource = paste(working_dir,"aux-functions.R",sep="")
} else {
  auxSource = paste(working_dir,"/aux-functions.R",sep="")
}
source(auxSource)
load_in_limited()

fileList <- scan(input_pointer, what="", sep="\n")
###########################
###########################
###########################


#################################
## 1. Loop and fit regressions ##
#################################
setwd(output_dir)
for (currFile in fileList) {
  print(currFile)
  currHeader = str_sub(currFile,0,-5)
  currOutputfilename = paste(currHeader,"__stats.txt",sep="")
  currData = read.csv(currFile,header=T)
  
  # Normalizing to match PTG:
  # "For all regression analyses, we standardized the covariates by subtracting the mean and dividing by 1 standard deviation"
  currData$normednumphones = (currData$numphones-mean(currData$numphones))/sd(currData$numphones)
  currData$normedsyllneglogprob = (currData$syllneglogprob-mean(currData$syllneglogprob))/sd(currData$syllneglogprob)
  currData$normedphonsurprise = (currData$phonsurprise-mean(currData$phonsurprise))/sd(currData$phonsurprise)
  
  write("WORDS APPEARING IN BY NUMBER OF PHONES", file = currOutputfilename, sep="")
  s1 = summary(glm(currData$wordspersyll~currData$normednumphones,family=quasipoisson()))
  capture.output(s1, file = currOutputfilename, append=TRUE)
  
  write("WORDS APPEARING IN BY NEG LOG PROB", file = currOutputfilename, append=TRUE)
  s2 = summary(glm(currData$wordspersyll~currData$normedsyllneglogprob,family=quasipoisson()))
  capture.output(s2, file = currOutputfilename, append=TRUE)
  
  write("WORDS APPEARING IN BY PHON SURPRISAL", file = currOutputfilename, append=TRUE)
  s3 = summary(glm(currData$wordspersyll~currData$normedphonsurprise,family=quasipoisson()))
  capture.output(s3, file = currOutputfilename, append=TRUE)
  
  write("WORDS APPEARING IN BY PHON SURPRISAL SQUARED", file = currOutputfilename, append=TRUE)
  s4 = summary(glm(currData$wordspersyll~currData$normedphonsurprise + I(currData$normedphonsurprise^2),family=quasipoisson()))
  capture.output(s4, file = currOutputfilename, append=TRUE)
}

print("Finished applying syllable regressions")
###########################
###########################
###########################
