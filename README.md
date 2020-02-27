![Docker Build](https://github.com/HolySheetOrg/HolySheetWebserver/workflows/Docker%20Build/badge.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/rubbaboy/testback)
<a href="https://hub.docker.com/repository/docker/rubbaboy/hs"><img src="https://img.shields.io/endpoint?url=https://holysheet.net/shields/holysheet/web-dev.json" alt="HS web-dev docker"/></a>
<a href="https://hub.docker.com/repository/docker/rubbaboy/testback"><img src="https://img.shields.io/endpoint?url=https://holysheet.net/shields/holysheetwebserver/master.json" alt="testback master docker"/></a>

The webserver backend for HolySheet. This is in charge of essentially relaying information to the core program via gPRC, allowing for things like rate limits and potentially restarting of the backend core without disruption of the connections. Later on, this will be containerized via Kubernetes to allow for a saleable approach.
