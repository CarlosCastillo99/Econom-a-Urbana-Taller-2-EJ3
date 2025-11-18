# Plan de Análisis Pre-Especificado (PAP): Discriminación en el Mercado de Alquiler en Suecia

## 📋 Descripción

Este proyecto presenta un **Plan de Análisis Pre-Especificado (Pre-Analysis Plan, PAP)** completo para un estudio de correspondencia (correspondence study) diseñado para medir discriminación étnica y de género en el mercado de alquiler de vivienda en Suecia. El documento incluye el diseño experimental, hipótesis, estrategia de análisis estadístico y cálculos de poder.

## 👥 Autores

- **Luis Alejandro Rubiano Guerrero** - 202013482 - [la.rubiano@uniandes.edu.co](mailto:la.rubiano@uniandes.edu.co)
- **Andrés Felipe Rosas Castillo** - 202013471 - [a.rosasc@uniandes.edu.co](mailto:a.rosasc@uniandes.edu.co)
- **Carlos Andrés Castillo Cabrera** - 202116837 - [ca.castilloc1@uniandes.edu.co](mailto:ca.castilloc1@uniandes.edu.co)

**Universidad de los Andes** - Curso de Economía Urbana (2025)

## 📁 Estructura del Repositorio

```
├── README.md                    # Este archivo
├── LICENSE                      # Licencia MIT
├── parte3.tex                   # Documento principal en LaTeX con el PAP completo
└── codigo 3 punto.R             # Script de R con simulaciones de poder estadístico
```

## 🔧 Requisitos

### Software necesario
- **R** (versión ≥ 4.0)
- **LaTeX** (para compilar el documento)

### Paquetes de R
```r
library(sandwich)    # Matrices de varianza robustas
library(lmtest)      # Tests de coeficientes con errores robustos
```

## 📖 Contenido del PAP

### 1. Introducción y Motivación

El documento contextualiza el problema de discriminación en mercados de alquiler, con énfasis en:

- **Experimentos de correspondencia** como mejora metodológica sobre auditorías tradicionales
- **El caso sueco**: Sistema de alquiler regulado, baja vacancia (~2%), largas listas de espera (9-20 años en grandes ciudades)
- **Relevancia de política pública**: Conexión con literatura de efectos de barrio y movilidad intergeneracional (Chetty & Hendren, 2018)

### 2. Revisión de Literatura

Síntesis de estudios previos:
- **Pioneros en EE.UU.**: Bertrand & Mullainathan (2004), Hanson & Hawley (2011)
- **Estudios europeos**: Baldini & Federici (2011, Italia), Bosch et al. (2010, España)
- **Evidencia sueca**: Ahmed & Hammarstedt (2008, 2010), Carlsson & Eriksson (2014)

### 3. Diseño Experimental

**Diseño de tratamientos:**

| Identidad | Nombre | Señal transmitida |
|-----------|--------|-------------------|
| Hombre sueco | Björn Svennsson | Nativo sueco, masculino |
| Mujer sueca | Astrid Fjördström | Nativa sueca, femenino |
| Hombre árabe | Muhammad Al-Hassan | Origen árabe/musulmán |

**Características del diseño:**
- Cada anuncio recibe **3 solicitudes** (una por identidad)
- Asignación **completamente aleatorizada** de orden de envío
- Tiempos de espera entre envíos generados por **proceso Poisson**
- Plantillas de email múltiples asignadas aleatoriamente
- Outcome primario: **Callback** (respuesta del arrendador)

### 4. Hipótesis de Investigación

**Principal (H1):**
> Solicitantes con nombres árabes tienen menor probabilidad de callback que solicitantes con nombres suecos nativos

**Secundarias:**
- **H2**: Diferencias de género dentro del grupo nativo
- **H3**: Heterogeneidad por tipo de arrendador (privado vs empresa)
- **H4**: Heterogeneidad espacial (urbano vs no metropolitano)
- **H5**: Heterogeneidad por nivel de renta
- **H6**: Heterogeneidad por origen aparente del arrendador

### 5. Plan de Análisis Estadístico

**Estimandos:**
- Efecto promedio del tratamiento (ATE): $$\tau^{M-B} = \mathbb{E}[Y(M) - Y(B)]$$
- Efectos heterogéneos (CATE): $$\tau^{M-B}(z) = \mathbb{E}[Y(M)-Y(B) | Z_j = z]$$

