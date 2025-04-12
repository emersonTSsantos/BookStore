# Etapa base com Python
FROM python:3.13.3-slim AS python-base

# Variáveis de ambiente
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

ENV PATH="${POETRY_HOME}/bin:${VENV_PATH}/bin:${PATH}"

# Instala dependências do sistema
RUN apt-get update && apt-get install --no-install-recommends -y \
    curl build-essential libpq-dev gcc && \
    rm -rf /var/lib/apt/lists/*

# Instala o Poetry (última versão estável)
RUN curl -sSL https://install.python-poetry.org | python3 -

# Cria diretório do projeto e define como diretório de trabalho
WORKDIR ${PYSETUP_PATH}

# Copia os arquivos de dependência para instalar em cache
COPY pyproject.toml poetry.lock ./

# Instala dependências do projeto (sem dev)
RUN poetry install --no-root --only main

# Etapa final - ambiente de produção
FROM python:3.13.3-slim

ENV PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv" \
    PATH="/opt/pysetup/.venv/bin:$PATH"

# Instala dependências mínimas do sistema
RUN apt-get update && apt-get install --no-install-recommends -y \
    libpq-dev gcc && \
    rm -rf /var/lib/apt/lists/*

# Copia os arquivos da etapa anterior (ambiente Python com dependências)
COPY --from=python-base ${PYSETUP_PATH} ${PYSETUP_PATH}

# Define diretório de trabalho do app
WORKDIR /app

# Copia o restante do código da aplicação
COPY . .

# Expõe a porta padrão do Django
EXPOSE 8000

# Comando padrão para rodar o Django
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
