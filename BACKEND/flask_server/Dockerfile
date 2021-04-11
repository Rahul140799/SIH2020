FROM python

COPY ./requirements.txt  /app/requirements.txt

ENV PORT=5000
WORKDIR /app
RUN pip install --upgrade pip
RUN pip install -vvv --no-cache-dir -r requirements.txt
RUN pip install https://med7.s3.eu-west-2.amazonaws.com/en_core_med7_lg.tar.gz
COPY . /app
EXPOSE 5000

CMD ["python","app.py"]