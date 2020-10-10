
###########################
## 0. Read in data files ##
###########################
data_source_dir = '' # e.g. path/to/ThePhonotacticMonkey/outputs/
working_dir = '' # e.g. path/to/ThePhonotacticMonkey/
PSMInputFile = "output_CELEXSAMPA_PSM_1_chron.txt"
threshold = "1"

args = commandArgs(trailingOnly=TRUE)
if (length(args)>3) {
  working_dir = args[1]
  data_source_dir = args[2]
  PSMInputFile = args[3]
  threshold = args[4]
}

outputPlotName = "PSM-semanticField"
lastCharWorkDir = substr(working_dir, nchar(working_dir), nchar(working_dir))
if (lastCharWorkDir == '/') {
  auxSource = paste(working_dir,"aux-functions.R",sep="")
} else {
  auxSource = paste(working_dir,"/aux-functions.R",sep="")
}
source(auxSource)
load_in_libraries()
load_in_voronoi()
load_in_plot_aesthetics()
setwd(data_source_dir)

PSMDataRaw=read.table(PSMInputFile,sep="\t",row.names=NULL, comment.char = "", stringsAsFactors = FALSE, col.names = c("Year", "Forms", "Senses", "Newform", "X", "Y", "ispolyseme"))
PSMDataRaw <- PSMDataRaw[-c(1),]

# Set X,Y coords to doubles
PSMDataRaw$X <- as.double(PSMDataRaw$X)
PSMDataRaw$Y <- as.double(PSMDataRaw$Y)

# Forms need to be factors
PSMDataRaw$Newform <- as.factor(PSMDataRaw$Newform)
PSMDataRaw[,'Newform']<-factor(PSMDataRaw[,'Newform'])

PSMDataRaw %>% group_by(Newform) %>% dplyr::summarize(count=n()) -> formsWithCounts

PSMDataNoFilterSuperZoomed <- subset(PSMDataRaw, X > 48.5 & X < 51.5 & Y > 48.5 & Y < 51.5)
###########################
###########################
###########################


##################################
## 1. Define plotting aesthetic ##
##################################
getPalette = colorRampPalette(brewer.pal(9, "Paired"))
colorCountNoFilterSuperZoomed = length(unique(PSMDataNoFilterSuperZoomed$Newform))
colorSetNoFilterSuperZoomed = getPalette(colorCountNoFilterSuperZoomed)

outline.df <- data.frame(x = c(48.5, 51.5, 51.5, 48.5),
                         y = c(48.5, 48.5, 51.5, 51.5))
###########################
###########################
###########################


#####################
## 2. Voronoi Plot ##
#####################
voronoi_T1_NoFilterSuperZoom <- ggplot(PSMDataNoFilterSuperZoomed, aes(x=X, y=Y)) +
  geom_voronoi(outline = outline.df, aes(fill = factor(Newform), group = -1L)) + 
  geom_point(shape = 20, size = voronoi_dot_size, colour = "black") +
  sem_field_theme() + 
  labs(title = "Sub-Region of PSM Semantic Field") +
  scale_x_continuous(limits = c(48.5,51.5), breaks=c(49,50,51), expand = c(0, 0)) +
  scale_y_continuous(limits = c(48.5,51.5), breaks=c(49,50,51), expand = c(0, 0)) +
  scale_fill_manual(values = colorSetNoFilterSuperZoomed)
outputPlotNameCurrent = paste(outputPlotName, "-Voronoi-T", threshold, ".png", sep = "", collapse = NULL)
ggsave(filename=outputPlotNameCurrent, width = 30, height = 30, units = "cm")
###########################
###########################
###########################
