
#/bin/sh
gpg --version
gpg --full-generate-key
git config --global user.signingkey $0
git config --global commit.gpgsign true
git log --show-signature