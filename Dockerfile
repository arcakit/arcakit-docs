# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t arcakit-docs .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name arcakit-docs arcakit-docs

ARG RUBY_VERSION=4.0.1
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips libssl-dev && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment variables and enable jemalloc for reduced memory usage and latency.
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock .ruby-version ./

RUN --mount=type=cache,id=arcakit-docs-bundle-${RUBY_VERSION},sharing=locked,target=/permabundle \
    gem install bundler && \
    BUNDLE_PATH=/permabundle bundle install && \
    cp -a /permabundle/. "$BUNDLE_PATH"/ && \
    bundle clean --force && \
    rm -rf "$BUNDLE_PATH"/ruby/*/bundler/gems/*/.git && \
    find "$BUNDLE_PATH" -type f \( -name '*.gem' -o -iname '*.a' -o -iname '*.o' -o -iname '*.h' -o -iname '*.c' -o -iname '*.hpp' -o -iname '*.cpp' \) -delete

# Copy application code
COPY . .

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Image metadata
ARG OCI_DESCRIPTION
LABEL org.opencontainers.image.description="${OCI_DESCRIPTION}"
ARG OCI_SOURCE
LABEL org.opencontainers.image.source="${OCI_SOURCE}"

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

# Copy built artifacts: gems, application
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
