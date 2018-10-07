<!---
  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.
-->

Robots: Continuous Integration Support
======================================

test-patch works hand-in-hand with various CI and other automated build systems.  test-patch will attempt to auto-determine if it is running under such a system and change its defaults to match known configuration parameters automatically. When robots are activated, there is generally some additional/changed behavior:

  * display extra information in the footer
  * change log entries from file names to URLs
  * automatically activate --resetrepo
  * automatically enable the running of unit tests and run them in parallel
  * if possible, write comments to bug systems
  * activate Docker maintenance when --docker is passed
  * automatically determine whether this is a full build (qbt-mode) or testing a patch/merge request/pull request.

Gitlab CI
=========

TRIGGER: ${GITLAB_CI}=true

Artifacts, patch logs, etc are configured to go to a yetus-out directory in the source tree after completion. Adding this stanza to your .gitlab-ci.yml file will upload and store those components for a week in Gitlab CI's artifact retrieval system:

```yaml
  artifacts:
    expire_in: 1 week
    when: always
    paths:
      - yetus-out/

```

Jenkins
=======

TRIGGER: ${JENKINS_URL}=(anything)

Jenkins is extremely open-ended and, given multiple executors, does not run workflows in isolation.  As a result, many more configuration options generally need to be configured as it is not safe for test-patch to autodetermine some settings.

If ${CHANGE_URL} has been set (usually by the [GitHub Branch Source Plugin](https://wiki.jenkins.io/display/JENKINS/GitHub+Branch+Source+Plugin)), then test-patch will use that for the location of the patch to test.  If ${ghprbPullId} and ${GIT_URL} are set (usually by the [GitHub Pull Request Builder Plugin](https://wiki.jenkins.io/display/JENKINS/GitHub+pull+request+builder+plugin)), then test-patch will use these URLs to configure the patch to test as well as test-patch's github plugin.

See also the source tree's Jenkinsfile for some tips and tricks.

See also [precommit-admin](precommit-admin), for special utilities built for Jenkins.

Travis CI
=========

TRIGGER: ${TRAVIS}=true

Travis CI support will update the local checked out source repository to include references to all branches and tags

If ${ARTIFACTS_PATH} is configured, then '--patch-dir' is set to the first listed directory path.  However, links to the location logs must still be configured manually.

Personalities will override the auto-detected Github repository information.  It may be necessary to manually configure it in your .travis.yml file.