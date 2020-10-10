
#############################
### Plot Theme Aesthetics ###
#############################

load_in_plot_aesthetics <- function(x) {
  
  axisTextSize <<- 32
  lineSize <<- 2
  dotSize <<- 4
  voronoi_dot_size <<- 3
  density_plot_ymax <<- 0.3
  
  # If errorbars overlapp use position_dodge to shift them horizontally
  pd <<- position_dodge(0.2)
  
  homophony_polysemy_labeled_theme <<- function () { 
    theme(legend.position = c(0.4, 0.9), aspect.ratio=1,
          legend.text = element_text(size=axisTextSize,face="bold"),
          legend.title = element_text(size=axisTextSize,face="bold"), 
          axis.text=element_text(size=axisTextSize,face="bold"),
          axis.title.x = element_text(size=axisTextSize,face="bold"),
          axis.title.y = element_text(size=axisTextSize,face="bold"),
          panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),
          axis.line = element_line(colour = "black"))
  }
  
  homophony_polysemy_labelednoLegend_theme <<- function () { 
    theme(legend.position="none", aspect.ratio=1,
          axis.text=element_text(size=axisTextSize,face="bold"),
          axis.title.x = element_text(size=axisTextSize,face="bold"),
          axis.title.y = element_text(size=axisTextSize,face="bold"),
          panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),
          axis.line = element_line(colour = "black"))
  }
  
  homophony_polysemy_nolabel_theme <<- function () { 
    theme(legend.position="none", aspect.ratio=1,
          axis.text=element_text(size=axisTextSize,face="bold"),
          axis.text.y=element_text(size=axisTextSize,face="bold"),
          axis.title.x = element_text(size=axisTextSize,face="bold"),
          axis.title.y = element_text(color="White", size=axisTextSize,face="bold"),
          panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank(),
          axis.line = element_line(colour = "black"))
  }
  
  single_pane_theme <<- function () { 
    theme_minimal() %+replace% 
      theme(legend.position="none", aspect.ratio=1,
            legend.title = element_text(size=axisTextSize,face="bold"),
            legend.text=element_text(size=axisTextSize,face="bold"),
            plot.title = element_text(hjust = 0.5,size=axisTextSize,face="bold"),
            axis.text=element_text(size=axisTextSize,face="bold"),
            axis.text.y=element_text(size=axisTextSize,face="bold"),
            axis.title.x = element_text(size=axisTextSize,face="bold"),
            axis.title.y = element_text(size=axisTextSize,face="bold", angle = 90),
            axis.line = element_line(colour = "black"),
            panel.border = element_rect(colour = "black", fill=NA, size=1)
      )
  }
  
  sem_field_theme <<- function () { 
    single_pane_theme() %+replace% 
      theme(aspect.ratio=0.8,
            axis.title.x = element_blank(),
            axis.title.y = element_blank(),
            panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank()
      )
  }

}

#############################
#############################
#############################

frequire <- require
require <- function(...) suppressPackageStartupMessages(frequire(...))


LEN <- 7 # the max length in syllables 
dataclean <- function(data)
{
	data <- data[data$numsylls <= LEN,]
	data <- data[data$phonsuprise < Inf,]
	data$numwordsensesm1 <- data$numwordsenses - 1

	data
}

sylldataclean <- function(sylldata)
{
	sylldata <- sylldata[sylldata$numphones <= LEN,]
	sylldata <- sylldata[sylldata$phonsurprise < Inf,]
	sylldata$wordspersyllm1 <- sylldata$wordspersyll - 1

	sylldata
}

aggrdata_exact_numgroups <- function(aggrvar, cutvar, numgroups, groupsize=10, func=mean)
{
	goal = numgroups
	actual = 0
	while(actual < goal && numgroups/goal < 100)
	{
		agroed_data = aggregate(aggrvar, by=list(cut2(cutvar, g=numgroups, m=groupsize, levels.mean=T )), func)
		actual = length(agroed_data$x)
		# print(c(actual, numgroups))
		numgroups = numgroups + 10
	}
	agroed_data$indepvar = as.numeric(levels(agroed_data$Group.1))[agroed_data$Group.1]
	# agroed_data$indepvar = as.numeric(agroed_data$Group.1)

	agroed_data
}

compute_summary_fun <- function(x, num_var){
  num_var <- enquo(num_var)
  x %>%
    dplyr::summarize(avg = mean(!!num_var), n = n(), 
                     sd = sd(!!num_var), se = sd/sqrt(n))
}

compute_length_bin_fun <- function(x, num_var){
  ifelse(x[,num_var] >= 3 & x[,num_var] < 5, '3-4',
         ifelse(x[,num_var] >= 5 & x[,num_var] < 7, '5-6',
                ifelse(x[,num_var] >= 7 & x[,num_var] < 9, '7-8',
                       ifelse(x[,num_var] >= 9, '+9', 'NA'))))
}

# density plot helper function
bw <- function(b, x) { b/bw.nrd0(x) }


