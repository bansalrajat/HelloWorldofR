FROM registry-proxy.lbg.eu-gb.mybluemix.net/modelmaker/ds/rocker/packrat:3.5.0

RUN R -e 'install.packages(c("lintr"  ,"MASS" ,"nlme" ,"survival" ,"boot" ,"cluster" ,"foreign" ,"KernSmooth","rpart","class","nnet" ,"spatial" ,"mgcv" ,"covr" ,"cyclocomp" ,"roxygen2" ,"rcmdcheck" ,"rmarkdown" ))'