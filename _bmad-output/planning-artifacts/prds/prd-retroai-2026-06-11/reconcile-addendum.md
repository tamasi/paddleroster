# Reconciliación: PRD vs addendum.md

## Gaps encontrados

1. **Restricciones de desarrollo no reflejadas**
   Addendum: "Desarrollador único (Hernan), sin equipo adicional. Sin plazo fijo establecido... Sin presupuesto definido para servicios externos (ej. WhatsApp Business API, pasarelas de pago)."
   El PRD no menciona restricciones de equipo/timeline/presupuesto en ninguna sección. Podría ir en una nueva sección "Constraints" (entre §1 Vision y §2 Target User) o como nota en §0 Document Purpose, ya que condiciona decisiones de scope y arquitectura.

2. **Costo de WhatsApp Business API a evaluar**
   Addendum: "la integración con WhatsApp Business API (oficial o vía proveedores como Twilio) puede tener costos por mensaje — a investigar en fase de Arquitectura, dado que no hay presupuesto definido."
   El PRD menciona en §8 Open Questions el "enfoque técnico del Bot de WhatsApp (API oficial vs. librería no oficial)" pero no menciona explícitamente la restricción de costo/presupuesto que motiva esa pregunta. Podría agregarse como nota en Open Question 5 o en la sección de Constraints sugerida arriba.

3. **Identidad de Jugador centralizada (nota para Arquitectura) no reflejada**
   Addendum: "se recomienda tenerlo presente al diseñar las entidades de Jugador/Usuario en la fase de Arquitectura, aunque no se implemente la red en el MVP" (identidad de jugador no atada a un complejo específico).
   El PRD menciona la red multi-complejo como Non-Goal (§5) pero no incluye esta nota arquitectónica específica sobre el diseño del modelo de datos de Jugador/Usuario. Podría ir en §5 Non-Goals (como nota de implicancia para arquitectura) o en §9 Assumptions Index.

4. **Contexto del complejo piloto: relación directa con el dueño**
   Addendum: "Hernan tiene relación directa con el dueño/administrador de este complejo — facilita la validación temprana y el acceso a feedback real."
   No aparece en el PRD. Es un dato más de contexto/negocio que de producto, pero podría mencionarse brevemente en §1 Vision o en una sección de Constraints/Context, ya que es relevante para entender la facilidad de validación del piloto (relacionado con SM-2, validación cualitativa).

5. **Persona "(Futuro) Jugador Ocasional/Visitante" — detalle de cuándo se desarrollará**
   Addendum: "queda como persona a desarrollar cuando se trabaje el matching/red multi-complejo."
   El PRD menciona el "Jugador ocasional/visitante" en §2.2 Non-Users (v1) con redacción equivalente ("relevante recién cuando exista una red multi-complejo"). Esto está cubierto — no es un gap real, se incluye solo para confirmar que fue verificado.

## Conclusión

Gaps 1-3 son los más relevantes (restricciones de desarrollo/presupuesto y la nota arquitectónica de identidad de jugador son decisiones/matices de negocio-arquitectura ausentes del PRD). Gap 4 es menor/contextual. Gap 5 no es un gap real (ya cubierto).
