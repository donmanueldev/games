# Asteroids — Collision Lab

Primera práctica 2D para aprender detección de choques con **LÖVE 11.x**.

Los recursos gráficos y de audio están en la carpeta `resources/`.
El logo propio está en `resources/logo.png` y también se usa como icono del launcher mediante `conf.lua`.

## Ejecutar

Desde esta carpeta:

```bash
love .
```

## Controles

- `A/D` o flechas: rotar la nave.
- `W` o flecha arriba: acelerar.
- `SPACE`: disparar.
- `P`: pausar.
- `H`: mostrar u ocultar hitboxes circulares.
- `S`: abrir Settings; dentro de Settings usa `W/S` o flechas para seleccionar, `A/D` o izquierda/derecha para cambiar y `ESC` para volver.
- `C`: abrir reasignación de controles desde Settings.
- `T`: abrir el tutorial desde el menú.
- `R` o `ENTER`: reiniciar después de perder.

La pantalla de Settings permite cambiar el modo (`campaign`, `endless` o `time trial`), dificultad, efectos, música, hitboxes y ayuda de controles durante la sesión.

## Conceptos incluidos

- Colisión círculo-círculo.
- Movimiento con velocidad y aceleración.
- Rotación usando vectores.
- Proyectiles con tiempo de vida.
- Bordes envolventes de pantalla.
- Fragmentación de asteroides.
- Estados `menu`, `playing`, `paused`, `gameover` y `victory`.
- Colisiones correctas a través de los bordes envolventes.
- Campaña de 10 niveles con pantalla de victoria.
- Variantes de meteoritos y dificultad por nivel.
- Dificultad progresiva por oleadas.
- Invulnerabilidad temporal después de recibir daño.
- Explosiones, sonidos y récord persistente.
- Mejoras de nave mediante power-ups: escudo, disparo rápido, doble disparo, motor, vida extra y multiplicador de puntos.
- UFOs con proyectiles y jefe final de campaña.
- Partículas, flash de daño, progreso de oleada y fondos dinámicos.
- Tutorial y leaderboard local con nombre, puntaje, dificultad y fecha.
- Música procedural en loop, independiente de los efectos de juego.
- Orbes de puntuación atraídos por el power-up magnético.
- Misión de campaña para destruir 20 asteroides y misión de supervivencia de 60 segundos.
