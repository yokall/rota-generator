# Rota Generator

## Quickstart

1. Create .env file, example:
    ```ini
    ROTA_NAMES=Alice,Bob,Charlie
    SMTP_HOST=smtp.gmail.com
    SMTP_PORT=587
    SMTP_USER=email@gmail.com
    SMTP_PASSWORD=xxx
    ```
1. Build the docker image `docker build -t rota-generator .`
1. Run the app `docker run --env-file .env rota-generator`