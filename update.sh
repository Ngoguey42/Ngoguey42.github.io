set -e

echo '> Cleaning and pulling /io submodule through https **********************'
git submodule deinit -f io
git submodule update --init --recursive --remote io

echo '> Latest /io commit is **************************************************'
(cd io && git log --pretty=oneline --reverse | head -1)

echo '> Updating jsoo compulation flags in bin/dune ***************************'
rpl -- '--pretty --debug-info --source-map-inline --sourcemap' '--opt=3 --no-sourcemap' io/bin/dune

echo '> Listing switches ******************************************************'
opam switch

echo '> Compiling /io *********************************************************'
(cd io && ./build.sh --profile release bin/page_builder.bc.js)

echo '> Listing files to copy from /io ****************************************'
(cd io && find *.html cinquante*.js *.css images lib/articles/*_ex[0123456789].ml build/default/bin/page_builder.bc.js -type f) > file-list.txt

echo '> Removing old website files ********************************************'
mkdir ./website 2>/dev/null || (rm -rf ./website && mkdir ./website)
find . -type l | xargs -L1 -I% rm %

echo '> Fill new website/ directory with rsync ********************************'
# How to avoid `rm -rf` using --files-from and --delete?
rsync -qarvm --files-from=file-list.txt io website
# rsync -arvm --include-from=file-list.txt --include='*/' --exclude='*' io temp --delete

echo '> New tree **************************************************************'
tree -a website || true

echo '> website/* sizes (uncompressed) ****************************************'
du -cbhs `find website -type f` | sort -h

echo '> generating sym link to website/ directory *****************************'
python -c '
import os
os.system("cd ")
root = os.getcwd()
for p in open("file-list.txt").read().strip().split("\n"):
    if os.path.islink(p) or os.path.exists(p):
       assert False

    d = os.path.dirname(p) or "."
    if d != ".":
       cmd = "mkdir -p {}".format(os.path.dirname(p))
       print(cmd)
       os.system(cmd)

    cmd = "ln -s {} {}".format(os.path.relpath(os.path.join("website", p), d), os.path.basename(p))
    print(cmd)
    os.chdir(d)
    os.system(cmd)
    os.chdir(root)
'


echo '> Success. Now: add, commit and push ************************************'
