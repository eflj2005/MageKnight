---
trigger: always_on
---

1. *SEGUIMIENTO*: SIEMPRE Al concluir cada iteración (por cada avance) las tareas completandas y las identificadas a futuro, se guardaran en un archivo que se llame "seguimieto.txt" bien estructurando, especificando fases, bloques de actividades y cada actividad especifica, con su respectiva fecha y estado. el archivo debe quedar en la raíz del proyecto con el fin de a futuro ver como evoluciono el proyecto
2. *SEGUIMIENTO*: SIEMPRE mantener actualizado (por cada avance) el artefacto de tareas "Task", que SIEMPRE reflejara TODO el avance del proyecto con sus fases y subfases detalladas, completadas y sin terminadas, pero sin replicar tal cual todo el detalle de **[seguimiento.txt}**.
3. *SEGUIMIENTO*: para el artefacto de tareas "Task" NUNCA crear archivo nuevo, modificar siempre el artefacto de conversación con IA
4. *SEGUIMIENTO*: SIEMPRE El artefacto "Task" debe tener **granularidad "Senior"**, en lugar de ser una lista simple, cada fase y subfase detalla los subsistemas clave (Motor, Identidad, Reglas de Ciclo, UX Refinada) sin llegar a ser tan detallado como la bitácora histórica de **[seguimiento.txt]** Esto te permitirá ver de un vistazo qué componentes de ingeniería están terminados y qué nos falta por construir.
5. *SEGUIMIENTO*: SIEMPRE garantizar la sicronización del archivos de seguimiento **[seguimiento.txt}** y el artefacto **{Task}**
6. *SEGUIMIENTO*: SIEMPRE Cada 20 iteraciones, generar una copia de toda las conversaciones usaurio/IA de este proyecto en un archivo tipo markdown llamado backupIA.md en raiz del proyecto en formato comprimido para IA. este archivo servira de base para siempre tener el contexto de lo que se ha realizado en todo el proyecto.