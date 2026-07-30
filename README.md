# Vampiros

Juego PVE de construcción de mazos hecho con Godot 4.7.1.

## Estado actual

El repositorio contiene el vertical slice jugable: selección de Juan o Michu,
mapa de ruta, tabernas, combate, recompensas, música y controles para escritorio
y pantalla táctil. La versión Web se publica automáticamente desde `main`.

Android queda pausado hasta la primera versión estable. Su workflow solo puede
arrancarse manualmente.

## Dónde vive cada cosa

| Carpeta | Contenido |
| --- | --- |
| `assets/` | Recursos finales que Godot importa y usa directamente |
| `art_source/` | Originales, mockups y descartes guardados en GitHub, ignorados por Godot |
| `scenes/` | Escenas de Godot |
| `scripts/` | Código del juego |
| `tools/` | Comprobaciones de solo lectura |

No hay recursos descargados desde Drive, URLs temporales ni pasos que creen o
reparen assets durante el despliegue. La música, las imágenes y las fuentes
necesarias están versionadas en este repositorio.

## Flujo de trabajo

1. Guarda el original en `art_source/`.
2. Prepara fuera de Godot la versión final y guárdala en `assets/`.
3. Usa una ruta normal `res://assets/...` desde la escena o el script.
4. Ejecuta `python3 tools/validate_project.py`.
5. Abre `project.godot` con Godot 4.7.1 y prueba el proyecto.
6. Publica el cambio en `main`; GitHub Actions valida, exporta y despliega Web.

El build nunca cambia el proyecto. Si el repositorio está bien, publica
exactamente esos mismos archivos. Si falta algo o Godot muestra un error, el
workflow falla antes de desplegar.

## Exportaciones

Los presets Web y Android declaran explícitamente:

```text
encrypt_pck=false
encrypt_directory=false
```

No se cifra ningún archivo del proyecto.
