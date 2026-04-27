 Auditoría del sistema definido en Claude.md               
                                                            
  Lo que funciona bien                                      
                                                            
  Los logs demuestran que el happy path (una variante a la  
  vez, secuencial) sí funciona: los 4 PRs se crean y mergean
   en orden, fast-forward, sin perder datos. La lógica de   
  nombres únicos de rama (run_id-run_attempt) y la exclusión
   de archivos pesados vía REGISTER_EXCLUDE_EXTS están bien
  diseñadas.

  ---
  Bugs / Problemas encontrados
                              
  1. CRÍTICO — El workspace nunca vuelve a la rama base 
  entre steps                                               
  
  Después de gh pr merge --squash --delete-branch, el runner
   local sigue parado en la rama efímera
  (mlops/f1-variant-...). El siguiente paso (make script1)  
  ejecuta en ese estado, y cuando commit-and-pr hace git 
  checkout -b mlops/f1-script-..., lo hace desde la rama
  efímera anterior, no desde checkout_branch.

  Esto forma una cadena de ramas apiladas:                  
  variant-branch  → parent: base@712c015
  script-branch   → parent: variant-branch@38766f1   ← no es
   base                                                     
  check-branch    → parent: script-branch@725bf75           
  register-branch → parent: check-branch@d084d45            
                                                            
  Funciona en los logs porque GitHub squash-merge produce un
   tree idéntico al del commit original, por lo que puede   
  hacer fast-forward igualmente. Es un comportamiento frágil
   y dependiente de un detalle de implementación de GitHub. 
                  
  Fix: Añadir tras cada merge:                              
  git fetch origin "$BASE_BRANCH"
  git checkout "$BASE_BRANCH"                               
  git reset --hard origin/"$BASE_BRANCH"
  O bien hacerlo al inicio de cada invocación de la action.
                                                            
  ---                                                       
  2. CRÍTICO — Sin retry en el merge (el caso de uso        
  principal está roto)                                      
                      
  El objetivo declarado es variantes concurrentes. La action
   tiene retry en el git push, pero el paso de gh pr merge  
  en el workflow no tiene ningún retry. Si dos variantes
  intentan mergear a la misma base al mismo tiempo, una     
  fallará con "branch out of date" o merge conflict. El job
  fallaría sin posibilidad de recuperación.

  ---
  3. MEDIO — always() inconsistente entre los 4 steps
                                                     
  ┌─────────┬─────────┬────────────────────────────────┐ 
  │  Step   │ Crear   │            Merge PR            │    
  │         │   PR    │                                │ 
  ├─────────┼─────────┼────────────────────────────────┤    
  │ variant │ (defaul │ steps.pr-variant.outputs.PR_NU │ 
  │         │ t)      │ MBER != '' (sin always())      │    
  ├─────────┼─────────┼────────────────────────────────┤ 
  │ script  │ (defaul │ always() && steps.pr-script.ou │    
  │         │ t)      │ tputs.PR_NUMBER != ''          │ 
  ├─────────┼─────────┼────────────────────────────────┤    
  │ check   │ always( │ always() && steps.pr-check.out │ 
  │         │ )       │ puts.PR_NUMBER != ''           │ 
  ├─────────┼─────────┼────────────────────────────────┤
  │ registe │ (defaul │ steps.pr-register.outputs.PR_N │    
  │ r       │ t)      │ UMBER != '' (sin always())     │
  └─────────┴─────────┴────────────────────────────────┘    
                  
  El paso check siempre crea su PR (aunque make check1      
  falle) para registrar el estado — eso es intencional. Pero
   el merge de variant y register no tienen always(), lo que
   significa que si un step anterior falla, esos merges
  podrían saltar aunque el PR sí se creó.

  ---
  4. MEDIO — Si el PR de variant falla, los datos se mezclan
   en el siguiente PR                                       
                     
  Si commit-and-pr para variant falla sin crear PR (e.g.,   
  falla el gh api), el output PR_NUMBER queda vacío, el     
  merge se salta, pero el job continúa con make script1. Los
   cambios de variant siguen en el workspace. El siguiente  
  commit-and-pr de script hará git add de sus paths
  específicos (metadata.yaml + outputs.yaml), pero
  metadata.yaml ya tenía cambios de variant sin mergear → el
   PR de script arrastrasrá cambios que corresponden al step
   de variant.

  ---
  5. MENOR — REGISTER_EXCLUDE_EXTS como variable global de 
  job                                                       
     
  El filtro de extensiones pesadas está definido a nivel de 
  job y aplica a todos los pasos de commit-and-pr. En los   
  pasos 1-3, las paths son archivos concretos (no
  directorios), así que el filtro no se aplica. Funciona,   
  pero si alguien en el futuro pone un directorio en el step
   script, los .parquet se excluirán aunque en ese step sí
  debería subirse el .dvc pointer (que DVC ya genera).

  ---
  6. INCOHERENCIA DE DISEÑO — El step register sube todo 
  $VARIANT_ROOT                                             
  
  paths: |                                                  
    ${{ env.VARIANT_ROOT }}   # directorio completo         
    .dvc/config
    dvc.yaml                                                
    dvc.lock      
                                                            
  El directorio completo incluye params.yaml, metadata.yaml,
   outputs.yaml, que ya fueron mergeados en pasos           
  anteriores. Git no los stagea dos veces (no hay cambios), 
  pero es redundante y poco legible. Sería más explícito
  listar solo lo que register1 realmente genera: .gitignore,
   *.dvc, preview.png, *_report.html.

  ---
  Resumen priorizado
                    
  ┌─────┬───────────┬───────────────────────────────────┐
  │  #  │ Severidad │             Problema              │   
  ├─────┼───────────┼───────────────────────────────────┤
  │ 1   │ 🔴        │ Sin re-sync a base branch entre   │   
  │     │ Crítico   │ steps (frágil)                    │
  ├─────┼───────────┼───────────────────────────────────┤   
  │ 2   │ 🔴        │ Sin retry en merge → concurrencia │
  │     │ Crítico   │  real rota                        │   
  ├─────┼───────────┼───────────────────────────────────┤
  │ 3   │ 🟡 Medio  │ always() inconsistente puede      │   
  │     │           │ dejar PRs huérfanos               │   
  ├─────┼───────────┼───────────────────────────────────┤
  │ 4   │ 🟡 Medio  │ Fallo silencioso de PR variant    │   
  │     │           │ contamina el siguiente            │   
  ├─────┼───────────┼───────────────────────────────────┤
  │ 5   │ 🟢 Menor  │ REGISTER_EXCLUDE_EXTS global      │   
  │     │           │ confuso                           │   
  ├─────┼───────────┼───────────────────────────────────┤
  │ 6   │ 🟢 Diseño │ Register sube paths redundantes   │   
  └─────┴───────────┴───────────────────────────────────┘   
  
  ¿Quieres que proceda a implementar las correcciones?  

