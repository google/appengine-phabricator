# Phabricator-on-App-Engine Docker Image

This repo defines a Docker Image that can be used to run Phabricator on App Engine Managed VMs.

## Prerequisites

The built image requires an external MySQL instance, and must be run inside of a GCE VM with
the "https://www.googleapis.com/auth/projecthosting" service account scope.

There are four environment variables that must be passed to a Docker container running the image:

1.  "SQL_HOST": The IPv4 address of the MySQL instance
2.  "SQL_PASS": The root password for the MySQL instance
3.  "PHABRICATOR_BASE_URI": The URL of the Phabricator instance (for linking back to itself)
4.  "ALTERNATE_FILE_DOMAIN": A second URL for the Phabricator instance used for linking to untrusted user content

## Phabricator version

The image is built using a fixed version of the source code for Phabricator and its
dependencies (libphutil and arcanist). These versions are defined by the git submodules
under the "third_party" directory named "arcanist", "libphutil", and "phabricator".

## Included extras

### Git/Phabricator mirror

This image includes a daemon which
[mirrors code reviews to and from git-notes](https://source.developers.google.com/id/AOYtBqJZlBK).

That allows the Phabricator instance to integrate with the
[git-review command line tool](https://source.developers.google.com/id/0tH0wAQFren), and
makes the use of the arcanist command line tool optional.

Operations performed by the mirror daemon show up as the "git-mirror" bot, which is automatically
created.

### Git authentication

This image includes a git credential helper that automatically authenticates access to
[Google Cloud Repositories](https://cloud.google.com/tools/repo/cloud-repositories) using
the service account of the VM (hence the requirement for the projecthosting scope).

## Building

### Getting the code

Since Phabricator and its dependencies are fetched as git submodules, you have to include them
when checking out the code:

    git clone --recurse-submodules https://source.developers.google.com/id/vMh0AXP1f1h phabricator-image
    cd phabricator-image

### Building a testing image

The image is built using Make, and the default target builds a new testing image
(and uploads it to gcr.io):

    make

### Labelling a validated testing image as "latest"

Once you've validated that a testing image is good, mark it as stable using the "release"
make target:

    make release

## Development

### Updating the Phabricator version

This step should be taken with care.

The git-phabricator-mirror tool included in this image calls into the conduit APIs provided by
Phabricator. As such, any breaking changes to those APIs need to be preceded by corresponding
updates to the mirror's use of those APIs.

    git submodule foreach 'cd .. && git submodule update --remote ./'

This will result in pending changes that have to be committed (and pushed) which update the
fixed versions for those submodules.
