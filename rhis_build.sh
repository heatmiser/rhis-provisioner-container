#!/bin/bash
version=$(<version.txt)
ansiblever="2.4"
imagename="rhis-provisioner-9-$ansiblever"
nocache="false"
multiarch="false"
buildargs=""

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -a|--ansible-ver)
            ansiblever="$2"
            shift # Shift past the value
            ;;
        -n|--no-cache)
            nocache="true"
            #shift # Shift past the value
            ;;
        -m|--multi-arch)
            multiarch="true"
            #shift # Shift past the value
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift # Shift past the option
done

# Check if Ansible is already present, may want to utilize currently initialized Ansible environment, ie venv
if command -v ansible &> /dev/null; then
    echo "Ansible already present and available."
else
    echo "Ansible is either not found or not in PATH, installing..."
    sudo dnf -y install ansible-core
fi

sudo dnf -y install podman
podman login registry.redhat.io

cp ansible.cfg sources/ansible.cfg
cp ansible.cfg.clean sources/ansible.cfg.clean
cp add_softlinks.yml sources/add_softlinks.yml
cp rhis-builder_sample_commands.txt sources/rhis-builder_sample_commands.txt 
cp build_idm_primary.sh sources/build_idm_primary.sh
cp build_sat_primary_connected.sh sources/build_sat_primary_connected.sh
cp build_test_hosts.sh sources/build_test_hosts.sh
cp destroy_test_hosts.sh sources/destroy_test_hosts.sh
cp build_aap_controller24.sh sources/build_aap_controller24.sh
cp build_aap_hub24.sh sources/build_aap_hub24.sh
cp README.md sources/README.md

echo
echo "Running 'podman build' with the following parameters:"
echo
echo "ansible-ver: $ansiblever"
echo "no-cache: $nocache"
echo "multi-arch: $multiarch"
echo

if [[ $ansiblever == "2.5" ]]; then
  buildargs="--build-arg ANSIBLE_VER=2.5"
else
  buildargs="--build-arg ANSIBLE_VER=2.4"
fi

if [[ $nocache == "true" ]]; then
  buildargs+=" --no-cache"
fi

if [[ $multiarch == "true" ]]; then
  podman manifest create $imagename
  buildargs+=" --platform linux/amd64,linux/arm64 --manifest localhost/$imagename"
fi

podman build $buildargs -t $imagename:$version .
podman tag localhost/$imagename:$version $imagename:latest
