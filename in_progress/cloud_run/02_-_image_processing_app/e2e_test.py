# Copyright 2020 Google, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This tests the Pub/Sub image processing sample

import os
import subprocess
import time
import uuid

from google.api_core.exceptions import NotFound
from google.cloud import pubsub_v1
from google.cloud import storage
from google.cloud.storage import Blob, notification

import pytest


SUFFIX = uuid.uuid4().hex[0:6]
PROJECT = os.environ["GOOGLE_CLOUD_PROJECT"]
IMAGE_NAME = f"gcr.io/{PROJECT}/image-proc-{SUFFIX}"
CLOUD_RUN_SERVICE = f"image-proc-{SUFFIX}"
INPUT_BUCKET = f"image-proc-input-{SUFFIX}"
OUTPUT_BUCKET = f"image-proc-output-{SUFFIX}"
TOPIC = f"image_proc_{SUFFIX}"


@pytest.fixture
def container_image():
    # Build container image for Cloud Run deployment
    subprocess.check_call(
        [
            "gcloud",
            "builds",
            "submit",
            "--tag",
            IMAGE_NAME,
            "--project",
            PROJECT,
            "--quiet",
        ]
    )
    yield IMAGE_NAME

    # Delete container image
    subprocess.check_call(
        [
            "gcloud",
            "container",
            "images",
            "delete",
            IMAGE_NAME,
            "--quiet",
            "--project",
            PROJECT,
        ]
    )


@pytest.fixture
def deployed_service(container_image, output_bucket):
    # Deploy image to Cloud Run

    subprocess.check_call(
        [
            "gcloud",
            "run",
            "deploy",
            CLOUD_RUN_SERVICE,
            "--image",
            container_image,
            "--region=us-central1",
            "--project",
            PROJECT,
            "--platform=managed",
            "--set-env-vars",
            f"BLURRED_BUCKET_NAME={output_bucket.name}",
            "--no-allow-unauthenticated",
        ]
    )

    yield CLOUD_RUN_SERVICE

    subprocess.check_call(
        [
            "gcloud",
            "run",
            "services",
            "delete",
            CLOUD_RUN_SERVICE,
            "--platform=managed",
            "--region=us-central1",
            "--quiet",
            "--async",
            "--project",
            PROJECT,
        ]
    )


@pytest.fixture
def service_url(deployed_service):
    # Get the URL for the cloud run service
    service_url = subprocess.run(
        [
            "gcloud",
            "run",
            "--project",
            PROJECT,
            "services",
            "describe",
            deployed_service,
            "--platform=managed",
            "--region=us-central1",
            "--format=value(status.url)",
        ],
        stdout=subprocess.PIPE,
        check=True,
    ).stdout.strip()

    yield service_url.decode()


@pytest.fixture()
def pubsub_topic():
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(PROJECT, TOPIC)
    publisher.create_topic(request={"name": topic_path})
    yield TOPIC
    try:
        publisher.delete_topic(request={"topic": topic_path})
    except NotFound:
        print("Topic not found, it was either never created or was already deleted.")


@pytest.fixture(autouse=True)
def pubsub_subscription(pubsub_topic, service_url):
    # Create pubsub push subscription to Cloud Run Service
    # Attach service account with Cloud Run Invoker role
    # See tutorial for details on setting up service-account:
    # https://cloud.google.com/run/docs/tutorials/pubsub
    publisher = pubsub_v1.PublisherClient()
    subscriber = pubsub_v1.SubscriberClient()
    subscription_id = f"{pubsub_topic}_sub"
    topic_path = publisher.topic_path(PROJECT, pubsub_topic)
    subscription_path = subscriber.subscription_path(PROJECT, subscription_id)
    push_config = pubsub_v1.types.PushConfig(
        push_endpoint=service_url,
        oidc_token=pubsub_v1.types.PushConfig.OidcToken(
            service_account_email=f"cloud-run-invoker@{PROJECT}.iam.gserviceaccount.com"
        ),
    )

    # wrapping in 'with' block automatically calls close on gRPC channel
    with subscriber:
        subscriber.create_subscription(
            request={
                "name": subscription_path,
                "topic": topic_path,
                "push_config": push_config,
            }
        )
    yield
    subscriber = pubsub_v1.SubscriberClient()

    # delete subscription
    with subscriber:
        try:
            subscriber.delete_subscription(request={"subscription": subscription_path})
        except NotFound:
            print(
                "Unable to delete - subscription either never created or already deleted."
            )


@pytest.fixture()
def input_bucket(pubsub_topic):
    # Create GCS Bucket
    storage_client = storage.Client()
    storage_client.create_bucket(INPUT_BUCKET)

    # Get input bucket
    input_bucket = storage_client.get_bucket(INPUT_BUCKET)

    # Create pub/sub notification on input_bucket
    notification.BucketNotification(
        input_bucket,
        topic_name=pubsub_topic,
        topic_project=PROJECT,
        payload_format="JSON_API_V1",
    ).create()

    yield input_bucket

    # Delete GCS bucket
    input_bucket.delete(force=True)


@pytest.fixture()
def output_bucket(pubsub_topic):
    # Create GCS Bucket
    storage_client = storage.Client()
    storage_client.create_bucket(OUTPUT_BUCKET)

    # Get output bucket
    output_bucket = storage_client.get_bucket(OUTPUT_BUCKET)

    yield output_bucket

    # Delete GCS bucket
    output_bucket.delete(force=True)


def test_end_to_end(input_bucket, output_bucket):
    # Upload image to the input bucket

    blob = Blob("zombie.jpg", input_bucket)
    blob.upload_from_filename("test-images/zombie.jpg", content_type="image/jpeg")

    # Wait for image processing to complete
    time.sleep(30)

    for x in range(10):
        # Check for blurred image in output bucket
        output_blobs = list(output_bucket.list_blobs())
        if len(output_blobs) > 0:
            break

        time.sleep(5)

    assert len(output_blobs) > 0