FROM docker:20.10

COPY ./install-plugin.sh .

RUN chmod +x ./install-plugin.sh