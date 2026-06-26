# Airbnb Amsterdam Data Analysis

## 📊 Descripción
Análisis estadístico de precios de Airbnb en Ámsterdam, comparando 
zonas Centro-Este (Centrum-Oost) y Centro-Oeste (Centrum-West).

## 🔍 Metodología
- **T-test independiente (Welch):** Comparación de precios entre barrios
- **ANOVA:** Análisis por tipo de propiedad
- **QQ-plot:** Verificación de normalidad de residuos

## 📈 Principales Hallazgos
- p-valor t-test: 0.9484 (sin diferencia significativa en precios)
- ANOVA F-statistic: 7.306148 (diferencias por tipo de propiedad)
- Alojamientos analizados: 3,472 (1,490 Centrum-Oost + 1,982 Centrum-West)

## 🛠️ Herramientas
- Python 3.x
- pandas, numpy, scipy.stats
- statsmodels (ols, anova_lm)
- matplotlib (visualización)

## 📁 Archivos
- `airbnb_analysis.ipynb` - Jupyter notebook con análisis
- `output_7_1.png` - QQ-plot de residuos
- `README.md` - Este archivo

## 💡 Key Insights
1. No hay diferencia estadística entre Centrum-Oost y Centrum-West
2. El tipo de propiedad es factor significativo en precio
3. Residuos muestran outliers en las colas

---
**Análisis con datos públicos de Airbnb Listings (Ámsterdam, 2021)**
