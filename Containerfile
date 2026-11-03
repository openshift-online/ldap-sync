# Multi-stage build: deps are installed in a Hummingbird builder, then copied into the
# distroless Red Hat Hardened Image (Project Hummingbird) runtime, which has no shell or
# package manager and runs as non-root UID 65532.
#
# Dependencies are installed with `pip --target` and run via `python3 -m` so nothing depends
# on console-script shebangs or the interpreter path. Both stages are Python 3.12 so wheels
# (e.g. PyYAML's) are ABI-compatible.

FROM registry.access.redhat.com/hi/python:3.12-builder AS builder
USER 0
WORKDIR /src
COPY . .
RUN python3 -m pip install --no-cache-dir --target=/app .

FROM registry.access.redhat.com/hi/python:3.12
WORKDIR /app
COPY --from=builder /app /app
ENV PYTHONPATH=/app \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
USER 65532
ENTRYPOINT ["python3", "-m", "ldap_sync"]
CMD ["--config", "/etc/sync/config.yaml"]
