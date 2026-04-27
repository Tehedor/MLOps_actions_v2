# Mergeado concurrente de variantes.
Worlfows de github actions que permiten a través de pull request subir variantes en una misma bramch, dando igual si se ejecutan a la vez, ya que ya se encargará github de ir mergenadnolas para que no se pierda ninguna variante.

## Ejemplos incomplentos
src: .github/workflows/reusable_fase1-Explore.yml
src2: .github/actions/commit-and-pr/action.yml

Estos worflows actualmente tienen un prototipo de como puede ser, pero quiero que me pongas la lógica exacta para que no haya ningun problema, ni se pierdan datos.

## Fases que quiero que se vayan subiendo a la rama
1. Cuando se crea la variante
2. Cuando se ejecuta
   Quiero que se suban todos los files, menso los .h5 .parquet ... osea archuvos pesados que se subiran luego a dvc, en la fase 4.
3. Cuando checkea 
4. Cuando se sube a alamacenamiento de dvc


## Ojo`
Antes de implementar nada dime que es lo que esta fallando.


## Logs importantes en fase1:
a. PR- publicar variant
```logs 
2s
Prepare all required actions
Run ./.github/actions/commit-and-pr
Run set -eu
Switched to a new branch 'mlops/f1-variant-v1_0107-24989560519-1'
[mlops/f1-variant-v1_0107-24989560519-1 38766f1] 🤖 AutoML (f1/variant): v1_0107
 2 files changed, 15 insertions(+)
 create mode 100644 executions/f01_explore/v1_0107/metadata.yaml
 create mode 100644 executions/f01_explore/v1_0107/params.yaml
remote: 
remote: Create a pull request for 'mlops/f1-variant-v1_0107-24989560519-1' on GitHub by visiting:        
remote:      https://github.com/***/MLOps_actions_v2/pull/new/mlops/f1-variant-v1_0107-24989560519-1        
remote: 
To https://github.com/***/MLOps_actions_v2
 * [new branch]      mlops/f1-variant-v1_0107-24989560519-1 -> mlops/f1-variant-v1_0107-24989560519-1
branch 'mlops/f1-variant-v1_0107-24989560519-1' set up to track 'origin/mlops/f1-variant-v1_0107-24989560519-1'.
[INFO] Base branch: test2
```

b. Merge PR variant 
```logs
Run gh pr merge "68" --squash --delete-branch
From https://github.com/***/MLOps_actions_v2
 * branch            test2      -> FETCH_HEAD
   712c015..4e908b9  test2      -> origin/test2
Updating 712c015..4e908b9
Fast-forward
 executions/f01_explore/v1_0107/metadata.yaml | 7 +++++++
 executions/f01_explore/v1_0107/params.yaml   | 8 ++++++++
 2 files changed, 15 insertions(+)
 create mode 100644 executions/f01_explore/v1_0107/metadata.yaml
 create mode 100644 executions/f01_explore/v1_0107/params.yaml
```

c. PR - publicar script
```logs
Prepare all required actions
Run ./.github/actions/commit-and-pr
Run set -eu
Switched to a new branch 'mlops/f1-script-v1_0107-24989560519-1'
[mlops/f1-script-v1_0107-24989560519-1 725bf75] 🤖 AutoML (f1/script): v1_0107
 2 files changed, 41 insertions(+), 3 deletions(-)
 create mode 100644 executions/f01_explore/v1_0107/outputs.yaml
remote: 
remote: Create a pull request for 'mlops/f1-script-v1_0107-24989560519-1' on GitHub by visiting:        
remote:      https://github.com/***/MLOps_actions_v2/pull/new/mlops/f1-script-v1_0107-24989560519-1        
remote: 
To https://github.com/***/MLOps_actions_v2
 * [new branch]      mlops/f1-script-v1_0107-24989560519-1 -> mlops/f1-script-v1_0107-24989560519-1
branch 'mlops/f1-script-v1_0107-24989560519-1' set up to track 'origin/mlops/f1-script-v1_0107-24989560519-1'.
[INFO] Base branch: test2
```

