.PHONY: test test-coverage coverage clean help run deploy

help:
	@echo "Available targets:"
	@echo "  make test          - Run tests with coverage and generate report"
	@echo "  make test-coverage - Run tests with coverage"
	@echo "  make coverage      - Generate coverage report"
	@echo "  make clean         - Remove coverage data"
	@echo "  make run           - Run generate_rota.pl (loads .env if present)"
	@echo "  make deploy        - Build and push Docker image"

test: test-coverage coverage

test-coverage:
	rm -rf data/
	yath test t/ --cover=-silent,1,-coverage,statement,branch,condition,subroutine,+ignore,^t/

coverage:
	cover -report=html_basic

clean:
	rm -rf cover_db/

run:
	bash -c 'set -a && . .env && set +a && perl bin/generate_rota.pl'

deploy:
	docker build -t europe-west1-docker.pkg.dev/rota-generator-477821/rota-generator-repo/rota-generator:latest .
	docker push europe-west1-docker.pkg.dev/rota-generator-477821/rota-generator-repo/rota-generator:latest
