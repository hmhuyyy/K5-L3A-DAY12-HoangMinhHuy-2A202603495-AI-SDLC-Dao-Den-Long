# Dockerfile — Runnable container environment for Dao Den Long v1.0.0 (Godot 4.7.2 headless/test/soak)
# Usage:
#   docker build -t dao-den-long:1.0.0 .
#   docker run --rm dao-den-long:1.0.0 bash tests/run_tests.sh
#   docker run --rm dao-den-long:1.0.0 godot --headless --path . --script res://src/soak.gd -- --seed 7 --nights 10 --out /tmp/soak.json
FROM ubuntu:24.04

ARG GODOT_VERSION=4.7.2-stable
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip python3 bash fontconfig libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" -o /tmp/godot.zip \
    && unzip -q /tmp/godot.zip -d /usr/local/bin/ \
    && mv "/usr/local/bin/Godot_v${GODOT_VERSION}_linux.x86_64" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm -f /tmp/godot.zip

ENV GODOT_BIN=/usr/local/bin/godot
WORKDIR /app
COPY . /app

CMD ["bash", "tests/run_tests.sh"]