d. Merge pr de scritp
```logs
Run gh pr merge "69" --squash --delete-branch
From https://github.com/***/MLOps_actions_v2
 * branch            test2      -> FETCH_HEAD
   4e908b9..841c128  test2      -> origin/test2
Updating 4e908b9..841c128
Fast-forward
 executions/f01_explore/v1_0107/metadata.yaml |  6 ++---
 executions/f01_explore/v1_0107/outputs.yaml  | 38 ++++++++++++++++++++++++++++
 2 files changed, 41 insertions(+), 3 deletions(-)
 create mode 100644 executions/f01_explore/v1_0107/outputs.yaml
```

e. PR - publicar check

```logs
Prepare all required actions
Run ./.github/actions/commit-and-pr
Run set -eu
Switched to a new branch 'mlops/f1-check-v1_0107-24989560519-1'
[mlops/f1-check-v1_0107-24989560519-1 d084d45] 🤖 AutoML (f1/check): v1_0107
 1 file changed, 2 insertions(+), 2 deletions(-)
remote: 
remote: Create a pull request for 'mlops/f1-check-v1_0107-24989560519-1' on GitHub by visiting:        
remote:      https://github.com/***/MLOps_actions_v2/pull/new/mlops/f1-check-v1_0107-24989560519-1        
remote: 
To https://github.com/***/MLOps_actions_v2
 * [new branch]      mlops/f1-check-v1_0107-24989560519-1 -> mlops/f1-check-v1_0107-24989560519-1
branch 'mlops/f1-check-v1_0107-24989560519-1' set up to track 'origin/mlops/f1-check-v1_0107-24989560519-1'.
[INFO] Base branch: test2
```


f. Merge PR de check
```logs
Run gh pr merge "70" --squash --delete-branch
From https://github.com/***/MLOps_actions_v2
 * branch            test2      -> FETCH_HEAD
   841c128..966d657  test2      -> origin/test2
Updating 841c128..966d657
Fast-forward
 executions/f01_explore/v1_0107/metadata.yaml | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
```

g. PR - Publicar register
```logs
Prepare all required actions
Run ./.github/actions/commit-and-pr
Run set -eu
Switched to a new branch 'mlops/f1-register-v1_0107-24989560519-1'
[mlops/f1-register-v1_0107-24989560519-1 f54d00b] 🤖 AutoML (f1/register): v1_0107
 5 files changed, 76 insertions(+), 1 deletion(-)
 create mode 100644 executions/f01_explore/v1_0107/.gitignore
 create mode 100644 executions/f01_explore/v1_0107/01_explore_dataset.parquet.dvc
 create mode 100644 executions/f01_explore/v1_0107/01_explore_report.html
 create mode 100644 executions/f01_explore/v1_0107/preview.png
remote: 
remote: Create a pull request for 'mlops/f1-register-v1_0107-24989560519-1' on GitHub by visiting:        
remote:      https://github.com/***/MLOps_actions_v2/pull/new/mlops/f1-register-v1_0107-24989560519-1        
remote: 
To https://github.com/***/MLOps_actions_v2
 * [new branch]      mlops/f1-register-v1_0107-24989560519-1 -> mlops/f1-register-v1_0107-24989560519-1
branch 'mlops/f1-register-v1_0107-24989560519-1' set up to track 'origin/mlops/f1-register-v1_0107-24989560519-1'.
[INFO] Base branch: test2
```

h. MErge..
```logs
Run gh pr merge "71" --squash --delete-branch
From https://github.com/***/MLOps_actions_v2
 * branch            test2      -> FETCH_HEAD
   966d657..348c5d5  test2      -> origin/test2
Updating 966d657..348c5d5
Fast-forward
 executions/f01_explore/v1_0107/.gitignore          |   1 +
 .../v1_0107/01_explore_dataset.parquet.dvc         |   5 ++
 .../f01_explore/v1_0107/01_explore_report.html     |  69 +++++++++++++++++++++
 executions/f01_explore/v1_0107/metadata.yaml       |   2 +-
 executions/f01_explore/v1_0107/preview.png         | Bin 0 -> 2625 bytes
 5 files changed, 76 insertions(+), 1 deletion(-)
 create mode 100644 executions/f01_explore/v1_0107/.gitignore
 create mode 100644 executions/f01_explore/v1_0107/01_explore_dataset.parquet.dvc
 create mode 100644 executions/f01_explore/v1_0107/01_explore_report.html
 create mode 100644 executions/f01_explore/v1_0107/preview.png
```


## Dato
Si ves algun tipo de incoherencia en como hago esto dimelo