load_in_libraries <- function(x) {
  
  if(require("cowplot")){
    # print("cowplot is loaded correctly")
  } else {
    print("trying to install cowplot")
    install.packages("cowplot",dependencies=TRUE)
    if(require("cowplot")){
      print("cowplot installed and loaded")
    } else {
      stop("could not install cowplot")
    }
  }
  
  if(require("ggplot2")){
    # print("ggplot2 is loaded correctly")
  } else {
    print("trying to install ggplot2")
    install.packages("ggplot2",dependencies=TRUE)
    if(require("ggplot2")){
      print("ggplot2 installed and loaded")
    } else {
      stop("could not install ggplot2")
    }
  }
  theme_set(theme_cowplot())
  
  if(require("Hmisc")){
    # print("Hmisc is loaded correctly")
  } else {
    print("trying to install Hmisc")
    install.packages("Hmisc",dependencies=TRUE)
    if(require("Hmisc")){
      print("Hmisc installed and loaded")
    } else {
      stop("could not install Hmisc")
    }
  }
  
  if(require("scales")){
    # print("scales is loaded correctly")
  } else {
    print("trying to install scales")
    install.packages("scales",dependencies=TRUE)
    if(require("scales")){
      print("scales installed and loaded")
    } else {
      stop("could not install scales")
    }
  }
  
  if(require("reshape2")){
    # print("reshape2 is loaded correctly")
  } else {
    print("trying to install reshape2")
    install.packages("reshape2",dependencies=TRUE)
    if(require("reshape2")){
      print("reshape2 installed and loaded")
    } else {
      stop("could not install reshape2")
    }
  }
  
  if(require("tidyr")){
    # print("tidyr is loaded correctly")
  } else {
    print("trying to install tidyr")
    install.packages("tidyr",dependencies=TRUE)
    if(require("tidyr")){
      print("tidyr installed and loaded")
    } else {
      stop("could not install tidyr")
    }
  }
  
  if(require("dplyr")){
    # print("dplyr is loaded correctly")
  } else {
    print("trying to install dplyr")
    install.packages("dplyr",dependencies=TRUE)
    if(require("dplyr")){
      print("dplyr installed and loaded")
    } else {
      stop("could not install dplyr")
    }
  }
  
  if(require("plyr")){
    # print("plyr is loaded correctly")
  } else {
    print("trying to install plyr")
    install.packages("plyr",dependencies=TRUE)
    if(require("plyr")){
      print("plyr installed and loaded")
    } else {
      stop("could not install plyr")
    }
  }
  
  if(require("RColorBrewer")){
    # print("RColorBrewer is loaded correctly")
  } else {
    print("trying to install RColorBrewer")
    install.packages("RColorBrewer",dependencies=TRUE)
    if(require("RColorBrewer")){
      print("RColorBrewer installed and loaded")
    } else {
      stop("could not install RColorBrewer")
    }
  }
  
  if(require("lme4")){
    # print("lme4 is loaded correctly")
  } else {
    print("trying to install lme4")
    install.packages("lme4",dependencies=TRUE)
    if(require("lme4")){
      print("lme4 installed and loaded")
    } else {
      stop("could not install lme4")
    }
  }

  if(require("pracma")){
    # print("pracma is loaded correctly")
  } else {
    print("trying to install pracma")
    install.packages("pracma",dependencies=TRUE)
    if(require("pracma")){
      print("pracma installed and loaded")
    } else {
      stop("could not install pracma")
    }
  }
  
  print("load_in_libraries correctly")
}


load_in_voronoi <- function(x) {
  
  if(require("ggvoronoi")){
    # print("ggvoronoi is loaded correctly")
  } else {
    print("trying to install ggvoronoi")
    install.packages("ggvoronoi",dependencies=TRUE)
    if(require("ggvoronoi")){
      print("ggvoronoi installed and loaded")
    } else {
      stop("could not install ggvoronoi")
    }
  }
  
  if(require("ggforce")){
   #  print("ggforce is loaded correctly")
  } else {
    print("trying to install ggforce")
    install.packages("ggforce",dependencies=TRUE)
    if(require("ggforce")){
      print("ggforce installed and loaded")
    } else {
      stop("could not install ggforce")
    }
  }
  print("load_in_voronoi correctly")
}


load_in_limited <- function(x) {
  
  if(require("Hmisc")){
    # print("Hmisc is loaded correctly")
  } else {
    print("trying to install Hmisc")
    install.packages("Hmisc",dependencies=TRUE)
    if(require("Hmisc")){
      print("Hmisc installed and loaded")
    } else {
      stop("could not install Hmisc")
    }
  }
  
  if(require("scales")){
    # print("scales is loaded correctly")
  } else {
    print("trying to install scales")
    install.packages("scales",dependencies=TRUE)
    if(require("scales")){
      print("scales installed and loaded")
    } else {
      stop("could not install scales")
    }
  }
  
  if(require("reshape2")){
    # print("reshape2 is loaded correctly")
  } else {
    print("trying to install reshape2")
    install.packages("reshape2",dependencies=TRUE)
    if(require("reshape2")){
      print("reshape2 installed and loaded")
    } else {
      stop("could not install reshape2")
    }
  }
  
  if(require("tidyr")){
    # print("tidyr is loaded correctly")
  } else {
    print("trying to install tidyr")
    install.packages("tidyr",dependencies=TRUE)
    if(require("tidyr")){
      print("tidyr installed and loaded")
    } else {
      stop("could not install tidyr")
    }
  }
  
  if(require("dplyr")){
    # print("dplyr is loaded correctly")
  } else {
    print("trying to install dplyr")
    install.packages("dplyr",dependencies=TRUE)
    if(require("dplyr")){
      print("dplyr installed and loaded")
    } else {
      stop("could not install dplyr")
    }
  }
  
  if(require("plyr")){
    # print("plyr is loaded correctly")
  } else {
    print("trying to install plyr")
    install.packages("plyr",dependencies=TRUE)
    if(require("plyr")){
      print("plyr installed and loaded")
    } else {
      stop("could not install plyr")
    }
  }

  if(require("stringr")){
    # print("stringr is loaded correctly")
  } else {
    print("trying to install stringr")
    install.packages("stringr",dependencies=TRUE)
    if(require("stringr")){
      print("stringr installed and loaded")
    } else {
      stop("could not install stringr")
    }
  }
  print("load_in_limited correctly")
  
}
