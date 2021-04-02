FROM docker:20.10

LABEL maintainer="Kaustav Banerjee <kaustav_b2006@yahoo.co.in>"

COPY ./install-plugin.sh .

RUN chmod +x ./install-plugin.sh