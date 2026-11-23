# ChainForge on Railway. Upstream publishes no official versioned image, so this
# installs the released ChainForge wheel from PyPI (hash-locked in
# requirements.txt) on a Python image pinned by version and digest, plus a pinned
# Caddy binary that puts a password in front of the app.
# Upstream: https://github.com/ianarawjo/ChainForge (PyPI chainforge 0.3.7.8)
# Update: regenerate requirements.txt for the new version, add a CHANGELOG.md
# entry, merge to main.
FROM caddy:2.11.9@sha256:4851e54a46b206517c574821bb5cc67f170d2156041e9fbc4c9193b45e84a75b AS caddy

FROM python:3.12.16-slim@sha256:5e2bdb1b0d542d5039cffb8181c65930093949194a65c365dfb1b0fe13a4fa5b

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

COPY requirements.txt /tmp/requirements.txt
RUN pip install --require-hashes --only-binary=:all: -r /tmp/requirements.txt \
 && rm /tmp/requirements.txt \
 && useradd -m -u 1000 chainforge \
 && mkdir -p /data/chainforge \
 && chown -R 1000:1000 /data

COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY --chmod=0644 Caddyfile /etc/chainforge-railway/Caddyfile
COPY --chmod=0755 railway-start.sh /usr/local/bin/railway-start.sh
RUN chmod 0755 /etc/chainforge-railway \
 && caddy version \
 && PORT=8080 CF_INTERNAL_PORT=8001 CF_USERNAME=check CF_PASSWORD_HASH="$(caddy hash-password -p build-check-only)" \
      caddy validate --config /etc/chainforge-railway/Caddyfile --adapter caddyfile \
 && chainforge --help >/dev/null && pip show chainforge | head -2

ENV PORT=8080 \
    DATA_DIR=/data

# No VOLUME here: Railway rejects it. The template attaches a Railway volume at /data.
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
