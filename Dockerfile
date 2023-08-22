FROM julia:1.7.1-alpine

ENV GENSHIN_UID=000000000

RUN julia -e "using Pkg; Pkg.add([\"JSON\",\"DataFrames\",\"HTTP\"])"
RUN mkdir data data/characters data/ratingRules
COPY *.jl ./
CMD ["julia", "Eikonomia.jl"]