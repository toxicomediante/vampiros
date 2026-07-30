# Fuentes visuales

Aquí viven los originales, mockups, descartes y versiones de trabajo. Están
guardados en GitHub para que no dependan de enlaces externos.

Godot ignora por completo esta carpeta gracias a `.gdignore`. Así una imagen
con croma verde o magenta, un fondo de cuadrícula o el archivo marcado
`no_usable` nunca puede colarse por accidente en el juego.

La regla de trabajo es:

1. El original o referencia se guarda aquí.
2. La versión final, válida y lista para importar se guarda en `assets/`.
3. Escenas y scripts solo apuntan a rutas `res://assets/...`.
4. GitHub Actions comprueba y exporta; nunca repara, transforma ni genera
   recursos durante la publicación.
