# Reconciliación: PRD vs. Market Research (market-plataformas-reserva-turnos-complejos-deportivos-padel-futbol5-latam-research-2026-06-11.md)

## Gaps encontrados

### Gap 1: Datos de tamaño/crecimiento de mercado ausentes en la Vision/contexto
La investigación aporta cifras concretas de tracción de mercado que no aparecen en ningún lado del PRD:
> "El pádel argentino está en pleno crecimiento (2-3M jugadores, +30% canchas en 3 años, 46% de los turnos totales según Easycancha), Playtomic admite estar sub-penetrado en el país..." (Research Synthesis, Executive Summary)

**Dónde podría ir:** §1 Vision o como nota de contexto de "Why Now" — un párrafo breve que sitúe el timing de mercado (mercado en expansión, no de suma cero) ayudaría a justificar el "por qué ahora" del MVP, hoy ausente del PRD.

### Gap 2: Contraste explícito "sin comisiones / sin descarga / sin registro" vs. Playtomic no está en el PRD
La recomendación estratégica #2 de la investigación es explícita:
> "Reforzar en el brief el contraste con Playtomic como argumento de 'What Makes This Different': 'sin comisiones, sin descarga, sin registro' responde directamente a las quejas más comunes documentadas contra el líder del mercado."

El PRD (§1 Vision) menciona que ningún competidor resuelve "el roster de un grupo fijo recurrente", pero no menciona el modelo sin costo/sin fricción para el jugador como diferenciador frente a las quejas documentadas (comisiones, cobros duplicados, no-shows injustos, soporte deficiente de Playtomic).

**Dónde podría ir:** §1 Vision, agregar una frase que conecte "el Jugador no paga nada extra, sin instalar/registrarse" con el rechazo documentado a comisiones/cobros de Playtomic — refuerza el "why now"/diferenciación y da contexto a por qué "App móvil/web dedicada para el Jugador" es un Non-Goal deliberado (§5).

### Gap 3: Posicionamiento del panel administrador como alternativa "ligera" frente a CanchaFija/ATC no está reflejado
Hallazgo competitivo clave:
> "Posicionar el panel del administrador como alternativa 'ligera' frente a CanchaFija/ATC, explícitamente para complejos de barrio que no necesitan (ni pueden pagar) un sistema de gestión completo" — y el dato de precio "ATC desde ~$48.500 ARS/mes (1-3 canchas)" como referencia de barrera de costo.

El PRD no menciona este posicionamiento ni el contraste de costo/sobre-funcionalidad frente a software de gestión existente.

**Dónde podría ir:** §1 Vision o como contexto introductorio de §6 MVP Scope — una frase que explique por qué el panel es "deliberadamente acotado" (pagos + ocupación, sin torneos/CRM/escuelitas) en relación a la oferta existente, dando justificación de negocio a varios de los Non-Goals de §5 (motor de precios dinámicos, funcionalidades tipo "comunidad").

### Gap 4: Riesgo competitivo de "feature creep" no mencionado como contexto
La investigación identifica una amenaza concreta:
> "Playtomic u otro player grande podría agregar una funcionalidad de 'roster de grupo + reemplazo vía WhatsApp'... CanchaFija/ATC podrían añadir un bot de WhatsApp para jugadores como feature adicional..." (Competitive Threats)

El PRD no tiene ninguna sección de riesgos ni menciona este timing/ventana competitiva, aunque es relevante para entender la urgencia del piloto.

**Dónde podría ir:** Si se agrega una sección de "Riesgos" o "Why Now" al PRD, este sería el contenido natural. Alternativamente, una mención breve en §1 Vision sobre la "ventana de timing" (mercado en expansión + ausencia de competencia directa en este ángulo, pero no garantizada a futuro).

### Gap 5: Validación del patrón de fútbol 5 por analogía (asunción de la investigación) no está citada
La investigación marca explícitamente:
> "`[ASUNCIÓN]` No se encontraron datos específicos sobre fútbol 5 en Argentina... Se asume que el patrón de 'grupo fijo semanal + coordinación informal por WhatsApp' aplica de forma análoga a fútbol 5."

El PRD trata pádel y fútbol 5 de forma simétrica en todo el documento (FR-1 a FR-3, "indistintamente" en §6.1) sin reconocer que el supuesto de comportamiento para fútbol 5 es una extrapolación por analogía, no validada con datos propios.

**Dónde podría ir:** §9 Assumptions Index — agregar una entrada que documente que el comportamiento de "grupo fijo + WhatsApp" para fútbol 5 se basa en analogía con datos de pádel (no validado externamente), relacionado con §2.2 Non-Users o como nota de riesgo de validación del piloto.

## Resumen
5 gaps identificados — ninguno crítico/bloqueante (el PRD ya incorpora correctamente el hallazgo central de la investigación: el "roster de grupo fijo" como espacio no cubierto). Los gaps son principalmente de **contexto narrativo y justificación estratégica** (Vision/Why Now) que la investigación recomienda explícitamente trasladar y que actualmente no aparecen en el PRD.
