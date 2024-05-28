ARG LAMBDA_IMAGE="amazon/aws-lambda-provided:al2"
ARG RIE_ARCH="amd64"

FROM --platform=$TARGETPLATFORM condaforge/miniforge3:latest as condasetup
LABEL MAINTAINER="Howard Butler <howard@hobu.co>"

ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT
RUN printf "I'm building for TARGETPLATFORM=${TARGETPLATFORM}" \
    && printf ", TARGETARCH=${TARGETARCH}" \
    && printf ", TARGETVARIANT=${TARGETVARIANT} \n" \
    && printf "With uname -s : " && uname -s \
    && printf "and  uname -m : " && uname -mm

ENV CONDA_ENV_NAME "pdal"
ENV CONDAENV "/opt/conda/envs/${CONDA_ENV_NAME}"


# Create the environment:
COPY build-environment.yml .
RUN conda env create -f build-environment.yml
RUN mamba update --all -y

COPY run-environment.yml .
RUN conda env create -f run-environment.yml


SHELL ["conda", "run", "-n", "build", "/bin/bash", "-c"]
RUN conda-pack -n ${CONDA_ENV_NAME} --dest-prefix=/var/task -o /tmp/env.tar && \
     mkdir /venv && cd /venv && tar xf /tmp/env.tar  && \
     rm /tmp/env.tar


FROM --platform=$TARGETPLATFORM ${LAMBDA_IMAGE:?} as al2

ARG RIE_ARCH
ARG LAMBDA_IMAGE
ARG TARGETPLATFORM
ARG TARGETARCH
ENV TARGETPLATFORM=${TARGETPLATFORM:-linux/amd64}
ENV TARGETARCH=${TARGETARCH:-amd64}

ENV CONDAENV "/var/task"
ENV CONDA_PREFIX "/var/task"
ENV TARGETPLATFORM "${TARGETPLATFORM}"
COPY --from=condasetup /venv ${CONDAENV}



ENV PROJ_LIB ${CONDAENV}/share/proj
ENV PROJ_NETWORK=TRUE
ENV PATH $PATH:${CONDAENV}/bin
ENV LD_LIBRARY_PATH=${CONDAENV}/lib

RUN /var/task/bin/python -m pip install awslambdaric==2.0.11
ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-${RIE_ARCH} /usr/bin/aws-lambda-rie

RUN chmod +x /usr/bin/aws-lambda-rie


WORKDIR /var/task
COPY python-entry.sh ./
COPY pdal_handler.py ./
COPY root-bashrc /root/.bashrc
ENTRYPOINT [ "/var/task/python-entry.sh" ]
CMD ["pdal_handler.handler"]
