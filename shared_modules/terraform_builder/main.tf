# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "null_resource" "build_and_push_image" {
  triggers = {
    cloudbuild_yaml_sha = sha1(file("${path.module}/cloudbuild.yaml"))
    entrypoint_sha      = sha1(file("${path.module}/entrypoint.bash"))
    dockerfile_sha      = sha1(file("${path.module}/Dockerfile"))
    build_script_sha    = sha1(file("${path.module}/scripts/build_container.sh"))
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = "./scripts/build_container.sh ${var.project_id} ${var.region} ${var.repository_name}"
  }
}