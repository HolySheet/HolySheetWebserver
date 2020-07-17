![Docker Build](https://github.com/HolySheet/HolySheetWebserver/workflows/Docker%20Build/badge.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/rubbaboy/testback)
<a href="https://hub.docker.com/repository/docker/rubbaboy/hs"><img src="https://byob.yarr.is/HolySheet/HolySheet/hs" alt="HS master docker"/></a>
<a href="https://hub.docker.com/repository/docker/rubbaboy/testback"><img src="https://byob.yarr.is/HolySheet/HolySheetWebserver/testback" alt="Testback master docker"/></a>

The webserver backend for HolySheet. This is in charge of essentially relaying information to the core program via gPRC, allowing for things like rate limits and potentially restarting of the backend core without disruption of the connections. Later on, this will be containerized via Kubernetes to allow for a saleable approach.