**Estimadores:**
1. **Diferencia de medias** (estimador no paramétrico)
2. **Modelo de probabilidad lineal (LPM):**
   $$Y_{ij} = \alpha + \beta_M T_{ij}^{M} + \beta_A T_{ij}^{A} + X_j' \gamma + \varepsilon_{ij}$$
3. **Errores estándar clusterizados** a nivel de anuncio

**Especificaciones de robustez:**
- Modelos no lineales (Logit/Probit)
- Sensibilidad a orden de envío
- Exclusión de respuestas automáticas
- Análisis por submuestras

## 🚀 Ejecución del Código

### Script de simulaciones (`codigo 3 punto.R`)

El script implementa cinco secciones independientes:

#### **1. Poder analítico**
Cálculo teórico de poder estadístico para diferencia de proporciones:

```r
# Supuestos:
p_B <- 0.40  # Probabilidad de respuesta (hombre sueco)
p_M <- 0.25  # Probabilidad de respuesta (hombre árabe)
Js <- c(500, 750, 1000, 1500)  # Número de anuncios

# Ejecutar:
power_vals <- sapply(Js, function(J) power_diff_prop(p1 = p_B, p2 = p_M, n1 = J))
```

#### **2. Simulación con clustering**
Simulaciones Monte Carlo que replican el diseño experimental completo:

```r
# Simula 500 experimentos con J=1000 anuncios
power_sim <- sapply(Js, function(J) power_simulation(J, R = 500))
```

**Características:**
- 3 solicitudes por anuncio
- Errores estándar clusterizados (paquete `sandwich`)
- Test bilateral α = 0.05

#### **3. Tamaño Mínimo Detectable (MDE)**
Encuentra el efecto mínimo para alcanzar 80% de poder:

```r
# MDE para J=1000:
mde_diff_prop(p_base = 0.40, J = 1000, target_power = 0.80)
```

#### **4. Poder para heterogeneidad**
Evalúa capacidad de detectar diferencias entre arrendadores privados y empresas:

```r
# Supuestos:
# Privados: brecha de -0.20 (fuerte discriminación)
# Empresas: brecha de -0.05 (débil discriminación)
power_sim_hetero(J = 1000, R = 500)
```

#### **5. Cobertura de intervalos de confianza**
Verifica que los IC al 95% tengan cobertura empírica correcta:

```r
coverage_simulation(J = 1000, R = 500)
# Resultado esperado: ~0.95
```

### Compilar el documento

```bash
pdflatex parte3.tex
bibtex parte3
pdflatex parte3.tex
pdflatex parte3.tex
```

## 📊 Resultados Principales de las Simulaciones

### Tabla de Poder y MDE

| J (anuncios) | Poder analítico | Poder simulado | MDE (80% poder) |
|--------------|-----------------|----------------|-----------------|
| 500          | 0.999           | 1.000          | 0.088           |
| 750          | 1.000           | 1.000          | 0.072           |
| 1000         | 1.000           | 1.000          | 0.062           |
| 1500         | 1.000           | 1.000          | 0.050           |

**Interpretación:**
- Con **efecto verdadero de -0.15** (40% vs 25%), el poder es prácticamente 1.0 incluso con 500 anuncios
- Con **J=1000**, se pueden detectar efectos tan pequeños como **6.2 puntos porcentuales** con 80% de poder

### Otros resultados

- **Poder para heterogeneidad** (J=1000): **0.962**
  - Alta capacidad de detectar diferencias entre privados y empresas
  
- **Cobertura empírica** (J=1000): **0.946**
  - Muy cercana al 95% nominal, validando la inferencia con errores clusterizados

## 🔍 Justificación Teórica

### Modelos de discriminación

1. **Taste-based discrimination (Becker, 1957)**
   - Arrendadores tienen preferencias contra ciertos grupos étnicos
   - Predicción: discriminación incluso sin diferencias en riesgo

2. **Statistical discrimination (Phelps, 1972; Arrow, 1973)**
   - Arrendadores usan etnicidad como proxy de características no observables
   - Predicción: mayor discriminación en segmentos de mayor riesgo percibido

### Conexión con movilidad intergeneracional

