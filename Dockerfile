FROM ubuntu:20.04

RUN set -x \
    && DEBIAN_FRONTEND=noninteractive  apt-get update \
    && DEBIAN_FRONTEND=noninteractive  apt-get install -y --no-install-recommends tzdata \
    && DEBIAN_FRONTEND=noninteractive  apt-get -y update \
    && :

RUN apt-get install -y build-essential python3.9 python3-pip
RUN pip3 -q install pip --upgrade
RUN pip install --no-cache notebook jupyterlab ipykernel
RUN apt-get install -y git gcc g++ python pkg-config libssl-dev libdbus-1-dev libglib2.0-dev libavahi-client-dev ninja-build python3-venv python3-dev python3-pip unzip libgirepository1.0-dev libcairo2-dev

# ENV TINI_VERSION v0.16.1
# ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
# RUN chmod +x /usr/bin/tini 
# ENTRYPOINT ["/usr/bin/tini", "--"]

ENV NB_USER jovyan
ENV NB_UID 1000
ENV HOME /home/${NB_USER}
RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

USER ${NB_USER}
WORKDIR ${HOME}
RUN mkdir devel
WORKDIR devel
RUN git clone --depth 1 https://github.com/project-chip/connectedhomeip.git
WORKDIR connectedhomeip
RUN ["/bin/bash", "-c", "source scripts/activate.sh"]
RUN ./scripts/build_python.sh --chip_detail_logging true
#RUN ["/bin/bash", "-c", "virtualenv ./out/python_env"]
#RUN ["/bin/bash", "-c", "source ./out/python_env/bin/activate"]
#RUN ["/bin/bash", "-c", "pip install ipykernel"]
RUN ["/bin/bash", "-c", "source ./out/python_env/bin/activate && pip install ipykernel"]

RUN scripts/examples/gn_build_example.sh examples/all-clusters-app/linux out/debug 'chip_config_network_layer_ble=false'

USER root
WORKDIR ${HOME}/devel/connectedhomeip
RUN ["/bin/bash", "-c", "source ./out/python_env/bin/activate && python -m ipykernel install --name=matter-env"]
USER ${NB_USER}

#WORKDIR ../../

#ENV HOME=/tmp


#COPY . ${HOME}
#USER root
#RUN chown -R ${NB_UID} ${HOME}
#USER ${NB_USER}
