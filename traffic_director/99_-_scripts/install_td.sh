#!/usr/bin/env bash

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

wget -O td-sidecar-injector-xdsv3.tgz https://storage.googleapis.com/traffic-director/td-sidecar-injector-xdsv3.tgz
tar -xzvf td-sidecar-injector-xdsv3.tgz

sed -i 's/your-project-here/test/g' td-sidecar-injector-xdsv3/specs/01-configmap.yaml