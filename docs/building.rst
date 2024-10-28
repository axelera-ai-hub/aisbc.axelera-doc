Building
========

- **Build meta-axelera**

  ::

   git clone ssh://<user_name>@gerrit-review.amarulasolutions.com:29418/axelera/meta-axelera
   cd meta-axelera
   kas-container build

- **Build voyager specific**

  ::

   kas-container --ssh-agent shell .config.yaml -c \
          "mkdir -p /builder/.ssh && ssh-keyscan -p 38745 gitea.amarulasolutions.com >> \
          /builder/.ssh/known_hosts && bitbake voyager-image voyager-image-weston"


  Once complete, wic images are found in build/tmp-glibc/deploy/images/itx-3588j

- **Clean kernel-module-axelera**

  ::

   kas-container shell -c "bitbake -c cleansstate kernel-module-axelera"

- **Build kernel-module-axelera**

  ::

   kas-container shell -c "bitbake -c cleansstate kernel-module-axelera"
