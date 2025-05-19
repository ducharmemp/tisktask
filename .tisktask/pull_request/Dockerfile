FROM elixir:1.17

ADD . /tisktask
WORKDIR /tisktask
RUN mix deps.get && apt-get update -yqq && apt-get install -y netcat-openbsd
