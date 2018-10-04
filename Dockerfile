FROM bitwalker/alpine-elixir:1.7.3 AS builder

WORKDIR /opt/app

ARG REPLACE_OS_VARS=true
ARG MIX_ENV=prod
ARG RELEASE_VERSION=0.0.1

RUN mix local.rebar --force && \
  mix local.hex --force

ADD . .

RUN mix do deps.get, deps.compile, compile

RUN mkdir -p /opt/built && \
  mix release --verbose && \
  cp /opt/app/_build/${MIX_ENV}/rel/ripple/releases/${RELEASE_VERSION}/ripple.tar.gz /opt/built && \
  cd /opt/built && \
  tar -xzf ripple.tar.gz && \
  rm ripple.tar.gz

FROM bitwalker/alpine-elixir:1.7.3

WORKDIR /opt/app

COPY --from=builder /opt/built .

CMD ["/opt/app/bin/ripple", "foreground"]
