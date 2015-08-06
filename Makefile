build:
# To clean the sub-module and build the xhpast binary needed to find any new class in Docker env
	git submodule foreach 'git clean -fX'
# TODO(ckerur): We should get rid of the below line, since this means we need to run arc liberate
# on the host as a pre-step to docker build. Figure out how to emulate host conditions on docker
# container and remove
	third_party/arcanist/bin/arc liberate third_party/phabricator/
	docker build -t google/phabricator-appengine .

deploy_requirements:
	if [ -z "${PROJECT}" ]; then echo "Usage: make deploy PROJECT=<YOUR_GCP_PROJECT>"; exit 1; fi

deploy: build deploy_requirements
	./install.sh "${PROJECT}"

# Note: The following make targets all require permissions to push to the corresponding gcr.io
# bucket. This means that they are only provided for the core dev team members with that
# permission. Anyone else should simply run the "build" make target, and then run the
# locally-tagged "google/phabricator-appengine" image.

testing: build
	docker tag -f google/phabricator-appengine gcr.io/developer_tools_bundle/bundle-phabricator:testing
	gcloud preview docker push gcr.io/developer_tools_bundle/bundle-phabricator:testing

release:
	gcloud preview docker pull gcr.io/developer_tools_bundle/bundle-phabricator:testing
	docker tag -f gcr.io/developer_tools_bundle/bundle-phabricator:testing gcr.io/developer_tools_bundle/bundle-phabricator:latest
	docker push gcr.io/developer_tools_bundle/bundle-phabricator:latest
