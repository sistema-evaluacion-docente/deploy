run:
	podman-compose up -d

build:
	podman-compose build

down:
	podman-compose down

pull:
	git pull origin main

deploy:
	git pull origin main
	podman-compose down
	podman-compose pull
	podman-compose up -d
	podman image prune -f