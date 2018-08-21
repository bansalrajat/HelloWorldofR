FROM registry-proxy.lbg.eu-gb.mybluemix.net/modelmaker/ds/rocker/packrat:3.5.0 AS dependencies

RUN R -e 'install.packages("lintr" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("MASS" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("nlme" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("survival" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("boot" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("cluster" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("foreign" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("KernSmooth" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("rpart" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("class" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("nnet" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("spatial" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("mgcv" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("covr" , repos="http://cran.us.r-project.org")'
RUN R -e 'install.packages("cyclocomp" , repos="http://cran.us.r-project.org")'


FROM dependencies AS build

RUN R --default-packages=lintr -e 'lintr::lint_package()'
