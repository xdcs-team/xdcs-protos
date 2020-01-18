FROM python:3.7

COPY factor.py .
COPY numbers.txt .
CMD python factor.py $XDCS_AGENT_ID $XDCS_AGENT_COUNT \
    numbers.txt results.txt
