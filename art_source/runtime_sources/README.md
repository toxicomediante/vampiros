# Fuentes de los recursos de ejecución

Esta carpeta conserva a máxima resolución los PNG transparentes y ya
limpiados que sirven de fuente para el juego.

Godot ignora todo `art_source/` mediante `.gdignore`. Los archivos de
`assets/` son las copias optimizadas para el tamaño real al que se dibujan en
pantalla. Para rehacer una copia de ejecución, se parte siempre del PNG
correspondiente de esta carpeta; no se amplía una versión ya reducida.

En los enemigos y el NPC de Trujillo se conservan aquí tanto la base maestra
como los atlas finales. Godot solo recibe en `assets/` los atlas que reproduce;
las bases permanecen disponibles para crear animaciones futuras sin engordar
el paquete Web con imágenes que ninguna escena dibuja.
