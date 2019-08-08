.PHONY: build
build:
	docker build -t job-wq-2 -f Dockerfile .

.PHONY: upload
upload:
	docker tag job-wq-2 192.168.0.210:5000/job-wq-2
	docker push 192.168.0.210:5000/job-wq-2

.PHONY: run
run:
	docker run -d --rm --name job-wq-2 job-wq-2 || :

.PHONY: exec
exec:
	docker exec -it job-wq-2 /bin/bash

.PHONY: stop
stop:
	docker stop job-wq-2 || :

.PHONY: logs
logs:
	docker logs -f job-wq-2 || :
