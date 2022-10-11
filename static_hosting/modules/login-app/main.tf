/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "null_resource" "build_and_push_image" {
  triggers = {
    build_container_image_sha = filesha256("${path.module}/src/build_container.sh")
    go_script_sha             = filesha256("${path.module}/src/main.go")
    go_dependencies_sha       = filesha256("${path.module}/src/go.mod")
    image_tag                 = var.image_tag
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/src"
    command     = "./build_container.sh ${var.project_id} ${var.image_name} ${var.image_tag}"
  }
}