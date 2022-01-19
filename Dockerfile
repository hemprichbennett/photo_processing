FROM rocker/rstudio

ENV TZ=Europe/Moscow \
    DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt upgrade -yq
RUN apt-get -yq install git libimage-exiftool-perl


RUN Rscript -e 'install.packages(c("exiftoolr", "lubridate", "magrittr", "dplyr"))'

