#!/bin/bash
gpg --version
gpg --full-generate-key
git config --global user.signingkey <id>
git config --global commit.gpgsign true
git log --show-signature