#!/bin/bash

rm -rf *


if [ $PUBLISH != true ]; then
  echo "Skipping publish step.  PUBLISH != true."
  exit 0
fi

if [[ -z $TREE_NAME ]]; then
  echo "TREE_NAME not set.  Not publishing."
  exit 1
fi

if [[ -z $GIT_DESCRIBE ]]; then
  echo "GIT_DESCRIBE not set. Not publishing."
  exit 1
fi

if [[ -z $ARCH_LIST ]]; then
  echo "ARCH_LIST not set.  Not publishing."
  exit 1
fi

# Sanity prevails, do the copy
for arch in ${ARCH_LIST}; do
   sudo touch /var/www/images/kernel-ci/$TREE_NAME/$GIT_DESCRIBE/$arch.done
done

# Tell the dashboard to import the build.
echo "Build has now finished, reporting result to dashboard."
curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'"}' api.kernelci.org/job

# Check if all builds for all architectures have finished. The magic number here is 3 (arm, arm64, x86)
# This magic number will need to be changed if new architectures are added.
export BUILDS_FINISHED=$(ls /var/www/images/kernel-ci/$TREE_NAME/$GIT_DESCRIBE/ | grep .done | wc -l)
if [[ BUILDS_FINISHED -eq 3 ]]; then
    echo "All builds have now finished, triggering testing..."
    if [ "$TREE_NAME" == "next" ] && [ "$TREE_NAME" == "arm-soc" ] && [ "$TREE_NAME" == "mainline" ] && [ "$TREE_NAME" == "stable" ] && [ "$TREE_NAME" == "rmk" ] && [ "$TREE_NAME" == "tegra" ]; then
        # Public Mailing List
        echo "Sending results pubic mailing list"
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "build_report": 1, "send_to": ["kernel-build-reports@lists.linaro.org"], "format": ["txt", "html"], "delay": 10}' api.kernelci.org/send
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "boot_report": 1, "send_to": ["kernel-build-reports@lists.linaro.org"], "format": ["txt", "html"], "delay": 12600}' api.kernelci.org/send
    elif [ "$TREE_NAME" == "alex" ]; then
        echo "Sending results to Alex Bennee"
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "build_report": 1, "send_to": ["alex.bennee@linaro.org", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 10}' api.kernelci.org/send
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "boot_report": 1, "send_to": ["alex.bennee@linaro.org", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 12600}' api.kernelci.org/send
    elif [ "$TREE_NAME" == "anders" ]; then
        echo "Sending results to Anders Roxell"
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "build_report": 1, "send_to": ["anders.roxell@linaro.org", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 10}' api.kernelci.org/send
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "boot_report": 1, "send_to": ["anders.roxell@linaro.org", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 12600}' api.kernelci.org/send
    elif [ "$TREE_NAME" == "collabora" ]; then
        echo "Sending results to Collabora team"
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "build_report": 1, "send_to": ["sjoerd.simons@collabora.co.uk", "javier.martinez@collabora.co.uk", "luis.araujo@collabora.co.uk", "daniels@collabora.com", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 10}' api.kernelci.org/send
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "boot_report": 1, "send_to": ["sjoerd.simons@collabora.co.uk", "javier.martinez@collabora.co.uk", "luis.araujo@collabora.co.uk", "daniels@collabora.com", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 12600}' api.kernelci.org/send
    elif [ "$TREE_NAME" == "dlezcano" ]; then
        echo "Sending results to Daniel Lezcano"
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "build_report": 1, "send_to": ["daniel.lezcano@linaro.org", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 10}' api.kernelci.org/send
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "boot_report": 1, "send_to": ["daniel.lezcano@linaro.org", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 12600}' api.kernelci.org/send
    elif [ "$TREE_NAME" == "omap" ]; then
        echo "Sending results to Tony Lindgren"
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "build_report": 1, "send_to": ["tony@atomide.com", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 10}' api.kernelci.org/send
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "boot_report": 1, "send_to": ["tony@atomide.com", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 12600}' api.kernelci.org/send
    elif [ "$TREE_NAME" == "lsk" ]; then
        echo "Sending results to LSK team"
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "build_report": 1, "send_to": ["alex.shi@linaro.org", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 10}' api.kernelci.org/send
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "boot_report": 1, "send_to": ["alex.shi@linaro.org", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 12600}' api.kernelci.org/send
    elif [ "$TREE_NAME" == "qcom-lt" ]; then
        echo "Sending results to QCOM-LT team"
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "build_report": 1, "send_to": ["nicolas.dechesne@linaro.org", "srinivas.kandagatla@linaro.org", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 10}' api.kernelci.org/send
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "boot_report": 1, "send_to": ["nicolas.dechesne@linaro.org", "srinivas.kandagatla@linaro.org", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 12600}' api.kernelci.org/send
    elif [ "$TREE_NAME" == "viresh" ]; then
        echo "Sending results to Viresh Kumar"
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "build_report": 1, "send_to": ["viresh.kumar@linaro.org", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 10}' api.kernelci.org/send
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "boot_report": 1, "send_to": ["viresh.kumar@linaro.org", "fellows@kernelci.org"], "format": ["txt", "html"], "delay": 12600}' api.kernelci.org/send
    else
        # Private Mailing List
        echo "Sending results to private mailing list"
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "build_report": 1, "send_to": ["fellows@kernelci.org"], "format": ["txt", "html"], "delay": 10}' api.kernelci.org/send
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "boot_report": 1, "send_to": ["fellows@kernelci.org"], "format": ["txt", "html"], "delay": 12600}' api.kernelci.org/send
    fi

    # Send stable* reports to stable list
    if [[ "$TREE_NAME" == "stable"* ]]; then
        echo "Sending stable results to stable pubic mailing list"
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "build_report": 1, "send_to": ["stable@vger.kernel.org"], "format": ["txt", "html"], "delay": 10}' api.kernelci.org/send
        curl -X POST -H "Authorization: 08a92277-7867-4bde-9a3d-a003b4b9cbbe" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "boot_report": 1, "send_to": ["stable@vger.kernel.org"], "format": ["txt", "html"], "delay": 12600}' api.kernelci.org/send
    fi
fi