---
# Solución
Revisando los 6 puntos del audit original contra el estado
   actual:
                                                            
  ---             
  Bug #1 — Workspace nunca vuelve a la rama base entre steps
  → DESCARTADO (aclarado por ti: no se necesita git pull    
  entre fases, dirs únicos por variante, el 3-way merge de
  GitHub lo gestiona correctamente)                         
                  
  ---                                                       
  Bug #2 — Sin retry en el merge
  → ✅ RESUELTO — Todos los merges en las 8 fases tienen
  ahora bucle de 5 intentos con backoff (i×3s)
                                                            
  ---
  Bug #3 — always() inconsistente                           
  → ✅ RESUELTO — always() solo permanece en el CREATE de   
  check y su merge. Eliminado del merge de script en todas
  las fases                                                 
                  
  ---                                                       
  Bug #4 — Fallo silencioso de PR variant contamina el 
  siguiente                                                 
  → NO ERA BUG — Si commit-and-pr falla (exit 1), el step
  falla y los siguientes se saltan por comportamiento por   
  defecto de GitHub Actions. Ya estaba bien                 
   
  ---                                                       
  Bug #5 — REGISTER_EXCLUDE_EXTS global confuso
  → ACEPTADO — Confirmado que se queda en env del job. El
  usuario ajusta las extensiones por fase directamente ahí
  (ya lo está haciendo: f7 tiene .csv/.json, f5 tiene       
  .h5/.parquet, etc.)
                                                            
  ---             
  Bug #6 — Register sube paths redundantes + Script subía 
  solo archivos específicos                                 
  → ✅ RESUELTO — Todos los steps (variant, script, check,
  register) usan ${{ env.VARIANT_ROOT }} como path. La      
  action solo stagea lo que realmente cambió, así que no hay
   redundancia efectiva
                                                            
  ---                                                     
  Extras implementados que no estaban en el audit original:
  - ✅ Fases 2-8 ahora tienen los 4 PRs (antes solo tenían 
  el de register)                                         
  - ✅ Fase 8 tenía permissions, VARIANT_ROOT y             
  REGISTER_EXCLUDE_EXTS ausentes — añadidos    
  - ✅ Fase 2 ejecutaba script2 dos veces — corregido       
  - ✅ Fases 2-7 les faltaba token: en el checkout — añadido
                                                            
  Todo resuelto.                                            
                             