- Evidencia reciente (Chetty & Hendren, 2018) muestra que **el barrio importa**
- Discriminación en acceso al arriendo → **segregación residencial** → **desigualdad intergeneracional**
- Barreras en la "puerta de entrada" perpetúan brechas de oportunidades

## 📚 Referencias Principales

- **Bertrand, M., & Mullainathan, S. (2004)**. Are Emily and Greg more employable than Lakisha and Jamal? *American Economic Review*, 94(4), 991-1013.

- **Ahmed, A. M., & Hammarstedt, M. (2008)**. Discrimination in the rental housing market: A field experiment on the Internet. *Journal of Urban Economics*, 64(2), 362-372.

- **Carlsson, M., & Eriksson, S. (2014)**. Discrimination in the rental market for apartments. *Journal of Housing Economics*, 23(1), 41-54.

- **Chetty, R., & Hendren, N. (2018)**. The impacts of neighborhoods on intergenerational mobility I: Childhood exposure effects. *Quarterly Journal of Economics*, 133(3), 1107-1162.

- **Heckman, J. J. (1998)**. Detecting discrimination. *Journal of Economic Perspectives*, 12(2), 101-116.

## 💡 Contribuciones del Estudio

1. **Actualización empírica**: Contexto digital contemporáneo (plataformas online)
2. **Diseño multidimensional**: Etnicidad × género simultáneamente
3. **Análisis de heterogeneidad**: Tipo de arrendador, geografía, nivel de renta
4. **Mejoras metodológicas**: Tiempos Poisson, plantillas múltiples, clasificación de respuestas automáticas
5. **Relevancia de política**: Conexión explícita con efectos de barrio y movilidad social

## 🎯 Validez y Robustez

### Validez interna
- **Amenazas**: Doble decisión, reconocimiento de nombres, respuestas automáticas
- **Mitigaciones**: Clustering, sensibilidad a orden, exclusión de bots

### Validez externa
- **Limitaciones**: Mercado privado online, grandes ciudades
- **Fortalezas**: Representa canal dominante de búsqueda contemporánea

### Consideraciones éticas
- Información mínima necesaria
- Sin completar procesos reales de arriendo
- Anonimato total de arrendadores
- Minimización de carga impuesta al mercado

## 📄 Contexto del Mercado Sueco

### Datos clave (2024-2025)

- **% hogares en alquiler**: ~35%
- **Alquiler promedio nacional**: 7,700 SEK/mes (~770 USD)
- **Alquiler Estocolmo**: 8,600 SEK/mes
- **Tasa de vacancia**: <2% (grandes ciudades)
- **Tiempo de espera (Estocolmo)**: >9 años para vivienda pública
- **Regulación**: Sistema de "valor de uso" (rentas reguladas)

### Características institucionales

- Parque dividido 50/50 entre municipales (allmännyttan) y privados
- Fuerte protección al inquilino
- Debate reciente sobre liberalización parcial (2021, no aprobado)
- Alta inflación reciente → ajustes atípicos en rentas reguladas (4-6% anual)

## 🔬 Aplicaciones

Este PAP es útil para:

- **Investigadores**: Plantilla metodológica para experimentos de correspondencia
- **Policy makers**: Evaluación de discriminación en mercados de vivienda
- **Reguladores**: Diseño de políticas antidiscriminatorias basadas en evidencia
- **Estudiantes**: Ejemplo completo de pre-registro y diseño experimental

## 📧 Contacto

Para preguntas sobre el diseño experimental, simulaciones o metodología, contactar a cualquiera de los autores mediante los correos listados arriba.

---

**Última actualización**: 2025  
**Curso**: Economía Urbana - Universidad de los Andes  
**Tipo de documento**: Plan de Análisis Pre-Especificado (PAP)  
**Estado**: Propuesta metodológica (no implementada empíricamente)

## 📄 Licencia

MIT License - Ver archivo [LICENSE](LICENSE) para más detalles.

---

### Nota Metodológica

Este es un **plan pre-especificado** diseñado como ejercicio académico. En un estudio real, el PAP debería registrarse públicamente (ej. AEA RCT Registry, OSF) **antes** de iniciar la recolección de datos para garantizar transparencia y evitar p-hacking o HARKing (Hypothesizing After Results are Known).
