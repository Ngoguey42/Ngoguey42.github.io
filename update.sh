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

echo '> removing old ./olds and fill it with rsync ****************************'
# How to avoid `rm -rf` using --files-from and --delete?
mkdir ./docs || (rm -rf ./docs && mkdir ./docs)
rsync -qarvm --files-from=file-list.txt io docs
# rsync -arvm --include-from=file-list.txt --include='*/' --exclude='*' io temp --delete

echo '> New tree **************************************************************'
tree -a docs || true

echo '> docs/* sizes (uncompressed) *******************************************'
du -cbhs `find docs -type f` | sort -h

echo '> Success. Now: add, commit and push ************************************'
