FROM nvidia/cuda

COPY md5-cracker md5-cracker
RUN cd md5-cracker && make

COPY run.sh run.sh
COPY hashes.txt hashes.txt

ENV XDCS_AGENT_ID=0
ENV XDCS_AGENT_COUNT=1

CMD ["./run.sh"]
