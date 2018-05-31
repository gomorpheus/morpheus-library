#!/usr/bin/env bash

###################################################################
# Load the base Omnibus environment
###################################################################
export PATH="/opt/omnibus-toolchain/bin:/usr/local/bin:$PATH"
export OMNIBUS_TOOLCHAIN_INSTALL_DIR=/opt/omnibus-toolchain
export SSL_CERT_FILE=/opt/omnibus-toolchain/embedded/ssl/certs/cacert.pem

echo ""
echo "========================================"
echo "= Environment"
echo "========================================"
echo ""

env -0 | sort -z | tr '\0' '\n'

###################################################################
# Query tool versions
###################################################################

echo ""
echo ""
echo "========================================"
echo "= Tool Versions"
echo "========================================"
echo ""

echo "Bash.........$(bash --version | head -1)"
echo "Bundler......$(bundle --version | head -1)"
echo "GCC..........$(gcc --version | head -1)"
echo "Git..........$(git --version | head -1)"
echo "Make.........$(make --version | head -1)"
echo "Ruby.........$(ruby --version | head -1)"
echo "RubyGems.....$(gem --version | head -1)"

echo ""
echo "========================================"
