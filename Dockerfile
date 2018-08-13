FROM ruby:2.5.1

ARG APP_HOME=/home/app
ARG UID=1000
ARG GID=1000

RUN groupadd -r --gid ${GID} app \
 && useradd --system --create-home --home ${APP_HOME} --shell /sbin/nologin --no-log-init \
 --gid ${GID} --uid ${UID} app

MAINTAINER lbellet@heliostech.fr

WORKDIR $APP_HOME

COPY . /

RUN mkdir -p /opt/vendor/bundle \
 && chown -R app:app /opt/vendor \
 && su app -s /bin/bash -c "bundle install --path /opt/vendor/bundle"

RUN mkdir -p /opt/vendor/bundle && \
    bundle install --path /opt/vendor/bundle

ENTRYPOINT bundle exec /bin/peatio
