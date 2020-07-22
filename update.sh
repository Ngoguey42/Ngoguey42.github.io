set -e

echo '> Making sure that we are in the right directory ************************'
ls .gitignore update.sh

echo '> Cleaning and pulling /io submodule through https **********************'
git submodule deinit -f io
git submodule update --init --recursive --remote io

echo '> Latest in /io commit is ***********************************************'
(cd io && git log --pretty=oneline --reverse | tail -1)

echo '> Updating jsoo compilation flags in bin/dune ***************************'
rpl -- '--pretty --debug-info --source-map-inline --sourcemap' '--opt=3 --no-sourcemap' io/bin/dune

echo '> Listing switches ******************************************************'
opam switch

echo '> Compiling /io *********************************************************'
(cd io && ./build.sh --profile release bin/page_builder.bc.js)

echo '> Listing files to copy from /io ****************************************'
(cd io && find *.html cinquante*.js *.css images lib/articles/*_ex[0123456789].ml -type f) > file-list.txt

echo '> Removing files from previous build ***********************************'
find . -type l | xargs -L1 -I% rm %
rm -rf build/default/bin/page_builder.bc.js

echo '> copying page_builder.bc.js ********************************************'
mkdir -p build/default/bin
cp io/build/default/bin/page_builder.bc.js build/default/bin/page_builder.bc.js

echo '> generating sym link to io/ directory **********************************'
python -c '
import os
root = os.getcwd()
for p in open("file-list.txt").read().strip().split("\n"):
    if os.path.islink(p) or os.path.exists(p):
       assert False

    d = os.path.dirname(p) or "."
    if d != ".":
       cmd = "mkdir -p {}".format(os.path.dirname(p))
       print(cmd)
       os.system(cmd)

    cmd = "ln -s {} {}".format(os.path.relpath(os.path.join("io", p), d), os.path.basename(p))
    print(cmd)
    os.chdir(d)
    os.system(cmd)
    os.chdir(root)
'

echo '> Success. Now: add, commit and push ************************************'
