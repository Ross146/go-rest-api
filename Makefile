MIGRATIONS_DIR=${PWD}/migrations/sql

mod-tidy:
	pushd ./src/server/api && go mod tidy && popd
mod-cd:
	cd ./src/server/api && go mod download
mod-upgrade:
	pushd ./src/server/api && go get -u && go mod tidy && popd
mod-install:
	@read -p "Enter the dependency to install: " dependency; \
	pushd ./src/server/api > /dev/null && \
	go get $$dependency && \
	popd > /dev/null

up: build
	DOCKERFILE=Dockerfile docker-compose -f docker-compose.yaml up -d
down:
	DOCKERFILE=Dockerfile docker-compose -f docker-compose.yaml down
build:
	DOCKERFILE=Dockerfile docker-compose -f docker-compose.yaml build
clean:
	DOCKERFILE=Dockerfile docker-compose -f docker-compose.yaml down -v
logs:
	DOCKERFILE=Dockerfile docker-compose -f docker-compose.yaml logs --tail=100 -f
uplogs: up logs
# lint-local:
# 	golangci-lint --config=./src/server/api/golangci-lint/.golangci.local.yaml run ./src/server/api/...
lint-local:
	docker run --rm -t -v $(shell pwd)/src/server/api:/app -w /app golangci/golangci-lint:v1.58.1 golangci-lint --config=./golangci-lint/.golangci.local.yaml run --color=always ./... -v

pprof-tool:
	go tool pprof -http=:8022 $(url)

pprof-prod:
	open https://api.justdone.ai/debug/pprof

pprof-stage:
	open https://stage-api.justdone.ai/debug/pprof

pprof-stage2:
	open https://stage2-api.justdone.ai/debug/pprof

update-dependencies:
	pushd src/server/api && go get -u ./... && go mod tidy && popd

up-dev: build-dev
	DOCKERFILE=Dockerfile.dev docker-compose -f docker-compose.yaml up -d
down-dev:
	DOCKERFILE=Dockerfile.dev docker-compose -f docker-compose.yaml down
build-dev:
	DOCKERFILE=Dockerfile.dev docker-compose -f docker-compose.yaml build
logs-dev:
	DOCKERFILE=Dockerfile.dev docker-compose -f docker-compose.yaml logs --tail=100 -f

swagger.gen:
	swag init --parseDependency  --parseInternal -d ./src/server/api -g ./main.go -o ./swagger
	mv ./swagger/swagger.json ./swagger/swagger.json.tmpl
	# get arguments

swagger.template:
	./scripts/swagger.sh ${JUSTDONE_BASE_URL} ${SWAGGER_FILE_URL}


swagger.start:
	sed -i -e 's/{host_api}/localhost:8081/g' ./swagger/swagger.yaml && rm ./swagger/swagger.yaml-e
	docker run --platform=linux/amd64 -d -p 8090:8080 --name justdone-ai-swagger \
		-v ${CURDIR}/swagger/swagger.yaml:/usr/share/nginx/html/swagger.yaml \
		-e URLS="[{url: \"swagger.yaml\", name: \"justdone-ai\"}]" \
		swaggerapi/swagger-ui

swagger.stop:
	docker stop justdone-ai-swagger && docker rm justdone-ai-swagger

swagger.restart: swagger.stop swagger.start

migrate-create: ## Create migration file with name
	docker run -v $(MIGRATIONS_DIR):/migrations migrate/migrate create -ext sql -dir /migrations -seq $(name)

lint:
	golangci-lint run ./src/server/api/...

cloudwatch.stage:
	./scripts/cloudwatch_logs.sh stage

cloudwatch.prod:
	./scripts/cloudwatch_logs.sh prod

migrations_folder = /migrations/sql

.PHONY: rename-migration
rename-migration:
ifndef name
	$(error name is undefined)
endif
	@for file in $$(ls $(migrations_folder)/*property.up.sql); do \
		mv $$file $$(echo $$file | sed 's/property/$(name)/'); \
	done
	@for file in $$(ls $(migrations_folder)/*property.down.sql); do \
		mv $$file $$(echo $$file | sed 's/property/$(name)/'); \
	done

