.PHONY: build
build:
	docker build -t job-wq -f Dockerfile .

.PHONY: upload
upload:
	docker tag job-wq 192.168.0.210:5000/job-wq
	docker push 192.168.0.210:5000/job-wq

.PHONY: run
run:
	docker run -d --rm --name job-wq job-wq || :

.PHONY: exec
exec:
	docker exec -it job-wq /bin/bash

.PHONY: stop
stop:
	docker stop job-wq || :

.PHONY: logs
logs:
	docker logs -f job-wq || :
