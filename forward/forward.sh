#!/bin/bash -le

shopt -s extglob

die () {
  [[ -n $1 ]] && echo "$*" >&2
  exit 1
}

[[ ${INPUT_MODULE} ]] || die "No module given input"
module=${INPUT_MODULE#votca/}

[[ ${GITHUB_REF} = refs/heads/* ]] || die "GITHUB_REF isn't refs/heads/*, but ${GITHUB_REF}"
branch=${GITHUB_REF#refs/heads/}
push_branch="update_${branch}_submodules"

echo "Working on $module, push $branch to $push_branch of votca/votca"

git checkout -b "${push_branch}" "origin/${push_branch}" || git checkout -b "${push_branch}" "origin/${branch}"
git submodule update --init
git -C "${module}" remote update
git -C "${module}" checkout "origin/${branch}"
git add "${module}"

gitmsg="$(git -C "${module}" log -1 --format=%s)"
if [[ "${gitmsg}" =~ "Merge pull request #"([0-9]*) ]]; then
  pr=" (votca/${module}#${BASH_REMATCH[1]})"
fi

[[ ${CI} = 'true' ]] || exit 0
git config --global user.name "Votca Bot"
git config --global user.email "github@votca.org"
# only push the update_*_submodules, if there was actually a change
if git commit -m "Update ${module} submodule${pr}"; then
  git push origin "${push_branch}"
fi
