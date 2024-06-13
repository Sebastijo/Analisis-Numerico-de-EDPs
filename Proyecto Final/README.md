# Inpainting de Imágenes

## Nuestro Objetivo

Nuestro objetivo es crear un proyecto que permita realizar inpainting de imagenes con herramientas de Análisis Numérico de Ecuaciones en Derivadas Parciales. El inpainting consiste en reconstruir partes 
faltantes de imagenes a partir de la información sí disponible de la imagen. Nuestro approach será dividir la imagen en dos imagenes, una conteniendo la textura y otra conteniendo la estructura, y luego
completar las imagenes por separado. Para completar las imagenes, en el caso de la estructura, se modela como un problema de Dirichlet en la parte faltante de la imagen, para la textura, se aplican otros
métodos, entre ellos, el método variacional mediante la minimisación de un funcional.

## Lo Que Hemos Implementado

Hasta ahora, hemos implementado de manera relativamente satisfactoria un proyecto que realiza inpainting estructural de imágenes a color. Este método de inpainting restaura imágenes solamente en base a su estructura (y no textura), o al menos ese es nuestro objetivo.
Pese a esto, logra restaurar imágenes de manera relativamente satisfactoria. Se incorporó, además, una interfaz de usuario gráfica que permite al usuario seleccionar la zona a reparar de manera dinámica (similar a paint).

## Cómo Funciona

En adelante, una función de imagen será una función que toma valores en un rectángulo de $\mathbb{R}^2$ y entrega valores en $[0, 1]$. En una imagen en blanco y negro, esto se puede interpretar como una asignación de luz donde 0 es negro y 1 es blanco.
Una imagen RGB sería entonces un objeto de la forma $(u_R, u_G, u_B)$ donde cada $u_i$ es una función de imagen. Todos los procesos se realizan en cada uno de estos canales RGB de manera independiente.

Primero, con el objetivo de reducir el ruido de la imagen, se realiza un pre-procesamiento de la imagen resolviendo la ecuación de difusión anisotrópica [1]

$$\frac{\partial I}{\partial t} = \text{div}\left( g\left(\|\nabla I\|\right) \nabla I \right),$$

donde $I$ es la función de imagen, $\nabla$ y $\text{div}$ son el gradiente y la divergencia respectivamente, y $g$ es una función (suficientemente regular) de conductividad que debe ser no-negativa, monótona decreciente que cumple $g(0) = 1$.
En nuestro caso, usamos la función $g(x) = \text{exp}\left(-\frac{x^2}{K^2}\right)$, donde $K$ es la constante de difusión. El objetivo de esto es suavizar la imagen en las partes donde el gradiente es cercano a $0$, preservando así la forma de la figura.

Luego se realiza el inpainting estructural, que se realiza mediante la solución de la ecuación [2]

$$ \frac{\partial I}{\partial t} = \nabla (\Delta I) \cdot (\nabla I)^{\perp}, $$

donde $\Omega$ es la zona por restaurar, $I$ es la función de imagen, $\nabla$ y $\nabla^\perp$ son el gradiente y el gradiente rotado en 90 grados respectivamente, y $\Delta$ es el Laplaciano.
El objetivo es arrastrar la información de los bordes siguiendo la dirección en la que el gradiente es pequeño (perpendicular al gradiente) para así seguir las curvas y preservar la estructura.

Ambas ecuaciones son solucionadas con diferencias finitas, esto permite, en el paso de inpainting, mezclar iteraciones de inpainting con iteraciones de difusión para así eliminar ruido y suavizar los resultados del inpainting (esto muestra una mejora
considerable al proceso). Las iteraciones estándar que utilizamos son de 2 iteraciones de difusión anisotrópica por cada 15 de inpainting estructural.

## Resultados

Acá un ejemplo de lo que se logró con 10000 iteraciones de inpainting estructural (mezclado con difusión anisotrópica en proporción 2:15) y 3000 iteraciones de difusión anisotrópica como pre-procesamiento.
Esto se realizó para cada uno de los 3 canales de RGB con lo que la cantidad de iteraciones se triplica. El proceso total tomó alrededor de 10 minutos en un Lenovo IdeaPad3 16GB RAM, Ryzen 7, implementando las partes de alto costo computacional en Julia.
(Usé mi foto de perfil de Microsoft porque estoy en un PC nuevo y es la única que tenía, los resultados fueron buenos así que voy a usarla como ejemplo. Más adelante esta imagen será remplazada).

### Imagen Original:
![Imagen Original](https://github.com/Sebastijo/Analisis-Numerico-de-EDPs/assets/144045099/5986a3b1-9174-4a59-bf9e-a01dc39bde56)

### Imagen Dañada:
![Imagen Dañada](https://github.com/Sebastijo/Analisis-Numerico-de-EDPs/assets/144045099/a3362bd4-203a-4ca7-bb04-ae5494d76495)

### Imagen Restaurada:
![Imagen Restaurada](https://github.com/Sebastijo/Analisis-Numerico-de-EDPs/assets/144045099/0fe12bf2-5ca9-49ff-bc7d-96e34901b50f)

## Comentario Sobre Los Resultados y Próximos Pasos

Los resultados fueron relativamente buenos, con el problema de que la foto se suavizó demasiado. El proceso de inpainting que estamos realizando es local (solo modifica la imagen donde está dañada),
con lo que el problema es la difusión anisotrópica. Es necesario ajustar los parámetros para evitar este tipo de resultados. Intentaremos modificar los parámetros de manera dinámica como es sugerido en [1].

Una vez realizado esto, continuaremos con el inpainting de textura. El objetivo final es descomponer la imagen en estructura y textura para aplicar los procesos por separado.

## Contribuyendo

Si deseas contribuir a este proyecto, por favor sigue las siguientes instrucciones:

1. Haz un fork del repositorio.
2. Crea una nueva rama (`git checkout -b feature/AmazingFeature`).
3. Realiza tus cambios (`git commit -m 'Add some AmazingFeature'`).
4. Sube los cambios a tu rama (`git push origin feature/AmazingFeature`).
5. Abre un Pull Request.
    
## Licencia

Este proyecto está bajo la Licencia Apache 2.0. Para más detalles, consulta el archivo [LICENSE](LICENSE).

## Contacto

Sebastian P. Pincheira - [sebastian.pincheira@ug.uchile.cl](mailto:sebastian.pincheira@ug.uchile.cl)

## Referencias

1. P. Perona and J. Malik, *Scale-space and edge detection using anisotropic diffusion*. IEEE-PAMI 12, pp. 629-639, 1990.
2. M. Bertalmio, G. Sapiro, V. Caselles, and C. Ballester, “Image inpainting,” in *Comput. Graph. (SIGGRAPH 2000)*, July 2000, pp. 417–424.
