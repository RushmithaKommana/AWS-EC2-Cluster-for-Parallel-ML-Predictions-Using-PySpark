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

# Since we are using miniconda3, setting up environment path beforehand
ENV PATH="/opt/miniconda3/bin:${PATH}"
ENV PYSPARK_PYTHON="/opt/miniconda3/bin/python"

# Install dependencies for our docker image
RUN set -ex && \
    apt-get update && \
    apt-get install -y curl bzip2 wget --no-install-recommends && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -f -p "/opt/miniconda3" && \
    rm /tmp/miniconda.sh && \
    . /opt/miniconda3/etc/profile.d/conda.sh && \
    conda activate base && \
    conda config --set auto_update_conda false && \
    conda config --set channel_priority disabled && \
    conda update -n base conda -y && \
    conda install -y pip && \
    pip install --no-cache pyspark${SPARK_EXTRAS:+[$SPARK_EXTRAS]}==${SPARK_VERSION} numpy && \
    conda clean -afy && \
    apt-get remove -y curl bzip2 wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Working env as /mlprog
ENV PROG_DIR /mlprog
ENV PROG_NAME wine_train.py
ENV TRAIN_NAME TrainingDataset.csv
ENV TEST_NAME ValidationDataset.csv

# Set Workdir as set in env variable PROG_DIR
WORKDIR ${PROG_DIR}

# Copy python files, and datasets to work directory
COPY ${PROG_NAME} .
COPY ${TRAIN_NAME} .
COPY ${TEST_NAME} .

# Set startup executable of docker as spark submit
ENTRYPOINT ["spark-submit", "wine_train.py"]
