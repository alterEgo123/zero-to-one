FROM python:3.9-slim-bullseye

COPY . .

RUN pip3 install flask

EXPOSE 5000

ENTRYPOINT flask --app hello run