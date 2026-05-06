# IGSIGN Production Dockerfile for Fly.io
FROM ruby:3.4.3-slim AS base
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential git curl libpq-dev postgresql-client libvips42 \
    libreoffice libreoffice-writer fonts-liberation fonts-dejavu \
    nodejs npm && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment true && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3
COPY package.json yarn.lock* ./
RUN npm install 2>/dev/null || true
COPY . .
RUN SECRET_KEY_BASE=placeholder RAILS_ENV=production \
    DATABASE_URL=postgresql://x:x@localhost/x \
    bundle exec rails assets:precompile 2>/dev/null || echo "Assets skipped"
RUN mkdir -p tmp && curl -L -o tmp/model.onnx \
    "https://github.com/docusealco/fields-detection/releases/download/v2.0.0/model.onnx" \
    2>/dev/null || echo "ONNX skipped"
EXPOSE 3000
CMD ["/bin/sh","-c","bundle exec rails db:migrate && bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
