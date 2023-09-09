FROM julia:rc-alpine3.18

ENV GENSHIN_UID=000000000
ENV EIKONOMIYA_RUN_CRON=1
EXPOSE 8080

RUN apk update && apk add curl openrc
RUN julia -e "using Pkg; Pkg.add([\"JSON\",\"DataFrames\",\"HTTP\"])"
# RUN mkdir /data/characters /data/ratingRules
COPY *.jl ./
COPY auto-refresh /etc/cron.d/auto-update
RUN chmod 0644 /etc/cron.d/auto-update
RUN crontab /etc/cron.d/auto-update
CMD ["julia", "Eikonomia.jl"]