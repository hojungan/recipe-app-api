FROM python:3.9-alpine3.13
LABEL maintainer="hojung"

ENV PYTHONUNBUFFERED 1


# COPY FILE FROM LOCAL TO DOCKER IMAGE

# copy requirements.txt from local to /tmp/requirements.txt in docker image
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt

# /app is the directory containing the django app
COPY ./app /app

# working directory where the commands are going to run when running commands on docker image
WORKDIR /app

# expose port from container to machine when container is ran
EXPOSE 8000

ARG DEV=false

# runs a command on the alpine image used to build image
# running below commands in multiple RUN will create new image layer for every single command
# running the commands in single RUN command will keep the image lightweight

# python -m venv /py && \ --> create new python virtual environment
#   /py/bin/pip install --upgrade pip && \ --> upgrade pip inside virtual environment
#   /py/bin/pip install -r /tmp/requirements.txt && \ --> install dependencies using pip inside virtual environment
#   rm -rf /tmp && \ --> remove /tmp folder after dependency install to ensure no extra depencies exist on the image after it's created
#   adduser \ --> calls the ADD User command, which adds a new user inside the image. do not use root user. 
#     --dsiabled-password \
#     --no-create-home \
#     django-user
RUN python -m venv /py && \
  /py/bin/pip install --upgrade pip && \
  apk add --update --no-cache postgresql-client && \
  apk add --update --no-cache --virtual .tmp-build-deps \
  build-base postgresql-dev musl-dev && \
  /py/bin/pip install -r /tmp/requirements.txt && \
  if [ $DEV = "true" ]; \
  then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
  fi && \
  rm -rf /tmp && \
  apk del .tmp-build-deps && \
  adduser \
  --disabled-password \
  --no-create-home \
  django-user

# update the environment variable inside the image
ENV PATH="/py/bin:$PATH"

USER django-user