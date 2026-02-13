.PHONY: test test-coverage coverage clean help

help:
	@echo "Available targets:"
	@echo "  make test          - Run tests with coverage and generate report"
	@echo "  make test-coverage - Run tests with coverage"
	@echo "  make coverage      - Generate coverage report"
	@echo "  make clean         - Remove coverage data"

test: test-coverage coverage

test-coverage:
	yath test t/ --cover=-coverage,statement,branch,condition,path,subroutine,time,-ignore,.t$

coverage:
	cover -report=html_basic

clean:
	rm -rf cover_db/
