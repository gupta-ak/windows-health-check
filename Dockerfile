ARG VERSION=latest

FROM microsoft/nanoserver:$VERSION

COPY mesos-tcp-connect.exe msvcp140.dll vcruntime140.dll C:/Windows/System32/