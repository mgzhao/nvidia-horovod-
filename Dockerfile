FROM nvcr.io/nvidia/tensorflow:19.06-py3

# Python 2.7 or 3.5 is supported by Ubuntu Xenial out of the box
ARG python=3.5
ENV PYTHON_VERSION=${python}

RUN apt-get update && apt-get install -y --no-install-recommends \
    net-tools

# Configure OpenMPI to run good defaults:
#   --bind-to none --map-by slot --mca btl_tcp_if_exclude lo,docker0
RUN echo "hwloc_base_binding_policy = none" >> /usr/local/mpi/etc/openmpi-mca-params.conf && \
    echo "rmaps_base_mapping_policy = slot" >> /usr/local/mpi/etc/openmpi-mca-params.conf && \
    echo "btl_tcp_if_exclude = lo,docker0,docker1,cni,veth,flannel" >> /usr/local/mpi/etc/openmpi-mca-params.conf

# Comment plm_rsh_agent in openmpi-mca-params.conf
RUN cat /usr/local/mpi/etc/openmpi-mca-params.conf | grep -v plm_rsh_agent > /usr/local/mpi/etc/openmpi-mca-params.conf.new && \
    echo "# plm_rsh_agent = /usr/local/mpi/bin/rsh_warn.sh" >> /usr/local/mpi/etc/openmpi-mca-params.conf.new && \
	mv /usr/local/mpi/etc/openmpi-mca-params.conf.new /usr/local/mpi/etc/openmpi-mca-params.conf
	
# Set default NCCL parameters
RUN echo NCCL_DEBUG=INFO >> /etc/nccl.conf && \
    echo NCCL_SOCKET_IFNAME=^docker0 >> /etc/nccl.conf

# Install OpenSSH for MPI to communicate between containers
RUN apt-get install -y --no-install-recommends openssh-client openssh-server && \
    mkdir -p /var/run/sshd

# Allow OpenSSH to talk to containers without asking for confirmation
RUN cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new && \
    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new && \
    mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config && \
	mkdir -p /root/.ssh

WORKDIR "/workspace"
COPY id_rsa /root/.ssh/
COPY authorized_keys /root/.ssh/
