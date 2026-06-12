
## Deferred from: code review of 1-1-inicializacion-del-proyecto.md (2026-06-11)
- Gemas redundantes en Gemfile: Gemas como jbuilder e image_processing vienen por defecto en Rails 8 pero no están explícitamente requeridas por la arquitectura del MVP. Se mantienen por ser defaults del framework.

## Deferred from: code review of 1-2-login-multi-usuario (2026-06-11)
- `seeds.rb` usa `find_or_create_by!` y no actualiza la password si el usuario admin ya existe con otra. Pre-existente, sin impacto en los AC de esta story.
- `PasswordsController#update` no valida longitud/complejidad mínima de password. Es código del scaffold generado por `bin/rails generate authentication`, fuera del alcance de los AC de Story 1.2 (login). Considerar en una futura story de seguridad/políticas de password.
- Falta test de normalización (mayúsculas/espacios) de `email_address` en el flujo de login (AC#2). `normalizes :email_address` ya aplica en el modelo, pero no hay test explícito que cubra login con email en distinto casing.
- `PasswordsController#update`, en el branch de error, redirige reutilizando el token viejo en vez de generar uno nuevo. Código del scaffold generado, fuera del alcance de esta story.
- La heurística de "sesión expirada" (basada en presencia de cookie `session_id` firmada) no distingue una cookie inválida/forjada de una expiración real — ambas muestran el mismo mensaje "Tu sesión expiró". Limitación de diseño documentada en Dev Notes de Story 1.2.
- `return_to_after_authenticating` solo se guarda para requests GET (no para POST/PUT/DELETE). Limitación de diseño documentada en Dev Notes de Story 1.2, aceptable para el AC#3 actual.
- `InputFieldComponent` usa clases utilitarias de Tailwind aproximadas en lugar de un mapeo 1:1 literal con los tokens de `DESIGN.md`. Desviación ya documentada en Completion Notes de Story 1.2; revisar cuando se implemente el sistema de theming en Story 1.6 (modo claro/oscuro global).
- URLs muy largas guardadas en `session[:return_to_after_authenticating]` podrían exceder el límite de tamaño de la cookie de sesión (4KB). Edge case de baja probabilidad dado el tamaño actual de las rutas de la app.
- `InputFieldComponent#field_id`: si `name` es `nil` o se reduce a string vacío tras `parameterize`, el `id`/`for` del campo queda vacío. Ningún caller actual (`sessions/new.html.erb`) dispara este caso.
- Falta test de integración que cubra el flujo intermedio: login fallido seguido de login exitoso preservando `return_to_after_authenticating` (actualmente solo se testea el caso de éxito directo).
