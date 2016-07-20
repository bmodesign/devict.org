#!bash -ex

# This script will build the site and deploy it to the master branch of the
# devict.github.io repo. It is heavily based on this gist:
# https://gist.github.com/domenic/ec8b0fc8ab45f39403dd


# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in .travis_key.enc -out travis_key -d
chmod 600 travis_key
eval `ssh-agent -s`
ssh-add travis_key





# Clean up in case there's leftovers from an old run
rm -rf public/

# Clone the deployment repo into a new repo named "public"
git clone --depth=5 --branch=master git@github.com:devict/devict.github.io.git public

# Generate the site in the public dir, removing any existing files that were
# deleted in the source.
hugo --cleanDestinationDir -d public

# Switch to the build dir
cd public

# If there are no changes to the compiled output then just bail.
if [ -z $(git diff --exit-code) ]; then
    echo "No changes to the output on this push; exiting."
    exit 0
fi

# Prepare git for committing and pushing.
git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

# Stage it all, commit, and push
git add -A
git commit -m "Deploy to GitHub Pages: ${SHA}"
git push origin master

# Go back so we end where we started
cd -
