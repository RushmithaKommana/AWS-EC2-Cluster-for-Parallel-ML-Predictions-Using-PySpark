# Save the JDK version to be used in a variable
ARG OPENJDK_VERSION=8
# Get a base docker image based on JDK
FROM openjdk:${OPENJDK_VERSION}-jre-slim

# Configure spark version to be used
ARG SPARK_VERSION=3.0.0
ARG SPARK_EXTRAS=

# Set Label for container
LABEL org.opencontainers.image.title="Apache PySpark $SPARK_VERSION" \
      org.opencontainers.image.version=$SPARK_VERSION

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    bzip2 \
    wget \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Download and install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/miniconda3 && \
    rm /tmp/miniconda.sh

# Set up environment variables
ENV PATH="/opt/miniconda3/bin:${PATH}"
ENV PYSPARK_PYTHON="/opt/miniconda3/bin/python"

# Initialize conda and create a base environment
RUN /opt/miniconda3/bin/conda init bash && \
    . /root/.bashrc && \
    conda config --set auto_update_conda false && \
    conda config --set channel_priority disabled

# Install PySpark and dependencies
RUN conda install -y \
    -c conda-forge \
    python=3.8 \
    openjdk=${OPENJDK_VERSION} \
    pip && \
    pip install --no-cache \
    pyspark${SPARK_EXTRAS:+[$SPARK_EXTRAS]}==${SPARK_VERSION} \
    numpy && \
    conda clean -afy

# Set Working directory
ENV PROG_DIR /mlprog
ENV PROG_NAME wine_train.py
ENV TRAIN_NAME TrainingDataset.csv
ENV TEST_NAME ValidationDataset.csv

WORKDIR ${PROG_DIR}

# Copy project files
COPY ${PROG_NAME} .
COPY ${TRAIN_NAME} .
COPY ${TEST_NAME} .

# Set startup executable
ENTRYPOINT ["spark-submit", "wine_train.py"]
