# Rota Generator

## Quickstart

1. Create .env file, example:
    ```ini
    FORCE=1
    ROTA_NAMES=Alice,Bob,Charlie
    SMTP_HOST=smtp.gmail.com
    SMTP_PORT=587
    SMTP_USER=email@gmail.com
    SMTP_PASSWORD=xxx
    ```
1. Build the docker image `docker build -t rota-generator .`
1. Run the app `docker run --env-file .env rota-generator`

## FORCE Environment Variable

For testing you will need to set the environment variable `FORCE` to true as the app will only run of Fridays be default.  This is for the scheduled cloud run that runs every 3rd Friday of the month by running between the 15th and 21st of the month but the app will only actually run on the Friday.

## GCS (Google Cloud Services) Persistence

1. setup a project and storage bucket:
    - Create a project in GCS
    - Install gcloud cli
    - Enable services
        - `gcloud services enable run.googleapis.com storage.googleapis.com cloudscheduler.googleapis.com secretmanager.googleapis.com iam.googleapis.com`
    - Create a bucket for storage
        - `gcloud storage buckets create gs://$BUCKET_NAME --location=europe-west1`
    - Create service accounts
        - `gcloud iam service-accounts create rota-runner-sa --display-name="Rota Cloud Run runtime SA"`
        - `gcloud iam service-accounts create rota-scheduler-sa --display-name="Rota Cloud Scheduler invoker SA"`
        - `gcloud projects add-iam-policy-binding $(gcloud config get-value project) --member="serviceAccount:rota-runner-sa@$(gcloud config get-value project).iam.gserviceaccount.com" --role="roles/storage.objectAdmin"`
    - Create a service account key for authentication
        - `gcloud iam service-accounts keys create ~/rota-runner-key.json --iam-account=rota-runner-sa@$(gcloud config get-value project).iam.gserviceaccount.com`

1. Add the following env vars to `.env`
    ```ini
    PERSISTENCE_PROVIDER=gcs
    PERSISTENCE_GCS_BUCKET=$BUCKET_NAME
    ```

1. Build and run the docker container
    ```
    docker build -t rota-generator .

    docker run --env-file .env --mount type=bind,source=/path/rota-runner-key.json,target=/secrets/rota-runner-key.json,readonly -e GOOGLE_APPLICATION_CREDENTIALS=/secrets/rota-runner-key.json rota-generator
    ```

## Pushing Docker Image to Google Cloud

```
docker build -t europe-west1-docker.pkg.dev/rota-generator-477821/rota-generator-repo/rota-generator:latest .

docker push europe-west1-docker.pkg.dev/rota-generator-477821/rota-generator-repo/rota-generator:latest
```