#!/bin/bash

# Tests the installation of requirements via bioconda channel and via pip for
# both Python 2 and 3.
#
# Runs main tests and doctests for Python 2 and 3.

set -e
set -x

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for PYTHON in 2 3; do

    # clone into a separate directory just for this python version
    src=/tmp/gffutils_py$PYTHON
    mkdir $src

    # travis-ci pulls the repo using --depth=50 which creates a shallow clone.
    # Getting rid of the `shallow` file lets us clone it elsewhere, avoiding
    # the "fatal: attempt to fetch/clone from a shallow repository" error.
    #
    # The reason we're cloning in the first place is to avoid root doing
    # anything in the existing directory -- especially creating the sdist
    rm -f $HERE/../.git/shallow
    git clone $HERE/.. $src
    cd $src

    # extract version
    VERSION=$(python -c 'exec(open("gffutils/version.py").read());print(version)')

    # ------------------------------------------------------------------------
    # Installs everything from bioconda channel for this python version.
    # Don't run any tests, just make sure things can be installed using conda.
    conda create -y -n bioconda_py${PYTHON} python=$PYTHON
    set +x; source activate bioconda_py${PYTHON}; set -x
    conda install -y -c bioconda --file requirements.txt
    python setup.py install
    (cd / && python -c 'import gffutils')
    set +x; source deactivate; set -x


    # ------------------------------------------------------------------------
    # Installs everything from sdist (simulates from PyPI)
    conda create -y -n py$PYTHON python=$PYTHON
    set +x; source activate py$PYTHON; set -x
    python setup.py clean sdist
    pip install dist/gffutils-${VERSION}.tar.gz
    (cd / && python -c 'import gffutils')

    # Prepare for testing by installing nose for main tests, other optional
    # packages for integration tests (biopython, pybedtools, bedtools) Then run
    # 'em. Exclude slow tests.
    conda install -y nose --file optional-requirements.txt --channel bioconda
    nosetests -x --with-doctest -a '!slow'

    # Install tools and run doctests
    conda install -y --file docs-requirements.txt
    (cd doc && make clean && make doctest)
    set +x; source deactivate; set -x


done
