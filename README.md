# GKE + Jenkins Blue/Green — Node + Python


This repo deploys a Node frontend and a Python API to **GKE** and sets up **Jenkins** to perform **blue/green** releases of the frontend.


## Prereqs
- GKE cluster ready and kubectl context pointing to it.
- Docker images pushed to Docker Hub:
- `pratha97/nod