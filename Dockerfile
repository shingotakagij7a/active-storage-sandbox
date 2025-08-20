# syntax = docker/dockerfile:1

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t my-app .
# docker run -d -p 80:80 -p 443:443 --name my-app -e RAILS_MASTER_KEY=<value from config/master.key> my-app

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.2
ARG RAILS_ENV=production
ARG BUNDLE_WITHOUT="development:test"
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
        apt-get install --no-install-recommends -y \
            curl \
            libjemalloc2 \
            libvips \
            sqlite3 \
            libyaml-0-2 \
        && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Set environment (RAILS_ENV can be overridden at build time)
ENV RAILS_ENV="${RAILS_ENV}" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="${BUNDLE_WITHOUT}"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
        apt-get install --no-install-recommends -y \
            build-essential \
            git \
            pkg-config \
            libyaml-dev \
        && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle lock --add-platform aarch64-linux && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
## NOTE: Earlier we added the aarch64-linux platform before bundle install, but the full COPY above overwrites Gemfile.lock.
## Re-add the platform (no dependency changes) to satisfy subsequent bootsnap precompile.
RUN bundle lock --add-platform aarch64-linux || true

## (Re)run a no-op bundle install only if needed (will be fast if unchanged)
RUN bundle install --local || bundle install

## Now precompile application bootsnap cache
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets only for production (dummy key for credentials-less build)
RUN if [ "$RAILS_ENV" = "production" ]; then \
            SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile; \
        else \
            echo "Skip assets:precompile for $RAILS_ENV"; \
        fi




# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]
