FROM elixir:1.19

ADD . /tisktask
WORKDIR /tisktask
RUN mix deps.get && mix compile && apt-get update -yqq && apt-get install -y openssl netcat-openbsd redis postgresql-client
