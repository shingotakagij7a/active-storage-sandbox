# syntax = docker/dockerfile:1

# Simpler single-stage Dockerfile for both development and production.
# Build (development): docker build -t app:dev --build-arg RAILS_ENV=development --build-arg BUNDLE_WITHOUT="" .
# Build (production):  docker build -t app:prod --build-arg RAILS_ENV=production --build-arg BUNDLE_WITHOUT="development:test" .

ARG RUBY_VERSION=3.4.2
FROM ruby:${RUBY_VERSION}-slim

ARG RAILS_ENV=production
ARG BUNDLE_WITHOUT="development:test"
ENV RAILS_ENV=${RAILS_ENV} \
        BUNDLE_WITHOUT=${BUNDLE_WITHOUT} \
        BUNDLE_PATH=/usr/local/bundle \
        BUNDLE_JOBS=4 \
        BUNDLE_RETRY=3

WORKDIR /rails

# Install required system packages (runtime + build tools). Optionally prune build tools later.
RUN apt-get update -qq && \
        apt-get install --no-install-recommends -y \
            build-essential \
            git \
            pkg-config \
            curl \
            libjemalloc2 \
            libvips \
            sqlite3 \
            libyaml-0-2 \
            libyaml-dev \
        && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install gems first (layer cache) – add platform for aarch64 if building on arm.
COPY Gemfile Gemfile.lock ./
RUN bundle lock --add-platform aarch64-linux || true && \
        bundle install && \
        bundle exec bootsnap precompile --gemfile

# App source
COPY . .

# Precompile bootsnap for app code (optional, skip in dev if desired)
RUN bundle exec bootsnap precompile app/ lib/ || echo "bootsnap precompile skipped"

# Assets only for production
RUN if [ "$RAILS_ENV" = "production" ]; then \
            echo "Precompiling assets..." && SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile; \
        else \
            echo "Skip assets:precompile (RAILS_ENV=$RAILS_ENV)"; \
        fi

# Add non-root user
RUN groupadd --system --gid 1000 rails && \
        useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
        mkdir -p log tmp/pids tmp/cache tmp/sockets storage && \
        chown -R rails:rails /rails
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["./bin/rails", "server"]
