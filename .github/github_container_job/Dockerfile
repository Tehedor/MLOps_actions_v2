# GitHub Container Registry (GHCR)
# Imagen ligera de Python 3.11 para MLOps 1
FROM python:3.11-slim

# Configuración de Python para mejor rendimiento
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Ruta al virtual environment (pre-construido en la imagen, FUERA de /workspace)
ENV MLOPS_VENV_PATH="/opt/.venv"
# ENV VIRTUAL_ENV=/opt/venv
# ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Instala herramientas del sistema + crea venv + instala deps (todo en una capa para optimizar)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    make \
    procps \
    util-linux \
    && rm -rf /var/lib/apt/lists/* \
    && python3.11 -m venv $MLOPS_VENV_PATH

# Copia requirements antes de instalar (para mejor caché en rebuilds)
COPY requirements.txt /tmp/

# Instala dependencias Python + limpia cachés y archivos innecesarios
RUN $MLOPS_VENV_PATH/bin/pip install --upgrade pip setuptools wheel && \
    $MLOPS_VENV_PATH/bin/pip install -r /tmp/requirements.txt && \
    find $MLOPS_VENV_PATH -type f -name "*.pyc" -delete && \
    find $MLOPS_VENV_PATH -type d -name "__pycache__" -delete && \
    find $MLOPS_VENV_PATH -type d -name "tests" -delete && \
    find $MLOPS_VENV_PATH -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null ; \
    rm -rf /tmp/requirements.txt /root/.cache/pip

WORKDIR /workspace

# El comando por defecto al arrancar el contenedor será bash
CMD ["/bin/bash"]

# docker build -f .mlops_tools/github_container_job/Dockerfile -t test-env .
# docker run -it --rm test-env /bin/bash